# Sprint Engine Spec Schema

This is the authoring contract for a sprint workflow spec: the JSON document an
author writes and the sprint engine reads. A spec has two top-level parts: a
`steps` array (the work to run, in order) and a `config` object (settings that
apply to the whole run, some required depending on what the steps contain).
Every rule below is part of that contract; a spec that breaks one is rejected
before anything runs.

Terms are defined the first time they are used, so this document can be read
on its own.

## Step kinds

There are seven step kinds. Four are containers: a container step holds its
own nested steps and can have other container steps nested inside it (up to
the depth cap below). The other three are simple steps: they do one thing and
hold no nested steps.

| Kind | One-clause definition | Container? |
|---|---|---|
| agent | call an AI agent | no |
| gate | a pass/fail check | no |
| shape | reformat results | no |
| parallel | several tracks at once | yes |
| map | repeat steps once per item in a list | yes |
| scored-retry | redo a weak result up to a bounded number of times, keep the best | yes |
| branch | if/else paths | yes |

## Field-optionality table

| Field | Optionality | Rule |
|---|---|---|
| `config.spillDir` | REQUIRED whenever the spec contains any agent step | Every agent step can produce an oversized result (see the spill contract below), and the oversized-output rule has nowhere to save its file without this folder. Requiring it whenever an agent step is present means the rule can never fire in a workflow that has nowhere to save. |
| `map.merge` | OPTIONAL | A map step may declare how its per-item results are combined; if it does not, a default combination applies. |
| `scored-retry.augment` | OPTIONAL | A scored-retry step may declare extra instructions fed into a retry attempt; if absent, a retry attempt runs without augmentation. |
| `scored-retry.mode` | REQUIRED | Two legal values: `first-passing` (stop and keep the first attempt that clears the threshold) and `keep-best` (run every attempt up to the bound and keep the highest-scoring one). |
| `scored-retry.threshold` | REQUIRED for `first-passing` mode; OPTIONAL for `keep-best` mode | `first-passing` needs a threshold to know when to stop; `keep-best` runs to its bound regardless and does not need one. |
| `branch.default` | OPTIONAL | If none of a branch step's conditions match and no `default` is declared, the run stops loudly with a diagnostic instead of guessing which path to take. |
| `config.schemas` | OPTIONAL | An optional config field for declaring schemas. |

## Predicate operator vocabulary

A predicate is how a gate step or a branch step's condition compares a value
already produced by an earlier step against something expected. A predicate
names the step and field it reads (for example, a step called `par` and its
field `failures`) and an operator to apply. Three operators are defined:
`equals`, `lte` (less than or equal), and `gte` (greater than or equal).

**Undefined-sentinel rule.** A predicate's step/field lookup can fail to
resolve -- the named step was never declared, or the field does not exist on
that step's result. When that happens, the predicate does not silently
evaluate the comparison against JavaScript's `undefined`. In plain
JavaScript, a comparison like `undefined <= 1` evaluates to `false` -- so a
naive implementation would misreport a broken spec as a legitimate failing
gate, with no way to tell the two apart. Instead, the engine records the
literal sentinel value `<<undefined>>` for the unresolved operand and halts
the run, so a broken reference is always visible as a broken reference, never
disguised as a normal failing check. This sentinel-and-halt rule applies to
`lte` and `gte` the same way it applies to `equals`.

## Template forms and reference resolution

A template is a `{{...}}` placeholder inside a step's configuration (most
commonly inside an agent step's prompt) that the engine fills in with a value
from an earlier step's result before that step runs. The engine resolves a
template by reading the text inside the braces as a dotted path into the
results collected so far and substituting the value found there.

Three template forms are recognized: `{{step.field}}`, `{{values.PATH}}`, and
`{{#if}}`. `{{step.field}}` is the form fully documented here, resolved by
the split rule below. The other two forms are named as recognized template
syntax; this document does not extend their behavior beyond that literal
syntax.

**Template split rule.** Because a step ID can itself contain dots, the
engine cannot just split a template reference on the first dot. Instead, a
template reference resolves by matching the longest declared step key that is
a prefix of the reference; everything after that matched prefix is the field
path read from that step's result. This also covers a declared step key that
happens to be a prefix of another declared step key -- the longest match
wins.

**Reserved segments.** The segment `attempts` and any bare-numeric segment
(such as `0`, `1`, `2`) are illegal in two places: as a spec step ID anywhere
in the spec, and as a top-level output-schema field name on a scored-retry
step or a map step. Both restrictions exist because the engine uses those
same segments itself in the result-key namespacing grammar below (a
scored-retry step's own attempts live under `attempts`, and a map step's own
items are numbered) -- an author-declared field with the same name would
collide with the engine's own namespacing.

**Nesting depth cap.** Container steps may nest inside one another (a
scored-retry inside a parallel branch, for example), but only to a depth of
3 container levels. A spec nested deeper than that is rejected at validation
with an error naming where the excess nesting occurs. Known use cases need
only 2 levels; the cap can be raised later if a real case demands it.

## Result-key namespacing grammar

Every step's result lands in the run's results map under a key. For a simple
top-level step, the key is just its own step ID. Container steps namespace
their nested steps' keys as dotted paths:

- **branch**: a nested step's key is `<branchId>.<stepId>`.
- **map**: a nested step's key is `<mapId>.<index>`, one entry per item in
  the list the map iterated over.
