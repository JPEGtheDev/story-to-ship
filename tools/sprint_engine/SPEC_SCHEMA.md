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
| `config.spillDir` | REQUIRED whenever the spec contains any agent step | Every agent step can produce an oversized result (see the spill contract below), and the oversized-output rule has nowhere to save its file without this folder. Requiring it whenever an agent step is present means the rule can never fire in a workflow that has nowhere to save. `spillDir` must be an absolute path; a relative path is rejected at validation with a named diagnostic. |
| `map.list` | REQUIRED whenever a map step is used | Names the earlier step (and an optional dotted field path) whose resolved result is the array this map step iterates over: `{step, field}` -- `field` is optional; when absent, the named step's whole result is used as the list directly. A missing or malformed `list`, a `list.step`/`list.field` that does not resolve, or a resolved value that is not an array each halt the run once execution reaches this map step. Structural validation does not check for this field ahead of time -- a spec missing it passes validation and only halts when the run reaches this step. |
| `map.merge` | RECOGNIZED, but declaring it halts the run | This contract names `map.merge` as a way to declare how per-item results are combined, but specifies no default combination for what happens when it is absent -- and the engine does not implement `merge` at all: declaring it on a map step, with any value, halts the run under `map-merge-not-supported` before any iteration dispatches. A map step must currently omit `merge` entirely; per-item results remain addressable only through the `<mapId>.<index>` keys the result-key namespacing grammar defines below. |
| `scored-retry.augment` | OPTIONAL | A scored-retry step may declare extra instructions fed into a retry attempt; if absent, a retry attempt runs without augmentation. |
| `scored-retry.mode` | REQUIRED | Two legal values: `first-passing` (stop and keep the first attempt that clears the threshold) and `keep-best` (run every attempt up to the bound and keep the highest-scoring one). |
| `scored-retry.maxAttempts` | REQUIRED | The bound on how many attempts this step runs: a positive integer. Missing, non-integer, or non-positive values halt the run under a named diagnostic once execution reaches this step -- like `map.list`, this field is not checked by structural validation ahead of time. |
| `scored-retry.threshold` | REQUIRED for `first-passing` mode; OPTIONAL for `keep-best` mode | `first-passing` needs a threshold to know when to stop; `keep-best` runs to its bound regardless and does not need one. A `threshold` that is present but not a finite number is a separate defect from a missing one: structural validation does not check its type, so this only surfaces once execution reaches this step, before any attempt dispatches. |
| `branch.default` | OPTIONAL | If none of a branch step's conditions match and no `default` is declared, the run stops loudly with a diagnostic instead of guessing which path to take. |
| `config.schemas` | OPTIONAL | An optional config field for declaring schemas. |
| `config.expectedSha256` | OPTIONAL | When present, the engine verifies the spec's own integrity before any structural validation or dispatch: it computes a canonical form of the spec (a JSON serialization of the parsed spec with `expectedSha256` itself excluded -- this field cannot bind to a hash that would need to include its own value to be checked) and hashes that canonical form with the engine's own sha256 primitive, identically whether the spec was received as a string or as an already-parsed object. A mismatch halts the run with a named diagnostic before any dispatch occurs. Any textual edit to the spec changes its canonical form and invalidates a previously computed `expectedSha256`; it must be recomputed by this same canonicalize-then-hash procedure after every edit, not carried over from a prior version of the spec. |
| `model` (on an agent or gate step) | OPTIONAL | Selects which model that step's agent call dispatches to. Pass-through only: the engine does not validate the value against any known-model list -- an unrecognized value causes a dispatch-time failure when the agent call is made, not a spec-validation error. When present, this step's own `model` overrides `config.model` for that one step. |
| `config.model` | OPTIONAL | The run-wide default model, applied to every agent/gate step that does not declare its own `model`, and to every engine-synthesized dispatch (a spill-writer or digest-verify step; see the spill contract below) -- those never carry a step-level `model` of their own, so they always follow this default. Precedence is step overrides config; if neither a step's own `model` nor `config.model` is set, the step's dispatch omits a model selection entirely and inherits whatever model the invoking session is already running under. This is the same pass-through-only rule as the per-step `model` field: the engine does not validate the value. |
| `verifyDigest` (on an agent step) | OPTIONAL | Declares a pre-dispatch integrity check on an on-disk file: `{path, sha256}`, both required once the field is present. Before this step's own prompt renders or dispatches, the engine issues a separate digest-verify dispatch for `path` and compares the digest it returns, in-engine, against the declared `sha256`. A match lets the step proceed to its own normal dispatch unchanged. A mismatch halts under `digest-verify-mismatch` before this step ever dispatches its own prompt. An unparseable or malformed digest-verify return halts as `uncertain` under `digest-verify-outcome-unparseable`. A malformed `verifyDigest` declaration itself (missing `path`, or a `sha256` that is not 64 lowercase hex characters) halts under `digest-verify-declaration-malformed` before any dispatch for this step at all, at no agent cost. Applies to agent steps only; a gate step never carries `verifyDigest`. Not checked by structural validation -- only at execute time, when the run reaches this step. |

