// Execute-loop suite for the sprint engine's three leaf step kinds: agent,
// gate, shape.
//
// Runs as: node tools/sprint_engine/tests/test-execute.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test. Each case below calls specEngineExecute(spec, dispatch) directly
// against a hand-built spec and a hand-built dispatch stub, and asserts on
// the returned outcome. specEngineExecute is async (it awaits the injected
// dispatcher), so this file wraps its cases in a single async main()
// instead of the fully-synchronous top-level style the sibling suites use.
//
// specEngineExecute's own contract: it walks spec.steps in order, running
// each leaf step (agent, gate, shape) and, now that parallel-step,
// map-step, scored-retry-step, and branch-step support have all landed,
// every container step kind too -- "parallel", "map", "scored-retry", and
// "branch". No container kind remains unsupported; the file's own
// 'container-step-not-supported' diagnostic is now a defensive-only guard
// for a kind that is declared in SPEC_ENGINE_CONTAINER_STEP_KINDS without
// its own explicit handling (see engine-core.js's own header comment above
// that guard). Dispatch capability is injected: the caller supplies an
// async dispatch(step, context) function; specEngineExecute itself carries
// no dispatch primitive of its own. See engine-core.js's own header
// comment above specEngineExecute for the full return-shape contract; see
// test-parallel.js, test-map.js, test-scored-retry.js, and test-branch.js
// for the full "parallel", "map", "scored-retry", and "branch" step-kind
// suites -- this file's own container-kind blocks below only prove that
// each of the four is now executed rather than rejected, each failing (if
// it fails at all) under its own execute-time malformed-shape guard
// instead of the generic diagnostic.

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

