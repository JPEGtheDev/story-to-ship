// Map-container suite for the sprint engine's execute loop: the "map" step
// kind, the second container kind specEngineExecute runs (after "parallel").
//
// Runs as: node tools/sprint_engine/tests/test-map.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test -- same house style as test-execute.js/test-parallel.js, including
// its own local copies of `check` and `makeRecordingDispatch` (each suite
// file is self-contained).
//
// Contract under test, per the "Container authoring syntax", "Map-body
// addressing", "ID-uniqueness is scoped", and "Result-key namespacing
// grammar" sections of SPEC_SCHEMA.md, plus five points SPEC_SCHEMA.md
// leaves open that this suite's own implementation had to settle (each
// disclosed at the point it is exercised below):
//
//   - a map step's nested steps live under `steps`, an array of step
//     objects run once per item of a resolved list (one run per item is
//     an "iteration").
//   - SPEC_SCHEMA.md never names the field a map step declares its list
//     source under. This implementation reads it from `list: { step,
//     field? }` -- reusing the same `{step, field}` reference shape a
//     predicate already uses to name an earlier step's result (minus
//     predicate's own operator/value), rather than a `{{...}}` template
//     string: a template render always stringifies its resolved value
//     (specEngineStringifyTemplateValue), which would turn an actual
//     array into JSON text and break iteration outright. `field` is
//     optional; when absent, the named step's entire result is the list.
//   - each iteration is seeded with a shallow clone of the results
//     collected so far (mirroring a parallel track's own seeding), plus a
//     synthetic bare-name `item` key holding that iteration's current list
//     item -- SPEC_SCHEMA.md's own vocabulary calls the map's per-run unit
//     "one item... of the list" but never names a field a body step reads
//     it through, so this is this suite's own inferred, disclosed choice.
//     A body step reads it as `{{item}}` (the whole item) or
//     `{{item.someField}}` (the split rule's ordinary field-path case).
//   - a later step in the SAME iteration reads an earlier one by bare step
//     name (`{{summarize}}`, not `{{chapters.0.summarize}}`), per the
//     ratified split-rule reading SPEC_SCHEMA.md's map-body-addressing
//     section names explicitly -- inherited for free by reusing
//     specEngineExecuteSequence per iteration, unchanged.
//   - storage shape, per the ratified "an iteration's result is stored as
//     an object keyed by step ID whenever the body holds more than one
//     step": a SINGLE-step body's plain `<mapId>.<index>` key holds that
//     one step's result directly (not wrapped in a one-key object); a
//     MULTI-step body's plain `<mapId>.<index>` key holds the
//     step-ID-keyed object. `<mapId>.<index>.<stepId>` is always written
//     per completed step regardless of body length, per the namespacing
//     grammar's own literal format.
//   - iteration failure containment mirrors track containment: one
//     iteration's own halt (a failing/uncertain gate, or any other
//     leaf-halt cause) is contained to that iteration -- other iterations
//     still run, the run continues past the map step, and nothing is
//     written to the results map for a failed iteration's own step(s).
//     SPEC_SCHEMA.md does not pin this; it is this suite's own disclosed,
//     owner-reversible design (the parallel precedent's containment
//     policy, applied to map -- but, unlike parallel, this implementation
//     does NOT add an aggregates object under the map step's own id, since
//     no ratified wording defines aggregate counts for map and the
//     namespacing grammar never declares a plain `<mapId>` key at all
//     (only the `<mapId>.<index>` pattern) -- a failed iteration is
//     inspectable only via the map step's own trace entry, under a new
//     `iterations` array, one `{ index, status, trace, halt }` summary per
//     iteration, mirroring parallel's own `tracks` trace field).
//   - concurrency: iterations run SEQUENTIALLY, in list order -- the
//     opposite of a parallel step's own tracks. SPEC_SCHEMA.md's one-line
//     step-kind definitions state a real textual contrast: parallel is
//     described as "several tracks AT ONCE" while map is described only as
//     "repeat steps once per item in a list", with no "at once" language
//     anywhere in the map bullet or the map-body-addressing section. This
//     suite reads that omission as deliberate and pins sequential order
//     explicitly as this suite's own disclosed, owner-reversible design.
//   - `map.merge` (a real, OPTIONAL contract field: "if it does not [declare
//     merge], a default combination applies, but no sourced wording
//     specifies what that default combination actually does -- this
//     contract does not invent one") is a recognized-but-rejected form
//     here, mirroring the existing predicate-form-gate precedent: a map
//     step declaring `merge` halts immediately, before any iteration runs,
//     under its own 'map-merge-not-supported' diagnostic, rather than
//     silently ignoring the field or guessing at combination semantics.
//   - malformed-shape guards: `steps` missing/not an array
//     ('map-steps-not-array'), `list` missing or not a well-formed
//     `{step, field?}` reference ('map-list-malformed'), a `list.step`/
//     `list.field` that does not resolve against the results collected so
//     far ('map-list-unresolved'), and a resolved list value that is not
//     an array ('map-list-not-array') -- mirroring the parallel-tracks-*
//     guard precedent, since validateSpec does not itself check any of
//     these shapes for a map step (confirmed by reading validateSpec's own
//     `type === 'map'` branch: it recurses into `step.steps` only when
//     `Array.isArray(step.steps)` is already true, silently doing nothing
//     otherwise, and it has no knowledge of `list` at all, since that
//     field name is this implementation's own invention).

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