**A note on "schema."** This word names three different things in this
contract: two resolved here, and a third, unrelated sense -- the shape of a
captured fixture record -- described in the reference-fixture capture
schema section further below. An **output schema** is a JSON-shape
declaration attached to a
single step -- its properties, which of them are required, and so on --
that constrains what that step's own structured output must look like; the
"output-schema field name" the reserved-segments rule refers to below is
this per-step field, and a gate step's verdict being reported as the
`uncertain` **schema member** (in the gate verdict section further below)
means the agent chose "uncertain" directly from that step's own output
schema. `config.schemas`, by contrast, is a single config-level field, not a
per-step schema, and this contract does not specify its internal structure
or how it relates to per-step output schemas -- no source settles that.

## Container authoring syntax

Every step object -- whether declared directly in the top-level `steps`
array or nested inside a track, a case, a map's `steps`, or a
scored-retry's `step` -- carries at minimum an `id` (a string; see the
reserved-segments rule below) and a `type` naming one of the seven step
kinds in the table above. The rest of a step's fields vary by kind, as the
rest of this section describes.

**The four container field names below are ratified by owner ruling.** A
parallel step's nested steps live under `tracks`, a branch step's under
`cases` and `default`, a map step's under `steps`, and a scored-retry
step's wrapped step under `step`. These are no longer this document's own
inference: the step-kind table above and the result-key namespacing grammar
below presuppose that a parallel step has tracks, a branch step has paths, a
map step repeats steps, and a scored-retry step wraps a result being
retried. The owner ruling settles the field names an author writes for that
vocabulary, matching the shapes already in use below.

- **parallel**: nested steps live under `tracks`, an array of `{ id, steps
  }` -- one entry per track, `id` is the track's own ID (the `trackId` the
  namespacing grammar below keys results by), `steps` is that track's step
  sequence.
- **branch step**: nested steps live under `cases`, an array of `{ when,
  steps }` -- `when` is a predicate (shape below), `steps` is the step
  sequence for that path. An optional `default: { steps }` holds the step
  sequence taken when no case matches.
- **map**: the steps repeated once per item live under `steps`, an array of
  step objects. This array may hold more than one step: a map body is
  ratified as a full multi-step process replicated over the list, not
  limited to one step per item. For example, a map step can split a book
  into chapters and run, per chapter, a process of parallel summarization,
  then a consolidation step, then a scored retry until the consolidated
  result is acceptable. The end result of that example is a book summary.
- **scored-retry**: the step being retried lives under `step`, a single
  nested step object rather than a list -- one weak result is retried at a
  time, matching the singular `<retryId>.attempts.<n>` key the namespacing
  grammar assigns per attempt.

**Worked example (a parallel step).** A parallel step with one track
holding one nested step, using the shapes above:

```json
{
  "id": "par1",
  "type": "parallel",
  "tracks": [
    {
      "id": "trackA",
      "steps": [
        {
          "id": "check",
          "type": "gate",
          "predicate": { "step": "upstream", "field": "score", "operator": "gte", "value": 1 }
        }
      ]
    }
  ]
}
```

