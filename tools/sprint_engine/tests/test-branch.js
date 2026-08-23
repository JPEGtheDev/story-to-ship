// Branch suite for the sprint engine's execute loop: the "branch" step
// kind (if/else path selection), per the "Container authoring syntax",
// "Predicate operator vocabulary", and "Result-key namespacing grammar"
// sections of SPEC_SCHEMA.md.
//
// Runs as: node tools/sprint_engine/tests/test-branch.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test -- same house style as test-execute.js/test-parallel.js/
// test-map.js/test-scored-retry.js, including its own local copy of
// `check`/`makeRecordingDispatch` (each suite file is self-contained).
//
// Contract under test, per SPEC_SCHEMA.md plus this implementation's own
// disclosed contract-gap fills (see specEngineExecuteBranchStep's own
// header comment in engine-core.js for the full disclosure each of these
// cases exercises):
//   - a branch step's nested steps live under `cases`, an array of
//     { when, steps }; `when` is a predicate, `steps` is that path's own
//     sequence. An optional `default: { steps }` is taken when no case
//     matches.
//   - cases are evaluated in declared order; the FIRST matching `when`
//     selects that path -- later cases are never evaluated once a match is
//     found, and their own `steps` never dispatch.
//   - a selected path's steps land at `<branchId>.<stepId>`, namespaced by
//     the branch step's own id, mirroring a parallel track's own
//     `<trackId>.<stepId>` namespacing; a step inside the path resolves an
//     earlier step in the SAME path by bare name, and resolves any step
//     that ran before the branch step by bare name too.
//   - no case matches and no `default` is declared -> the run halts loudly
//     under 'branch-no-match-no-default', naming every case predicate that
//     was evaluated (step, field, operator, declared value, and the actual
//     value read) in the halt message -- never a silent fall-through.
//   - a branch step's own selected-path failure PROPAGATES as this
//     branch's own returned status (gap-fill A) -- there is no sibling
//     path left running whose own completion needs protecting the way a
//     track's or a map iteration's own containment protects its siblings,
//     so a gate fail (or any other halt) inside the selected path becomes
//     the run's own status exactly as if those steps had been written
//     directly into the enclosing sequence -- contained only by whatever
//     DOES wrap this branch step (a track, a map iteration, another
//     branch's own selected path, or nothing at all at the top level).
//   - an empty `cases` array is a legal, structurally valid shape
//     (gap-fill B), not a malformed-shape guard failure -- it behaves as
//     "no case can ever match," falling straight through to `default` (or
//     the no-match-no-default halt if there is none).
//   - no plain `results[branchId]` key is ever written (gap-fill C),
//     mirroring map's own choice: the namespacing grammar only defines
//     `<branchId>.<stepId>`, never a bare `<branchId>` key.
//   - malformed-shape guards (`cases` missing/not-an-array, a case entry
//     not an object or missing `when`/`steps`, a present-but-malformed
//     `default`) halt spend-free, before any predicate is evaluated or any
//     step dispatched, under their own 'branch-*' diagnostics.
//   - a matching case always wins over a declared `default` (the default
//     is only ever a fallback, never a tiebreaker); a "skip" case (a
//     non-matching predicate evaluated before the winning one) never
//     dispatches; a case AFTER the winning one is never even EVALUATED
//     (its own `when` is never touched, not just its `steps`) -- a
//     nonexistent-step reference in a later case's `when`, which would
//     halt if evaluated, must never surface once an earlier case already
//     matched. A predicate's `when.step` also accepts a dotted key (an
//     earlier branch step's own namespaced `<branchId>.<stepId>` result),
//     since specEngineEvalPredicate looks `step` up as an exact key, not a
//     dotted split.

'use strict';

const { specEngineExecute } = require('../engine-core.js');

let passCount = 0;
let failCount = 0;

function check(description, condition) {
  if (condition) {
    passCount += 1;
  } else {
    failCount += 1;
    console.error('FAIL: ' + description);
  }
}