// makeRecordingDispatch(outcomesById) returns a dispatch stub that, for
// each call, records the dispatched step's id (in call order) into
// `calls`, and resolves with whatever outcomesById[step.id] holds --
// looked up fresh on every call, so a test can hand it a plain object
// literal without worrying about dispatch being called more than once per
// step in this loop (it never is, since this loop runs each step exactly
// once).
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
  // -- dispatch order: three agent steps dispatch in declared order -------
  {
    const spec = {
      steps: [
        { id: 'a1', type: 'agent' },
        { id: 'a2', type: 'agent' },
        { id: 'a3', type: 'agent' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      a1: { text: 'one' },
      a2: { text: 'two' },
      a3: { text: 'three' },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a run of three agent steps completes', outcome.status === 'completed');
    check(
      'dispatch was called once per step, in declared step order',
      dispatch.calls.length === 3 && dispatch.calls[0].id === 'a1' && dispatch.calls[1].id === 'a2' && dispatch.calls[2].id === 'a3'
    );
  }

  // -- results-map accumulation: a later agent step's dispatch context ----
  // -- sees an earlier step's stored result under its step id -------------
  {
    const spec = {
      steps: [
        { id: 'first', type: 'agent' },
        { id: 'second', type: 'agent' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      first: { score: 7 },
      second: { score: 8 },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('the results-map-accumulation run completes', outcome.status === 'completed');
    check(
      "the second step's dispatch context carries the first step's result under its step id",
      dispatch.calls[1].context.results.first.score === 7
    );
    check(
      "the final results map carries both steps' results under their step ids",
      outcome.results.first.score === 7 && outcome.results.second.score === 8
    );
  }

  // -- shape steps execute in-engine (no dispatch) and land in the -------
  // -- results map like any other step's result ----------------------------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        { id: 'reshaped', type: 'shape', template: { greeting: 'hi {{upstream.name}}' } },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { name: 'alpha' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a run with a shape step completes', outcome.status === 'completed');
    check('the shape step never triggers a dispatch call', dispatch.calls.length === 1 && dispatch.calls[0].id === 'upstream');
    check(
      "the shape step's rendered output lands in the results map under its own step id",
      outcome.results.reshaped.greeting === 'hi alpha'
    );
  }

  // -- an agent step's prompt is template-rendered against prior results --
  // -- before being handed to the dispatcher --------------------------------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        { id: 'downstream', type: 'agent', prompt: 'summarize {{upstream.topic}}' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      upstream: { topic: 'sprints' },
      downstream: { summary: 'ok' },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('the agent-prompt-templating run completes', outcome.status === 'completed');
    check(
      "the downstream agent step's dispatched prompt has its template reference resolved",
      dispatch.calls[1].step.prompt === 'summarize sprints'
    );
  }

  // -- a render halt from an unresolved reference in an agent step's ------
  // -- prompt carries the steps[i] locator, not a bare renderer sub-path --
  {
    const spec = {
      steps: [
        { id: 'a1', type: 'agent' },
        { id: 'broken', type: 'agent', prompt: 'refers to {{missingStep.field}}' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ a1: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an unresolved agent-prompt template reference halts with status "failed"', outcome.status === 'failed');
    check(
      'the render halt reuses the existing template-operand-unresolved diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'template-operand-unresolved'
    );
    check(
      'the render halt path carries the steps[i] locator for the failing agent step, not a bare renderer sub-path',
      outcome.halt !== null && outcome.halt.path.indexOf('steps[1]') === 0
    );
    check('the broken agent step never dispatches (the render halts before dispatch)', dispatch.calls.length === 1 && dispatch.calls[0].id === 'a1');
  }

  // -- a render halt from an unresolved reference in a shape step's -------
  // -- template carries the steps[i] locator the same way -----------------
  {
    const spec = {
      steps: [
        { id: 'upstream', type: 'agent' },
        { id: 'broken', type: 'shape', template: { x: '{{missingStep.field}}' } },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ upstream: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an unresolved shape-template reference halts with status "failed"', outcome.status === 'failed');
    check(
      'the shape render halt reuses the existing template-operand-unresolved diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'template-operand-unresolved'
    );
    check(
      'the shape render halt path carries the steps[i] locator for the failing shape step, not a bare renderer sub-path',
      outcome.halt !== null && outcome.halt.path.indexOf('steps[1]') === 0
    );
  }

  // -- gate verdict "pass": the run continues past the gate ----------------
  {
    const spec = {
      steps: [
        { id: 'check', type: 'gate' },
        { id: 'after', type: 'agent' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      check: { verdict: 'pass', reason: 'looks fine' },
      after: { done: true },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a passing gate lets the run complete', outcome.status === 'completed');
    check('the step after a passing gate still runs', dispatch.calls.length === 2 && dispatch.calls[1].id === 'after');
    check("the gate's own outcome lands in the results map", outcome.results.check.verdict === 'pass');
  }

  // -- gate verdict "fail": the run halts with status "gated" plus a ------
  // -- partial result naming the failing gate -------------------------------
  {
    const spec = {
      steps: [
        { id: 'before', type: 'agent' },
        { id: 'check', type: 'gate' },
        { id: 'after', type: 'agent' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      before: { ok: true },
      check: { verdict: 'fail', reason: 'engineered failure' },
      after: { done: true },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a failing gate halts the run with status "gated"', outcome.status === 'gated');
    check('the step after a failing gate never dispatches', dispatch.calls.length === 2);
    check('the halt names the failing gate step', outcome.halt !== null && outcome.halt.path.indexOf('steps[1]') === 0);
    check('the halt uses a named gate-failure diagnostic', outcome.halt.diagnostic === 'gate-verdict-failed');
    check('the halt carries the halted:true discriminator every halt-returning function in this file uses', outcome.halt.halted === true);
    check(
      'partial results collected before the failing gate are still returned',
      outcome.results.before.ok === true
    );
    check("the failing gate's own outcome is not folded into the completed-results map", typeof outcome.results.check === 'undefined');
  }

  // -- gate verdict "uncertain", cause 1: the outcome reports "uncertain" -
  // -- directly (the schema-member case) ------------------------------------
  {
    const spec = { steps: [{ id: 'check', type: 'gate' }], config: {} };
    const dispatch = makeRecordingDispatch({ check: { verdict: 'uncertain', reason: 'not sure' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a gate reporting "uncertain" directly halts with status "uncertain"', outcome.status === 'uncertain');
    check(
      'the raw gate outcome that produced the halt is recorded in the trace',
      outcome.trace[0].outcome && outcome.trace[0].outcome.verdict === 'uncertain'
    );
  }

  // -- gate verdict "uncertain", cause 2: the reported verdict text cannot -
  // -- be parsed into a known verdict at all --------------------------------
  {
    const spec = { steps: [{ id: 'check', type: 'gate' }], config: {} };
    const dispatch = makeRecordingDispatch({ check: { verdict: 'maybe-ish', reason: 'ambiguous' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a gate reporting an unparseable verdict halts with status "uncertain"', outcome.status === 'uncertain');
    check('the halt is reported under the unparseable-verdict diagnostic', outcome.halt.diagnostic === 'gate-verdict-unparseable');
  }

  // -- gate verdict "uncertain", cause 2b: a null dispatch outcome for a --
  // -- gate step is also unparseable, not a hang or a crash -----------------
  {
    const spec = { steps: [{ id: 'check', type: 'gate' }], config: {} };
    const dispatch = makeRecordingDispatch({ check: null });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a gate whose dispatch resolves to null halts with status "uncertain", not a hang', outcome.status === 'uncertain');
    check('the null-outcome gate halt uses the unparseable-verdict diagnostic', outcome.halt.diagnostic === 'gate-verdict-unparseable');
  }

  // -- gate verdict "uncertain", cause 3: the say-vs-do cross-check trips -
  {
    const spec = {
      steps: [
        {
          id: 'check',
          type: 'gate',
          claimField: 'claim',
          evidenceField: 'evidence',
          minTokenOverlap: 3,
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      check: { verdict: 'pass', claim: 'the tests all pass now', evidence: 'unrelated evidence text' },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a say-vs-do trip halts with status "uncertain" even though the reported verdict was "pass"', outcome.status === 'uncertain');
    check('the say-vs-do halt uses the verdict-unsupported diagnostic', outcome.halt.diagnostic === 'verdict-unsupported');
    check(
      'the trace records the verdict-unsupported flag for this gate',
      outcome.trace[0].flags.indexOf('verdict-unsupported') !== -1
    );
  }

  // -- gate verdict "uncertain", cause 3 (reported verdict "fail"): the ---
  // -- say-vs-do cross-check trips REGARDLESS of what verdict was reported,
  // -- so this halts "uncertain" with verdict-unsupported, NOT "gated" ----
  {
    const spec = {
      steps: [
        {
          id: 'check',
          type: 'gate',
          claimField: 'claim',
          evidenceField: 'evidence',
          minTokenOverlap: 3,
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      check: { verdict: 'fail', claim: 'the tests all pass now', evidence: 'unrelated evidence text' },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check(
      'a say-vs-do trip halts with status "uncertain", not "gated", even though the reported verdict was "fail"',
      outcome.status === 'uncertain'
    );
    check(
      'the say-vs-do halt (reported verdict "fail") uses the verdict-unsupported diagnostic, not gate-verdict-failed',
      outcome.halt !== null && outcome.halt.diagnostic === 'verdict-unsupported'
    );
    check(
      'the trace records the verdict-unsupported flag for this gate (reported verdict "fail")',
      outcome.trace[0].flags.indexOf('verdict-unsupported') !== -1
    );
  }

  // -- say-vs-do cross-check: sufficient overlap does NOT trip it, and the -
  // -- reported verdict stands -----------------------------------------------
  {
    const spec = {
      steps: [
        {
          id: 'check',
          type: 'gate',
          claimField: 'claim',
          evidenceField: 'evidence',
          minTokenOverlap: 2,
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({
      check: { verdict: 'pass', claim: 'the tests all pass', evidence: 'the tests all pass, confirmed' },
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('sufficient claim/evidence overlap lets a passing gate stand', outcome.status === 'completed');
  }

  // -- a dispatcher null result for an AGENT step surfaces as a failed -----
  // -- halt, never a hang ----------------------------------------------------
  {
    const spec = { steps: [{ id: 'a1', type: 'agent' }], config: {} };
    const dispatch = makeRecordingDispatch({ a1: null });
    const raced = await Promise.race([
      specEngineExecute(spec, dispatch).then(function (outcome) {
        return { timedOut: false, outcome: outcome };
      }),
      new Promise(function (resolve) {
        setTimeout(function () {
          resolve({ timedOut: true });
        }, 1000);
      }),
    ]);
    check('a null agent-dispatch result resolves instead of hanging', raced.timedOut === false);
    if (!raced.timedOut) {
      check('a null agent-dispatch result halts with status "failed"', raced.outcome.status === 'failed');
      check(
        'the halt uses the agent-dispatch-null-result diagnostic',
        raced.outcome.halt.diagnostic === 'agent-dispatch-null-result'
      );
    }
  }

  // -- "branch" is now executed too, not rejected: a bare malformed -------
  // -- branch step (missing "cases") still halts, but under its OWN -------
  // -- execute-time malformed-shape guard, not the generic --------------
  // -- container-step-not-supported diagnostic -- spend-free, zero --------
  // -- dispatches (full branch-execution coverage lives in test-branch.js)
  {
    const spec = {
      steps: [
        { id: 'before', type: 'agent' },
        { id: 'branch1', type: 'branch' },
        { id: 'after', type: 'agent' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ before: { ok: true }, after: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a bare branch step (missing "cases") fails at execute time', outcome.status === 'failed');
    check(
      'a branch step with no "cases" field instead fails under its own branch-cases-not-array diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'branch-cases-not-array'
    );
    check('the step after the malformed branch step never dispatches', dispatch.calls.length === 1 && dispatch.calls[0].id === 'before');
  }

  // -- "parallel" is now executed, not rejected: a bare parallel step with
  // -- no "tracks" field still halts, but for a DIFFERENT, more specific --
  // -- reason -- its own execute-time malformed-shape guard, not the ------
  // -- container-step-not-supported diagnostic the two kinds above get ----
  // -- (full parallel-execution coverage lives in test-parallel.js) -------
  {
    const spec = { steps: [{ id: 'c1', type: 'parallel' }], config: {} };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a tracks-less parallel step fails at execute time', outcome.status === 'failed');
    check(
      'a parallel step with no "tracks" field instead fails under its own parallel-tracks-not-array diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'parallel-tracks-not-array'
    );
  }

  // -- "map" is now executed too, not rejected: a bare map step with no ---
  // -- "steps"/"list" fields still halts, but under its OWN execute-time --
  // -- malformed-shape guards, not the container-step-not-supported -------
  // -- diagnostic the two still-unsupported kinds above get (full ---------
  // -- map-execution coverage lives in test-map.js) ------------------------
  {
    const spec = { steps: [{ id: 'm1', type: 'map' }], config: {} };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a steps-less, list-less map step fails at execute time', outcome.status === 'failed');
    check(
      'a map step with no "steps" field instead fails under its own map-steps-not-array diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'map-steps-not-array'
    );
    check('a malformed map step never reaches dispatch', dispatch.calls.length === 0);
  }

  // -- "scored-retry" is now executed too, not rejected: a bare -----------
  // -- scored-retry step with none of its own required fields still -------
  // -- halts, but under its OWN execute-time malformed-shape guard, not ---
  // -- the container-step-not-supported diagnostic the one still ----------
  // -- unsupported kind above gets (full scored-retry-execution coverage --
  // -- lives in test-scored-retry.js) ---------------------------------------
  {
    const spec = { steps: [{ id: 'sr1', type: 'scored-retry' }], config: {} };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a bare scored-retry step (missing "mode") fails at execute time', outcome.status === 'failed');
    check(
      'a scored-retry step with no "mode" field instead fails under its own scored-retry-mode-required diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'scored-retry-mode-required'
    );
    check('a malformed scored-retry step never reaches dispatch', dispatch.calls.length === 0);
  }

  // -- a gate step carrying a "predicate" field is a recognized-but------
  // -- rejected form: it is never dispatched, and halts immediately -------
  // -- under its own named diagnostic ---------------------------------------
  {
    const spec = {
      steps: [
        {
          id: 'check',
          type: 'gate',
          predicate: { step: 'upstream', field: 'score', operator: 'gte', value: 1 },
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ check: { verdict: 'pass' } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a predicate-form gate halts the run with status "failed"', outcome.status === 'failed');
    check(
      'the halt uses the gate-predicate-form-not-supported diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'gate-predicate-form-not-supported'
    );
    check(
      'a predicate-form gate names the offending step in the halt path',
      outcome.halt !== null && outcome.halt.path.indexOf('steps[0]') === 0
    );
    check('a predicate-form gate is never dispatched', dispatch.calls.length === 0);
  }

  // -- malformed-spec guard: a spec that is not a plain object halts ------
  // -- with status "failed" under the reused spec-not-object diagnostic ---
  // -- NOTE: this fixture must be a non-STRING, non-object value -- a bare
  // -- string is now a legal spec input form (specEngineExecute JSON.parses
  // -- a string spec; see test-carriage.js's own spec-input-forms coverage),
  // -- so a string fixture here would exercise the spec-json-unparseable
  // -- diagnostic instead of this one. 42 is neither a string nor a plain
  // -- object, so it still reaches (and still fails) the spec-not-object
  // -- guard.
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(42, dispatch);
    check('a non-object, non-string spec (number) halts with status "failed"', outcome.status === 'failed');
    check('the halt uses the reused spec-not-object diagnostic (number)', outcome.halt.diagnostic === 'spec-not-object');
    check('a non-object, non-string spec (number) never reaches dispatch', dispatch.calls.length === 0);
  }

  // -- malformed-spec guard, fold-in: null is a second, distinct
  // -- non-object, non-string value that must reach the same spec-not-object
  // -- guard as the number 42 above -- typeof null === 'object' in
  // -- JavaScript, so this fixture also proves the guard's own plain-object
  // -- check rejects null specifically, not just "typeof !== 'object'".
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(null, dispatch);
    check('a null spec halts with status "failed"', outcome.status === 'failed');
    check('the halt uses the reused spec-not-object diagnostic (null)', outcome.halt.diagnostic === 'spec-not-object');
    check('a null spec never reaches dispatch', dispatch.calls.length === 0);
  }

  // -- malformed-spec guard: a spec whose "steps" is not an array halts ---
  // -- with status "failed" under the reused steps-not-array diagnostic ---
  {
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute({ steps: 'not-an-array', config: {} }, dispatch);
    check('a non-array spec.steps halts with status "failed"', outcome.status === 'failed');
    check('the halt uses the reused steps-not-array diagnostic', outcome.halt.diagnostic === 'steps-not-array');
    check('a non-array spec.steps never reaches dispatch', dispatch.calls.length === 0);
  }

  // -- malformed-step guard mid-sequence: a non-object entry in spec.steps
  // -- halts with status "failed", and results collected before it are ----
  // -- preserved, not discarded --------------------------------------------
  {
    const spec = {
      steps: [{ id: 'a1', type: 'agent' }, 'not-a-step-object', { id: 'a2', type: 'agent' }],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ a1: { ok: true }, a2: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a non-object step mid-sequence halts with status "failed"', outcome.status === 'failed');
    check('the halt uses the reused step-not-object diagnostic', outcome.halt.diagnostic === 'step-not-object');
    check("the earlier step's result is preserved in the partial results map", outcome.results.a1.ok === true);
    check('the step after the malformed entry never dispatches', dispatch.calls.length === 1 && dispatch.calls[0].id === 'a1');
  }

  // -- unknown-step-kind guard: a declared type outside the seven --------
  // -- recognized step kinds halts with status "failed" -------------------
  {
    const spec = { steps: [{ id: 'x1', type: 'not-a-real-kind' }], config: {} };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('an unrecognized step kind halts with status "failed"', outcome.status === 'failed');
    check('the halt uses the unknown-step-kind diagnostic', outcome.halt.diagnostic === 'unknown-step-kind');
    check('an unrecognized step kind never reaches dispatch', dispatch.calls.length === 0);
  }

  // -- a dispatcher null result for a GATE step resolves instead of -------
  // -- hanging, mirroring the agent-step race-style proof above -----------
  {
    const spec = { steps: [{ id: 'check', type: 'gate' }], config: {} };
    const dispatch = makeRecordingDispatch({ check: null });
    const raced = await Promise.race([
      specEngineExecute(spec, dispatch).then(function (outcome) {
        return { timedOut: false, outcome: outcome };
      }),
      new Promise(function (resolve) {
        setTimeout(function () {
          resolve({ timedOut: true });
        }, 1000);
      }),
    ]);
    check('a null gate-dispatch result resolves instead of hanging', raced.timedOut === false);
    if (!raced.timedOut) {
      check('a null gate-dispatch result halts with status "uncertain"', raced.outcome.status === 'uncertain');
      check(
        'the halt uses the gate-verdict-unparseable diagnostic',
        raced.outcome.halt.diagnostic === 'gate-verdict-unparseable'
      );
    }
  }

  console.log(passCount + ' passed, ' + failCount + ' failed');
  process.exit(failCount === 0 ? 0 : 1);
}

main().catch(function (err) {
  console.error('test-execute.js crashed: ' + (err && err.stack ? err.stack : err));
  process.exit(1);
});