An **output schema** (the per-step field the reserved-segments rule refers
to, named in the schema-disambiguation paragraph above) is carried on a
step as `outputSchema: { properties: { ... } }`, `properties` reusing this
contract's own word for "its properties, which of them are required" from
that same paragraph. An outputSchema guides what the dispatched agent is
asked to return; the engine itself never validates a dispatch outcome
against it. A result that nominally conforms -- every declared property
present -- but also carries that same structured content re-encoded as a
JSON string in one of its fields passes through unchecked: nothing in this
engine inspects a field's type against its schema beyond what a specific
downstream check (a gate's verdict field, a scored-retry's score field, and
so on) already requires on its own.

A **predicate** (the gate-step and branch-case comparison the next section
describes) is an object `{ step, field, operator, value }`: `step` and
`field` are the step ID and field name it reads, `operator` is one of the
three operators named in that section, `value` is what it compares
against. A branch case's predicate is carried under `when`; a gate step's
predicate is carried under `predicate`. This repo's earlier prototype
evidence instead records predicates with the operator itself as the JSON
key (`{ step, field, <operator>: <value> }`), consistently across the
instances checked, but this section deliberately adopts the
named-operator form above instead, since operator validation is then a
single field lookup rather than a check across whichever key happens to
be present.

**Map-body addressing below the iteration boundary is ratified by owner
ruling.** Call one run of the map's body over one item of the list an
iteration -- an item is one element of the list the map ran over; an
iteration is the body's single run over that item, producing that item's
results. A specific step's result inside one iteration is addressed as
`<mapId>.<index>.<stepId>` -- for example, `chapters.0.consolidate` is the
`consolidate` step's result from the iteration over chapter `0`, in a map
step whose body runs a `consolidate` step per chapter. The plain
`<mapId>.<index>` key, without a step-ID suffix, refers to everything that
iteration produced, not one step within it. This means an iteration's
result is stored as an object keyed by step ID whenever the body holds more
than one step -- the storage shape here is this document's own account of
how the ratified addressing format is realized under the pre-existing
template split rule, not itself a separate ruling -- so the split rule
below resolves a reference like `chapters.0.consolidate` the same way it
resolves any other reference: `chapters.0` is the matched step key, and
`consolidate` is the field path read from that key's result -- here, the
`consolidate` member of the per-iteration object.

Addressing between two steps in the same iteration works differently from
addressing into an iteration from outside it: a step reads an earlier
step's result from its own iteration by bare step name, without any index
or map-ID prefix -- the same bare-name resolution the template split rule
below defines (an exact-key reference with no trailing field path resolves
to that step's entire result). For example, a `consolidate` step reading an
earlier `summarize` step's result from the same iteration writes
`{{summarize}}`, not `{{chapters.0.summarize}}`.

**ID-uniqueness is scoped, inferred the same way.** A step ID must be
unique within its addressing scope: the top-level spec is one scope, each
parallel track is its own scope (namespaced by its `trackId`), each branch
step's combined cases-and-default is one scope (namespaced by the branch
step's own ID), and each map step's body and each scored-retry step's
wrapped step are each their own scope, isolated from the scope they are
nested inside. Two steps sharing a declared ID in two different scopes do
not collide, because each scope's namespaced result keys differ, prefixed
by that scope's own identifier: a parallel track or a branch step's
cases-and-default by its trackId or branch step ID, a map step's body by
its mapId and per-iteration index (per the ratified map-body addressing
above), and a scored-retry step's wrapped step by the enclosing retry
step's own ID in its `<retryId>.attempts.<n>` key. This scoping rule is
this section's own inference, not carried from a ratified wording.

## Predicate operator vocabulary

A predicate is how a gate step or a branch step's condition compares a value
already produced by an earlier step against something expected. A predicate
names the step and field it reads (for example, a step called `par` and its
field `failures` -- one of the aggregate counts a parallel step's result
carries, defined in the result-key namespacing grammar below) and an
operator to apply. Three operators are defined: `equals`, `lte` (less than
or equal), and `gte` (greater than or equal).

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

A shape step's own `template` field (see the minimal valid spec at the end
of this document) is this same mechanism, not a separate one: its value is
an object whose string leaves may contain `{{...}}` placeholders, resolved
exactly as described here, to build the step's output from earlier results.