// makeRecordingDispatch(outcomesById) -- see test-execute.js's own copy of
// this helper for the full contract; identical here. A single, STATIC
// outcome per step id, returned on every call for that id.
function makeRecordingDispatch(outcomesById) {
  const calls = [];
  const dispatch = async function (step, context) {
    calls.push({ id: step.id, step: step, context: context });
    return outcomesById[step.id];
  };
  dispatch.calls = calls;
  return dispatch;
}

async function main() {
  // -- first-match-wins: case 0 and case 1 BOTH match the same predicate --
  // -- (identical "when"); case 0's path must win -- direction-sensitive: -
  // -- an implementation evaluating cases in reverse order would select ---
  // -- case 1's path (pathB) instead, dispatching pathB and never pathA ---
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        {
          id: 'br1',
          type: 'branch',
          cases: [
            { when: { step: 'upstream', field: 'x', operator: 'equals', value: 'match' }, steps: [{ id: 'pathA', type: 'agent' }] },
            { when: { step: 'upstream', field: 'x', operator: 'equals', value: 'match' }, steps: [{ id: 'pathB', type: 'agent' }] },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { x: 'match' }, pathA: { out: 'A' }, pathB: { out: 'B' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('first-match-wins run completes', outcome.status === 'completed');
    check('exactly two dispatches occur (upstream, then the winning path only)', dispatch.calls.length === 2);
    check('the second dispatch is pathA, not pathB', dispatch.calls[1].id === 'pathA');
    check("case 0's path result lands at br1.pathA", outcome.results['br1.pathA'] && outcome.results['br1.pathA'].out === 'A');
    check("case 1's path never dispatches, so br1.pathB is absent", typeof outcome.results['br1.pathB'] === 'undefined');
    check('no plain results.br1 key is ever written (gap-fill C)', typeof outcome.results.br1 === 'undefined');
  }

  // -- default is taken when no case matches; the non-matching case's -----
  // -- own steps never dispatch --------------------------------------------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        {
          id: 'br2',
          type: 'branch',
          cases: [{ when: { step: 'upstream', field: 'x', operator: 'equals', value: 'nomatch' }, steps: [{ id: 'never', type: 'agent' }] }],
          default: { steps: [{ id: 'defStep', type: 'agent' }] },
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { x: 'other' }, never: { out: 'N' }, defStep: { out: 'D' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a default-taken run completes', outcome.status === 'completed');
    check('exactly two dispatches occur (upstream, then default only)', dispatch.calls.length === 2);
    check("default's step result lands at br2.defStep", outcome.results['br2.defStep'] && outcome.results['br2.defStep'].out === 'D');
    check("the non-matching case's own step never dispatches", typeof outcome.results['br2.never'] === 'undefined');
  }

  // -- no case matches and no default is declared: a loud halt naming -----
  // -- every evaluated predicate (step, field, operator, declared value, --
  // -- and the actual value read) -- not just the diagnostic --------------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        {
          id: 'br3',
          type: 'branch',
          cases: [
            { when: { step: 'upstream', field: 'x', operator: 'equals', value: 'a' }, steps: [{ id: 'p1', type: 'agent' }] },
            { when: { step: 'upstream', field: 'x', operator: 'equals', value: 'b' }, steps: [{ id: 'p2', type: 'agent' }] },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { x: 'z' }, p1: { out: '1' }, p2: { out: '2' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a no-match-no-default run halts with status "failed"', outcome.status === 'failed');
    check('the halt uses the branch-no-match-no-default diagnostic', outcome.halt && outcome.halt.diagnostic === 'branch-no-match-no-default');
    check('the halt message names both cases (cases[0] and cases[1])', outcome.halt.message.indexOf('cases[0]') !== -1 && outcome.halt.message.indexOf('cases[1]') !== -1);
    check('the halt message names case 0\'s step/field/operator', outcome.halt.message.indexOf('step: "upstream"') !== -1 && outcome.halt.message.indexOf('field: "x"') !== -1 && outcome.halt.message.indexOf('operator: "equals"') !== -1);
    check('the halt message names case 0\'s declared value', outcome.halt.message.indexOf('value: "a"') !== -1);
    check('the halt message names case 1\'s declared value', outcome.halt.message.indexOf('value: "b"') !== -1);
    check('the halt message names the actual value read from upstream.x for both cases', outcome.halt.message.split('read "z"').length - 1 === 2);
    check('neither case path ever dispatches -- only upstream does', dispatch.calls.length === 1 && dispatch.calls[0].id === 'upstream');
  }

  // -- a multi-step path: a later step in the same path reads an earlier --
  // -- step's result by bare name; a step AFTER the branch reads INTO the -
  // -- branch's own namespaced results via {{branchId.stepId.field}} ------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        {
          id: 'br4',
          type: 'branch',
          cases: [
            {
              when: { step: 'upstream', field: 'x', operator: 'equals', value: 'go' },
              steps: [
                { id: 'step1', type: 'agent' },
                { id: 'step2', type: 'agent', prompt: 'ref {{step1.val}}' },
              ],
            },
          ],
        },
        { id: 'after', type: 'shape', template: { fromBranch: '{{br4.step2.val}}' } },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { x: 'go' }, step1: { val: 'v1' }, step2: { val: 'v2' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a multi-step branch path run completes', outcome.status === 'completed');
    const step2Call = dispatch.calls.filter(function (c) { return c.id === 'step2'; })[0];
    check("step2's prompt resolved step1's result by bare name, within the path", !!step2Call && step2Call.step.prompt === 'ref v1');
    check('both path steps land under their namespaced keys', outcome.results['br4.step1'].val === 'v1' && outcome.results['br4.step2'].val === 'v2');
    check(
      'a step after the branch resolves a template INTO the branch results via {{branchId.stepId.field}}',
      outcome.results.after.fromBranch === 'v2'
    );
  }

  // -- malformed-shape guards: each halts spend-free, before any dispatch,
  // -- under its own named diagnostic --------------------------------------
  {
    const spec = {
      steps: [{ id: 'before', type: 'agent' }, { id: 'brBad', type: 'branch' }],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ before: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a branch step with no "cases" field fails at execute time', outcome.status === 'failed');
    check('the halt uses the branch-cases-not-array diagnostic', outcome.halt && outcome.halt.diagnostic === 'branch-cases-not-array');
    check('the step before the branch still dispatches, but nothing inside the branch does', dispatch.calls.length === 1 && dispatch.calls[0].id === 'before');
  }
  {
    const spec = {
      steps: [{ id: 'before', type: 'agent' }, { id: 'brBad', type: 'branch', cases: ['not-an-object'] }],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ before: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a branch step with a non-object case entry fails at execute time', outcome.status === 'failed');
    check('the halt uses the branch-case-not-object diagnostic', outcome.halt && outcome.halt.diagnostic === 'branch-case-not-object');
    check('nothing inside the malformed branch dispatches', dispatch.calls.length === 1 && dispatch.calls[0].id === 'before');
  }
  {
    const spec = {
      steps: [{ id: 'before', type: 'agent' }, { id: 'brBad', type: 'branch', cases: [{ steps: [{ id: 'never', type: 'agent' }] }] }],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ before: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a branch case missing "when" fails at execute time', outcome.status === 'failed');
    check('the halt uses the branch-case-when-missing diagnostic', outcome.halt && outcome.halt.diagnostic === 'branch-case-when-missing');
    check('nothing inside the malformed branch dispatches', dispatch.calls.length === 1 && dispatch.calls[0].id === 'before');
  }
  {
    const spec = {
      steps: [
        { id: 'before', type: 'agent' },
        { id: 'brBad', type: 'branch', cases: [{ when: { step: 'before', field: 'ok', operator: 'equals', value: true } }] },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ before: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a branch case missing "steps" fails at execute time', outcome.status === 'failed');
    check('the halt uses the branch-case-steps-not-array diagnostic', outcome.halt && outcome.halt.diagnostic === 'branch-case-steps-not-array');
    check('nothing inside the malformed branch dispatches (guard fires before any predicate evaluates)', dispatch.calls.length === 1 && dispatch.calls[0].id === 'before');
  }
  {
    const spec = {
      steps: [{ id: 'before', type: 'agent' }, { id: 'brBad', type: 'branch', cases: [], default: { notSteps: true } }],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ before: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a branch step with a malformed "default" fails at execute time', outcome.status === 'failed');
    check('the halt uses the branch-default-malformed diagnostic', outcome.halt && outcome.halt.diagnostic === 'branch-default-malformed');
    check('nothing inside the malformed branch dispatches', dispatch.calls.length === 1 && dispatch.calls[0].id === 'before');
  }

  // -- an empty "cases" array is a legal shape (gap-fill B), not a --------
  // -- malformed-shape guard failure: with a default present, it is -------
  // -- taken directly, dispatching nothing else ----------------------------
  {
    const spec = {
      steps: [{ id: 'br7', type: 'branch', cases: [], default: { steps: [{ id: 'd7', type: 'agent' }] } }],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ d7: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an empty-cases branch with a default completes', outcome.status === 'completed');
    check('only the default step dispatches', dispatch.calls.length === 1 && dispatch.calls[0].id === 'd7');
    check("the default step's result lands at br7.d7", outcome.results['br7.d7'].ok === true);
  }

  // -- an empty "cases" array with NO default halts under the same --------
  // -- no-match-no-default diagnostic, naming that zero predicates were ---
  // -- evaluated (not a malformed-shape guard) -----------------------------
  {
    const spec = { steps: [{ id: 'br8', type: 'branch', cases: [] }], config: {} };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('an empty-cases, default-less branch halts with status "failed"', outcome.status === 'failed');
    check('the halt uses the branch-no-match-no-default diagnostic', outcome.halt && outcome.halt.diagnostic === 'branch-no-match-no-default');
    check('the halt message notes zero cases were evaluated', outcome.halt.message.indexOf('"cases" is empty') !== -1);
    check('nothing dispatches', dispatch.calls.length === 0);
  }

  // -- a container step nested inside a branch path (a scored-retry, ------
  // -- here) is an executable container kind: its results land under ------
  // -- composite keys of the shape "<branchId>.<retryId>.attempts.<n>" ----
  // -- (and the plain "<branchId>.<retryId>" winner key), per the ---------
  // -- result-key namespacing grammar's "composites" rule -- this falls ---
  // -- out for free because specEngineExecuteScoredRetryStep writes into --
  // -- whatever results object it is handed (the branch path's own -------
  // -- private results object), and this branch's own re-namespacing ------
  // -- prefixes those keys with "br5." the same way it prefixes any other -
  // -- path step's key ------------------------------------------------------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        {
          id: 'br5',
          type: 'branch',
          cases: [
            {
              when: { step: 'upstream', field: 'x', operator: 'equals', value: 'go' },
              steps: [{ id: 'retryC', type: 'scored-retry', mode: 'first-passing', threshold: 5, maxAttempts: 2, step: { id: 'attempt', type: 'agent' } }],
            },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { x: 'go' }, attempt: { score: 7 } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a branch path with a nested scored-retry completes', outcome.status === 'completed');
    check('the composite plain winner key is present', outcome.results['br5.retryC'] && outcome.results['br5.retryC'].score === 7);
    check('the composite attempts key is present', outcome.results['br5.retryC.attempts.0'] && outcome.results['br5.retryC.attempts.0'].score === 7);
    check('the two composite keys hold the identical value', outcome.results['br5.retryC'] === outcome.results['br5.retryC.attempts.0']);
  }

  // -- a selected path's own failure (a gate fail, here) PROPAGATES as ----
  // -- this run's own status (gap-fill A) -- it is never silently -------
  // -- contained the way a track's or an iteration's own failure is, and --
  // -- the step after the branch never runs -------------------------------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        {
          id: 'br6',
          type: 'branch',
          cases: [{ when: { step: 'upstream', field: 'x', operator: 'equals', value: 'go' }, steps: [{ id: 'gateStep', type: 'gate' }] }],
        },
        { id: 'never', type: 'agent' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { x: 'go' }, gateStep: { verdict: 'fail', reason: 'no' }, never: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a top-level branch path gate-fail propagates as the run\'s own "gated" status', outcome.status === 'gated');
    check('the halt uses the gate-verdict-failed diagnostic, forwarded unchanged from the path\'s own sequence', outcome.halt && outcome.halt.diagnostic === 'gate-verdict-failed');
    check('exactly two dispatches occur, and the step after the branch never runs', dispatch.calls.length === 2 && dispatch.calls[1].id === 'gateStep');
  }

  // -- a branch nested INSIDE a parallel track: the branch's own own ------
  // -- (propagated) failure is still CONTAINED by the enclosing track, ----
  // -- exactly like any other step's failure -- the sibling track still --
  // -- completes and the overall run continues past the join --------------
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            { id: 'trackA', steps: [{ id: 'okStep', type: 'agent' }] },
            {
              id: 'trackB',
              steps: [
                { id: 'flag', type: 'agent' },
                { id: 'brNested', type: 'branch', cases: [{ when: { step: 'flag', field: 'go', operator: 'equals', value: false }, steps: [{ id: 'failGate', type: 'gate' }] }] },
              ],
            },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ okStep: { ok: true }, flag: { go: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('the overall run still completes -- trackB\'s contained branch failure does not escalate', outcome.status === 'completed');
    check('the aggregate counts trackB as a failure and trackA as a success', outcome.results.par1.failures === 1 && outcome.results.par1.successes === 1);
    const parallelTraceEntry = outcome.trace[outcome.trace.length - 1];
    const trackBSummary = parallelTraceEntry && parallelTraceEntry.tracks[1];
    check('trackB\'s own summary carries the contained branch-no-match-no-default halt', !!trackBSummary && trackBSummary.status === 'failed' && trackBSummary.halt.diagnostic === 'branch-no-match-no-default');
  }

  // -- a matching case coexists with a declared default: the matched ------
  // -- case's path dispatches, the default's own steps never dispatch, ---
  // -- and no default-step result key lands at all -------------------------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        {
          id: 'br9',
          type: 'branch',
          cases: [{ when: { step: 'upstream', field: 'x', operator: 'equals', value: 'go' }, steps: [{ id: 'matchedStep', type: 'agent' }] }],
          default: { steps: [{ id: 'defOnly', type: 'agent' }] },
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { x: 'go' }, matchedStep: { out: 'M' }, defOnly: { out: 'D' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a matching case wins over a declared default -- the run completes', outcome.status === 'completed');
    check('exactly two dispatches occur (upstream, then the matched case only)', dispatch.calls.length === 2 && dispatch.calls[1].id === 'matchedStep');
    check("the matched case's path result lands at br9.matchedStep", outcome.results['br9.matchedStep'] && outcome.results['br9.matchedStep'].out === 'M');
    check("the declared default's own step never dispatches, so br9.defOnly is absent", typeof outcome.results['br9.defOnly'] === 'undefined');
  }

  // -- skip-then-match: case 0's predicate is FALSE, case 1's is TRUE -- --
  // -- case 1's path must dispatch, never case 0's -------------------------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        {
          id: 'br10',
          type: 'branch',
          cases: [
            { when: { step: 'upstream', field: 'x', operator: 'equals', value: 'no' }, steps: [{ id: 'skipStep', type: 'agent' }] },
            { when: { step: 'upstream', field: 'x', operator: 'equals', value: 'go' }, steps: [{ id: 'hitStep', type: 'agent' }] },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { x: 'go' }, skipStep: { out: 'S' }, hitStep: { out: 'H' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a skip-then-match run completes', outcome.status === 'completed');
    check("exactly two dispatches occur (upstream, then case 1's path only)", dispatch.calls.length === 2 && dispatch.calls[1].id === 'hitStep');
    check("case 1's path result lands at br10.hitStep", outcome.results['br10.hitStep'] && outcome.results['br10.hitStep'].out === 'H');
    check("case 0's own non-matching path never dispatches, so br10.skipStep is absent", typeof outcome.results['br10.skipStep'] === 'undefined');
  }

  // -- later cases are never EVALUATED once a match is found, not merely --
  // -- never dispatched -- case 1's own "when" references a nonexistent --
  // -- step, which would halt (predicate-operand-unresolved) IF it were ---
  // -- ever evaluated; the run must still complete, with no halt at all ---
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        {
          id: 'br11',
          type: 'branch',
          cases: [
            { when: { step: 'upstream', field: 'x', operator: 'equals', value: 'go' }, steps: [{ id: 'firstStep', type: 'agent' }] },
            { when: { step: 'doesNotExist', field: 'y', operator: 'equals', value: 'z' }, steps: [{ id: 'neverStep', type: 'agent' }] },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { x: 'go' }, firstStep: { out: 'F' }, neverStep: { out: 'N' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check("the run completes -- case 1's unresolvable predicate is never evaluated", outcome.status === 'completed');
    check('no halt is recorded', outcome.halt === null);
    check("exactly two dispatches occur (upstream, then case 0's path only)", dispatch.calls.length === 2 && dispatch.calls[1].id === 'firstStep');
    check("case 0's path result lands at br11.firstStep", outcome.results['br11.firstStep'] && outcome.results['br11.firstStep'].out === 'F');
  }

  // -- a later top-level branch step's own "when.step" reads an EARLIER --
  // -- branch step's namespaced result (a dotted key, ---------------------
  // -- "earlierBranch.someStep") -- proving dotted keys work as predicate -
  // -- operands against branch results, per specEngineEvalPredicate's own -
  // -- exact-key lookup -----------------------------------------------------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        {
          id: 'brEarlier',
          type: 'branch',
          cases: [{ when: { step: 'upstream', field: 'x', operator: 'equals', value: 'go' }, steps: [{ id: 'someStep', type: 'agent' }] }],
        },
        {
          id: 'brLater',
          type: 'branch',
          cases: [{ when: { step: 'brEarlier.someStep', field: 'flag', operator: 'equals', value: true }, steps: [{ id: 'laterMatched', type: 'agent' }] }],
          default: { steps: [{ id: 'laterDefault', type: 'agent' }] },
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { x: 'go' }, someStep: { flag: true }, laterMatched: { out: 'LM' }, laterDefault: { out: 'LD' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check("a later branch step reading an earlier branch step's dotted result completes", outcome.status === 'completed');
    check('exactly three dispatches occur (upstream, someStep, then the matched later case)', dispatch.calls.length === 3 && dispatch.calls[2].id === 'laterMatched');
    check("the later branch's matched case result lands at brLater.laterMatched", outcome.results['brLater.laterMatched'] && outcome.results['brLater.laterMatched'].out === 'LM');
    check("the later branch's declared default never dispatches", typeof outcome.results['brLater.laterDefault'] === 'undefined');
  }

  console.log(passCount + ' passed, ' + failCount + ' failed');
  process.exit(failCount === 0 ? 0 : 1);
}

main().catch(function (err) {
  console.error('test-branch.js crashed: ' + (err && err.stack ? err.stack : err));
  process.exit(1);
});
