// Integrity checker for a captured live-run fixture under
// skills/sprint-runner/tools/tests/fixtures/live/ (see SPEC_SCHEMA.md's
// "Reference-fixture capture schema" section for the per-record shape this
// checks: { stepKey, dispatchIndex, promptSha256, output }).
//
// Runs as:
//   node skills/sprint-runner/tools/tests/verify-live-fixture.js <specPath> <fixturePath> [--journal <journalPath>]
//
// Example (from the repo root):
//   node skills/sprint-runner/tools/tests/verify-live-fixture.js \
//     skills/sprint-runner/tools/examples/build-test-review.json \
//     skills/sprint-runner/tools/tests/fixtures/live/build-test-review.json
//
// This script takes no default journal path and carries no ephemeral
// run-output location of its own -- the journal a fixture was captured
// from is not tracked content, so it is only ever supplied by the caller
// as an explicit --journal argument, and only affects check (1) below.
//
// Five checks, matching the capture ceremony's own integrity contract:
//   (1) [only with --journal] every fixture record's "output" matches the
//       corresponding journal-recorded dispatch result, canonical-JSON-equal
//       (compared via JSON.stringify of each side -- the values are JSON
//       data, not raw text, so structural equality is the meaningful
//       comparison, not byte-for-byte text equality). "Corresponding" means
//       positional: dispatchIndex N is defined as "the order in which this
//       step's dispatch was issued" (SPEC_SCHEMA.md), so it is checked
//       against the (N+1)-th "started"/"result" pair in the journal file,
//       0-indexed.
//   (2) fixture record count equals the journal's own dispatch count (only
//       with --journal; without it, only the fixture's own record count is
//       reported).
//   (3) every fixture promptSha256 is reproducible from the committed spec
//       and the fixture alone: this script replays the spec through the
//       real engine (specEngineExecute), using a dispatch mock that returns
//       each fixture record's own "output" value in place of a live agent
//       call, capturing the exact prompt text the engine's own render path
//       (specEngineRenderStepForDispatch, invoked inside specEngineExecute)
//       produces for each dispatch, and for the two engine-synthesized
//       envelope kinds -- digest-verify, spill-writer -- reconstructing the
//       prompt with the exact template strings the runner glue in
//       sprint-runner.js uses to wrap them (copied verbatim below, since
//       those two kinds never carry a "prompt" field of their own). No
//       journal access is needed for this check -- it is the self-contained
//       replay proof required before this fixture can be trusted by a fresh
//       checkout with no /tmp state.
//   (4) the replay's own terminal state matches this reference fixture's
//       captured terminal state exactly: status, halt diagnostic, and halt
//       path. These three expected values are pinned constants below (see
//       EXPECTED_REPLAY_* ) -- properties of THIS specific captured run
//       (live run 3 of build-test-review.json), not a general rule the
//       engine enforces. A spec/fixture pair that still reproduces every
//       promptSha256 (check 3) but replays to a different terminal state
//       (for example, a tampered final-gate output record whose verdict was
//       changed to "pass") is exactly the corruption class this check
//       exists to catch -- checks (1)-(3) alone cannot catch it, since none
//       of them inspect the replay's own outcome, only its per-dispatch
//       inputs and hashes.
//   (5) the fixture's build-record content hash and its spill-writer
//       receipt both match their own pinned values (see the constraint
//       comment above EXPECTED_BUILD_CONTENT_SHA256 below for why these two
//       hashes are pinned to two DIFFERENT values on purpose, not one).
//
// Dispatch identity, for matching a live replay call back to the right
// fixture record: every fixture stepKey is either an exact match for the
// leaf step id the engine's dispatch(step, ...) call carries (the two
// engine-synthesized kinds, whose id already equals their full namespaced
// key, and any bare top-level step), or the stepKey ends with
// "." + step.id (any namespaced leaf, e.g. "unit.run_unit_tests" for
// step.id "run_unit_tests"). The one exception is "review_module", which
// this spec dispatches multiple times with the same step.id (once per
// map iteration x scored-retry attempt) -- map iterations and scored-retry
// attempts run sequentially, never interleaved, so a plain call counter
// derives which (mapIndex, attemptIndex) pair a given dispatch is, matching
// it to the fixture's own "per_module_review.<mapIndex>.code_review_with_retry.attempts.<attemptIndex>"
// stepKey.

const fs = require('fs');
const { specEngineExecute, specEngineSha256 } = require('../engine-core.js');

function fail(message) {
  console.error('FAIL: ' + message);
  process.exitCode = 1;
}

function parseArgs(argv) {
  const positional = [];
  let journalPath = null;
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--journal') {
      journalPath = argv[i + 1];
      i += 1;
    } else {
      positional.push(argv[i]);
    }
  }
  if (positional.length !== 2) {
    console.error('usage: node verify-live-fixture.js <specPath> <fixturePath> [--journal <journalPath>]');
    process.exit(2);
  }
  return { specPath: positional[0], fixturePath: positional[1], journalPath: journalPath };
}

