// Scored-retry suite for the sprint engine's execute loop: the
// "scored-retry" step kind, per the "Container authoring syntax" and
// "Result-key namespacing grammar" sections of SPEC_SCHEMA.md.
//
// Runs as: node skills/sprint-runner/tools/tests/test-scored-retry.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test -- same house style as test-execute.js/test-parallel.js/test-map.js,
// including its own local copy of `check` (each suite file is
// self-contained).
//
// Contract under test, per SPEC_SCHEMA.md plus this implementation's own
// seven disclosed contract-gap fills (see specEngineExecuteScoredRetryStep's
// own header comment in engine-core.js for the full disclosure each of
// these cases exercises):
//   - the wrapped step lives under `step`, a single nested step object.
//   - `mode` is REQUIRED: "first-passing" (stop at the first attempt whose
//     score clears `threshold`) or "keep-best" (run every attempt up to
//     `maxAttempts` and keep the highest scorer).
//   - `threshold` is REQUIRED for "first-passing", OPTIONAL for
//     "keep-best".
//   - `maxAttempts` is this implementation's own REQUIRED, execute-time-only
//     field (mirroring map's own `list` field) -- a positive integer bound.
//   - an attempt's score is read from a fixed `score` field on the wrapped
//     step's own completed result, via specEngineIsFiniteNumber;
//     unparseable -> "uncertain" halt.
//   - `augment`, when declared, is appended to the wrapped step's own
//     `prompt` field on RETRY attempts only (never attempt 0).
//   - each attempt's key is `<retryId>.attempts.<n>`; the kept winner is
//     additionally recorded at the plain `<retryId>` key, identical to its
//     own attempt-key entry.
//   - a scoreless attempt (the wrapped step's own sub-sequence does not
//     complete) is contained and retried, subject to the bound; a
//     score-parse failure always halts immediately, "uncertain"; exhausting
//     every attempt with no winner halts "failed" under
//     'scored-retry-no-winner'.
//   - a PRESENT but non-numeric `threshold` (either mode) halts spend-free,
//     before any attempt dispatches, under 'scored-retry-threshold-invalid'
//     -- an execute-time-only guard, never added to validateSpec, the same
//     scope boundary `maxAttempts` already has (see
//     specEngineExecuteScoredRetryStep's own header comment).

'use strict';

const { specEngineExecute, validateSpec } = require('../engine-core.js');

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

// makeSequencedDispatch(sequencesById) -- a scored-retry-specific variant:
// the SAME wrapped-step id is dispatched once per attempt, so a single
// static outcome per id (as makeRecordingDispatch offers) cannot express
// "attempt 0 scores 2, attempt 1 scores 9, attempt 2 scores 5." Each id in
// `sequencesById` maps to an array of outcomes, consumed in call order (one
// per dispatch of that id); an id not present in `sequencesById` yields
// `undefined`, matching makeRecordingDispatch's own miss behavior.
function makeSequencedDispatch(sequencesById) {
  const calls = [];
  const cursors = Object.create(null);
  const dispatch = async function (step, context) {
    calls.push({ id: step.id, step: step, context: context });
    if (!Object.prototype.hasOwnProperty.call(sequencesById, step.id)) {
      return undefined;
    }
    const sequence = sequencesById[step.id];
    const cursor = cursors[step.id] || 0;
    cursors[step.id] = cursor + 1;
    return sequence[cursor];
  };
  dispatch.calls = calls;
  return dispatch;
}

