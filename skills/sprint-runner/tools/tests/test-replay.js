// Replay-parity suite: replays the committed live fixture and all
// DETERMINISM-grade edge fixtures through the real specEngineExecute and
// asserts their pinned outcomes.
//
// This suite asserts engine OUTCOMES only. Per-dispatch integrity checks
// (promptSha256 reproduction against the committed spec, journal
// cross-check, the pinned build-content and spill-writer-receipt hashes)
// stay in verify-live-fixture.js and are not duplicated here -- this file
// reuses that script's mock DESIGN (matching a live dispatch back to its
// captured fixture record by stepKey) without re-running its five checks.

'use strict';

const fs = require('fs');
const path = require('path');
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

// ---------------------------------------------------------------------
// Part A: live-reference parity over skills/sprint-runner/tools/examples/
// build-test-review.json and skills/sprint-runner/tools/tests/fixtures/live/
// build-test-review.json (17 captured dispatch records).
// ---------------------------------------------------------------------

const REVIEW_MODULE_STEP_ID = 'review_module';

function findLiveFixtureRecord(fixture, step, reviewModuleCounterRef) {
  if (step.id === REVIEW_MODULE_STEP_ID) {
    const n = reviewModuleCounterRef.value;
    reviewModuleCounterRef.value += 1;
    // Same derivation as verify-live-fixture.js's own mock: the example
    // spec's per_module_review.code_review_with_retry.maxAttempts is 2, so
    // a flat call counter recovers (mapIndex, attemptIndex) from the flat
    // dispatch sequence (map iterations and scored-retry attempts run
    // sequentially, never interleaved).
    const mapIndex = Math.floor(n / 2);
    const attemptIndex = n % 2;
    const wantedKey = 'per_module_review.' + mapIndex + '.code_review_with_retry.attempts.' + attemptIndex;
    const matches = fixture.filter(function (r) {
      return r.stepKey === wantedKey;
    });
    if (matches.length !== 1) {
      throw new Error('expected exactly one fixture record for review_module call #' + n + ' (stepKey "' + wantedKey + '"), found ' + matches.length);
    }
    return matches[0];
  }

  const matches = fixture.filter(function (r) {
    return r.stepKey === step.id || r.stepKey.slice(-(step.id.length + 1)) === '.' + step.id;
  });
  if (matches.length !== 1) {
    throw new Error('expected exactly one fixture record matching step id "' + step.id + '", found ' + matches.length);
  }
  return matches[0];
}

async function runPartA() {
  const specPath = path.join(__dirname, '..', 'examples', 'build-test-review.json');
  const fixturePath = path.join(__dirname, 'fixtures', 'live', 'build-test-review.json');
  const spec = JSON.parse(fs.readFileSync(specPath, 'utf8'));
  const fixture = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));

  const reviewModuleCounterRef = { value: 0 };
  const dispatchOrder = [];

  async function dispatch(step) {
    const record = findLiveFixtureRecord(fixture, step, reviewModuleCounterRef);
    dispatchOrder.push(record.stepKey);
    return record.output;
  }

  const outcome = await specEngineExecute(spec, dispatch);

  check('Part A: exactly 17 dispatches occur', dispatchOrder.length === 17);

  // Order parity: each dispatch resolved to the fixture record whose
  // stepKey matches the dispatching step, so the recorded dispatch order
  // must equal the fixture's own dispatchIndex 0..16 order -- EXCEPT for
  // the test_suites parallel container's two tracks (unit, integration),
  // where relative order is not a contract: this replay deterministically
  // dispatches unit.run_unit_tests before integration.run_integration_tests
  // (track declaration order in the spec), while the fixture recorded them
  // in the OPPOSITE order (dispatchIndex 3, 4), because the original live
  // run's dispatchIndex there reflects real agent response timing across
  // two concurrent tracks, not an engine ordering guarantee (confirmed by
  // direct probe against this committed engine-core.js before writing this
  // assertion). That one sibling pair is therefore compared as a set, not
  // an ordered pair; every other position is compared exactly.
  const expectedOrder = fixture
    .slice()
    .sort(function (a, b) {
      return a.dispatchIndex - b.dispatchIndex;
    })
    .map(function (r) {
      return r.stepKey;
    });
  const CONCURRENT_SIBLING_PAIR = ['unit.run_unit_tests', 'integration.run_integration_tests'];
  function canonicalizeConcurrentSiblingPair(order) {
    const copy = order.slice();
    const indices = [];
    copy.forEach(function (key, idx) {
      if (CONCURRENT_SIBLING_PAIR.indexOf(key) !== -1) {
        indices.push(idx);
      }
    });
    if (indices.length === 2) {
      const sortedPair = CONCURRENT_SIBLING_PAIR.slice().sort();
      copy[indices[0]] = sortedPair[0];
      copy[indices[1]] = sortedPair[1];
    }
    return copy;
  }
  check(
    'Part A: dispatch call order matches fixture dispatchIndex order (test_suites track pair compared as a set, see comment above)',
    JSON.stringify(canonicalizeConcurrentSiblingPair(dispatchOrder)) === JSON.stringify(canonicalizeConcurrentSiblingPair(expectedOrder))
  );

  check('Part A: final status is "gated"', outcome.status === 'gated');
  check('Part A: halt diagnostic is "gate-verdict-failed"', !!outcome.halt && outcome.halt.diagnostic === 'gate-verdict-failed');
  check('Part A: halt path is "steps[5]"', !!outcome.halt && outcome.halt.path === 'steps[5]');

  // route_by_risk selected the default arm: the fixture's own record at
  // dispatchIndex 15 is route_by_risk.log_auto_approval (the default arm's
  // step), never route_by_risk.flag_for_manual_review (the case arm's
  // step) -- so a faithful replay's own results land under the default
  // arm's namespaced key and never under the case arm's. Two separately
  // named checks so a failure identifies which condition broke.
  check('Part A: route_by_risk default-arm result key (log_auto_approval) is present', outcome.results['route_by_risk.log_auto_approval'] !== undefined);
  check(
    'Part A: route_by_risk case-arm result key (flag_for_manual_review) is absent',
    outcome.results['route_by_risk.flag_for_manual_review'] === undefined
  );

  // keep-best winners per module, pinned as literals -- machine-verified
  // this session directly from the fixture's own attempt records (grep
  // over "stepKey"/"score" in tests/fixtures/live/build-test-review.json,
  // module order taken from the build record's changedModules: auth,
  // billing, search-index, notifications):
  //   module 0 (auth):          attempts.0 score 0.8,  attempts.1 score 0.9  -> winner 0.9
  //   module 1 (billing):       attempts.0 score 0.93, attempts.1 score 0.72 -> winner 0.93
  //   module 2 (search-index):  attempts.0 score 0.72, attempts.1 score 0.5  -> winner 0.72
  //   module 3 (notifications): attempts.0 score 1,    attempts.1 score 0.8  -> winner 1
  // A scored-retry nested inside a map stores its keep-best winner at
  // "<mapId>.<index>.<retryId>" (confirmed by direct probe against this
  // committed engine-core.js before writing this assertion).
  const EXPECTED_WINNER_SCORES = [0.9, 0.93, 0.72, 1];
  EXPECTED_WINNER_SCORES.forEach(function (expectedScore, moduleIndex) {
    const key = 'per_module_review.' + moduleIndex + '.code_review_with_retry';
    const winner = outcome.results[key];
    check('Part A: module ' + moduleIndex + ' keep-best winner score is ' + expectedScore, !!winner && winner.score === expectedScore);
  });
}

