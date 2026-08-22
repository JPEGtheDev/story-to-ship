# Sprint Engine Runtime Probe Results

The sprint engine runs multi-agent workflows from a JSON spec on top of the
existing workflow runtime. Before building the engine, one probe workflow was
executed against the runtime to turn two design assumptions into observed
behavior instead of guesses:

1. How the runtime's `parallel()` primitive behaves -- what shape it returns,
   whether a failing verdict from a gate -- a step that checks a prior step's
   result and returns a pass or fail verdict -- produced inside one branch
   disrupts result delivery for that branch or the overall join, and whether
   a step that runs after the join can reference both branches' results.
2. Whether a dispatched agent -- an AI agent the workflow starts as a
   separate worker -- can *write* a file to a named absolute path on
   disk. Every prior observation of agent behavior in this repo's probe
   record was a read; the engine's design for handling oversized step output
   (spilling it to a file instead of returning it inline) depends on agents
   being able to write.

This document records the probe workflow script that was run, the run's
structured result, the verification performed on that result, and the
conclusions that can and cannot be drawn from it.

## Probe workflow script

```js
export const meta = {
  name: 'sprint-engine-t0-probe',
  description: 'Probe parallel() semantics and dispatched-agent write capability before the sprint engine is built on them',
  phases: [
    { title: 'Parallel', detail: '2 branches agent->gate, one gate engineered to FAIL' },
    { title: 'PostJoin', detail: 'cross-branch reference + write capability probe' },
  ],
}

const AGENT_SCHEMA = { type: 'object', properties: { answer: { type: 'string' } }, required: ['answer'], additionalProperties: false }
const GATE_SCHEMA = { type: 'object', properties: { verdict: { type: 'string', enum: ['pass', 'fail'] }, reason: { type: 'string' } }, required: ['verdict', 'reason'], additionalProperties: false }

phase('Parallel')
const branchResults = await parallel([
  async () => {
    const a = await agent('Return the single word alpha in the answer field. Do nothing else. Do not run any tools.', { label: 'branch-a:agent', phase: 'Parallel', schema: AGENT_SCHEMA, model: 'sonnet', effort: 'low' })
    const g = await agent('You are a gate check. The upstream step returned answer="' + (a && a.answer) + '". Return verdict "pass" if that answer is exactly the word alpha, otherwise verdict "fail". One-line reason. Do not run any tools.', { label: 'branch-a:gate', phase: 'Parallel', schema: GATE_SCHEMA, model: 'sonnet', effort: 'low' })
    return { agentResult: a, gateResult: g }
  },
  async () => {
    const a = await agent('Return the single word bravo in the answer field. Do nothing else. Do not run any tools.', { label: 'branch-b:agent', phase: 'Parallel', schema: AGENT_SCHEMA, model: 'sonnet', effort: 'low' })
    const g = await agent('You are a gate check acting as a test fixture engineered to fail: regardless of input, return verdict "fail" with reason "engineered failure for probe". For the record, the upstream answer was "' + (a && a.answer) + '". Do not run any tools.', { label: 'branch-b:gate', phase: 'Parallel', schema: GATE_SCHEMA, model: 'sonnet', effort: 'low' })
    return { agentResult: a, gateResult: g }
  },
])

const shapeObservation = {
  isArray: Array.isArray(branchResults),
  length: branchResults === null ? null : branchResults.length,
  topLevelKeys: branchResults === null ? null : Object.keys(branchResults),
  branchANull: branchResults === null ? null : branchResults[0] === null,
  branchBNull: branchResults === null ? null : branchResults[1] === null,
}

phase('PostJoin')
const a0 = branchResults && branchResults[0] ? branchResults[0] : { agentResult: null, gateResult: null }
const b0 = branchResults && branchResults[1] ? branchResults[1] : { agentResult: null, gateResult: null }
const crossRef = await agent('Two parallel branches finished. Branch A: answer "' + (a0.agentResult && a0.agentResult.answer) + '", gate verdict "' + (a0.gateResult && a0.gateResult.verdict) + '". Branch B: answer "' + (b0.agentResult && b0.agentResult.answer) + '", gate verdict "' + (b0.gateResult && b0.gateResult.verdict) + '". Return in the answer field ONE sentence that names both answers and both verdicts. Do not run any tools.', { label: 'post-join-crossref', phase: 'PostJoin', schema: AGENT_SCHEMA, model: 'sonnet', effort: 'low' })

const WRITE_PATH = '/home/JPEG/Projects/story-to-ship/.claude/worktrees/defining-done/scratch/t0-probe/write-test.txt'
const WRITE_SCHEMA = { type: 'object', properties: { wrote: { type: 'boolean' }, path: { type: 'string' }, sha256: { type: 'string' }, bytes: { type: 'integer' }, error: { type: 'string' } }, required: ['wrote', 'path', 'sha256', 'bytes', 'error'], additionalProperties: false }
const writer = await agent('Write-capability probe. Using shell commands, do exactly this: (1) mkdir -p /home/JPEG/Projects/story-to-ship/.claude/worktrees/defining-done/scratch/t0-probe  (2) write exactly one line reading  sprint-engine T0 write probe  followed by a single newline into ' + WRITE_PATH + '  (3) run sha256sum on the file and stat -c %s for its byte count. Return {wrote: true, path: the absolute path, sha256: the 64-character hex digest, bytes: the byte count, error: ""}. If ANY step is refused or fails, return wrote: false with the verbatim error text in the error field and empty-string/zero for the unknown fields. Do not write to any other location.', { label: 'write-probe', phase: 'PostJoin', schema: WRITE_SCHEMA, model: 'sonnet', effort: 'low' })

const READBACK_SCHEMA = { type: 'object', properties: { exists: { type: 'boolean' }, sha256: { type: 'string' }, bytes: { type: 'integer' }, error: { type: 'string' } }, required: ['exists', 'sha256', 'bytes', 'error'], additionalProperties: false }
const readback = await agent('Read-back probe, independent of any earlier step. Run sha256sum ' + WRITE_PATH + ' and stat -c %s ' + WRITE_PATH + ' with shell. Return {exists: true, sha256: the 64-character hex digest, bytes: the byte count, error: ""}. If the file does not exist or reads fail, return exists: false with the verbatim error in the error field and empty-string/zero for unknown fields.', { label: 'read-back-probe', phase: 'PostJoin', schema: READBACK_SCHEMA, model: 'sonnet', effort: 'low' })

return { shapeObservation, branchResults, crossRef, writer, readback }
```