function loadJournalDispatches(journalPath) {
  const lines = fs
    .readFileSync(journalPath, 'utf8')
    .split('\n')
    .filter(function (l) {
      return l.length > 0;
    })
    .map(function (l) {
      return JSON.parse(l);
    });
  const started = lines.filter(function (l) {
    return l.type === 'started';
  });
  const resultByKey = {};
  lines
    .filter(function (l) {
      return l.type === 'result';
    })
    .forEach(function (l) {
      resultByKey[l.key] = l.result;
    });
  return started.map(function (s) {
    return resultByKey[s.key];
  });
}

// Exact glue prompt templates, copied verbatim from the committed
// sprint-runner.js (below ===ENGINE-CORE-END===) -- see this file's header
// comment for why these are needed here at all. This copy can go silently
// stale: if sprint-runner.js's own envelope-wrapper text ever changes,
// these two functions keep matching the OLD fixture's already-recorded
// promptSha256 values, so check (3) keeps passing -- it proves internal
// consistency between this copy and the fixture, not that the copy still
// matches the live glue, and gives no signal that the fixture needs
// re-capture against the new wrapper text.
function spillWriterPrompt(step) {
  return (
    'Write the content below, exactly as given between the two marker lines (no marker lines themselves), to the absolute path "' +
    step.path +
    '" -- create the containing directory first if it does not exist. Then compute the sha256 digest and byte count of the file you just wrote. Return {written: true, path: the absolute path you wrote, sha256: the 64-character lowercase-hex digest, bytes: the byte count}. If the write fails for any reason, return {written: false, path: "", sha256: "", bytes: 0}.\n' +
    '---CONTENT-BEGIN---\n' +
    step.prompt +
    '\n---CONTENT-END---'
  );
}
function digestVerifyPrompt(step) {
  return 'Compute the sha256 digest of the file at the absolute path "' + step.path + '". Return {digest: the 64-character lowercase-hex digest}.';
}

// Pinned expected terminal state for THIS reference fixture (live run 3 of
// build-test-review.json): the final_release_gate step is engineered to
// always fail (see its prompt in the committed spec), so a faithful replay
// of this exact spec+fixture pair halts here, every time. These are not
// general engine invariants -- a different spec or a different captured
// run would pin different values -- so check (4) below is specific to this
// fixture, not a reusable assertion for any future fixture this script
// might also be pointed at.
const EXPECTED_REPLAY_STATUS = 'gated';
const EXPECTED_REPLAY_HALT_DIAGNOSTIC = 'gate-verdict-failed';
const EXPECTED_REPLAY_HALT_PATH = 'steps[5]';

const REVIEW_MODULE_STEP_ID = 'review_module';