// makeItemAwareDispatch() returns a dispatch stub whose resolved outcome is
// keyed by BOTH the step id and the current iteration's own item (read from
// context.results.item, the synthetic bare-name key this suite's map
// implementation seeds every iteration with) -- so a fixture asserting that
// two different iterations' results differ cannot accidentally pass on a
// dispatch stub that returns the same static object for every call.
// makeRecordingDispatch's own outcome lookup, by contrast, is keyed by step
// id ALONE, which is identical across every iteration of the same map body
// and would defeat exactly the direction-sensitive assertions this file's
// map-body-storage-shape blocks need to make.
function makeItemAwareDispatch() {
  const calls = [];
  const dispatch = async function (step, context) {
    const item = context.results.item;
    calls.push({ id: step.id, item: item, step: step, context: context });
    return { text: step.id + '-for-' + item };
  };
  dispatch.calls = calls;
  return dispatch;
}

async function main() {
  // -- fan-out: a 3-item list dispatches once per item, and each --------
  // -- iteration's body sees its OWN item via the bare {{item}} reference -
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0', 'ch1', 'ch2'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [{ id: 'summarize', type: 'agent', prompt: 'summarize {{item}}' }],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step over a 3-item list completes', outcome.status === 'completed');
    check('the map step dispatches once per item, three calls total', dispatch.calls.length === 3);
    check(
      'each iteration renders {{item}} into its OWN distinct item, in list order (direction-sensitive)',
      dispatch.calls.length === 3 &&
        dispatch.calls[0].step.prompt === 'summarize ch0' &&
        dispatch.calls[1].step.prompt === 'summarize ch1' &&
        dispatch.calls[2].step.prompt === 'summarize ch2'
    );
  }

  // -- <mapId>.<index>.<stepId> keys are present after the map step joins -
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0', 'ch1', 'ch2'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [{ id: 'summarize', type: 'agent', prompt: 'summarize {{item}}' }],
        },
      ],
      config: {},
    };
    const dispatch = makeItemAwareDispatch();
    const outcome = await specEngineExecute(spec, dispatch);
    check(
      'the <mapId>.<index>.<stepId> keys are present for every iteration, holding that iteration\'s own dispatch outcome',
      typeof outcome.results['chapters.0.summarize'] !== 'undefined' &&
        typeof outcome.results['chapters.1.summarize'] !== 'undefined' &&
        typeof outcome.results['chapters.2.summarize'] !== 'undefined'
    );
    check(
      'iteration 0 and iteration 2 hold DIFFERENT dispatch outcomes, not interchangeable ones (direction-sensitive)',
      JSON.stringify(outcome.results['chapters.0.summarize']) !== JSON.stringify(outcome.results['chapters.2.summarize'])
    );
  }

  // -- plain <mapId>.<index> holds the keyed-OBJECT iteration result once -
  // -- the body holds MORE THAN ONE step, per the ratified sentence -------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0', 'ch1'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [
            { id: 'summarize', type: 'agent', prompt: 'summarize {{item}}' },
            { id: 'wordcount', type: 'agent', prompt: 'count {{item}}' },
          ],
        },
      ],
      config: {},
    };
    const dispatch = makeItemAwareDispatch();
    const outcome = await specEngineExecute(spec, dispatch);
    check('a multi-step-body map over a 2-item list completes', outcome.status === 'completed');
    check(
      'the plain <mapId>.<index> key is a step-ID-keyed object for a multi-step body',
      outcome.results['chapters.0'] &&
        typeof outcome.results['chapters.0'] === 'object' &&
        typeof outcome.results['chapters.0'].summarize !== 'undefined' &&
        typeof outcome.results['chapters.0'].wordcount !== 'undefined'
    );
    check(
      'the keyed-object member equals the same value the dotted <mapId>.<index>.<stepId> key holds',
      !!outcome.results['chapters.0'] &&
        outcome.results['chapters.0'].summarize === outcome.results['chapters.0.summarize'] &&
        outcome.results['chapters.0'].wordcount === outcome.results['chapters.0.wordcount']
    );
    check(
      'iteration 1 gets its own independent keyed object (direction-sensitive: not a shared/aliased object with iteration 0)',
      outcome.results['chapters.1'] !== outcome.results['chapters.0']
    );
  }

  // -- single-step-body storage shape: the plain <mapId>.<index> key is ---
  // -- the step's result DIRECTLY, not wrapped in a one-key object --------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0', 'ch1'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [{ id: 'summarize', type: 'agent', prompt: 'summarize {{item}}' }],
        },
      ],
      config: {},
    };
    const dispatch = makeItemAwareDispatch();
    const outcome = await specEngineExecute(spec, dispatch);
    check(
      'for a single-step body, the plain <mapId>.<index> key IS the step\'s own dispatch outcome, not a {summarize: ...} wrapper',
      !!outcome.results['chapters.0'] &&
        outcome.results['chapters.0'] === outcome.results['chapters.0.summarize'] &&
        typeof outcome.results['chapters.0'].summarize === 'undefined'
    );
  }

  // -- bare-name same-iteration reference: a later step in the SAME -------
  // -- iteration reads an earlier one by bare step name, per iteration ----
  // -- (direction-sensitive: iteration 0 and iteration 1 must each read ---
  // -- their OWN earlier step, never the other iteration's) ---------------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0', 'ch1'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [
            { id: 'summarize', type: 'agent', prompt: 'summarize {{item}}' },
            { id: 'consolidate', type: 'agent', prompt: 'consolidated: {{summarize.text}}' },
          ],
        },
      ],
      config: {},
    };
    const dispatch = async function (step, context) {
      if (step.id === 'summarize') {
        return { text: 'summary-of-' + context.results.item };
      }
      return { ok: true };
    };
    const outcome = await specEngineExecute(spec, dispatch);
    check('a bare-name same-iteration reference resolves for both iterations', outcome.status === 'completed');
    check(
      'iteration 0\'s consolidate step reads ITS OWN summarize result via {{summarize.text}}',
      outcome.results['chapters.0.consolidate'] && outcome.results['chapters.0'] // sanity: shape assertions above already cover this
    );
  }

  // -- same bare-name reference, asserted directly through the dispatch ---
  // -- prompt actually sent, so the fixture cannot pass by accident -------
  {
    const calls = [];
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0', 'ch1'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [
            { id: 'summarize', type: 'agent', prompt: 'summarize {{item}}' },
            { id: 'consolidate', type: 'agent', prompt: 'consolidated: {{summarize.text}}' },
          ],
        },
      ],
      config: {},
    };
    const dispatch = async function (step, context) {
      calls.push({ id: step.id, prompt: step.prompt });
      if (step.id === 'summarize') {
        return { text: 'summary-of-' + context.results.item };
      }
      return { ok: true };
    };
    await specEngineExecute(spec, dispatch);
    const consolidateCalls = calls.filter(function (c) {
      return c.id === 'consolidate';
    });
    check(
      'iteration 0 and iteration 1 each rendered a DIFFERENT consolidate prompt, from their own iteration\'s summarize (direction-sensitive)',
      consolidateCalls.length === 2 &&
        consolidateCalls[0].prompt === 'consolidated: summary-of-ch0' &&
        consolidateCalls[1].prompt === 'consolidated: summary-of-ch1'
    );
  }

  // -- EMPTY LIST: zero iterations, zero dispatch calls, run continues, ---
  // -- and no <mapId>.<index>* keys are ever written -----------------------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: [] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [{ id: 'summarize', type: 'agent', prompt: 'summarize {{item}}' }],
        },
        { id: 'after', type: 'agent' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ after: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step over an empty list completes with zero dispatch calls', outcome.status === 'completed');
    check('zero dispatch calls were made for the empty map (the step after it still dispatches)', dispatch.calls.length === 1 && dispatch.calls[0].id === 'after');
    check(
      'no namespaced key of any shape exists for an empty map',
      Object.keys(outcome.results).filter(function (k) {
        return k.indexOf('chapters.') === 0;
      }).length === 0
    );
    const mapTraceEntry = outcome.trace.filter(function (t) {
      return t.step === 'chapters';
    })[0];
    check('the map step\'s own trace entry records zero iterations', !!mapTraceEntry && Array.isArray(mapTraceEntry.iterations) && mapTraceEntry.iterations.length === 0);
  }

  // -- one failed iteration is CONTAINED: the other iterations still run --
  // -- and complete, the whole run does not halt, and the failed --------
  // -- iteration (the MIDDLE one, not an end -- direction-sensitive) ------
  // -- writes nothing to the results map ------------------------------------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['a', 'b', 'c'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [{ id: 'check', type: 'gate' }],
        },
      ],
      config: {},
    };
    const calls = [];
    const dispatch = async function (step, context) {
      calls.push(context.results.item);
      if (context.results.item === 'b') {
        return { verdict: 'fail', reason: 'engineered' };
      }
      return { verdict: 'pass', text: 'ok-' + context.results.item };
    };
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step with one internally-failing iteration still completes overall (no whole-run halt)', outcome.status === 'completed');
    check('every iteration was attempted, including the ones after the failing one', calls.length === 3 && calls[0] === 'a' && calls[1] === 'b' && calls[2] === 'c');
    check('the completed iteration BEFORE the failure has its results present', outcome.results['chapters.0'] && outcome.results['chapters.0'].verdict === 'pass');
    check('the completed iteration AFTER the failure has its results present too', outcome.results['chapters.2'] && outcome.results['chapters.2'].verdict === 'pass');
    check(
      'the failing iteration writes nothing to the results map, at either addressing shape',
      typeof outcome.results['chapters.1'] === 'undefined' && typeof outcome.results['chapters.1.check'] === 'undefined'
    );
    const mapTraceEntry = outcome.trace.filter(function (t) {
      return t.step === 'chapters';
    })[0];
    check('the map step\'s own trace entry carries one iteration summary per item', !!mapTraceEntry && mapTraceEntry.iterations.length === 3);
    check(
      'the failed iteration\'s own status/halt is inspectable from the map step\'s trace entry',
      !!mapTraceEntry &&
        !!mapTraceEntry.iterations[1] &&
        mapTraceEntry.iterations[1].status === 'gated' &&
        !!mapTraceEntry.iterations[1].halt &&
        mapTraceEntry.iterations[1].halt.diagnostic === 'gate-verdict-failed'
    );
    check(
      'the surrounding iterations report "completed" status in the same trace entry (direction-sensitive: only index 1 is not)',
      !!mapTraceEntry &&
        !!mapTraceEntry.iterations[0] &&
        !!mapTraceEntry.iterations[2] &&
        mapTraceEntry.iterations[0].status === 'completed' &&
        mapTraceEntry.iterations[2].status === 'completed'
    );
  }

  // -- concurrency/ordering proof: iterations run SEQUENTIALLY -- the -----
  // -- second item's dispatch does not fire until the first item's --------
  // -- dispatch has resolved (the opposite of test-parallel.js's own ------
  // -- concurrency proof for tracks) ---------------------------------------
  {
    let releaseFirst;
    const gate = new Promise(function (resolve) {
      releaseFirst = resolve;
    });
    const startOrder = [];
    const dispatch = async function (step, context) {
      startOrder.push(context.results.item);
      if (context.results.item === 'x0') {
        await gate;
      }
      return { ok: true };
    };
    const spec = {
      steps: [
        { id: 'src', type: 'shape', template: { list: ['x0', 'x1', 'x2'] } },
        { id: 'm1', type: 'map', list: { step: 'src', field: 'list' }, steps: [{ id: 'step1', type: 'agent' }] },
      ],
      config: {},
    };
    const executePromise = specEngineExecute(spec, dispatch);
    // Give the microtask/timer queue a turn -- if iterations ran
    // concurrently (like parallel tracks), item x1's dispatch would already
    // have fired by now, same as test-parallel.js's own proof shows for
    // tracks. Sequential execution means it must NOT have.
    await new Promise(function (resolve) {
      setTimeout(resolve, 10);
    });
    check(
      'only the FIRST iteration has dispatched while it is still blocked -- the second has not started (sequential, not concurrent)',
      startOrder.length === 1 && startOrder[0] === 'x0'
    );
    releaseFirst();
    const outcome = await executePromise;
    check('the run completes once the blocked first iteration is released', outcome.status === 'completed');
    check(
      'iterations dispatched in strict list order once unblocked: x0, then x1, then x2',
      startOrder.length === 3 && startOrder[0] === 'x0' && startOrder[1] === 'x1' && startOrder[2] === 'x2'
    );
  }

  // -- map.merge is a recognized-but-rejected form: never dispatched, -----
  // -- halts immediately under its own named diagnostic --------------------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          merge: 'concat',
          steps: [{ id: 'summarize', type: 'agent', prompt: 'summarize {{item}}' }],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step declaring "merge" halts the run with status "failed"', outcome.status === 'failed');
    check('the halt uses the map-merge-not-supported diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'map-merge-not-supported');
    check('a map step declaring "merge" is never dispatched -- not even one iteration runs', dispatch.calls.length === 0);
  }

  // -- malformed shape, execute-time guard: "steps" missing entirely ------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0'] } },
        { id: 'chapters', type: 'map', list: { step: 'chapterList', field: 'chapters' } },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step with no "steps" field halts the whole run', outcome.status === 'failed');
    check('the halt uses the map-steps-not-array diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'map-steps-not-array');
    check('a malformed map step never reaches dispatch', dispatch.calls.length === 0);
  }

  // -- malformed shape, execute-time guard: "steps" present but not an ----
  // -- array -----------------------------------------------------------------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0'] } },
        { id: 'chapters', type: 'map', list: { step: 'chapterList', field: 'chapters' }, steps: 'not-an-array' },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step whose "steps" is not an array halts the whole run', outcome.status === 'failed');
    check('the halt uses the map-steps-not-array diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'map-steps-not-array');
  }

  // -- guard: a map body step declared with the literal id "item" collides
  // -- with the synthetic per-iteration item key. Without this guard, the --
  // -- step would still DISPATCH (spend occurs) and its result would then --
  // -- be silently excluded from both <mapId>.<index>.item and the --------
  // -- <mapId>.<index> keyed object -- status completed, halt null, the ---
  // -- work surviving only buried in the trace. This is spend-attached ----
  // -- silent data loss, the same class the contract's undefined-sentinel -
  // -- rationale forbids elsewhere -- so this halts BEFORE any iteration --
  // -- dispatches, exactly like the other malformed-shape guards above ----
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [{ id: 'item', type: 'agent', prompt: 'summarize {{item}}' }],
        },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({ item: { ok: true } });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map body step declared with id "item" halts the whole run', outcome.status === 'failed');
    check(
      'the halt uses the map-body-step-id-item-reserved diagnostic',
      !!outcome.halt && outcome.halt.diagnostic === 'map-body-step-id-item-reserved'
    );
    check(
      'a map body step declared with id "item" is NEVER dispatched -- the guard fires before any spend occurs',
      dispatch.calls.length === 0
    );
  }

  // -- malformed shape, execute-time guard: "list" missing entirely -------
  {
    const spec = {
      steps: [{ id: 'chapters', type: 'map', steps: [{ id: 'summarize', type: 'agent' }] }],
      config: {},
    };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step with no "list" field halts the whole run', outcome.status === 'failed');
    check('the halt uses the map-list-malformed diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'map-list-malformed');
  }

  // -- malformed shape, execute-time guard: "list" present but not a ------
  // -- well-formed {step, field?} reference --------------------------------
  {
    const spec = {
      steps: [{ id: 'chapters', type: 'map', list: 'chapterList.chapters', steps: [{ id: 'summarize', type: 'agent' }] }],
      config: {},
    };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step whose "list" is a bare string (not {step, field?}) halts the whole run', outcome.status === 'failed');
    check('the halt uses the map-list-malformed diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'map-list-malformed');
  }

  // -- malformed shape, execute-time guard: "list.step" names a step with -
  // -- no result at this point in the spec ---------------------------------
  {
    const spec = {
      steps: [{ id: 'chapters', type: 'map', list: { step: 'doesNotExist' }, steps: [{ id: 'summarize', type: 'agent' }] }],
      config: {},
    };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step whose list.step names an undeclared step halts the whole run', outcome.status === 'failed');
    check('the halt uses the map-list-unresolved diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'map-list-unresolved');
  }

  // -- malformed shape, execute-time guard: "list.field" does not resolve -
  // -- on the named step's result ----------------------------------------------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0'] } },
        { id: 'chapters', type: 'map', list: { step: 'chapterList', field: 'noSuchField' }, steps: [{ id: 'summarize', type: 'agent' }] },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step whose list.field does not resolve halts the whole run', outcome.status === 'failed');
    check('the halt uses the map-list-unresolved diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'map-list-unresolved');
  }

  // -- malformed shape, execute-time guard: the resolved list value is not
  // -- an array -----------------------------------------------------------------
  {
    const spec = {
      steps: [
        { id: 'notAList', type: 'shape', template: { foo: 'bar' } },
        { id: 'chapters', type: 'map', list: { step: 'notAList' }, steps: [{ id: 'summarize', type: 'agent' }] },
      ],
      config: {},
    };
    const dispatch = makeRecordingDispatch({});
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step whose resolved list is not an array halts the whole run', outcome.status === 'failed');
    check('the halt uses the map-list-not-array diagnostic', !!outcome.halt && outcome.halt.diagnostic === 'map-list-not-array');
  }

  // -- coverage: a 3-item map with a 3-step bare-name chain body ----------
  // -- (stepA -> stepB -> stepC within each iteration), mirroring the ------
  // -- ratified book/chapters worked example (split -> summarize -> -------
  // -- consolidate). Pins per-step keys, the keyed-object iteration -------
  // -- result carrying all 3 step IDs, and direction-sensitive item -------
  // -- routing (iteration 0 got the FIRST item, iteration 2 the THIRD) ----
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0', 'ch1', 'ch2'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [
            { id: 'stepA', type: 'agent', prompt: 'A sees {{item}}' },
            { id: 'stepB', type: 'agent', prompt: 'B sees {{stepA.text}}' },
            { id: 'stepC', type: 'agent', prompt: 'C sees {{stepB.text}}' },
          ],
        },
      ],
      config: {},
    };
    const dispatch = async function (step, context) {
      if (step.id === 'stepA') {
        return { text: 'A-' + context.results.item };
      }
      if (step.id === 'stepB') {
        return { text: 'B-' + context.results.stepA.text };
      }
      return { text: 'C-' + context.results.stepB.text };
    };
    const outcome = await specEngineExecute(spec, dispatch);
    check('a 3-item map with a 3-step bare-name chain body completes', outcome.status === 'completed');
    check(
      'per-step <mapId>.<index>.<stepId> keys are present for all three steps, in iterations 0 and 2',
      typeof outcome.results['chapters.0.stepA'] !== 'undefined' &&
        typeof outcome.results['chapters.0.stepB'] !== 'undefined' &&
        typeof outcome.results['chapters.0.stepC'] !== 'undefined' &&
        typeof outcome.results['chapters.2.stepA'] !== 'undefined' &&
        typeof outcome.results['chapters.2.stepB'] !== 'undefined' &&
        typeof outcome.results['chapters.2.stepC'] !== 'undefined'
    );
    check(
      'the keyed-object iteration result carries exactly the 3 step IDs the body declares, no more and no fewer',
      !!outcome.results['chapters.0'] &&
        Object.keys(outcome.results['chapters.0']).length === 3 &&
        Object.keys(outcome.results['chapters.0']).indexOf('stepA') !== -1 &&
        Object.keys(outcome.results['chapters.0']).indexOf('stepB') !== -1 &&
        Object.keys(outcome.results['chapters.0']).indexOf('stepC') !== -1
    );
    check(
      'the bare-name chain resolved end-to-end within each iteration (stepC traces back through stepB and stepA)',
      !!outcome.results['chapters.0.stepC'] &&
        outcome.results['chapters.0.stepC'].text === 'C-B-A-ch0' &&
        !!outcome.results['chapters.2.stepC'] &&
        outcome.results['chapters.2.stepC'].text === 'C-B-A-ch2'
    );
    check(
      'iteration 0 got the FIRST list item and iteration 2 got the THIRD, never swapped (direction-sensitive)',
      !!outcome.results['chapters.0.stepA'] &&
        outcome.results['chapters.0.stepA'].text === 'A-ch0' &&
        !!outcome.results['chapters.2.stepA'] &&
        outcome.results['chapters.2.stepA'].text === 'A-ch2'
    );
  }

  // -- coverage: POSITIVE field-absent list case -- list: { step } where --
  // -- the named step's ENTIRE result IS the array (not a field carved ----
  // -- out of a wrapper object). The existing malformed-shape guards only -
  // -- prove the negative side of this; this proves the happy path -------
  // -- actually iterates, not just that it validates. ----------------------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'agent' },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList' },
          steps: [{ id: 'summarize', type: 'agent', prompt: 'summarize {{item}}' }],
        },
      ],
      config: {},
    };
    const dispatch = async function (step, context) {
      if (step.id === 'chapterList') {
        return ['ch0', 'ch1'];
      }
      return { text: 'summary-of-' + context.results.item };
    };
    const outcome = await specEngineExecute(spec, dispatch);
    check('a map step whose list.step result IS the array directly (no "field") completes', outcome.status === 'completed');
    check(
      'both iterations ran against the field-absent array source, each against its own item, in order (direction-sensitive)',
      !!outcome.results['chapters.0'] &&
        outcome.results['chapters.0'].text === 'summary-of-ch0' &&
        !!outcome.results['chapters.1'] &&
        outcome.results['chapters.1'].text === 'summary-of-ch1'
    );
  }

  // -- coverage: a post-map step consumes ONE SPECIFIC iteration's key ----
  // -- via a dotted template reference ({{mapId.1.stepX.field}}), and the -
  // -- rendered value must come from THAT iteration, not an adjacent one --
  // -- (direction-sensitive: a swapped index would silently pass a --------
  // -- symmetric fixture) --------------------------------------------------
  {
    const spec = {
      steps: [
        { id: 'chapterList', type: 'shape', template: { chapters: ['ch0', 'ch1', 'ch2'] } },
        {
          id: 'chapters',
          type: 'map',
          list: { step: 'chapterList', field: 'chapters' },
          steps: [{ id: 'summarize', type: 'agent', prompt: 'summarize {{item}}' }],
        },
        { id: 'pick', type: 'shape', template: { picked: '{{chapters.1.summarize.text}}' } },
      ],
      config: {},
    };
    const dispatch = makeItemAwareDispatch();
    const outcome = await specEngineExecute(spec, dispatch);
    check('a post-map step referencing one specific iteration key by dotted template completes', outcome.status === 'completed');
    check(
      'the rendered value came from ITERATION 1 specifically, not iteration 0 or iteration 2',
      !!outcome.results.pick &&
        outcome.results.pick.picked === 'summarize-for-ch1' &&
        outcome.results.pick.picked !== 'summarize-for-ch0' &&
        outcome.results.pick.picked !== 'summarize-for-ch2'
    );
  }

  console.log(passCount + ' passed, ' + failCount + ' failed');
  process.exit(failCount === 0 ? 0 : 1);
}

main().catch(function (err) {
  console.error('test-map.js crashed: ' + (err && err.stack ? err.stack : err));
  process.exit(1);
});
