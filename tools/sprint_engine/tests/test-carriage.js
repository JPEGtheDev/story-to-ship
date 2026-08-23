// Oversized-output carriage and spill-mechanics suite for the sprint
// engine: B1 (spec input forms), B2 (inline-spec integrity), B3
// (producer-pointer recording), B4 (engine-side oversized-output guard +
// writer backstop), B5 (status/trace/receipt-sub-field exclusion), B6
// (by-path digest-verify flow).
//
// Runs as: node tools/sprint_engine/tests/test-carriage.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test, mirroring test-execute.js's own style: each case calls
// specEngineExecute(spec, dispatch) directly against a hand-built spec and
// a hand-built dispatch stub, and asserts on the returned outcome with a
// single async main().
//
// Locked design principle this whole suite exists to prove: payload bytes
// must NEVER transit any agent's OUTPUT tokens, and the engine itself NEVER
// writes files -- every file write below is either producer-side (an
// 'agent' step's own dispatch stub, standing in for a real producer agent
// that would actually write the file) or writer-agent-side (a 'spill-writer'
// step's own dispatch stub, standing in for the dedicated backstop agent
// the engine dispatches). No assertion in this file ever calls fs.writeFile
// or any filesystem API from the engine's own code path -- the dispatch
// stubs below only ever RETURN receipt-shaped objects, exactly as a real
// producer/writer agent's own tool use would report back over its own
// structured output (never the raw content itself, over the SAME channel
// this suite proves the engine never reads oversized content from).

'use strict';

const {
  specEngineExecute,
  specEngineSha256,
  specEngineCanonicalizeSpecForIntegrity,
  SPEC_ENGINE_SPILL_THRESHOLD_BYTES,
} = require('../engine-core.js');

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

// A 64-char lowercase-hex placeholder digest, used everywhere a well-formed
// receipt/digest-verify return needs SOME valid-shaped sha256 but the exact
// value is not itself under test.
const HEX64_A = 'a'.repeat(64);
const HEX64_B = 'b'.repeat(64);

// makeDispatch(handlers) returns a dispatch stub that records every call
// (in order) into `calls` ({ id, type, step, context }) and resolves each
// call by looking up handlers[step.type] (falling back to handlers.default)
// and invoking it with (step, context) -- so one stub can serve an
// 'agent'/'gate' step, a 'spill-writer' backstop dispatch, and a
// 'digest-verify' dispatch all through the SAME injected dispatcher, the
// way specEngineApplySpillGuard's own contract requires.
function makeDispatch(handlers) {
  const calls = [];
  const dispatch = async function (step, context) {
    calls.push({ id: step.id, type: step.type, step: step, context: context });
    const handler = Object.prototype.hasOwnProperty.call(handlers, step.type) ? handlers[step.type] : handlers.default;
    if (typeof handler !== 'function') {
      return undefined;
    }
    return handler(step, context);
  };
  dispatch.calls = calls;
  return dispatch;
}

