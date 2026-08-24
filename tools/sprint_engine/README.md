# Sprint Engine

## What it is

The sprint engine executes a JSON pipeline spec -- an ordered plan of steps
-- against an injected `dispatch(step, context)` function that runs each
agent or gate step. There are seven step kinds: three simple (agent, gate,
shape) and four containers that hold nested steps of their own (parallel,
map, scored-retry, branch). See SPEC_SCHEMA.md's "Step kinds" table for the
one-clause definition of each.

The engine performs no dispatch of its own outside the caller-supplied
`dispatch` function, and it never writes to the filesystem itself -- even
the oversized-output spill mechanism (see below) has the file write happen
on the dispatched agent's own side, never inside the engine module. The
core region has no `require`/`import` of its own: it computes its own
sha256 in pure JavaScript rather than depending on a crypto library.

Two files:

- `engine-core.js` -- the dialect-neutral core, between the
  `===ENGINE-CORE-BEGIN===` / `===ENGINE-CORE-END===` markers. That region
  uses no import, export, require, or top-level return, so the identical
  source text parses standalone as plain CommonJS or inside a
  module-wrapped execution context.
- `sprint-runner.js` -- the workflow-runtime wrapper. It embeds a
  byte-identical copy of the marker-delimited core region (never
  hand-edited there) plus a small runner-glue footer that wires the
  runtime's injected dispatch capability to the engine's own
  `dispatch(step, context)` contract. `tests/inline-copy-check.sh` enforces
  the byte-match between the two copies on every test run.

## Authoring a spec

SPEC_SCHEMA.md is the authoring contract -- read it before writing a spec.
This section is an index into it, not a restatement.

The smallest valid spec (mirrors SPEC_SCHEMA.md's "Minimal valid spec"
section verbatim -- keep the two in sync if either changes):

```json
{
  "steps": [
    { "id": "pass_through", "type": "shape", "template": {} }
  ],
  "config": {}
}
```

Verified against `validateSpec`:

```
$ node -e "
const { validateSpec } = require('./engine-core.js');
console.log('violations:', validateSpec({
  steps: [{ id: 'pass_through', type: 'shape', template: {} }],
  config: {}
}));
"
violations: []
```

An empty violation list means the spec is structurally valid.

Gotchas a first-timer hits (each is a real validation or execute-time rule):

- `config.spillDir` is REQUIRED as soon as the spec has any agent step at
  all, because an agent step's result can exceed the 40,000-byte spill
  threshold and the spill writer needs somewhere to write to.
- `config.expectedSha256`, when present, is checked against a canonical
  hash of the spec before anything runs. It must be recomputed after any
  textual edit to the spec -- it is never carried over from a prior
  version.
- Inside one track of a parallel step (or any other single scope), a step
  reads an earlier sibling by bare name, e.g. `{{run_unit_tests}}` -- not a
  namespaced form. The namespaced `<trackId>.<stepId>` form only exists in
  the scope enclosing the parallel step, once its join has completed.
- A gate step's verdict must come back as a JSON OBJECT
  (`{"verdict": "pass", ...}`), never a JSON-encoded string. A string
  return -- even one that would parse into a legal verdict -- lands on
  `uncertain`, because the engine never unwraps a string looking for an
  embedded verdict.
- A dangling `{{...}}` reference inside an agent or gate step's `prompt`
  field is NOT statically checked. Static validation only scans a gate
  step's `predicate` (or a branch case's `when`) and a shape step's
  `template` field. A bad reference inside a prompt only surfaces at
  render time, as a run halt.

`examples/build-test-review.json` is the worked example: it exercises all
seven step kinds in one pipeline (an agent build step; a parallel step
running unit and integration test tracks, each gated; a map over per-module
review wrapping a scored-retry around each review; a shape step assembling
a report; a branch on risk; and a final gate).

## Running the tests

`bash tests/run.sh` is the single entrypoint. Per its own header, it runs,
in order: reports the node version in use, `node --check` on
engine-core.js, the runner-syntax-check.sh loadability proxy, every
`tests/test-*.js` suite (discovered by glob, not a hard-coded list), and
the inline-copy-check.sh marker-region byte-match gate. Every step runs
regardless of an earlier step's outcome, so one invocation reports every
failure at once; the exit code is nonzero if any step failed.