Three template forms are recognized: `{{step.field}}`, `{{values.PATH}}`, and
`{{#if}}`. `{{step.field}}` is the form fully documented here, resolved by
the split rule below; a bare declared step name with no trailing field (such
as `{{A}}`) is this same form's empty-field-path case, and resolves to that
step's entire result rather than to one field of it, per the split rule's
own account of that case below. The other two forms are named as recognized
template syntax; this document does not extend their behavior beyond that
literal syntax.

**Undefined-sentinel rule (templates).** The same sentinel-and-halt
discipline that applies to predicates also applies to template resolution:
if a template's dotted path does not resolve -- the named step was never
declared, or the field is missing from its result -- the engine does not
silently substitute the literal text "undefined" into the rendered prompt
and continue. It records the sentinel `<<undefined>>` and halts the run,
exactly as an unresolved predicate operand does. This rule matters because
without it, a dangling template reference could silently inject the word
"undefined" into a live agent's prompt while the run kept going -- a
prompt-corruption failure with spend attached and no halt and no
diagnostic. Both resolution paths -- predicate lookups and template
rendering -- carry the identical sentinel-and-halt rule for this reason.

**Template split rule.** Because a step ID can itself contain dots, the
engine cannot just split a template reference on the first dot. Instead, a
template reference resolves by matching the longest declared step key that is
a prefix of the reference; everything after that matched prefix is the field
path read from that step's result. This also covers a declared step key that
happens to be a prefix of another declared step key -- the longest match
wins. A reference that matches a declared step key exactly, with no field
path following it (a bare step name, such as `{{A}}`), resolves to that
step's entire result rather than to one field of it -- the empty-field-path
case of the same rule. This is the mechanism a bare reference like
`{{summarize}}` in the map-body addressing definition above relies on.

**Static-checking scope.** The dangling-reference check above only runs
over two places: a gate step's own `predicate` (or a branch case's `when`),
and a shape step's own `template` field. It does not scan an agent or gate
step's `prompt` field for `{{...}}` placeholders. A dangling reference
inside a prompt is therefore never caught ahead of time -- it surfaces only
when that step actually renders, at dispatch time, as the same
undefined-sentinel halt described above, under the diagnostic
`template-operand-unresolved`: the runtime counterpart of the
`dangling-template-reference` diagnostic a shape step's template would get
caught on statically.

**Reserved segments.** The segment `attempts` and any bare-numeric segment
(such as `0`, `1`, `2`) are illegal in two places: as a spec step ID anywhere
in the spec, and as a top-level output-schema field name on a scored-retry
step or a map step. Both restrictions exist because the engine uses those
same segments itself in the result-key namespacing grammar below (a
scored-retry step's own attempts live under `attempts`, and a map step's own
items are numbered) -- an author-declared field with the same name would
collide with the engine's own namespacing.

**Nesting depth cap.** Container steps may nest inside one another (a
scored-retry step nested inside a parallel step, for example), but only to a depth of
3 container levels. A spec nested deeper than that is rejected at validation
with an error naming where the excess nesting occurs. Known use cases need
only 2 levels; the cap can be raised later if a real case demands it.

## Result-key namespacing grammar

Every step's result lands in the run's results map under a key. For a simple
top-level step, the key is just its own step ID. Container steps namespace
their nested steps' keys as dotted paths.

The word "branch" is used two ways elsewhere in this contract: a parallel
step runs several branches (tracks) at once, and there is also a separate
if/else "branch" step kind. To keep those apart here, this section calls one
strand of a parallel step a **track**, and reserves **branch step** for the
if/else step kind.

- **parallel**: a nested step's key is `<trackId>.<stepId>`, one segment per
  track that ran -- but that composite key only exists in the SCOPE
  ENCLOSING the parallel step, once its join has completed. While a track
  is still running, a step inside that same track addresses an earlier
  sibling step in its own track by bare step name, exactly the way a step
  outside any track addresses an earlier top-level step -- not by the
  `<trackId>.<stepId>` composite, which is not yet in scope from inside the
  track that produced it. A step positioned after the parallel step can
  reference any track's namespaced results once the parallel step has completed;
  referencing a track's step result from a step positioned BEFORE the
  parallel step's join (that is, from inside a different track, or from a
  step that runs concurrently rather than after) is invalid and is caught by
  static validation before dispatch. A parallel step's own result also
  carries aggregate counts alongside the per-track results: `{failures,
  successes, total}`, one count of how many tracks failed, how many
  succeeded, and how many ran in total. These are the fields the predicate
  example above reads (a step called `par` with field `failures` is reading
  this aggregate count).