function findFixtureRecord(fixture, step, reviewModuleCounterRef) {
  if (step.id === REVIEW_MODULE_STEP_ID) {
    const n = reviewModuleCounterRef.value;
    reviewModuleCounterRef.value += 1;
    // The literal 2 here is the example spec's own
    // per_module_review.code_review_with_retry.maxAttempts: 2 -- every map
    // iteration runs exactly that many scored-retry attempts, so a plain
    // call counter divided by 2 (integer) and modulo 2 recovers
    // (mapIndex, attemptIndex) from the flat dispatch sequence.
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

async function main() {
  const { specPath, fixturePath, journalPath } = parseArgs(process.argv.slice(2));

  const spec = JSON.parse(fs.readFileSync(specPath, 'utf8'));
  const fixture = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));

  if (!Array.isArray(fixture)) {
    fail('fixture file is not a JSON array of capture records: ' + fixturePath);
    return;
  }
  console.log('fixture record count: ' + fixture.length);

  // Every record must carry exactly the four schema fields.
  const requiredFields = ['stepKey', 'dispatchIndex', 'promptSha256', 'output'];
  fixture.forEach(function (record, i) {
    requiredFields.forEach(function (field) {
      if (!Object.prototype.hasOwnProperty.call(record, field)) {
        fail('fixture record ' + i + ' is missing required field "' + field + '"');
      }
    });
  });

  // dispatchIndex must be a contiguous 0..N-1 permutation with no gaps or
  // duplicates -- "the order in which this step's dispatch was issued".
  const sortedByIndex = fixture.slice().sort(function (a, b) {
    return a.dispatchIndex - b.dispatchIndex;
  });
  sortedByIndex.forEach(function (record, i) {
    if (record.dispatchIndex !== i) {
      fail('dispatchIndex is not a contiguous 0-based sequence: expected ' + i + ' at sorted position ' + i + ', found ' + record.dispatchIndex);
    }
  });

  // Checks (1) and (2): journal cross-check, only if --journal was given.
  // Printed in header order: (1) output equality first, then (2) count.
  if (journalPath) {
    const journalOutputs = loadJournalDispatches(journalPath);
    console.log('journal dispatch count: ' + journalOutputs.length);

    let allOutputsMatch = true;
    sortedByIndex.forEach(function (record) {
      const journalOutput = journalOutputs[record.dispatchIndex];
      const a = JSON.stringify(record.output);
      const b = JSON.stringify(journalOutput);
      if (a !== b) {
        allOutputsMatch = false;
        fail('dispatchIndex ' + record.dispatchIndex + ' (' + record.stepKey + '): fixture output does not canonical-JSON-equal the journal result');
      }
    });
    if (allOutputsMatch) {
      console.log('check (1) PASS: every fixture output canonical-JSON-equals its journal result (dispatchIndex ' + (fixture.length - 1) + ' pairs checked)');
    }

    if (journalOutputs.length !== fixture.length) {
      fail('fixture record count (' + fixture.length + ') does not equal journal dispatch count (' + journalOutputs.length + ')');
    } else {
      console.log('check (2) PASS: fixture count == journal count == ' + fixture.length);
    }
  } else {
    console.log('no --journal given: skipping checks (1) and (2) (journal-dependent, not required for a fresh checkout)');
  }

  // Check (3): self-contained promptSha256 reproducibility, using only the
  // committed spec and this fixture -- no journal, no /tmp state.
  const reviewModuleCounterRef = { value: 0 };
  const recomputed = [];
  async function dispatch(step) {
    let record;
    let promptText;
    if (step.type === 'digest-verify') {
      record = findFixtureRecord(fixture, step, reviewModuleCounterRef);
      promptText = digestVerifyPrompt(step);
    } else if (step.type === 'spill-writer') {
      record = findFixtureRecord(fixture, step, reviewModuleCounterRef);
      promptText = spillWriterPrompt(step);
    } else {
      record = findFixtureRecord(fixture, step, reviewModuleCounterRef);
      promptText = step.prompt;
    }
    recomputed.push({ dispatchIndex: record.dispatchIndex, stepKey: record.stepKey, promptSha256: specEngineSha256(promptText) });
    return record.output;
  }

  let replayOutcome;
  try {
    replayOutcome = await specEngineExecute(spec, dispatch);
  } catch (e) {
    fail('replay threw: ' + e.message);
    return;
  }
  console.log('replay status: ' + replayOutcome.status + (replayOutcome.halt ? ' (halt: ' + replayOutcome.halt.diagnostic + ')' : ''));

  // Check (3): recomputed promptSha256 values, one per replay dispatch,
  // must match the fixture's own recorded values. Printed before check (4)
  // to match the header order above.
  if (recomputed.length !== fixture.length) {
    fail('replay issued ' + recomputed.length + ' dispatches, fixture has ' + fixture.length + ' records');
  }

  let allPromptsMatch = true;
  recomputed.forEach(function (r) {
    const record = fixture.filter(function (f) {
      return f.dispatchIndex === r.dispatchIndex;
    })[0];
    if (!record || record.promptSha256 !== r.promptSha256) {
      allPromptsMatch = false;
      fail('dispatchIndex ' + r.dispatchIndex + ' (' + r.stepKey + '): recomputed promptSha256 (' + r.promptSha256 + ') does not match fixture (' + (record ? record.promptSha256 : '(no record)') + ')');
    }
  });
  if (allPromptsMatch && recomputed.length === fixture.length) {
    console.log('check (3) PASS: all ' + recomputed.length + ' promptSha256 values reproduced from the committed spec and fixture alone');
  }

  // Check (4): the replay's terminal state must match this fixture's own
  // pinned expected terminal state -- see EXPECTED_REPLAY_* above. This is
  // what actually proves the replay ended up in the SAME place the
  // reference run did; checks (1)-(3) only prove the per-dispatch inputs
  // and prompt hashes line up, not the run's own outcome.
  const actualHaltDiagnostic = replayOutcome.halt ? replayOutcome.halt.diagnostic : null;
  const actualHaltPath = replayOutcome.halt ? replayOutcome.halt.path : null;
  let terminalStateMatches = true;
  if (replayOutcome.status !== EXPECTED_REPLAY_STATUS) {
    terminalStateMatches = false;
    fail('check (4): replay status "' + replayOutcome.status + '" does not match the expected terminal status "' + EXPECTED_REPLAY_STATUS + '"');
  }
  if (actualHaltDiagnostic !== EXPECTED_REPLAY_HALT_DIAGNOSTIC) {
    terminalStateMatches = false;
    fail('check (4): replay halt diagnostic "' + actualHaltDiagnostic + '" does not match the expected "' + EXPECTED_REPLAY_HALT_DIAGNOSTIC + '"');
  }
  if (actualHaltPath !== EXPECTED_REPLAY_HALT_PATH) {
    terminalStateMatches = false;
    fail('check (4): replay halt path "' + actualHaltPath + '" does not match the expected "' + EXPECTED_REPLAY_HALT_PATH + '"');
  }
  if (terminalStateMatches) {
    console.log('check (4) PASS: replay terminal state matches the fixture (status "' + EXPECTED_REPLAY_STATUS + '", halt "' + EXPECTED_REPLAY_HALT_DIAGNOSTIC + '" at "' + EXPECTED_REPLAY_HALT_PATH + '")');
  }

  // Check (5): the fixture's build-record content hash and its
  // spill-writer receipt both match their own pinned values.
  //
  // These two pinned hashes deliberately DIFFER, and that is correct, not
  // a bug: the run's spill-writer step is a live agent call asked to copy
  // the build agent's raw content to disk verbatim, and in the run this
  // fixture captures it introduced a one-character transcription
  // infidelity (offset 35863 of the 52125-byte content: the producer wrote
  // "8", the writer agent wrote "9"). Both values below were re-verified
  // this session against the run's actual on-disk artifacts: the fixture's
  // own build record content hashes to EXPECTED_BUILD_CONTENT_SHA256 (the
  // producer's true output, byte-for-byte as returned), and the on-disk
  // spilled file the writer agent actually produced independently re-hashes
  // to EXPECTED_SPILL_RECEIPT.sha256 -- i.e. the receipt is faithful to
  // what got written, just not to what the producer originally returned.
  // Both are kept verbatim per the fixture-fidelity ruling: a spill receipt
  // proves what the writer wrote, not that the writer transcribed
  // faithfully, and this script's job is to pin and detect drift in EITHER
  // captured value, not to adjudicate or correct the writer's own
  // transcription fidelity (that implication belongs on the owner log, not
  // in this checker).
  const EXPECTED_BUILD_CONTENT_SHA256 = '5ebece9e148e088d0ea1b971e962f71acd3e5eb45e213796aa7de5f82b6ba2d5';
  // NOTE: this is the spill-writer step's OWN raw dispatch return shape
  // (required: written, path, sha256, bytes -- see spillWriterPrompt's
  // schema comment above, copied from the glue in sprint-runner.js), not
  // the "{spilled: true, ...}" receipt shape the engine later stores under
  // the producing step's own oversized field (that shape lives in the
  // BUILD record's output.content, checked separately above -- a
  // different record, a different field, a different key).
  const EXPECTED_SPILL_RECEIPT = {
    written: true,
    path: '/tmp/sprint-engine-examples/build-test-review-spill/build.content',
    sha256: '5da7c678fbe6dda77d444d4f9567c8fbb3ddab6dacff4aea89030587f5f3317f',
    bytes: 52125,
  };

  const buildRecord = fixture.filter(function (r) {
    return r.stepKey === 'build';
  })[0];
  const spillWriterRecord = fixture.filter(function (r) {
    return r.stepKey.slice(-'.spill-writer'.length) === '.spill-writer';
  })[0];

  let check5Matches = true;
  if (!buildRecord) {
    check5Matches = false;
    fail('check (5): no fixture record with stepKey "build" found to check the producer content hash');
  } else {
    const actualBuildContentSha256 = specEngineSha256(buildRecord.output.content);
    if (actualBuildContentSha256 !== EXPECTED_BUILD_CONTENT_SHA256) {
      check5Matches = false;
      fail('check (5): fixture build record output.content hashes to "' + actualBuildContentSha256 + '", expected the pinned producer hash "' + EXPECTED_BUILD_CONTENT_SHA256 + '"');
    }
  }
  if (!spillWriterRecord) {
    check5Matches = false;
    fail('check (5): no fixture record with a ".spill-writer" stepKey found to check the spill receipt');
  } else {
    const actualReceipt = JSON.stringify(spillWriterRecord.output);
    const expectedReceipt = JSON.stringify(EXPECTED_SPILL_RECEIPT);
    if (actualReceipt !== expectedReceipt) {
      check5Matches = false;
      fail('check (5): fixture spill-writer record output (' + actualReceipt + ') does not equal the pinned receipt (' + expectedReceipt + ')');
    }
  }
  if (check5Matches) {
    console.log('check (5) PASS: producer content hash and spill-writer receipt both match their pinned values (see the constraint comment above -- these two hashes deliberately differ)');
  }

  if (process.exitCode) {
    console.log('RESULT: FAIL');
  } else {
    console.log('RESULT: PASS');
  }
}

main().catch(function (e) {
  console.error('verify-live-fixture.js crashed: ' + (e && e.stack ? e.stack : e));
  process.exit(1);
});
