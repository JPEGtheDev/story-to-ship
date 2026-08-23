// Integrity checker for a captured live-run fixture under
// tools/sprint_engine/tests/fixtures/live/ (see SPEC_SCHEMA.md's
// "Reference-fixture capture schema" section for the per-record shape this
// checks: { stepKey, dispatchIndex, promptSha256, output }).
//
// Runs as:
//   node tools/sprint_engine/tests/verify-live-fixture.js <specPath> <fixturePath> [--journal <journalPath>]
//
// Example (from the repo root):
//   node tools/sprint_engine/tests/verify-live-fixture.js \
//     tools/sprint_engine/examples/build-test-review.json \
//     tools/sprint_engine/tests/fixtures/live/build-test-review.json
//
// This script takes no default journal path and carries no ephemeral
// run-output location of its own -- the journal a fixture was captured
// from is not tracked content, so it is only ever supplied by the caller
// as an explicit --journal argument, and only affects check (1) below.
//
// Three checks, matching the capture ceremony's own integrity contract:
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
const path = require('path');
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
// comment for why these are needed here at all.
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

const REVIEW_MODULE_STEP_ID = 'review_module';
const REVIEW_MODULE_KEY_RE = /^per_module_review\.(\d+)\.code_review_with_retry\.attempts\.(\d+)$/;

function findFixtureRecord(fixture, step, reviewModuleCounterRef) {
  if (step.id === REVIEW_MODULE_STEP_ID) {
    const n = reviewModuleCounterRef.value;
    reviewModuleCounterRef.value += 1;
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

  // Check (1) and (2): journal cross-check, only if --journal was given.
  if (journalPath) {
    const journalOutputs = loadJournalDispatches(journalPath);
    console.log('journal dispatch count: ' + journalOutputs.length);
    if (journalOutputs.length !== fixture.length) {
      fail('fixture record count (' + fixture.length + ') does not equal journal dispatch count (' + journalOutputs.length + ')');
    } else {
      console.log('check (2) PASS: fixture count == journal count == ' + fixture.length);
    }

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