- **branch step**: a nested step's key is `<branchId>.<stepId>`, where
  `branchId` is the branch step's own ID and `stepId` is a step inside
  whichever path it selected -- this format is inferred from the
  container-namespacing pattern used elsewhere in this section, not carried
  from a ratified wording specific to this step kind.
- **map**: a nested step's key is `<mapId>.<index>.<stepId>`, one entry per
  step per iteration -- one iteration per item in the list the map ran
  over -- ratified by owner ruling (see the map-body addressing definition
  above). The plain `<mapId>.<index>` key, without a step-ID suffix, refers
  to everything that iteration produced.
- **scored-retry**: each attempt's key is `<retryId>.attempts.<n>`; the
  attempt the step actually kept (the winner, by whichever mode was
  declared) is additionally recorded at the plain `<retryId>` key.
- **composites**: when containers nest inside each other, their namespacing
  concatenates -- for example, a scored-retry nested inside a parallel
  track produces keys like `<trackId>.<retryId>.attempts.<n>`.

## Map step execution contract

Inside one iteration of a map step's body, the current list item is
available under the bare key `item` -- a synthetic reference the engine
seeds into that iteration's own results, not one of the body's own declared
steps. Because of this, a body step cannot itself declare the id `item`:
doing so is rejected before any iteration dispatches, under
`map-body-step-id-item-reserved`, so the collision this would otherwise
cause (the body step's own result being silently excluded from the map
step's results) can never reach a live dispatch.

Iterations run sequentially, not concurrently: a later item's dispatches do
not begin until the earlier item's own body has fully settled. An empty
resolved list runs zero iterations and contributes no results at all -- the
run continues past the map step as if it had never been declared, other
than its own empty trace entry.

A map step's own result carries no aggregate object -- nothing like a
parallel step's `{failures, successes, total}` exists for map. A failed
iteration is contained to its own entry and never escalates to a whole-run
halt on its own; it stays inspectable through the run's trace, under that
map step's `iterations` array -- one `{index, status, trace, halt}` entry
per resolved list item, in list order.

## Scored-retry execution contract

A scored-retry step's score comes from one fixed field: the wrapped step's
own result must carry a finite numeric `score` field. An attempt whose
result has no parseable `score` halts the whole scored-retry step as
`uncertain`, regardless of how many attempts remain.

Threshold comparison is `gte`: an attempt clears the threshold when its
score is greater than or equal to it, never strictly greater.

When two or more attempts tie for the highest score, the earliest one
wins -- a later attempt with an equal score never replaces it.

The attempt kept as this step's result (by whichever mode was declared)
lands on the plain `<retryId>` key, per the result-key namespacing grammar
above; it is the wrapped step's own result value, not an object naming
which attempt won.

In `keep-best` mode, if every attempt is scoreless, there is no winner to
keep: the step halts under `scored-retry-no-winner` once `maxAttempts` is
exhausted. The same halt covers `first-passing` mode never clearing its
threshold.

## Branch step execution contract

Once a branch step selects a path (a matching case, or `default`), that
path's own failure is never independently contained: it propagates as this
branch step's own status and halt, exactly as if the branch step itself had
failed. Containment, when it exists, comes from an enclosing container (for
example, a parallel track wrapped around the branch step), not from the
branch step itself.

An empty `cases` array is legal: nothing in this contract requires `cases`
to be non-empty, so a branch step with zero cases falls straight through to
`default` (or the no-match halt the field-optionality table describes
above) exactly as a populated-but-all-non-matching `cases` array would.

A branch step writes no plain `results[branchId]` key of its own -- only
the namespaced `<branchId>.<stepId>` keys for whichever path's steps
actually ran, per the result-key namespacing grammar above.

A predicate that halts instead of resolving to a clean pass/fail (an
unresolved operand, for example) is forwarded to the run with the
evaluator's own locator -- the same `<step>.<field>` operand path a gate
step's own predicate failure would carry -- not a locator built fresh for
the branch step.

## Oversized-output spill contract

An agent step's result can contain a content field too large to return
directly. The threshold is exactly 40,000 bytes -- chosen to sit just below
the measured INLINE-carriage floor of 41,628 characters, the highest point
this repo has confirmed inline payload carriage works intact at (no failure
was ever observed above it, and no ceiling above it has been located). The
threshold sits below that floor by policy: a deliberate, disclosed choice,
not a margin padded out from an untested number.

**Producer-side spill.** When a content field would exceed 40,000 bytes, the
agent that produced it writes the content to a file instead of returning it:
it creates the spill directory if needed (`mkdir -p`), writes the content to
`<spillDir>/<stepId>.<field>` -- `spillDir` is always an absolute path, per
the field-optionality table above -- computes the file's sha256 checksum, and
returns a receipt in place of the content: `{spilled: true, path, sha256,
bytes}`. The engine stores that receipt in the results map; the oversized
text itself never transits the agent's own output. `<stepId>` here means the
step's own FULL namespaced result key -- the same key the "Result-key
namespacing grammar" section describes results being stored under (bare
`stepId` at the top level, `<trackId>.<stepId>` inside a parallel track,
`<mapId>.<index>.<stepId>` inside a map iteration, and so on for the other
containers) -- never the step's bare local id alone. This keeps two
same-named steps in different tracks or map iterations from spilling to the
same file: a step called `inner` in track `t1` spills to
`<spillDir>/t1.inner.<field>`, and the same-named step in track `t2` spills
to `<spillDir>/t2.inner.<field>`.