async function main() {
  // ======================================================================
  // B1: spec input forms -- object, raw JSON string, unparseable string.
  // ======================================================================

  // -- an object-form spec runs normally ----------------------------------
  {
    const spec = { steps: [{ id: 'a', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ ok: true, via: 'object' }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B1: an object-form spec completes', outcome.status === 'completed');
    check('B1: an object-form spec dispatches exactly once', dispatch.calls.length === 1);
    check("B1: an object-form spec's result lands under its step id", outcome.results.a.via === 'object');
  }

  // -- a raw JSON string of the SAME content runs identically -------------
  {
    const specObj = { steps: [{ id: 'a', type: 'agent' }], config: {} };
    const specString = JSON.stringify(specObj);
    const dispatch = makeDispatch({ agent: async () => ({ ok: true, via: 'string' }) });
    const outcome = await specEngineExecute(specString, dispatch);
    check('B1: a string-form spec of the same content completes', outcome.status === 'completed');
    check('B1: a string-form spec dispatches exactly once, same as object form', dispatch.calls.length === 1);
    check("B1: a string-form spec's result lands under its step id, identically to object form", outcome.results.a.via === 'string');
  }

  // -- a garbage (unparseable-JSON) string halts loudly, zero dispatch ----
  {
    const dispatch = makeDispatch({});
    const outcome = await specEngineExecute('{this is not valid json', dispatch);
    check('B1: an unparseable spec string halts with status "failed"', outcome.status === 'failed');
    check('B1: an unparseable spec string halts under the spec-json-unparseable diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spec-json-unparseable');
    check('B1: an unparseable spec string never reaches dispatch', dispatch.calls.length === 0);
  }

  // ======================================================================
  // B2: inline-spec integrity (config.expectedSha256, optional).
  // ======================================================================

  // -- a matching digest (object-form spec) lets the run proceed ----------
  {
    const spec = { steps: [{ id: 'a', type: 'agent' }], config: { expectedSha256: HEX64_A } };
    spec.config.expectedSha256 = specEngineSha256(specEngineCanonicalizeSpecForIntegrity(spec));
    const dispatch = makeDispatch({ agent: async () => ({ ok: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B2: a matching expectedSha256 (object-form spec) lets the run complete', outcome.status === 'completed');
    check('B2: a matching expectedSha256 dispatches the run normally', dispatch.calls.length === 1);
  }

  // -- a matching digest (STRING-form spec) lets the run proceed too, via -
  // -- the identical canonicalization (parse-then-canonicalize, per the ---
  // -- decision pinned in specEngineCheckSpecIntegrity's own header comment)
  {
    const draft = { steps: [{ id: 'a', type: 'agent' }], config: { expectedSha256: HEX64_A } };
    draft.config.expectedSha256 = specEngineSha256(specEngineCanonicalizeSpecForIntegrity(draft));
    const specString = JSON.stringify(draft);
    const dispatch = makeDispatch({ agent: async () => ({ ok: true }) });
    const outcome = await specEngineExecute(specString, dispatch);
    check('B2: a matching expectedSha256 (string-form spec) lets the run complete', outcome.status === 'completed');
  }

  // -- a mismatched digest halts spend-free, naming both digests ----------
  {
    const spec = { steps: [{ id: 'a', type: 'agent' }], config: { expectedSha256: '0'.repeat(64) } };
    const dispatch = makeDispatch({ agent: async () => ({ ok: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B2: a mismatched expectedSha256 halts with status "failed"', outcome.status === 'failed');
    check('B2: a mismatched expectedSha256 halts under the spec-integrity-mismatch diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spec-integrity-mismatch');
    check('B2: a mismatched expectedSha256 halt message names the declared digest', outcome.halt.message.indexOf('0'.repeat(64)) !== -1);
    check('B2: a mismatched expectedSha256 never dispatches (spend-free)', dispatch.calls.length === 0);
  }

  // -- the OBJECT-FORM decision is pinned: object-form specs are checked --
  // -- via the same canonical-form comparison as string-form specs (the --
  // -- chosen alternative to a named object-form-unsupported halt) --------
  {
    const spec = { steps: [{ id: 'a', type: 'agent' }], config: { expectedSha256: '0'.repeat(64) } };
    const dispatch = makeDispatch({ agent: async () => ({ ok: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check(
      'B2: an object-form spec with a WRONG expectedSha256 is still evaluated (not rejected as unsupported) -- it mismatches on its own merits',
      outcome.status === 'failed' && outcome.halt.diagnostic === 'spec-integrity-mismatch'
    );
  }

  // ======================================================================
  // B3: producer-pointer recording (well-formed vs malformed receipts).
  // ======================================================================

  // -- a well-formed receipt is recorded as the field value as-is, and its
  // -- pointer sub-fields are consumable by a later predicate/template ----
  {
    const spec = {
      steps: [
        { id: 'report', type: 'agent' },
        { id: 'check', type: 'gate', predicate: undefined, prompt: 'path is {{report.content.path}}, bytes is {{report.content.bytes}}' },
      ],
      config: {},
    };
    const dispatch = makeDispatch({
      agent: async () => ({ content: { spilled: true, path: '/spill/report.content', sha256: HEX64_A, bytes: 45000 } }),
      gate: async (step) => ({ verdict: 'pass', reason: step.prompt }),
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B3: a well-formed receipt run completes', outcome.status === 'completed');
    check(
      "B3: the well-formed receipt is recorded as the field value as-is",
      outcome.results.report.content.spilled === true &&
        outcome.results.report.content.path === '/spill/report.content' &&
        outcome.results.report.content.sha256 === HEX64_A &&
        outcome.results.report.content.bytes === 45000
    );
    check(
      "B3: the receipt's pointer sub-fields (.path, .bytes) are consumable in a later template",
      outcome.results.check.reason === 'path is /spill/report.content, bytes is 45000'
    );
  }

  // -- malformed receipt variants each halt, naming the missing piece -----
  {
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: { spilled: true, sha256: HEX64_A, bytes: 5 } }) }); // missing path
    const outcome = await specEngineExecute(spec, dispatch);
    check('B3: a receipt missing "path" halts with status "failed"', outcome.status === 'failed');
    check('B3: a receipt missing "path" uses the spill-receipt-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-receipt-malformed');
    check('B3: a receipt missing "path" names "path" in the halt message', outcome.halt.message.indexOf('path') !== -1);
  }
  {
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: { spilled: true, path: '/x', sha256: 'not-64-hex', bytes: 5 } }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B3: a receipt with a malformed "sha256" halts with status "failed"', outcome.status === 'failed');
    check('B3: a receipt with a malformed "sha256" uses the spill-receipt-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-receipt-malformed');
    check('B3: a receipt with a malformed "sha256" names "sha256" in the halt message', outcome.halt.message.indexOf('sha256') !== -1);
  }
  {
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: { spilled: true, path: '/x', sha256: HEX64_A, bytes: 'not-a-number' } }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B3: a receipt with a non-numeric "bytes" halts with status "failed"', outcome.status === 'failed');
    check('B3: a receipt with a non-numeric "bytes" uses the spill-receipt-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-receipt-malformed');
    check('B3: a receipt with a non-numeric "bytes" names "bytes" in the halt message', outcome.halt.message.indexOf('bytes') !== -1);
  }

  // ======================================================================
  // B4: engine-side oversized-output guard + writer backstop.
  // ======================================================================

  // -- an oversized field (41,628 chars, the measured inline-carriage -----
  // -- floor from SPEC_SCHEMA.md's own spill-contract section) triggers ---
  // -- EXACTLY ONE writer dispatch; the field is swapped for a receipt; ---
  // -- a trace entry names the violation; the raw payload is ABSENT from --
  // -- the results object (sentinel scan) ----------------------------------
  {
    const sentinel = 'PAYLOAD-SENTINEL-B4-';
    const oversized = sentinel + 'x'.repeat(41628 - sentinel.length);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({
      agent: async () => ({ content: oversized, other: 'kept-inline' }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: oversized.length }),
    });
    const outcome = await specEngineExecute(spec, dispatch);

    check('B4: an oversized-field run still completes', outcome.status === 'completed');
    check('B4: exactly one writer dispatch is issued (dispatch.calls.length === 2: agent + spill-writer)', dispatch.calls.length === 2);
    check('B4: the second dispatch call is the spill-writer envelope', dispatch.calls[1].type === 'spill-writer');
    check("B4: the spill-writer envelope's own id is derived from the step and field", dispatch.calls[1].id === 'report.content.spill-writer');
    check("B4: the spill-writer envelope's target path is <spillDir>/<stepId>.<field>", dispatch.calls[1].step.path === '/spill/report.content');
    check('B4: the spill-writer envelope carries the content on its own prompt field (never the return value)', dispatch.calls[1].step.prompt === oversized);
    check(
      'B4: the oversized field is swapped for a normal spill receipt',
      outcome.results.report.content.spilled === true &&
        outcome.results.report.content.path === '/spill/report.content' &&
        outcome.results.report.content.sha256 === HEX64_A &&
        outcome.results.report.content.bytes === oversized.length
    );
    check('B4: a sibling field that was never oversized is left untouched', outcome.results.report.other === 'kept-inline');
    check(
      'B4: a trace entry naming the violation (step, field, byte count, writer outcome) is present',
      outcome.trace.some(function (entry) {
        return entry.kind === 'spill-guard' && entry.step === 'report' && entry.field === 'content' && entry.bytes === oversized.length && entry.writerOutcome && entry.writerOutcome.written === true;
      })
    );
    check(
      'B4: the raw oversized payload never appears anywhere in the results object (sentinel scan)',
      JSON.stringify(outcome.results).indexOf(sentinel) === -1
    );
  }

  // -- boundary: a field at EXACTLY 40,000 bytes does NOT trigger ---------
  {
    const exactlyAtThreshold = 'y'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES);
    check('B4 boundary fixture: the fixture is exactly the threshold length', exactlyAtThreshold.length === SPEC_ENGINE_SPILL_THRESHOLD_BYTES);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: exactlyAtThreshold }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B4 boundary: a field at exactly the threshold completes with no writer dispatch', outcome.status === 'completed');
    check('B4 boundary: dispatch is called exactly once (agent only, no spill-writer)', dispatch.calls.length === 1);
    check('B4 boundary: the field is returned inline, never swapped for a receipt', outcome.results.report.content === exactlyAtThreshold);
  }

  // -- boundary, direction-sensitive: one byte OVER the threshold DOES ----
  // -- trigger (proves the boundary is ">", not ">=" and not "off by a ----
  // -- large margin") -------------------------------------------------------
  {
    const oneOver = 'y'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({
      agent: async () => ({ content: oneOver }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: oneOver.length }),
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B4 boundary: a field one byte OVER the threshold DOES trigger the writer dispatch', dispatch.calls.length === 2 && dispatch.calls[1].type === 'spill-writer');
  }

  // -- byte-length, not code-unit-length: a multi-byte-character field ----
  // -- whose UTF-16 .length (20,000) sits under the threshold but whose ---
  // -- UTF-8 BYTE length (60,000, 3 bytes per euro-sign char) sits well ----
  // -- over it still triggers -- proving the guard measures UTF-8 bytes ---
  // -- (via the existing specEngineUtf8Encode primitive), never str.length
  {
    const multiByte = '\u20AC'.repeat(20000); // euro sign, via an ASCII escape (keeps this source file ASCII-only), 3 UTF-8 bytes each
    check('B4 UTF-8 fixture: str.length sits under the threshold', multiByte.length < SPEC_ENGINE_SPILL_THRESHOLD_BYTES);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({
      agent: async () => ({ content: multiByte }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: 60000 }),
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check(
      'B4 UTF-8: a field whose UTF-8 byte length exceeds the threshold triggers the writer even though .length does not',
      dispatch.calls.length === 2 && dispatch.calls[1].type === 'spill-writer'
    );
  }

  // -- multiple oversized fields in one outcome: one writer per field, ----
  // -- in field-declaration order -------------------------------------------
  {
    const fieldA = 'a'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 500);
    const fieldB = 'b'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 900);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({
      agent: async () => ({ first: fieldA, second: fieldB }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: step.prompt.length }),
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B4 multi-field: dispatch is called three times (agent + 2 writers)', dispatch.calls.length === 3);
    check('B4 multi-field: the writer calls run in field-declaration order (first, then second)', dispatch.calls[1].step.path.indexOf('.first') !== -1 && dispatch.calls[2].step.path.indexOf('.second') !== -1);
    check(
      'B4 multi-field: both fields are swapped for their own receipts',
      outcome.results.report.first.spilled === true && outcome.results.report.second.spilled === true
    );
  }

  // -- writer returning null resolves to a named failure, never a hang ----
  {
    const oversized = 'z'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }), 'spill-writer': async () => null });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B4: a null writer return halts with status "failed"', outcome.status === 'failed');
    check('B4: a null writer return uses the spill-writer-outcome-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-writer-outcome-malformed');
    check('B4: a null writer return never leaks the payload into results (results stays empty on this halt path)', JSON.stringify(outcome.results).indexOf(oversized) === -1);
  }

  // -- writer returning garbage (missing required fields) is the same -----
  // -- named-failure class -------------------------------------------------
  {
    const oversized = 'z'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }), 'spill-writer': async () => ({ written: true }) }); // missing path/sha256/bytes
    const outcome = await specEngineExecute(spec, dispatch);
    check('B4: a garbage writer return halts with status "failed"', outcome.status === 'failed');
    check('B4: a garbage writer return uses the spill-writer-outcome-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-writer-outcome-malformed');
  }

  // -- a missing/empty config.spillDir, with an oversized field actually --
  // -- present, halts loudly instead of building a bogus target path ------
  {
    const oversized = 'z'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B4: an oversized field with no spillDir halts with status "failed"', outcome.status === 'failed');
    check('B4: an oversized field with no spillDir uses the spill-guard-spilldir-unavailable diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-guard-spilldir-unavailable');
    check('B4: an oversized field with no spillDir never dispatches a writer', dispatch.calls.length === 1);
  }

  // ======================================================================
  // B5: the guard scans only outcome DATA fields -- never the engine's own
  // status/halt/trace bookkeeping, and never a receipt's own sub-fields.
  // ======================================================================

  // -- a trace-heavy run (many small steps) stays unspilled: the guard ----
  // -- is applied PER AGENT STEP's own outcome, never to the engine's own -
  // -- accumulated trace array -----------------------------------------------
  {
    const stepCount = 40;
    const steps = [];
    for (let i = 0; i < stepCount; i += 1) {
      steps.push({ id: 's' + i, type: 'agent' });
    }
    const spec = { steps: steps, config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async (step) => ({ note: 'small result for ' + step.id }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B5: a trace-heavy run (40 small steps) completes', outcome.status === 'completed');
    check('B5: a trace-heavy run never dispatches a spill-writer', dispatch.calls.every(function (c) { return c.type === 'agent'; }));
    check('B5: a trace-heavy run never produces a spilled receipt anywhere in results', JSON.stringify(outcome.results).indexOf('"spilled":true') === -1);
  }

  // -- a receipt's own path string is never re-guarded, even when that ----
  // -- path string is itself longer than the spill threshold ---------------
  {
    const longPath = '/spill/' + 'p'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1000);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: { spilled: true, path: longPath, sha256: HEX64_A, bytes: 99 } }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check("B5: an already-spilled receipt whose own .path is longer than the threshold still completes", outcome.status === 'completed');
    check('B5: that long .path never triggers a second writer dispatch (dispatch called once, agent only)', dispatch.calls.length === 1);
    check("B5: the receipt's own .path is preserved unchanged, not re-spilled into a nested receipt", outcome.results.report.content.path === longPath);
  }

  // ======================================================================
  // B6: by-path digest-verify flow (config-silent field: step.verifyDigest).
  // ======================================================================

  // -- a matching stub digest lets the consuming agent step proceed -------
  {
    const spec = {
      steps: [{ id: 'consume', type: 'agent', verifyDigest: { path: '/data/input.bin', sha256: HEX64_A }, prompt: 'use {{values.x}}' }],
      config: { values: { x: 1 } },
    };
    const dispatch = makeDispatch({
      'digest-verify': async (step) => ({ digest: HEX64_A }),
      agent: async () => ({ consumed: true }),
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B6: a matching digest-verify lets the run complete', outcome.status === 'completed');
    check('B6: a matching digest-verify dispatches the digest-verify step then the consuming agent step, in order', dispatch.calls.length === 2 && dispatch.calls[0].type === 'digest-verify' && dispatch.calls[1].type === 'agent');
    check("B6: the digest-verify envelope names the declared path", dispatch.calls[0].step.path === '/data/input.bin');
    check('B6: the consuming agent step\'s own result lands normally', outcome.results.consume.consumed === true);
  }

  // -- a mismatched digest halts named, SAFE (fail closed): zero further --
  // -- dispatch of the consuming step ---------------------------------------
  {
    const spec = { steps: [{ id: 'consume', type: 'agent', verifyDigest: { path: '/data/input.bin', sha256: HEX64_A } }], config: {} };
    const dispatch = makeDispatch({ 'digest-verify': async () => ({ digest: HEX64_B }), agent: async () => ({ consumed: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B6: a mismatched digest halts with status "failed"', outcome.status === 'failed');
    check('B6: a mismatched digest uses the digest-verify-mismatch diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'digest-verify-mismatch');
    check('B6: a mismatched digest never dispatches the consuming agent step', dispatch.calls.length === 1 && dispatch.calls[0].type === 'digest-verify');
  }

  // -- a garbage/unparseable digest return halts named, "uncertain"-class -
  {
    const spec = { steps: [{ id: 'consume', type: 'agent', verifyDigest: { path: '/data/input.bin', sha256: HEX64_A } }], config: {} };
    const dispatch = makeDispatch({ 'digest-verify': async () => ({ oops: 'not a digest' }), agent: async () => ({ consumed: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B6: a garbage digest-verify return halts with status "uncertain" (the uncertain-class)', outcome.status === 'uncertain');
    check('B6: a garbage digest-verify return uses the digest-verify-outcome-unparseable diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'digest-verify-outcome-unparseable');
    check('B6: a garbage digest-verify return never dispatches the consuming agent step', dispatch.calls.length === 1 && dispatch.calls[0].type === 'digest-verify');
  }

  // -- a null digest-verify return is the same "uncertain"-class outcome, -
  // -- resolving instead of hanging ------------------------------------------
  {
    const spec = { steps: [{ id: 'consume', type: 'agent', verifyDigest: { path: '/data/input.bin', sha256: HEX64_A } }], config: {} };
    const dispatch = makeDispatch({ 'digest-verify': async () => null, agent: async () => ({ consumed: true }) });
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
    check('B6: a null digest-verify return resolves instead of hanging', raced.timedOut === false);
    if (!raced.timedOut) {
      check('B6: a null digest-verify return halts with status "uncertain"', raced.outcome.status === 'uncertain');
      check('B6: a null digest-verify return uses the digest-verify-outcome-unparseable diagnostic', raced.outcome.halt.diagnostic === 'digest-verify-outcome-unparseable');
    }
  }

  // -- a malformed verifyDigest DECLARATION itself (not the agent's own ---
  // -- return) halts spend-free, before any dispatch at all -----------------
  {
    const spec = { steps: [{ id: 'consume', type: 'agent', verifyDigest: { path: '', sha256: HEX64_A } }], config: {} };
    const dispatch = makeDispatch({ 'digest-verify': async () => ({ digest: HEX64_A }), agent: async () => ({ consumed: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('B6: a malformed verifyDigest declaration (empty path) halts with status "failed"', outcome.status === 'failed');
    check('B6: a malformed verifyDigest declaration uses the digest-verify-declaration-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'digest-verify-declaration-malformed');
    check('B6: a malformed verifyDigest declaration never dispatches anything (spend-free)', dispatch.calls.length === 0);
  }

  console.log(passCount + ' passed, ' + failCount + ' failed');
  process.exit(failCount === 0 ? 0 : 1);
}

main().catch(function (err) {
  console.error('test-carriage.js crashed: ' + (err && err.stack ? err.stack : err));
  process.exit(1);
});