- **scored-retry**: each attempt's key is `<retryId>.attempts.<n>`; the
  attempt the step actually kept (the winner, by whichever mode was
  declared) is additionally recorded at the plain `<retryId>` key.
- **composites**: when containers nest inside each other, their namespacing
  concatenates -- for example, a scored-retry nested inside a parallel
  branch produces keys like `<branchId>.<retryId>.attempts.<n>`.

## Oversized-output spill contract

An agent step's result can contain a content field too large to return
directly. The threshold is exactly 40,000 bytes -- chosen to sit just below
the largest payload size this repo's evidence has actually carried
byte-exact, so the rule engages before an untested size range is reached,
rather than being padded out to some larger untested margin.

**Producer-side spill.** When a content field would exceed 40,000 bytes, the
agent that produced it writes the content to a file instead of returning it:
it creates the spill directory if needed (`mkdir -p`), writes the content to
`<spillDir>/<stepId>.<field>`, computes the file's sha256 checksum, and
returns a receipt in place of the content: `{spilled: true, path, sha256,
bytes}`. The engine stores that receipt in the results map; the oversized
text itself never transits the agent's own output.

**Pointer sub-fields are first-class referents.** Once a field has spilled,
its receipt's own sub-fields are legal things to reference in a later
template or predicate: `{{A.content.path}}`, `{{A.content.sha256}}`, or a
predicate reading `A.content.bytes`. Referencing the raw field directly --
`{{A.content}}`, or a predicate over `A.content` itself -- after it has
spilled is illegal and halts the run with a named diagnostic, because that
raw value no longer exists in the results map; only its receipt does.

**Worked example.** Suppose a step called `report` produces a `content` field
holding a 45,000-byte piece of text -- over the 40,000-byte threshold. The
agent spills it: it writes the 45,000 bytes to
`<spillDir>/report.content`, hashes the file, and returns `{spilled: true,
path: "<spillDir>/report.content", sha256: "<64-char digest>", bytes: 45000}`
instead of the text. A later step's prompt containing
`{{report.content.path}}` resolves legally -- it reads the path out of the
receipt. The same later step referencing `{{report.content}}` directly halts
with a named diagnostic, because `report.content` is no longer a 45,000-byte
string in the results map; it is a receipt object, and the raw field it used
to hold is gone.

**Size-boundary caveat.** This means the exact same spec can behave
differently purely because of how large a payload turned out to be at run
time: `{{report.content}}` is a perfectly legal reference if `report.content`
stays under 40,000 bytes, and the same reference halts the run if that same
field happens to spill on a different run. Authors should not rely on a
field's size staying below the threshold.

**Size-robust authoring pattern.** Because of that caveat, the size-robust
way to author a spec is to always reference a field's pointer sub-fields
(`.path`, `.sha256`, `.bytes`) whenever that field is one that CAN spill,
rather than referencing the raw field directly -- that way the spec behaves
the same way regardless of the payload's size on any given run.

## Gate verdict domain

A gate step's verdict is one of three values: `pass`, `fail`, or
`uncertain`. Each has different halt behavior:

- **pass**: the run continues to the next step.
- **fail**: the run halts with status `gated`, and the partial results
  collected so far are returned, naming the gate that failed.
- **uncertain**: the run halts with a distinct status, `uncertain`, and the
  raw outcome that produced it is recorded in the trace. A gate lands on
  `uncertain` in any of three cases: its verdict was reported as the
  `uncertain` schema member directly, its reported verdict text could not be
  parsed into a known verdict at all, or it tripped the say-vs-do check
  below.

**Worked example (pass and fail).** A probe run in this repo dispatched two
gate agents. One evaluated an upstream answer of `"alpha"` and returned
`{"verdict":"pass","reason":"Answer is exactly \"alpha\"."}` -- the run
continued past it. The other was deliberately built to fail regardless of
its input and returned `{"verdict":"fail","reason":"engineered failure for
probe"}` -- the branch carrying that gate recorded the failing verdict, and
the overall run's handling of a gate failure applies from there. `uncertain`
has not been exercised by a live probe in this repo; the halt behavior above
is the rule this contract specifies for it.

## Say-vs-do cross-check

A gate can be configured to check not just whether an agent CLAIMS its work
passed, but whether the evidence it points to actually SUPPORTS that claim.
Per-gate config carries three fields: `claimField` (where the claim lives),
`evidenceField` (where the supporting evidence lives), and `minTokenOverlap`
(the minimum overlap required between the two). The engine computes the
token overlap between the claim and the evidence; if it falls below
`minTokenOverlap`, the engine records a trace flag named
`verdict-unsupported` and the gate's outcome becomes `uncertain`, regardless
of what verdict the agent itself reported.

## Reference-fixture capture schema

When a live run of a spec is captured as a reference fixture (for later
replay comparison), each step's capture record has this shape:

```json
{
  "stepKey": "the step's namespaced result key",
  "dispatchIndex": "the order in which this step's dispatch was issued",
  "promptSha256": "sha256 of the exact prompt text sent for this dispatch",
  "output": "the step's captured output"
}
```

## Minimal valid spec

The smallest spec that validates has one step and no agent steps, so it does
not need `config.spillDir`:

```json
{
  "steps": [
    { "id": "pass_through", "type": "shape", "template": {} }
  ],
  "config": {}
}
```