async function main() {
  // -- first-passing stops at the first attempt that clears the threshold -
  // -- (gte semantics): later attempts are NEVER dispatched ----------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'first-passing',
          threshold: 5,
          maxAttempts: 3,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ score: 2 }, { score: 9 }, { score: 1 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('first-passing that clears the threshold completes the run', outcome.status === 'completed');
    check('first-passing dispatches only up through the clearing attempt, never a third', dispatch.calls.length === 2);
    check('the kept winner is the clearing attempt (score 9), not the non-clearing first one', outcome.results.retryA.score === 9);
    check("the clearing attempt's own attempts key carries the same value", outcome.results['retryA.attempts.1'].score === 9);
  }

  // -- first-passing gte semantics at the EXACT boundary: a score equal to
  // -- (not merely above) the threshold clears it -- direction-sensitive: -
  // -- an implementation using a strictly-greater comparison instead of ---
  // -- gte would fail to stop here and dispatch a third, unnecessary ------
  // -- attempt (scores 3, 5, 9 -- threshold 5 -- attempt 1 must clear) ----
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'first-passing',
          threshold: 5,
          maxAttempts: 3,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ score: 3 }, { score: 5 }, { score: 9 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an exactly-equal score clears first-passing and completes the run', outcome.status === 'completed');
    check('exactly two attempts dispatch -- the equal-scoring attempt stops the run, the third never dispatches', dispatch.calls.length === 2);
    check('the winner is the exactly-equal-scoring attempt (score 5), not the higher unused third', outcome.results.retryA.score === 5);
    check('the never-dispatched third attempt contributes no attempts.2 key', typeof outcome.results['retryA.attempts.2'] === 'undefined');
  }

  // -- keep-best runs exactly maxAttempts and keeps the highest scorer, ---
  // -- direction-sensitive: the winner is neither the first nor the last --
  // -- attempt (scores 2, 9, 5 -> winner is attempt 1, score 9) -----------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 3,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ score: 2 }, { score: 9 }, { score: 5 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('keep-best completes the run', outcome.status === 'completed');
    check('keep-best dispatches every one of the three attempts, never stopping early', dispatch.calls.length === 3);
    check('the kept winner is neither the first nor the last attempt, but the highest scorer (attempt 1, score 9)', outcome.results.retryA.score === 9);
  }

  // -- attempts keys <retryId>.attempts.0..n-1 are ALL present, one per ----
  // -- attempt that actually ran, regardless of which one won -------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 3,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ score: 2 }, { score: 9 }, { score: 5 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('attempts.0 is present with its own score', !!outcome.results['retryA.attempts.0'] && outcome.results['retryA.attempts.0'].score === 2);
    check('attempts.1 is present with its own score', !!outcome.results['retryA.attempts.1'] && outcome.results['retryA.attempts.1'].score === 9);
    check('attempts.2 is present with its own score', !!outcome.results['retryA.attempts.2'] && outcome.results['retryA.attempts.2'].score === 5);
  }

  // -- the winner at the plain <retryId> key is IDENTICAL (same value) to -
  // -- its own winning attempt's <retryId>.attempts.<n> entry -------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 3,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ score: 2 }, { score: 9 }, { score: 5 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check(
      'the plain retryA key and the winning attempts.1 key hold the identical value',
      outcome.results.retryA === outcome.results['retryA.attempts.1']
    );
  }

  // -- keep-best tie-breaking: when a LATER attempt ties the current best -
  // -- (scores 4, 9, 9 -- attempts 1 and 2 tie), the EARLIEST top scorer ---
  // -- wins, not the last one -- direction-sensitive: an implementation ---
  // -- that replaced the best on a "greater-or-equal" comparison instead --
  // -- of a strictly-greater one would keep attempts.2 here instead of ----
  // -- attempts.1, and this fixture would fail --------------------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 3,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ score: 4 }, { score: 9 }, { score: 9 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a tied keep-best run still completes', outcome.status === 'completed');
    check('all three attempts are dispatched -- keep-best always runs to the bound', dispatch.calls.length === 3);
    check(
      'the winner at the plain key is the EARLIEST tied top scorer (attempts.1), not the later tie (attempts.2)',
      outcome.results.retryA === outcome.results['retryA.attempts.1']
    );
    check(
      'the winner is NOT the later tied attempt',
      outcome.results.retryA !== outcome.results['retryA.attempts.2']
    );
  }

  // -- augment reaches attempt 2+ prompts (concatenated onto the wrapped --
  // -- step's own prompt) but NEVER attempt 1's own prompt -----------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 3,
          augment: 'extra instructions',
          step: { id: 'attempt', type: 'agent', prompt: 'base prompt' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ score: 1 }, { score: 2 }, { score: 3 }] });
    await specEngineExecute(spec, dispatch);
    check("attempt 1's own dispatched prompt is unaugmented", dispatch.calls[0].step.prompt === 'base prompt');
    check("attempt 2's own dispatched prompt carries the augment text", dispatch.calls[1].step.prompt === 'base prompt\n\nextra instructions');
    check("attempt 3's own dispatched prompt carries the augment text too", dispatch.calls[2].step.prompt === 'base prompt\n\nextra instructions');
  }

  // -- augment mechanics, edge case 1: an empty-string "augment" never -----
  // -- augments ANY attempt (not just attempt 1) -- every dispatched -----
  // -- prompt is identical, unaugmented ------------------------------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 3,
          augment: '',
          step: { id: 'attempt', type: 'agent', prompt: 'base prompt' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ score: 1 }, { score: 2 }, { score: 3 }] });
    await specEngineExecute(spec, dispatch);
    check('an empty-string augment leaves attempt 1 unaugmented', dispatch.calls[0].step.prompt === 'base prompt');
    check('an empty-string augment leaves attempt 2 unaugmented too', dispatch.calls[1].step.prompt === 'base prompt');
    check('an empty-string augment leaves attempt 3 unaugmented too', dispatch.calls[2].step.prompt === 'base prompt');
  }

  // -- augment mechanics, edge case 2: augment text carrying a -------------
  // -- {{...}} placeholder resolves through the ordinary render pipeline --
  // -- on retry attempts, against a value from an EARLIER, enclosing-scope
  // -- step -- no separate rendering surface exists for augment text ------
  {
    const spec = {
      steps: [
        { id: 'seed', type: 'agent' },
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 2,
          augment: 'ref: {{seed.value}}',
          step: { id: 'attempt', type: 'agent', prompt: 'base prompt' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ seed: [{ value: 42 }], attempt: [{ score: 1 }, { score: 2 }] });
    await specEngineExecute(spec, dispatch);
    check('the seed step dispatches first', dispatch.calls[0].id === 'seed');
    check("attempt 1's own prompt is unaugmented (no placeholder to resolve)", dispatch.calls[1].step.prompt === 'base prompt');
    check(
      "attempt 2's own prompt has the augment's {{seed.value}} placeholder resolved through the render pipeline",
      dispatch.calls[2].step.prompt === 'base prompt\n\nref: 42'
    );
  }

  // -- the bound is never exceeded: maxAttempts caps dispatch count even ---
  // -- when more outcomes are available in the stub ------------------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 2,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ score: 1 }, { score: 2 }, { score: 3 }, { score: 4 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('keep-best with maxAttempts 2 completes', outcome.status === 'completed');
    check('exactly maxAttempts (2) dispatches occur, never the 3rd/4th stub entry', dispatch.calls.length === 2);
    check('the winner is the highest of the two attempts actually run (score 2), not a later unused one', outcome.results.retryA.score === 2);
  }

  // -- a score-parse failure (the wrapped step completed, but its result --
  // -- carries no finite numeric "score" field) halts "uncertain" -------
  // -- immediately, with the raw outcome recorded in the trace ------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 3,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ text: 'no score field here' }, { score: 9 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a score-parse failure halts the run with status "uncertain"', outcome.status === 'uncertain');
    check('the halt uses the scored-retry-score-unparseable diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'scored-retry-score-unparseable');
    check('the score-parse failure halts immediately -- the second attempt is never dispatched', dispatch.calls.length === 1);
    const traceEntry = outcome.trace[outcome.trace.length - 1];
    check(
      'the raw outcome that produced the score-parse halt is recorded in the trace',
      !!traceEntry && traceEntry.outcome && traceEntry.outcome.text === 'no score field here'
    );
  }

  // -- a score-parse failure on first-passing halts "uncertain" the same --
  // -- way it does on keep-best (coverage was keep-best-only before) ------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'first-passing',
          threshold: 5,
          maxAttempts: 3,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ text: 'no score field here' }, { score: 9 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a score-parse failure on first-passing halts the run with status "uncertain"', outcome.status === 'uncertain');
    check(
      'the halt uses the scored-retry-score-unparseable diagnostic on first-passing too',
      outcome.halt !== null && outcome.halt.diagnostic === 'scored-retry-score-unparseable'
    );
    check('the score-parse failure on first-passing halts immediately -- the second attempt is never dispatched', dispatch.calls.length === 1);
  }

  // -- no-winner ruling: every attempt exhausted without a first-passing --
  // -- attempt ever clearing the threshold halts "failed" under -----------
  // -- 'scored-retry-no-winner' -- partial per-attempt results are still --
  // -- preserved in the results map even though the step itself failed ----
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'first-passing',
          threshold: 100,
          maxAttempts: 2,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [{ score: 1 }, { score: 2 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('exhausting every attempt with no winner halts the run with status "failed"', outcome.status === 'failed');
    check('the halt uses the scored-retry-no-winner diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'scored-retry-no-winner');
    check('both attempts actually ran before the no-winner halt', dispatch.calls.length === 2);
    check('no plain retryA winner key is written on a no-winner halt', typeof outcome.results.retryA === 'undefined');
    check('attempts.0 is still preserved in the partial results map', !!outcome.results['retryA.attempts.0'] && outcome.results['retryA.attempts.0'].score === 1);
    check('attempts.1 is still preserved in the partial results map', !!outcome.results['retryA.attempts.1'] && outcome.results['retryA.attempts.1'].score === 2);
  }

  // -- attempt-failure ruling: an attempt whose wrapped step's own -------
  // -- dispatch resolves to null (never completes) is a SCORELESS ---------
  // -- attempt -- contained, recorded, and retried, never halting the -----
  // -- scored-retry step by itself ------------------------------------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 2,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [null, { score: 9 }] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a scoreless first attempt does not halt the run -- the second attempt still runs and wins', outcome.status === 'completed');
    check('both attempts were dispatched', dispatch.calls.length === 2);
    check('the winner is the only attempt that ever completed', outcome.results.retryA.score === 9);
    check('the failed first attempt contributes no attempts.0 key (no completed result to address)', typeof outcome.results['retryA.attempts.0'] === 'undefined');
    check('the completed second attempt does contribute an attempts.1 key', !!outcome.results['retryA.attempts.1']);
  }

  // -- keep-best where EVERY attempt is scoreless (matching the scoreless-
  // -- containment fixture's own shape -- a dispatch resolving to null,
  // -- not a score-parse failure): bestIndex never advances past -1, so
  // -- keep-best's own "at least one scored attempt" gate never fires --
  // -- this is the no-winner ruling reached via keep-best instead of via -
  // -- first-passing's own never-clears path -------------------------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 2,
          step: { id: 'attempt', type: 'agent' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({ attempt: [null, null] });
    const outcome = await specEngineExecute(spec, dispatch);
    check('keep-best where every attempt is scoreless halts the run with status "failed"', outcome.status === 'failed');
    check(
      'the halt uses the scored-retry-no-winner diagnostic, not a false "completed" with a null winner',
      outcome.halt !== null && outcome.halt.diagnostic === 'scored-retry-no-winner'
    );
    check('no plain retryA winner key is written when every attempt was scoreless', typeof outcome.results.retryA === 'undefined');
    check('both attempts still dispatched before the no-winner halt', dispatch.calls.length === 2);
  }

  // -- malformed-shape guards: every one of these is spend-free -----------
  // -- (dispatch is never called) and halts under its own named diagnostic
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(
      { steps: [{ id: 'retryA', type: 'scored-retry', maxAttempts: 3, step: { id: 'attempt', type: 'agent' } }], config: {} },
      dispatch
    );
    check('missing "mode" halts "failed" under scored-retry-mode-required', outcome.status === 'failed' && outcome.halt.diagnostic === 'scored-retry-mode-required');
    check('missing "mode" never dispatches', dispatch.calls.length === 0);
  }
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(
      { steps: [{ id: 'retryA', type: 'scored-retry', mode: 'bogus-mode', maxAttempts: 3, step: { id: 'attempt', type: 'agent' } }], config: {} },
      dispatch
    );
    check('an illegal "mode" halts "failed" under scored-retry-mode-invalid', outcome.status === 'failed' && outcome.halt.diagnostic === 'scored-retry-mode-invalid');
    check('an illegal "mode" never dispatches', dispatch.calls.length === 0);
  }
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(
      { steps: [{ id: 'retryA', type: 'scored-retry', mode: 'first-passing', maxAttempts: 3, step: { id: 'attempt', type: 'agent' } }], config: {} },
      dispatch
    );
    check(
      'first-passing without "threshold" halts "failed" under scored-retry-threshold-required',
      outcome.status === 'failed' && outcome.halt.diagnostic === 'scored-retry-threshold-required'
    );
    check('missing threshold never dispatches', dispatch.calls.length === 0);
  }
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(
      { steps: [{ id: 'retryA', type: 'scored-retry', mode: 'keep-best', step: { id: 'attempt', type: 'agent' } }], config: {} },
      dispatch
    );
    check(
      'missing "maxAttempts" halts "failed" under scored-retry-max-attempts-required',
      outcome.status === 'failed' && outcome.halt.diagnostic === 'scored-retry-max-attempts-required'
    );
    check('missing maxAttempts never dispatches', dispatch.calls.length === 0);
  }
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(
      { steps: [{ id: 'retryA', type: 'scored-retry', mode: 'keep-best', maxAttempts: 0, step: { id: 'attempt', type: 'agent' } }], config: {} },
      dispatch
    );
    check(
      'a non-positive "maxAttempts" halts "failed" under scored-retry-max-attempts-invalid',
      outcome.status === 'failed' && outcome.halt.diagnostic === 'scored-retry-max-attempts-invalid'
    );
    check('malformed maxAttempts never dispatches', dispatch.calls.length === 0);
  }
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(
      { steps: [{ id: 'retryA', type: 'scored-retry', mode: 'keep-best', maxAttempts: 'three', step: { id: 'attempt', type: 'agent' } }], config: {} },
      dispatch
    );
    check(
      'a non-integer "maxAttempts" halts "failed" under scored-retry-max-attempts-invalid too',
      outcome.status === 'failed' && outcome.halt.diagnostic === 'scored-retry-max-attempts-invalid'
    );
    check('non-integer maxAttempts never dispatches', dispatch.calls.length === 0);
  }
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(
      { steps: [{ id: 'retryA', type: 'scored-retry', mode: 'keep-best', maxAttempts: 3 }], config: {} },
      dispatch
    );
    check(
      'a missing/non-object wrapped "step" halts "failed" under scored-retry-step-not-object',
      outcome.status === 'failed' && outcome.halt.diagnostic === 'scored-retry-step-not-object'
    );
    check('a missing wrapped step never dispatches', dispatch.calls.length === 0);
  }

  // -- a PRESENT but non-numeric "threshold" is a malformed-shape defect --
  // -- of its own, distinct from a MISSING threshold: without this guard --
  // -- a string threshold like "5" would silently never clear (since ------
  // -- specEngineIsFiniteNumber('5') is false), masking the real defect ---
  // -- (a malformed threshold) behind a generic scored-retry-no-winner ----
  // -- halt after every attempt still dispatched -- this guard instead ----
  // -- halts loudly, spend-free, before any attempt runs, naming the ------
  // -- actual defect. Applies in BOTH modes whenever threshold is present -
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(
      {
        steps: [
          {
            id: 'retryA',
            type: 'scored-retry',
            mode: 'first-passing',
            threshold: '5',
            maxAttempts: 3,
            step: { id: 'attempt', type: 'agent' },
          },
        ],
        config: {},
      },
      dispatch
    );
    check(
      'a string "threshold" on first-passing halts "failed" under scored-retry-threshold-invalid',
      outcome.status === 'failed' && outcome.halt.diagnostic === 'scored-retry-threshold-invalid'
    );
    check('a string threshold on first-passing never dispatches -- spend-free', dispatch.calls.length === 0);
  }
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(
      {
        steps: [
          {
            id: 'retryA',
            type: 'scored-retry',
            mode: 'keep-best',
            threshold: '5',
            maxAttempts: 3,
            step: { id: 'attempt', type: 'agent' },
          },
        ],
        config: {},
      },
      dispatch
    );
    check(
      'a string "threshold" on keep-best (where threshold is otherwise optional) also halts under scored-retry-threshold-invalid',
      outcome.status === 'failed' && outcome.halt.diagnostic === 'scored-retry-threshold-invalid'
    );
    check('a string threshold on keep-best never dispatches -- spend-free', dispatch.calls.length === 0);
  }

  // -- reserved-segments interplay: a wrapped step declared with the ------
  // -- literal id "attempts" is ALREADY rejected by validateSpec's own ----
  // -- reserved-segment rule (it checks every step id in the tree, --------
  // -- including a scored-retry step's own wrapped step) -- no additional
  // -- execute-time guard is added here for this, since the collision is --
  // -- unreachable at execute time on a spec that already passed
  // -- validateSpec, matching the "add an execute guard only if reachable"
  // -- discipline this suite follows elsewhere -----------------------------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 3,
          step: { id: 'attempts', type: 'agent' },
        },
      ],
      config: {},
    };
    const violations = validateSpec(spec);
    check(
      'validateSpec already rejects a wrapped step declared with the reserved id "attempts"',
      violations.some(function (v) {
        return v.diagnostic === 'reserved-segment' && v.path === 'steps[0].step.id';
      })
    );
  }

  // -- a step after the scored-retry step consumes both the winner's plain
  // -- <retryId>.field reference AND its equivalent <retryId>.attempts.1.-
  // -- field reference, via the ordinary template pipeline -- no special --
  // -- template-resolution surface is needed for scored-retry keys --------
  {
    const spec = {
      steps: [
        {
          id: 'retryA',
          type: 'scored-retry',
          mode: 'keep-best',
          maxAttempts: 3,
          step: { id: 'attempt', type: 'agent' },
        },
        {
          id: 'after',
          type: 'shape',
          template: { winner: '{{retryA.field}}', viaAttemptKey: '{{retryA.attempts.1.field}}' },
        },
      ],
      config: {},
    };
    const dispatch = makeSequencedDispatch({
      attempt: [{ field: 'a0', score: 2 }, { field: 'a1', score: 9 }, { field: 'a2', score: 5 }],
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('the post-retry step run completes', outcome.status === 'completed');
    check('the post-retry template resolves the plain <retryId>.field reference to the winner', outcome.results.after.winner === 'a1');
    check(
      'the post-retry template resolves the <retryId>.attempts.1.field reference identically',
      outcome.results.after.viaAttemptKey === 'a1'
    );
  }

  console.log(passCount + ' passed, ' + failCount + ' failed');
  process.exit(failCount === 0 ? 0 : 1);
}

main().catch(function (err) {
  console.error('test-scored-retry.js crashed: ' + (err && err.stack ? err.stack : err));
  process.exit(1);
});