**Receipt fidelity caveat.** This receipt attests to what the agent that
computed it wrote and hashed -- the engine does not independently
recompute that hash against the content the producer meant to write, so a
transcription mismatch between the producer's own content and the bytes
actually written to `path` is not detected by this contract.

**Spill-path containment.** Names that participate in a spill path -- every
step id at any level (including a map, branch, or scored-retry step's own
id, which composes into the namespaced key the same way a track id does),
each parallel track's own id, and outcome field names -- must not contain
`.`, `/`, or `\`, and must be non-empty. A violation halts under
`spill-path-unsafe` before any writer dispatch. This is the first
execute-time restriction on an author-controlled name: every other
character legal to the validator (spaces, colons, parentheses, non-ASCII
characters, and so on) remains legal in a step or track id, including one
that spills. Engine-generated segments -- a map iteration's numeric index,
and the literal `attempts` and attempt number a scored-retry step composes
-- are never author-controlled and always pass this rule.

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
  below. The unparseable case also covers an outcome that arrives as a
  JSON-encoded STRING rather than an object: the engine does not parse or
  unwrap a string result looking for an embedded verdict, so a gate agent
  that returns `"{\"verdict\":\"pass\"}"` as a string, instead of the
  object `{"verdict":"pass"}`, lands on `uncertain` the same as any other
  unparseable outcome.

**Worked example (pass and fail).** A probe run in this repo dispatched two
gate agents. One evaluated an upstream answer of `"alpha"` and returned
`{"verdict":"pass","reason":"Answer is exactly \"alpha\"."}` -- the run
continued past it. The other was deliberately built to fail regardless of
its input and returned `{"verdict":"fail","reason":"engineered failure for
probe"}` -- the track carrying that gate recorded the failing verdict, and
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

Two implemented conventions this shape relies on. `dispatchIndex` is
0-based and contiguous over the whole run, in the order the engine's
dispatch calls are issued -- not scoped per step, per track, or per
container. And an engine-synthesized dispatch (one the engine itself
issues, not an author-declared step) carries its own distinct `stepKey`:
a digest-verify dispatch (see `verifyDigest` in the field-optionality table
above) uses `<stepId>.verify-digest`, and a spill-writer dispatch (see the
oversized-output spill contract above) uses `<stepId>.<field>.spill-writer`
-- in both cases `<stepId>` is the consuming step's own full namespaced
result key, not its bare local id alone.

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