## Run result

The run dispatched 7 agents; all 7 completed with 0 errors. The structured
result returned by the workflow was:

```json
{"shapeObservation":{"isArray":true,"length":2,"topLevelKeys":["0","1"],"branchANull":false,"branchBNull":false},"branchResults":[{"agentResult":{"answer":"alpha"},"gateResult":{"verdict":"pass","reason":"Answer is exactly \"alpha\"."}},{"agentResult":{"answer":"bravo"},"gateResult":{"verdict":"fail","reason":"engineered failure for probe"}}],"crossRef":{"answer":"Branch A returned \"alpha\" with a passing gate verdict, while Branch B returned \"bravo\" with a failing gate verdict."},"writer":{"wrote":true,"path":"/home/JPEG/Projects/story-to-ship/.claude/worktrees/defining-done/scratch/t0-probe/write-test.txt","sha256":"38323d4d6d0dbec223419a87438edf106d70266620ca6a3b3a4bfc5eee9fc763","bytes":29,"error":""},"readback":{"exists":true,"sha256":"38323d4d6d0dbec223419a87438edf106d70266620ca6a3b3a4bfc5eee9fc763","bytes":29,"error":""}}
```

## Verification

The write probe was checked with a triple digest comparison, not taken on the
writing agent's word alone:

- The writing agent reported sha256 `38323d4d6d0dbec223419a87438edf106d70266620ca6a3b3a4bfc5eee9fc763`
  at 29 bytes.
- An independent read-back agent, given no information from the write step
  beyond the target path, reported sha256 `38323d4d6d0dbec223419a87438edf106d70266620ca6a3b3a4bfc5eee9fc763`
  at 29 bytes -- the same digest and byte count.
- The session that launched the probe run (outside the workflow, on the same
  machine) ran its own local `sha256sum` against the file and got
  `38323d4d6d0dbec223419a87438edf106d70266620ca6a3b3a4bfc5eee9fc763` at 29
  bytes again -- the same digest and byte count a third time.

Before the run was started, that same launching session computed the digest
and byte count the write was expected to produce, by running the intended
file content through the same tools directly:

```
$ printf 'sprint-engine T0 write probe\n' | sha256sum
38323d4d6d0dbec223419a87438edf106d70266620ca6a3b3a4bfc5eee9fc763

$ printf 'sprint-engine T0 write probe\n' | wc -c
29
```

All three values matched each other, and all three matched the sha256 digest
computed from the intended file content before the run was started. Three
independent measurements of the same file agreeing on both digest and size is
strong evidence the write actually happened as specified, rather than an
agent fabricating a plausible-looking success report.

## Observed conclusions

- **`parallel()` returns a positional array, not a labeled object.** The
  `shapeObservation` block shows `isArray: true` with `topLevelKeys: ["0",
  "1"]` -- the two branches come back as array indices 0 and 1, not as named
  keys. The engine's branch-namespacing logic must map array positions to
  branch IDs itself; the runtime does not carry branch names through
  `parallel()`.
- **A gate agent returning a fail verdict inside a branch does not disrupt
  that branch's result delivery or the overall join.** Branch B's gate
  returned `verdict: "fail"`, and its full result (`agentResult` and
  `gateResult` both populated) still came back through `parallel()` and the
  run continued to the post-join phase. This is a single run observed, not a
  stress test of failure handling.
- **A step after the join can reference both branches' results.** The
  `crossRef` step named both answers ("alpha", "bravo") and both verdicts
  ("pass" and "fail") correctly in a single sentence, confirming both
  branches' output is visible to a later step in the same workflow.
- **A dispatched agent can create a directory and write a file at a named
  absolute path.** The writer agent ran `mkdir -p`, wrote a file, and
  reported a digest that the independent read-back agent and the launching
  session's own `sha256sum` both confirmed. This is the first observed
  agent write in this repo's probe record -- every prior probe observed
  reads only. The observation is a single instance: one path, one
  environment, a 29-byte file.

## Not measured

- Nothing above the 29-byte write was probed for size. Whether larger writes
  (the sizes the engine's oversized-output spill design would actually use)
  succeed the same way is untested.
- Only one environment and one target path were tried. Write behavior under
  different permissions, filesystems, or sandbox configurations is unknown.
- How the engine should aggregate or contain a failing gate verdict inside a
  branch is an engine design decision, not something this probe observed --
  the probe only shows that the runtime itself does not suppress or corrupt
  the failing branch's result.
- All `parallel()` observations come from a single run with two branches.
  Behavior with more branches, nested `parallel()` calls, or a branch that
  throws instead of returning a fail verdict was not probed.