// ---------------------------------------------------------------------
// Part B: edge-fixture replay over every file in skills/sprint-runner/tools/
// tests/fixtures/edge/, discovered by glob rather than a hardcoded list
// so a future fixture is picked up automatically.
// ---------------------------------------------------------------------

async function runPartB() {
  const edgeDir = path.join(__dirname, 'fixtures', 'edge');
  const files = fs
    .readdirSync(edgeDir)
    .filter(function (f) {
      return f.slice(-'.json'.length) === '.json';
    })
    .sort();

  check('Part B: at least 4 edge fixtures discovered by glob', files.length >= 4);

  for (let i = 0; i < files.length; i += 1) {
    const file = files[i];
    const fixture = JSON.parse(fs.readFileSync(path.join(edgeDir, file), 'utf8'));

    const scripted = fixture.scriptedOutputs.slice();
    let cursor = 0;
    const calls = [];
    async function dispatch(step) {
      calls.push(step.id);
      const entry = scripted[cursor];
      cursor += 1;
      if (!entry || entry.stepId !== step.id) {
        throw new Error('scriptedOutputs order mismatch in ' + file + ' at step "' + step.id + '"');
      }
      return entry.output;
    }

    const outcome = await specEngineExecute(fixture.spec, dispatch);

    check(file + ': status matches expected', outcome.status === fixture.expected.status);
    check(file + ': dispatchCount matches expected', calls.length === fixture.expected.dispatchCount);

    // Guard the halt dereference: every committed edge fixture today
    // halts (expected.status is "failed" or "uncertain", expected.halt is
    // an object), but this loop discovers files by glob, so a future
    // non-halting fixture must fail a named check here instead of
    // throwing a TypeError on fixture.expected.halt.path/.diagnostic --
    // preserving the auto-pickup promise instead of crashing the suite.
    const expectedHasHaltObject =
      Object.prototype.hasOwnProperty.call(fixture.expected, 'halt') && fixture.expected.halt !== null && typeof fixture.expected.halt === 'object';
    if (!expectedHasHaltObject) {
      check(file + ': expected block has halt object', false);
    } else {
      check(file + ': halt.path matches expected', !!outcome.halt && outcome.halt.path === fixture.expected.halt.path);
      check(file + ': halt.diagnostic matches expected', !!outcome.halt && outcome.halt.diagnostic === fixture.expected.halt.diagnostic);
      if (Object.prototype.hasOwnProperty.call(fixture.expected.halt, 'value')) {
        check(file + ': halt.value matches expected', !!outcome.halt && outcome.halt.value === fixture.expected.halt.value);
      }
    }
  }
}

async function main() {
  await runPartA();
  await runPartB();
  console.log(passCount + ' passed, ' + failCount + ' failed');
  process.exit(failCount === 0 ? 0 : 1);
}

main().catch(function (e) {
  console.error('test-replay.js crashed: ' + (e && e.stack ? e.stack : e));
  process.exit(1);
});
