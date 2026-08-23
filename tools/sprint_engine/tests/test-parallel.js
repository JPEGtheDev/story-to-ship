// Parallel-container suite for the sprint engine's execute loop: the
// "parallel" step kind, the only container kind specEngineExecute runs
// today.
//
// Runs as: node tools/sprint_engine/tests/test-parallel.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test -- same house style as test-execute.js, including its own local
// copies of `check` and `makeRecordingDispatch` (each suite file is
// self-contained).
//
// Contract under test, per the "Container authoring syntax" and
// "Result-key namespacing grammar" sections of SPEC_SCHEMA.md, and the
// PROBE_RESULTS.md observation that a failing gate verdict inside one
// branch does not disrupt the other branch's result delivery or the
// overall join:
//   - a parallel step's nested steps live under `tracks`, an array of
//     { id, steps }; each track's steps run as a full sequence (the same
//     agent/gate/shape leaf semantics the top-level loop uses).
//   - a nested step's result key is `<trackId>.<stepId>` -- the parallel
//     step's own id is never part of a nested key.
//   - the parallel step's own result, under its own id, carries the
//     aggregate counts {failures, successes, total}.
//   - within one track, a bare step-name reference resolves to that same
//     track's own earlier steps.
//   - a gate FAIL (or any other halt cause) inside one track halts that
//     track's own remaining steps only; the track counts as failed in the
//     aggregates; other tracks run to completion; the run CONTINUES past
//     the join rather than halting the whole run.
//   - gate verdict "uncertain" inside a track is contained the same way --
//     a design decision this suite pins explicitly, since SPEC_SCHEMA.md
//     does not itself settle whether "uncertain" escalates.
//   - tracks run concurrently: the injected dispatch function is awaited
//     per-track, not serialized track-by-track.

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
// this helper for the full contract; identical here.
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
  // -- a track runs as a full sequence: a later step in the same track ----
  // -- resolves an earlier step's result by bare name, the same way the ---
  // -- top-level loop resolves a bare step name -----------------------------
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            {
              id: 'trackA',
              steps: [
                { id: 'gen', type: 'agent' },
                { id: 'echo', type: 'agent', prompt: 'value is {{gen.text}}' },
              ],
            },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ gen: { text: 'alpha' }, echo: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a parallel step with one multi-step track completes', outcome.status === 'completed');
    check(
      "a later step in the same track resolves an earlier step's result by bare name",
      dispatch.calls.length === 2 && dispatch.calls[1].id === 'echo' && dispatch.calls[1].step.prompt === 'value is alpha'
    );
  }

  // -- namespaced <trackId>.<stepId> results land in the results map ------
  // -- after the join; the parallel step's own id never prefixes the key --
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [{ id: 'trackA', steps: [{ id: 'step1', type: 'agent' }] }],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ step1: { value: 42 } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a single-track parallel step completes', outcome.status === 'completed');
    check(
      "the track's step result lands in the results map under <trackId>.<stepId>",
      outcome.results['trackA.step1'] && outcome.results['trackA.step1'].value === 42
    );
    check(
      "the parallel step's own id does not prefix the nested key",
      typeof outcome.results['par1.trackA.step1'] === 'undefined'
    );
  }

  // -- aggregates {failures, successes, total} are correct in a mixed -----
  // -- outcome (one track passes, one track's gate fails) -----------------
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            { id: 'trackA', steps: [{ id: 'okStep', type: 'agent' }] },
            { id: 'trackB', steps: [{ id: 'badGate', type: 'gate' }] },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      okStep: { done: true },
      badGate: { verdict: 'fail', reason: 'engineered' },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a parallel step with one failing track and one passing track still completes overall', outcome.status === 'completed');
    check(
      'the aggregate counts reflect one failure, one success, two total',
      outcome.results.par1.failures === 1 && outcome.results.par1.successes === 1 && outcome.results.par1.total === 2
    );
  }

  // -- aggregates, ASYMMETRIC case: the fixture above is 1-fail/1-pass, so
  // -- a mutation that swaps which branch counts as a failure vs a --------
  // -- success (counting "completed" as a failure and vice versa) passes --
  // -- that fixture too, since a 1/1 split reads the same either way. ------
  // -- Two failing tracks and one passing track makes the count itself ----
  // -- direction-sensitive: failures !== successes, so a swapped branch ---
  // -- flips which number lands where the assertion expects it. -----------
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            { id: 'trackA', steps: [{ id: 'okA', type: 'agent' }] },
            { id: 'trackB', steps: [{ id: 'gateB', type: 'gate' }] },
            { id: 'trackC', steps: [{ id: 'gateC', type: 'gate' }] },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      okA: { ok: true },
      gateB: { verdict: 'fail', reason: 'engineered B' },
      gateC: { verdict: 'fail', reason: 'engineered C' },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an asymmetric two-failing/one-passing parallel step still completes overall', outcome.status === 'completed');
    check(
      'the aggregate counts two failures and one success out of three tracks (direction-sensitive, unlike the 1/1 fixture above)',
      outcome.results.par1.failures === 2 && outcome.results.par1.successes === 1 && outcome.results.par1.total === 3
    );
  }

  // -- aggregates, second asymmetric pin: an all-passing three-track run --
  // -- (0 failures, 3 successes) is also direction-sensitive -- a swapped -
  // -- branch would report 3 failures, 0 successes instead. ---------------
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            { id: 'trackA', steps: [{ id: 'a1', type: 'agent' }] },
            { id: 'trackB', steps: [{ id: 'b1', type: 'agent' }] },
            { id: 'trackC', steps: [{ id: 'c1', type: 'agent' }] },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ a1: { ok: true }, b1: { ok: true }, c1: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an all-passing three-track parallel step completes', outcome.status === 'completed');
    check(
      'the aggregate counts three successes and zero failures',
      outcome.results.par1.successes === 3 && outcome.results.par1.failures === 0 && outcome.results.par1.total === 3
    );
  }

  // -- a post-join step can reference EITHER track's result via its -------
  // -- namespaced key ---------------------------------------------------------
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            { id: 'trackA', steps: [{ id: 'a1', type: 'agent' }] },
            { id: 'trackB', steps: [{ id: 'b1', type: 'agent' }] },
          ],
        },
        { id: 'summary', type: 'shape', template: { both: '{{trackA.a1.text}} and {{trackB.b1.text}}' } },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      a1: { text: 'alpha' },
      b1: { text: 'bravo' },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a post-join shape step referencing both tracks by namespaced key completes', outcome.status === 'completed');
    check(
      "the post-join step's rendered template resolved both tracks' namespaced results",
      outcome.results.summary.both === 'alpha and bravo'
    );
  }

  // -- one-failing-track containment: the other track completes, the ------
  // -- aggregates reflect the mix, and the run continues past the join, ---
  // -- including a step positioned AFTER the parallel step -----------------
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            { id: 'trackA', steps: [{ id: 'a1', type: 'agent' }] },
            {
              id: 'trackB',
              steps: [
                { id: 'b1', type: 'agent' },
                { id: 'gateB', type: 'gate' },
              ],
            },
          ],
        },
        { id: 'after', type: 'agent' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      a1: { ok: true },
      b1: { ok: true },
      gateB: { verdict: 'fail', reason: 'engineered' },
      after: { ok: true },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a run with one internally-failing track still completes overall (no whole-run gated halt)', outcome.status === 'completed');
    check(
      "the completed track's result is present under its namespaced key",
      outcome.results['trackA.a1'] && outcome.results['trackA.a1'].ok === true
    );
    check(
      "the failing track's step BEFORE its own gate is still present under its namespaced key",
      outcome.results['trackB.b1'] && outcome.results['trackB.b1'].ok === true
    );
    check(
      "the failing gate's own outcome is not folded into the results map (same contained-result rule the top-level loop applies to a failing gate)",
      typeof outcome.results['trackB.gateB'] === 'undefined'
    );
    check(
      'the aggregate counts one failure and one success out of two tracks',
      outcome.results.par1.failures === 1 && outcome.results.par1.successes === 1 && outcome.results.par1.total === 2
    );
    check(
      'the step positioned after the parallel step still dispatches',
      dispatch.calls.length > 0 && dispatch.calls[dispatch.calls.length - 1].id === 'after'
    );
  }

  // -- a track-contained gate fail preserves its halt detail, inspectable -
  // -- from the parallel step's own trace entry -----------------------------
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [{ id: 'trackB', steps: [{ id: 'gateB', type: 'gate' }] }],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ gateB: { verdict: 'fail', reason: 'engineered' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a run whose only track fails still completes overall', outcome.status === 'completed');
    const parallelTraceEntry = outcome.trace[outcome.trace.length - 1];
    check('the parallel step has its own trace entry', !!parallelTraceEntry && parallelTraceEntry.step === 'par1');
    check(
      'the trace entry carries a per-track breakdown',
      !!parallelTraceEntry && Array.isArray(parallelTraceEntry.tracks) && parallelTraceEntry.tracks.length === 1
    );
    const trackBSummary = parallelTraceEntry && parallelTraceEntry.tracks[0];
    check("the failing track's own status is preserved", !!trackBSummary && trackBSummary.trackId === 'trackB' && trackBSummary.status === 'gated');
    check(
      "the failing track's halt detail (diagnostic) is preserved and inspectable",
      !!trackBSummary && !!trackBSummary.halt && trackBSummary.halt.diagnostic === 'gate-verdict-failed'
    );
  }

  // -- a container step nested inside a track (a scored-retry, here) is ---
  // -- now an executable container kind: scored-retry execution landed, ---
  // -- so this nested step runs for real and its results land under -------
  // -- composite keys of the shape "<trackId>.<retryId>.attempts.<n>" (and
  // -- the plain "<trackId>.<retryId>" winner key) per the result-key -----
  // -- namespacing grammar's "composites" rule -- no scored-retry-specific
  // -- composite-key logic exists anywhere in the engine; this falls out --
  // -- for free because specEngineExecuteScoredRetryStep writes its own ---
  // -- plain/attempts keys into whatever results object it was handed -----
  // -- (here, trackB's own private results object), and the SAME -------
  // -- track-level re-namespacing every other track step's key already ----
  // -- gets prefixes those keys with "trackB." too. The wrapped step's own
  // -- outcome (score 7) clears the first-passing threshold (5) on its ----
  // -- very first attempt, so both tracks now complete successfully.
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
                {
                  id: 'retryB',
                  type: 'scored-retry',
                  mode: 'first-passing',
                  threshold: 5,
                  maxAttempts: 2,
                  step: { id: 'attempt', type: 'agent' },
                },
              ],
            },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ okStep: { ok: true }, attempt: { score: 7 } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a parallel step with a now-executable nested container in one track completes overall', outcome.status === 'completed');
    check(
      'the aggregate counts both tracks as successes -- the nested scored-retry no longer fails its track',
      outcome.results.par1.failures === 0 && outcome.results.par1.successes === 2
    );
    check(
      "the nested scored-retry's winner lands at the composite plain key <trackId>.<retryId>",
      !!outcome.results['trackB.retryB'] && outcome.results['trackB.retryB'].score === 7
    );
    check(
      "the nested scored-retry's attempt lands at the composite attempts key <trackId>.<retryId>.attempts.<n>",
      !!outcome.results['trackB.retryB.attempts.0'] && outcome.results['trackB.retryB.attempts.0'].score === 7
    );
    check(
      'the composite plain key and the composite attempts key hold the identical value',
      outcome.results['trackB.retryB'] === outcome.results['trackB.retryB.attempts.0']
    );
    const parallelTraceEntry = outcome.trace[outcome.trace.length - 1];
    const trackBSummary = parallelTraceEntry && parallelTraceEntry.tracks[1];
    check(
      "the nested scored-retry track now completes instead of failing",
      !!trackBSummary && trackBSummary.trackId === 'trackB' && trackBSummary.status === 'completed'
    );
  }

  // -- gate verdict "uncertain" inside a track is contained the same way --
  // -- as a gate fail: a design decision this suite pins explicitly, ------
  // -- since SPEC_SCHEMA.md does not itself settle whether "uncertain" ----
  // -- escalates past a track boundary -------------------------------------
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            { id: 'trackA', steps: [{ id: 'a1', type: 'agent' }] },
            { id: 'trackB', steps: [{ id: 'gateB', type: 'gate' }] },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ a1: { ok: true }, gateB: { verdict: 'uncertain', reason: 'not sure' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check(
      'a gate verdict "uncertain" inside a track is CONTAINED to that track and does not escalate to a whole-run uncertain halt',
      outcome.status === 'completed'
    );
    check(
      'the uncertain track is counted as a failure in the aggregate',
      outcome.results.par1.failures === 1 && outcome.results.par1.successes === 1
    );
  }

  // -- a track failing for a reason OTHER than a gate verdict (a null -----
  // -- agent-dispatch result) is contained the same way --------------------
  {
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            { id: 'trackA', steps: [{ id: 'a1', type: 'agent' }] },
            { id: 'trackB', steps: [{ id: 'b1', type: 'agent' }] },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ a1: { ok: true }, b1: null });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a null agent-dispatch result inside a track is contained to that track, not a whole-run halt', outcome.status === 'completed');
    check(
      'the aggregate counts the null-result track as a failure',
      outcome.results.par1.failures === 1 && outcome.results.par1.successes === 1
    );
  }

  // -- dispatch-order/concurrency observability: trackB's dispatch fires --
  // -- while trackA's dispatch is still pending, proving tracks run -------
  // -- concurrently rather than trackB waiting for trackA's full sequence -
  {
    let releaseA;
    const aGate = new Promise(function (resolve) {
      releaseA = resolve;
    });
    const calls = [];
    const dispatch = async function (step) {
      calls.push(step.id);
      if (step.id === 'aStep') {
        await aGate;
        return { from: 'A' };
      }
      return { from: 'B' };
    };
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            { id: 'trackA', steps: [{ id: 'aStep', type: 'agent' }] },
            { id: 'trackB', steps: [{ id: 'bStep', type: 'agent' }] },
          ],
        },
      ],
      config: {},
    };
    const executePromise = specEngineExecute(spec, dispatch);
    // Give the microtask/timer queue a turn so both tracks' dispatch calls
    // have a chance to fire before trackA's gate is released.
    await new Promise(function (resolve) {
      setTimeout(resolve, 10);
    });
    check(
      "trackB's dispatch fired while trackA's dispatch is still blocked/pending (tracks run concurrently, not sequentially)",
      calls.indexOf('bStep') !== -1 && calls.indexOf('aStep') !== -1
    );
    releaseA();
    const outcome = await executePromise;
    check('the run completes once the blocked track is released', outcome.status === 'completed');
  }

  // -- malformed parallel step, execute-time guard: "tracks" missing ------
  // -- entirely halts the whole run (validateSpec does not itself flag ----
  // -- this shape) -----------------------------------------------------------
  {
    const spec = { steps: [{ id: 'par1', type: 'parallel' }], config: {} };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a parallel step with no "tracks" field halts the whole run', outcome.status === 'failed');
    check('the halt uses the parallel-tracks-not-array diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'parallel-tracks-not-array');
    check('a malformed parallel step never reaches dispatch', dispatch.calls.length === 0);
  }

  // -- malformed parallel step, execute-time guard: "tracks" present but --
  // -- not an array -----------------------------------------------------------
  {
    const spec = { steps: [{ id: 'par1', type: 'parallel', tracks: 'not-an-array' }], config: {} };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a parallel step whose "tracks" is not an array halts the whole run', outcome.status === 'failed');
    check('the halt uses the parallel-tracks-not-array diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'parallel-tracks-not-array');
  }

  // -- malformed parallel step, execute-time guard: a tracks[] entry that -
  // -- is not a plain object ---------------------------------------------------
  {
    const spec = { steps: [{ id: 'par1', type: 'parallel', tracks: ['not-an-object'] }], config: {} };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a non-object track entry halts the whole run', outcome.status === 'failed');
    check('the halt uses the parallel-track-not-object diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'parallel-track-not-object');
  }

  // -- malformed parallel step, execute-time guard: a track missing its ---
  // -- own "id" ----------------------------------------------------------------
  {
    const spec = { steps: [{ id: 'par1', type: 'parallel', tracks: [{ steps: [] }] }], config: {} };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a track with no "id" halts the whole run', outcome.status === 'failed');
    check('the halt uses the parallel-track-id-missing diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'parallel-track-id-missing');
  }

  // -- malformed parallel step, execute-time guard: a track missing its ---
  // -- own "steps" array -------------------------------------------------------
  {
    const spec = { steps: [{ id: 'par1', type: 'parallel', tracks: [{ id: 'trackA' }] }], config: {} };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a track with no "steps" array halts the whole run', outcome.status === 'failed');
    check('the halt uses the parallel-track-steps-not-array diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'parallel-track-steps-not-array');
  }

  console.log(passCount + ' passed, ' + failCount + ' failed');
  process.exit(failCount === 0 ? 0 : 1);
}

main().catch(function (err) {
  console.error('test-parallel.js crashed: ' + (err && err.stack ? err.stack : err));
  process.exit(1);
});