Current shape: 13 suites, 708 checks. Verified:

```
$ bash tests/run.sh
...
suites: 13 run, 13 passed, 0 failed
...
run.sh: PASS -- all steps succeeded
```
(exit code 0)

`tests/verify-live-fixture.js` is a manually-run CLI verifier for the
committed live-run capture. Per its own header, it runs five checks:

1. (only with `--journal`) every fixture record's output matches the
   corresponding journal-recorded dispatch result.
2. fixture record count equals the journal's own dispatch count.
3. every fixture `promptSha256` is reproducible by replaying the committed
   spec through the real engine -- the self-contained proof that needs no
   journal access.
4. the replay's own terminal state (status, halt diagnostic, halt path)
   matches this fixture's pinned terminal state exactly.
5. the fixture's build-record content hash and its spill-writer receipt
   each match their own pinned values.

Fixtures:

- `tests/fixtures/live/` -- a verbatim capture of a live run of
  `examples/build-test-review.json`: 17 dispatch records in order, covering
  every authored agent and gate step plus two engine-synthesized
  dispatches (a digest-verify and a spill-writer call). Never edit this
  file -- it is a captured record, not an authored fixture.
- `tests/fixtures/edge/` -- hand-authored, deterministic halt fixtures (no
  live agents), replayed by `tests/test-replay.js` against the real
  `specEngineExecute` to pin specific halt behaviors, such as a dangling
  template reference halting under `template-operand-unresolved` with the
  `<<undefined>>` sentinel value.

## Reading a result map

Every step's result lands in the run's results map under a key, per
SPEC_SCHEMA.md's "Result-key namespacing grammar":

- a plain top-level step: its own step ID.
- inside a parallel step, once the join has completed: `<trackId>.<stepId>`.
- inside a map step: `<mapId>.<index>.<stepId>`; the plain `<mapId>.<index>`
  key (no step suffix) refers to everything that iteration produced.
- inside a scored-retry step: each attempt is `<retryId>.attempts.<n>`; the
  attempt actually kept lands additionally at the plain `<retryId>` key.
- inside a branch step: `<branchId>.<stepId>` for whichever path ran; a
  branch step writes no plain `results[branchId]` key of its own.
- nested containers concatenate their namespacing, e.g.
  `<trackId>.<retryId>.attempts.<n>`.

A run's top-level return is `{ status, results, trace, halt }`. When a halt
occurs, `halt` carries `{ path, diagnostic, message, halted: true }`, plus a
`value` field when a sentinel is recorded -- the literal `<<undefined>>` an
unresolved predicate or template operand records instead of silently
evaluating against JavaScript's `undefined`.

`trace` is the run's step-by-step record: one entry per step attempted,
each carrying at minimum `{ step, kind, status, outcome, flags }`. A map
step's own trace additionally nests an `iterations` array, one
`{ index, status, trace, halt }` entry per resolved list item.

## Evidence pointers and re-probe trigger

RUNTIME_FACTS.md holds verbatim-quoted facts, measured directly against the
workflow runtime this engine's design depends on: the script sandbox has no
filesystem and no crypto library available to it (the engine's own sha256
is pure JavaScript because of this); a spec handed to the runtime can arrive
as a raw JSON string even when passed as an object; the output-token cap a
script dispatch can hit (32,000 tokens, observed as an echo-probe failure,
not a measurement of a generated-output ceiling); and that a dispatched
agent can create a directory and write a file to an absolute path.

These are point-in-time observations of one specific runtime version, not a
permanent guarantee. Any harness or runtime upgrade invalidates them as
evidence, and the payload-carriage and spill-contract design decisions that
rest on them must be re-probed before being trusted again after such a
change.

PROBE_RESULTS.md holds the original probe workflow script and its raw
transcript -- the source two further facts in RUNTIME_FACTS.md's closing
section are drawn from.
