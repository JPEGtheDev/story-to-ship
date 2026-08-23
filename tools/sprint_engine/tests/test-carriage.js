// Oversized-output carriage and spill-mechanics suite for the sprint
// engine: spec input forms (object vs. raw JSON string), inline-spec
// integrity (an optional whole-spec digest check), producer-pointer
// recording (a well-formed spill receipt is trusted as-is; a malformed one
// halts), the engine-side oversized-output guard and its writer-agent
// backstop, the guard's own scan-scope exclusions (it never re-scans the
// engine's own bookkeeping or a receipt's own sub-fields), spill-path
// namespacing (two same-named steps in different containers must never
// collide on the same target file), spill-guard halt trace safety (a
// halted guard must never leak the oversized payload into the run's own
// trace), and by-path digest verification (an agent step can gate its own
// dispatch on an in-engine digest check against a declared file).
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
  // Spec input forms: object, raw JSON string, unparseable string.
  // ======================================================================

  // -- an object-form spec runs normally ----------------------------------
  {
    const spec = { steps: [{ id: 'a', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ ok: true, via: 'object' }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an object-form spec completes', outcome.status === 'completed');
    check('an object-form spec dispatches exactly once', dispatch.calls.length === 1);
    check("an object-form spec's result lands under its step id", outcome.results.a.via === 'object');
  }

  // -- a raw JSON string of the SAME content runs identically -------------
  {
    const specObj = { steps: [{ id: 'a', type: 'agent' }], config: {} };
    const specString = JSON.stringify(specObj);
    const dispatch = makeDispatch({ agent: async () => ({ ok: true, via: 'string' }) });
    const outcome = await specEngineExecute(specString, dispatch);
    check('a string-form spec of the same content completes', outcome.status === 'completed');
    check('a string-form spec dispatches exactly once, same as object form', dispatch.calls.length === 1);
    check("a string-form spec's result lands under its step id, identically to object form", outcome.results.a.via === 'string');
  }

  // -- a garbage (unparseable-JSON) string halts loudly, zero dispatch ----
  {
    const dispatch = makeDispatch({});
    const outcome = await specEngineExecute('{this is not valid json', dispatch);
    check('an unparseable spec string halts with status "failed"', outcome.status === 'failed');
    check('an unparseable spec string halts under the spec-json-unparseable diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spec-json-unparseable');
    check('an unparseable spec string never reaches dispatch', dispatch.calls.length === 0);
  }

  // ======================================================================
  // Inline-spec integrity (config.expectedSha256, optional).
  // ======================================================================

  // -- a matching digest (object-form spec) lets the run proceed ----------
  {
    const spec = { steps: [{ id: 'a', type: 'agent' }], config: { expectedSha256: HEX64_A } };
    spec.config.expectedSha256 = specEngineSha256(specEngineCanonicalizeSpecForIntegrity(spec));
    const dispatch = makeDispatch({ agent: async () => ({ ok: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a matching expectedSha256 (object-form spec) lets the run complete', outcome.status === 'completed');
    check('a matching expectedSha256 dispatches the run normally', dispatch.calls.length === 1);
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
    check('a matching expectedSha256 (string-form spec) lets the run complete', outcome.status === 'completed');
  }

  // -- a mismatched digest halts spend-free, naming both digests ----------
  {
    const spec = { steps: [{ id: 'a', type: 'agent' }], config: { expectedSha256: '0'.repeat(64) } };
    const dispatch = makeDispatch({ agent: async () => ({ ok: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a mismatched expectedSha256 halts with status "failed"', outcome.status === 'failed');
    check('a mismatched expectedSha256 halts under the spec-integrity-mismatch diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spec-integrity-mismatch');
    check('a mismatched expectedSha256 halt message names the declared digest', outcome.halt.message.indexOf('0'.repeat(64)) !== -1);
    check('a mismatched expectedSha256 never dispatches (spend-free)', dispatch.calls.length === 0);
  }

  // -- the OBJECT-FORM decision is pinned: object-form specs are checked --
  // -- via the same canonical-form comparison as string-form specs (the --
  // -- chosen alternative to a named object-form-unsupported halt) --------
  {
    const spec = { steps: [{ id: 'a', type: 'agent' }], config: { expectedSha256: '0'.repeat(64) } };
    const dispatch = makeDispatch({ agent: async () => ({ ok: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check(
      'an object-form spec with a WRONG expectedSha256 is still evaluated (not rejected as unsupported) -- it mismatches on its own merits',
      outcome.status === 'failed' && outcome.halt.diagnostic === 'spec-integrity-mismatch'
    );
  }

  // ======================================================================
  // Producer-pointer recording: well-formed vs malformed spill receipts.
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
    check('a well-formed receipt run completes', outcome.status === 'completed');
    check(
      'a well-formed receipt is recorded as the field value as-is',
      outcome.results.report.content.spilled === true &&
        outcome.results.report.content.path === '/spill/report.content' &&
        outcome.results.report.content.sha256 === HEX64_A &&
        outcome.results.report.content.bytes === 45000
    );
    check(
      "a receipt's pointer sub-fields (.path, .bytes) are consumable in a later template",
      outcome.results.check.reason === 'path is /spill/report.content, bytes is 45000'
    );
  }

  // -- malformed receipt variants each halt, naming the missing piece -----
  {
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: { spilled: true, sha256: HEX64_A, bytes: 5 } }) }); // missing path
    const outcome = await specEngineExecute(spec, dispatch);
    check('a receipt missing "path" halts with status "failed"', outcome.status === 'failed');
    check('a receipt missing "path" uses the spill-receipt-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-receipt-malformed');
    check('a receipt missing "path" names "path" in the halt message', outcome.halt.message.indexOf('path') !== -1);
  }
  {
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: { spilled: true, path: '/x', sha256: 'not-64-hex', bytes: 5 } }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a receipt with a malformed "sha256" halts with status "failed"', outcome.status === 'failed');
    check('a receipt with a malformed "sha256" uses the spill-receipt-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-receipt-malformed');
    check('a receipt with a malformed "sha256" names "sha256" in the halt message', outcome.halt.message.indexOf('sha256') !== -1);
  }
  {
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: { spilled: true, path: '/x', sha256: HEX64_A, bytes: 'not-a-number' } }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a receipt with a non-numeric "bytes" halts with status "failed"', outcome.status === 'failed');
    check('a receipt with a non-numeric "bytes" uses the spill-receipt-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-receipt-malformed');
    check('a receipt with a non-numeric "bytes" names "bytes" in the halt message', outcome.halt.message.indexOf('bytes') !== -1);
  }
  // -- non-blocking coverage note from review: a non-string "path" is a ---
  // -- distinct malformed shape from a MISSING "path" -- both must halt ---
  {
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: { spilled: true, path: 42, sha256: HEX64_A, bytes: 5 } }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a receipt with a non-string "path" halts with status "failed"', outcome.status === 'failed');
    check('a receipt with a non-string "path" uses the spill-receipt-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-receipt-malformed');
    check('a receipt with a non-string "path" names "path" in the halt message', outcome.halt.message.indexOf('path') !== -1);
  }
  // -- non-blocking coverage note from review: uppercase-hex "sha256" must
  // -- halt too -- the receipt shape requires LOWERCASE hex, matching the -
  // -- lowercase digest specEngineSha256 itself always produces -----------
  {
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: { spilled: true, path: '/x', sha256: HEX64_A.toUpperCase(), bytes: 5 } }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a receipt with an uppercase-hex "sha256" halts with status "failed"', outcome.status === 'failed');
    check('a receipt with an uppercase-hex "sha256" uses the spill-receipt-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-receipt-malformed');
    check('a receipt with an uppercase-hex "sha256" names "sha256" in the halt message', outcome.halt.message.indexOf('sha256') !== -1);
  }

  // ======================================================================
  // Engine-side oversized-output guard + writer backstop.
  // ======================================================================

  // -- an oversized field (41,628 chars, the measured inline-carriage -----
  // -- floor from SPEC_SCHEMA.md's own spill-contract section) triggers ---
  // -- EXACTLY ONE writer dispatch; the field is swapped for a receipt; ---
  // -- a trace entry names the violation; the raw payload is ABSENT from --
  // -- the FULL return value (results + trace + halt; sentinel scan) ------
  {
    const sentinel = 'PAYLOAD-SENTINEL-OVERSIZED-';
    const oversized = sentinel + 'x'.repeat(41628 - sentinel.length);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({
      agent: async () => ({ content: oversized, other: 'kept-inline' }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: oversized.length }),
    });
    const outcome = await specEngineExecute(spec, dispatch);

    check('an oversized-field run still completes', outcome.status === 'completed');
    check('exactly one writer dispatch is issued (dispatch.calls.length === 2: agent + spill-writer)', dispatch.calls.length === 2);
    check('the second dispatch call is the spill-writer envelope', dispatch.calls[1].type === 'spill-writer');
    check("the spill-writer envelope's own id is derived from the step's namespaced key and field", dispatch.calls[1].id === 'report.content.spill-writer');
    check("the spill-writer envelope's target path is <spillDir>/<namespacedKey>.<field> (top-level: namespacedKey === stepId)", dispatch.calls[1].step.path === '/spill/report.content');
    check('the spill-writer envelope carries the content on its own prompt field (never the return value)', dispatch.calls[1].step.prompt === oversized);
    check(
      'the oversized field is swapped for a normal spill receipt',
      outcome.results.report.content.spilled === true &&
        outcome.results.report.content.path === '/spill/report.content' &&
        outcome.results.report.content.sha256 === HEX64_A &&
        outcome.results.report.content.bytes === oversized.length
    );
    check('a sibling field that was never oversized is left untouched', outcome.results.report.other === 'kept-inline');
    check(
      'a trace entry naming the violation (step, field, byte count, writer outcome) is present',
      outcome.trace.some(function (entry) {
        return entry.kind === 'spill-guard' && entry.step === 'report' && entry.field === 'content' && entry.bytes === oversized.length && entry.writerOutcome && entry.writerOutcome.written === true;
      })
    );
    check(
      'the raw oversized payload never appears anywhere in the FULL returned outcome (status + results + trace + halt; sentinel scan)',
      JSON.stringify(outcome).indexOf(sentinel) === -1
    );
  }

  // -- boundary: a field at EXACTLY 40,000 bytes does NOT trigger ---------
  {
    const exactlyAtThreshold = 'y'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES);
    check('the boundary fixture is exactly the threshold length', exactlyAtThreshold.length === SPEC_ENGINE_SPILL_THRESHOLD_BYTES);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: exactlyAtThreshold }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a field at exactly the threshold completes with no writer dispatch', outcome.status === 'completed');
    check('dispatch is called exactly once at the boundary (agent only, no spill-writer)', dispatch.calls.length === 1);
    check('the field at the boundary is returned inline, never swapped for a receipt', outcome.results.report.content === exactlyAtThreshold);
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
    check('a field one byte OVER the threshold DOES trigger the writer dispatch', dispatch.calls.length === 2 && dispatch.calls[1].type === 'spill-writer');
  }

  // -- byte-length, not code-unit-length: a multi-byte-character field ----
  // -- whose UTF-16 .length (20,000) sits under the threshold but whose ---
  // -- UTF-8 BYTE length (60,000, 3 bytes per euro-sign char) sits well ----
  // -- over it still triggers -- proving the guard measures UTF-8 bytes ---
  // -- (via the existing specEngineUtf8Encode primitive), never str.length
  {
    const multiByte = '\u20AC'.repeat(20000); // euro sign, via an ASCII escape (keeps this source file ASCII-only), 3 UTF-8 bytes each
    check('the UTF-8 fixture\'s str.length sits under the threshold', multiByte.length < SPEC_ENGINE_SPILL_THRESHOLD_BYTES);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({
      agent: async () => ({ content: multiByte }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: 60000 }),
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check(
      'a field whose UTF-8 byte length exceeds the threshold triggers the writer even though .length does not',
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
    check('dispatch is called three times for two oversized fields (agent + 2 writers)', dispatch.calls.length === 3);
    check('the writer calls run in field-declaration order (first, then second)', dispatch.calls[1].step.path.indexOf('.first') !== -1 && dispatch.calls[2].step.path.indexOf('.second') !== -1);
    check(
      'both oversized fields are swapped for their own receipts',
      outcome.results.report.first.spilled === true && outcome.results.report.second.spilled === true
    );
  }

  // -- writer returning null resolves to a named failure, never a hang; ---
  // -- the sentinel never appears anywhere in the FULL return value -------
  {
    const sentinel = 'PAYLOAD-SENTINEL-NULL-WRITER-';
    const oversized = sentinel + 'z'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }), 'spill-writer': async () => null });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a null writer return halts with status "failed"', outcome.status === 'failed');
    check('a null writer return uses the spill-writer-outcome-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-writer-outcome-malformed');
    check(
      'a null writer return never leaks the payload into the FULL returned outcome (status + results + trace + halt; sentinel scan)',
      JSON.stringify(outcome).indexOf(sentinel) === -1
    );
  }

  // -- writer returning garbage (missing required fields) is the same -----
  // -- named-failure class, and is equally payload-free in the FULL -------
  // -- return value ---------------------------------------------------------
  {
    const sentinel = 'PAYLOAD-SENTINEL-GARBAGE-WRITER-';
    const oversized = sentinel + 'z'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }), 'spill-writer': async () => ({ written: true }) }); // missing path/sha256/bytes
    const outcome = await specEngineExecute(spec, dispatch);
    check('a garbage writer return halts with status "failed"', outcome.status === 'failed');
    check('a garbage writer return uses the spill-writer-outcome-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-writer-outcome-malformed');
    check(
      'a garbage writer return never leaks the payload into the FULL returned outcome (status + results + trace + halt; sentinel scan)',
      JSON.stringify(outcome).indexOf(sentinel) === -1
    );
  }

  // -- a missing/empty config.spillDir, with an oversized field actually --
  // -- present, halts loudly instead of building a bogus target path -- and
  // -- the sentinel never appears anywhere in the FULL return value -------
  {
    const sentinel = 'PAYLOAD-SENTINEL-NO-SPILLDIR-';
    const oversized = sentinel + 'z'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an oversized field with no spillDir halts with status "failed"', outcome.status === 'failed');
    check('an oversized field with no spillDir uses the spill-guard-spilldir-unavailable diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-guard-spilldir-unavailable');
    check('an oversized field with no spillDir never dispatches a writer', dispatch.calls.length === 1);
    check(
      'an oversized field with no spillDir never leaks the payload into the FULL returned outcome (status + results + trace + halt; sentinel scan)',
      JSON.stringify(outcome).indexOf(sentinel) === -1
    );
  }

  // ======================================================================
  // Guard scan-scope exclusion: the guard scans only outcome DATA fields --
  // never the engine's own status/halt/trace bookkeeping, and never a
  // receipt's own sub-fields.
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
    check('a trace-heavy run (40 small steps) completes', outcome.status === 'completed');
    check('a trace-heavy run never dispatches a spill-writer', dispatch.calls.every(function (c) { return c.type === 'agent'; }));
    check('a trace-heavy run never produces a spilled receipt anywhere in results', JSON.stringify(outcome.results).indexOf('"spilled":true') === -1);
  }

  // -- a receipt's own path string is never re-guarded, even when that ----
  // -- path string is itself longer than the spill threshold ---------------
  {
    const longPath = '/spill/' + 'p'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1000);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: { spilled: true, path: longPath, sha256: HEX64_A, bytes: 99 } }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an already-spilled receipt whose own .path is longer than the threshold still completes', outcome.status === 'completed');
    check('a long receipt .path never triggers a second writer dispatch (dispatch called once, agent only)', dispatch.calls.length === 1);
    check("a receipt's own .path is preserved unchanged, not re-spilled into a nested receipt", outcome.results.report.content.path === longPath);
  }

  // ======================================================================
  // Spill-path namespacing: two steps sharing a bare id in different
  // containers (parallel tracks, map iterations) must never target the
  // same spill file; top-level paths stay exactly as before this fix.
  // ======================================================================

  // -- top-level path is unchanged: <spillDir>/<stepId>.<field> -----------
  {
    const oversized = 'w'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({
      agent: async () => ({ content: oversized }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: oversized.length }),
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a top-level step\'s spill path is unchanged: <spillDir>/<stepId>.<field>', outcome.results.report.content.path === '/spill/report.content');
  }

  // -- two parallel tracks with a SAME-NAMED step ("inner") spill to two --
  // -- DIFFERENT, trackId-qualified paths -- never the same file; a THIRD -
  // -- track whose own id is unsafe halts, CONTAINED to that track alone --
  // -- (engine-core.js:1606-1613's own design: a track-internal halt never
  // -- propagates to the whole run's status, so the run-level status
  // -- assertion alone cannot detect a regression here -- the track's own
  // -- status/diagnostic in the parallel trace is the property that
  // -- actually proves containment) ----------------------------------------
  {
    const oversized = 'y'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = {
      steps: [
        {
          id: 'par1',
          type: 'parallel',
          tracks: [
            { id: 't1', steps: [{ id: 'inner', type: 'agent' }] },
            { id: 't2', steps: [{ id: 'inner', type: 'agent' }] },
            { id: 'bad.track', steps: [{ id: 'inner', type: 'agent' }] },
          ],
        },
      ],
      config: { spillDir: '/spill' },
    };
    const dispatch = makeDispatch({
      agent: async () => ({ content: oversized }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: oversized.length }),
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('the run with two same-named tracked steps (plus a third, unsafe-id track) still completes overall', outcome.status === 'completed');
    check(
      "track t1's own \"inner\" step spills under a trackId-qualified path",
      typeof outcome.results['t1.inner'] !== 'undefined' && outcome.results['t1.inner'].content.path === '/spill/t1.inner.content'
    );
    check(
      "track t2's own \"inner\" step spills under a trackId-qualified path",
      typeof outcome.results['t2.inner'] !== 'undefined' && outcome.results['t2.inner'].content.path === '/spill/t2.inner.content'
    );
    check(
      "the two tracks' same-named steps spill to DIFFERENT paths, never the same file",
      typeof outcome.results['t1.inner'] !== 'undefined' &&
        typeof outcome.results['t2.inner'] !== 'undefined' &&
        outcome.results['t1.inner'].content.path !== outcome.results['t2.inner'].content.path
    );
    const trackSummaries = outcome.trace[0].tracks;
    const badTrackSummary = trackSummaries.filter(function (t) {
      return t.trackId === 'bad.track';
    })[0];
    check("the unsafe track id's own track status is \"failed\", CONTAINED to that track alone", typeof badTrackSummary !== 'undefined' && badTrackSummary.status === 'failed');
    check(
      "the unsafe track id's own track halts under the spill-path-unsafe diagnostic",
      typeof badTrackSummary !== 'undefined' && badTrackSummary.halt !== null && badTrackSummary.halt.diagnostic === 'spill-path-unsafe'
    );
    check("the unsafe track id's own step never lands in the results map (contained, never merged)", typeof outcome.results['bad.track.inner'] === 'undefined');
    check(
      "the parallel step's own aggregate counts the contained track failure without miscounting it as a success",
      outcome.results.par1.failures === 1 && outcome.results.par1.successes === 2
    );
  }

  // -- a 2-item map body reusing the same step id per iteration spills to -
  // -- two DIFFERENT paths, each embedding its own iteration index --------
  {
    const oversized = 'z'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = {
      steps: [
        { id: 'src', type: 'shape', template: { list: ['a', 'b'] } },
        { id: 'mp', type: 'map', list: { step: 'src', field: 'list' }, steps: [{ id: 'inner', type: 'agent' }] },
      ],
      config: { spillDir: '/spill' },
    };
    const dispatch = makeDispatch({
      agent: async () => ({ content: oversized }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: oversized.length }),
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('the 2-item map run still completes', outcome.status === 'completed');
    check("map iteration 0's own \"inner\" step spills under an index-qualified path", outcome.results['mp.0'].content.path === '/spill/mp.0.inner.content');
    check("map iteration 1's own \"inner\" step spills under an index-qualified path", outcome.results['mp.1'].content.path === '/spill/mp.1.inner.content');
    check('the two iterations\' same-named steps spill to DIFFERENT paths, each embedding its own index', outcome.results['mp.0'].content.path !== outcome.results['mp.1'].content.path);
  }

  // ======================================================================
  // By-path digest-verify flow (a step-level, config-silent field:
  // step.verifyDigest).
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
    check('a matching digest-verify lets the run complete', outcome.status === 'completed');
    check('a matching digest-verify dispatches the digest-verify step then the consuming agent step, in order', dispatch.calls.length === 2 && dispatch.calls[0].type === 'digest-verify' && dispatch.calls[1].type === 'agent');
    check('the digest-verify envelope names the declared path', dispatch.calls[0].step.path === '/data/input.bin');
    check("the consuming agent step's own result lands normally", outcome.results.consume.consumed === true);
  }

  // -- a mismatched digest halts named, SAFE (fail closed): zero further --
  // -- dispatch of the consuming step ---------------------------------------
  {
    const spec = { steps: [{ id: 'consume', type: 'agent', verifyDigest: { path: '/data/input.bin', sha256: HEX64_A } }], config: {} };
    const dispatch = makeDispatch({ 'digest-verify': async () => ({ digest: HEX64_B }), agent: async () => ({ consumed: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a mismatched digest halts with status "failed"', outcome.status === 'failed');
    check('a mismatched digest uses the digest-verify-mismatch diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'digest-verify-mismatch');
    check('a mismatched digest never dispatches the consuming agent step', dispatch.calls.length === 1 && dispatch.calls[0].type === 'digest-verify');
  }

  // -- a garbage/unparseable digest return halts named, "uncertain"-class -
  {
    const spec = { steps: [{ id: 'consume', type: 'agent', verifyDigest: { path: '/data/input.bin', sha256: HEX64_A } }], config: {} };
    const dispatch = makeDispatch({ 'digest-verify': async () => ({ oops: 'not a digest' }), agent: async () => ({ consumed: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a garbage digest-verify return halts with status "uncertain" (the uncertain-class)', outcome.status === 'uncertain');
    check('a garbage digest-verify return uses the digest-verify-outcome-unparseable diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'digest-verify-outcome-unparseable');
    check('a garbage digest-verify return never dispatches the consuming agent step', dispatch.calls.length === 1 && dispatch.calls[0].type === 'digest-verify');
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
    check('a null digest-verify return resolves instead of hanging', raced.timedOut === false);
    if (!raced.timedOut) {
      check('a null digest-verify return halts with status "uncertain"', raced.outcome.status === 'uncertain');
      check('a null digest-verify return uses the digest-verify-outcome-unparseable diagnostic', raced.outcome.halt.diagnostic === 'digest-verify-outcome-unparseable');
    }
  }

  // -- a malformed verifyDigest DECLARATION itself (not the agent's own ---
  // -- return) halts spend-free, before any dispatch at all -----------------
  {
    const spec = { steps: [{ id: 'consume', type: 'agent', verifyDigest: { path: '', sha256: HEX64_A } }], config: {} };
    const dispatch = makeDispatch({ 'digest-verify': async () => ({ digest: HEX64_A }), agent: async () => ({ consumed: true }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a malformed verifyDigest declaration (empty path) halts with status "failed"', outcome.status === 'failed');
    check('a malformed verifyDigest declaration uses the digest-verify-declaration-malformed diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'digest-verify-declaration-malformed');
    check('a malformed verifyDigest declaration never dispatches anything (spend-free)', dispatch.calls.length === 0);
  }

  // ======================================================================
  // Spill-path containment: the target path this engine constructs must
  // never escape spillDir, even when an untrusted input (a dispatch
  // return's own field name, or a spec-authored step id) carries path
  // syntax.
  // ======================================================================

  // -- a malicious field name in the dispatched agent's own return value --
  // -- (untrusted producer output) halts under spill-path-unsafe, never --
  // -- reaches a writer dispatch, and never leaks the payload -------------
  {
    const sentinel = 'PAYLOAD-SENTINEL-UNSAFE-FIELD-';
    const oversized = sentinel + 'x'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/tmp/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ 'ok/../../escaped': oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an unsafe field name halts with status "failed"', outcome.status === 'failed');
    check('an unsafe field name uses the spill-path-unsafe diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-path-unsafe');
    check('an unsafe field name never reaches a writer dispatch (dispatch called once, agent only)', dispatch.calls.length === 1);
    check(
      'an unsafe field name never leaks the payload into the FULL returned outcome (status + results + trace + halt; sentinel scan)',
      JSON.stringify(outcome).indexOf(sentinel) === -1
    );
  }

  // -- a step id carrying path-traversal syntax halts the same way, before
  // -- any writer dispatch, with the payload never leaked -----------------
  {
    const sentinel = 'PAYLOAD-SENTINEL-UNSAFE-STEPID-';
    const oversized = sentinel + 'x'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: '../../../etc/evil', type: 'agent' }], config: { spillDir: '/tmp/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an unsafe step id halts with status "failed"', outcome.status === 'failed');
    check('an unsafe step id uses the spill-path-unsafe diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-path-unsafe');
    check('an unsafe step id never reaches a writer dispatch (dispatch called once, agent only)', dispatch.calls.length === 1);
    check(
      'an unsafe step id never leaks the payload into the FULL returned outcome (status + results + trace + halt; sentinel scan)',
      JSON.stringify(outcome).indexOf(sentinel) === -1
    );
  }

  // -- a validator-legal id containing a space is NOT rejected by the -----
  // -- containment guard (a denylist, not an allowlist): it spills --------
  // -- normally, reaching a real writer dispatch -----------------------------
  {
    const oversized = 'v'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = { steps: [{ id: 'a b', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({
      agent: async () => ({ content: oversized }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: oversized.length }),
    });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a validator-legal id containing a space still completes', outcome.status === 'completed');
    check(
      'a validator-legal id containing a space reaches a real writer dispatch (agent then spill-writer)',
      dispatch.calls.length === 2 && dispatch.calls[1].type === 'spill-writer'
    );
    check('a validator-legal id containing a space spills to a path that preserves the space', outcome.results['a b'].content.path === '/spill/a b.content');
  }

  // -- a dot inside a RAW step id must halt before path construction: -----
  // -- composed, it is indistinguishable from the engine's own namespace --
  // -- separator, so the same joined path could otherwise be reached by ---
  // -- two unrelated specs -------------------------------------------------
  {
    const oversized = 'q'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const specDotted = { steps: [{ id: 'a.b', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatchDotted = makeDispatch({
      agent: async () => ({ content: oversized }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: oversized.length }),
    });
    const outcomeDotted = await specEngineExecute(specDotted, dispatchDotted);
    check('a top-level step id containing a dot halts with status "failed"', outcomeDotted.status === 'failed');
    check(
      'a top-level step id containing a dot uses the spill-path-unsafe diagnostic',
      outcomeDotted.halt !== null && outcomeDotted.halt.diagnostic === 'spill-path-unsafe'
    );
    check('a top-level step id containing a dot never reaches a writer dispatch (dispatch called once, agent only)', dispatchDotted.calls.length === 1);

    // The genuinely-composed pair (track "a" containing step "b") joins to
    // the IDENTICAL path "/spill/a.b.content" -- and must still spill
    // normally, proving the guard tells the two apart by validating RAW
    // segments before any join, not the already-joined string. A second
    // step in the SAME track, "c.d", carries a raw id that itself
    // contains a dot -- proving the same rule applies to a step id nested
    // inside a track, CONTAINED to that track alone: step "b" (which
    // already completed) keeps its own result, the track's own status/
    // diagnostic in the parallel trace reads "failed"/spill-path-unsafe,
    // and the whole run still completes (a track-internal halt never
    // propagates to the run's own status -- engine-core.js:1606-1613).
    const specComposed = {
      steps: [
        {
          id: 'par',
          type: 'parallel',
          tracks: [
            {
              id: 'a',
              steps: [
                { id: 'b', type: 'agent' },
                { id: 'c.d', type: 'agent' },
              ],
            },
          ],
        },
      ],
      config: { spillDir: '/spill' },
    };
    const dispatchComposed = makeDispatch({
      agent: async () => ({ content: oversized }),
      'spill-writer': async (step) => ({ written: true, path: step.path, sha256: HEX64_A, bytes: oversized.length }),
    });
    const outcomeComposed = await specEngineExecute(specComposed, dispatchComposed);
    check(
      'track "a" containing step "b" (plus a later, unsafe-id step "c.d" in the SAME track) still completes overall',
      outcomeComposed.status === 'completed'
    );
    check(
      'track "a" containing step "b" spills to the SAME joined path a dotted top-level id would otherwise produce (the earlier, already-completed step keeps its own result)',
      typeof outcomeComposed.results['a.b'] !== 'undefined' && outcomeComposed.results['a.b'].content.path === '/spill/a.b.content'
    );
    const composedTrackSummaries = outcomeComposed.trace[0].tracks;
    const trackASummary = composedTrackSummaries.filter(function (t) {
      return t.trackId === 'a';
    })[0];
    check(
      'the dotted step id nested in the track is caught: the track\'s own status is "failed", CONTAINED to that track alone',
      typeof trackASummary !== 'undefined' && trackASummary.status === 'failed'
    );
    check(
      'the dotted step id nested in the track halts under the spill-path-unsafe diagnostic',
      typeof trackASummary !== 'undefined' && trackASummary.halt !== null && trackASummary.halt.diagnostic === 'spill-path-unsafe'
    );
    check("the dotted step id's own field never lands in the results map (contained, never merged)", typeof outcomeComposed.results['a.c.d'] === 'undefined');
  }

  // -- a dotted FIELD name (from a dispatched agent's own return value) ---
  // -- halts the same way as a dotted step id, never leaking the payload --
  {
    const sentinel = 'PAYLOAD-SENTINEL-DOTTED-FIELD-';
    const oversized = sentinel + 'x'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ 'a.b': oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a dotted field name halts with status "failed"', outcome.status === 'failed');
    check('a dotted field name uses the spill-path-unsafe diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-path-unsafe');
    check('a dotted field name never reaches a writer dispatch (dispatch called once, agent only)', dispatch.calls.length === 1);
    check('a dotted field name never leaks the payload into the FULL returned outcome (sentinel scan)', JSON.stringify(outcome).indexOf(sentinel) === -1);
  }

  // ======================================================================
  // Denylist arm isolation: every existing backslash fixture above also
  // contains a dot, so the dot arm alone is enough to halt them -- it
  // masks whether the backslash arm and the empty-segment arm are
  // independently enforced. These fixtures use DOT-FREE vectors so each
  // arm is exercised on its own.
  // ======================================================================

  // -- a dot-free backslash-containing step id halts on its own ----------
  {
    const oversized = 'k'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = { steps: [{ id: 'C:\\spill\\sub\\evil', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a dot-free backslash-containing step id halts with status "failed"', outcome.status === 'failed');
    check('a dot-free backslash-containing step id uses the spill-path-unsafe diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-path-unsafe');
    check('a dot-free backslash-containing step id never reaches a writer dispatch (dispatch called once, agent only)', dispatch.calls.length === 1);
  }

  // -- a dot-free backslash-containing FIELD name halts on its own, never -
  // -- leaking the payload -------------------------------------------------
  {
    const sentinel = 'PAYLOAD-SENTINEL-BACKSLASH-FIELD-';
    const oversized = sentinel + 'x'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ 'ok\\escaped': oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a dot-free backslash-containing field name halts with status "failed"', outcome.status === 'failed');
    check('a dot-free backslash-containing field name uses the spill-path-unsafe diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-path-unsafe');
    check('a dot-free backslash-containing field name never reaches a writer dispatch (dispatch called once, agent only)', dispatch.calls.length === 1);
    check('a dot-free backslash-containing field name never leaks the payload into the FULL returned outcome (sentinel scan)', JSON.stringify(outcome).indexOf(sentinel) === -1);
  }

  // -- an empty-string FIELD name halts on its own (the empty-segment -----
  // -- arm), rather than spilling to "<spillDir>/<stepId>." ---------------
  {
    const sentinel = 'PAYLOAD-SENTINEL-EMPTY-FIELD-';
    const oversized = sentinel + 'x'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: 'ok', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ '': oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an empty-string field name halts with status "failed"', outcome.status === 'failed');
    check('an empty-string field name uses the spill-path-unsafe diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-path-unsafe');
    check('an empty-string field name never reaches a writer dispatch (dispatch called once, agent only)', dispatch.calls.length === 1);
    check('an empty-string field name never leaks the payload into the FULL returned outcome (sentinel scan)', JSON.stringify(outcome).indexOf(sentinel) === -1);
  }

  // -- an empty-string step id (reachable only by calling specEngineExecute
  // -- directly, bypassing validateSpec's own non-empty-string rule) halts
  // -- on its own too, the same empty-segment arm --------------------------
  {
    const oversized = 'j'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = { steps: [{ id: '', type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('an empty-string step id halts with status "failed"', outcome.status === 'failed');
    check('an empty-string step id uses the spill-path-unsafe diagnostic', outcome.halt !== null && outcome.halt.diagnostic === 'spill-path-unsafe');
    check('an empty-string step id never reaches a writer dispatch (dispatch called once, agent only)', dispatch.calls.length === 1);
  }

  // ======================================================================
  // Fail-closed on a missing/non-string step id: specEngineExecute() can
  // be called directly, bypassing validateSpec's own non-empty-string
  // requirement -- this guard must halt, never throw, when a namespaced
  // segment is not a string.
  // ======================================================================
  {
    const oversized = 'm'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = { steps: [{ type: 'agent' }], config: { spillDir: '/spill' } };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a step with a missing id and an oversized field halts rather than throwing', outcome.status === 'failed');
    check(
      'a step with a missing id and an oversized field uses the spill-path-unsafe diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'spill-path-unsafe'
    );
    check('a step with a missing id and an oversized field never reaches a writer dispatch (dispatch called once, agent only)', dispatch.calls.length === 1);
  }

  // ======================================================================
  // Digest-verify halt trace safety: both digest-verify halt paths must
  // scrub an oversized sibling field before pushing into the trace, the
  // same way every spill-guard halt does.
  // ======================================================================

  // -- digest-verify-outcome-unparseable: the digest agent's own return is
  // -- malformed AND carries an oversized sibling field -- the sentinel ---
  // -- must never appear anywhere in the FULL returned outcome ------------
  {
    const sentinel = 'PAYLOAD-SENTINEL-DIGEST-UNPARSEABLE-';
    const oversized = sentinel + 'z'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: 'consume', type: 'agent', verifyDigest: { path: '/data/input.bin', sha256: HEX64_A } }], config: {} };
    const dispatch = makeDispatch({ 'digest-verify': async () => ({ notDigest: 'nope', extra: oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a malformed digest-verify return with an oversized sibling halts with status "uncertain"', outcome.status === 'uncertain');
    check(
      'a malformed digest-verify return with an oversized sibling uses the digest-verify-outcome-unparseable diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'digest-verify-outcome-unparseable'
    );
    check(
      'a malformed digest-verify return never leaks its oversized sibling into the FULL returned outcome (sentinel scan)',
      JSON.stringify(outcome).indexOf(sentinel) === -1
    );
  }

  // -- digest-verify-mismatch: the digest agent returns a well-formed but -
  // -- WRONG digest, plus an oversized sibling field -- same sentinel-free
  // -- requirement -----------------------------------------------------------
  {
    const sentinel = 'PAYLOAD-SENTINEL-DIGEST-MISMATCH-';
    const oversized = sentinel + 'z'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: 'consume', type: 'agent', verifyDigest: { path: '/data/input.bin', sha256: HEX64_A } }], config: {} };
    const dispatch = makeDispatch({ 'digest-verify': async () => ({ digest: HEX64_B, extra: oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    check('a mismatched digest-verify return with an oversized sibling halts with status "failed"', outcome.status === 'failed');
    check(
      'a mismatched digest-verify return with an oversized sibling uses the digest-verify-mismatch diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'digest-verify-mismatch'
    );
    check(
      'a mismatched digest-verify return never leaks its oversized sibling into the FULL returned outcome (sentinel scan)',
      JSON.stringify(outcome).indexOf(sentinel) === -1
    );
  }

  // ======================================================================
  // Untested scrub path: a malformed receipt AND an oversized sibling
  // field reaching the SAME halt (pass 1 runs before pass 2, so this shape
  // reaches spill-receipt-malformed with the oversized field still
  // present in the working outcome).
  // ======================================================================
  {
    const sentinel = 'PAYLOAD-SENTINEL-MALFORMED-RECEIPT-PLUS-OVERSIZED-';
    const oversized = sentinel + 'z'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1 - sentinel.length);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ badReceipt: { spilled: true, sha256: HEX64_A, bytes: 5 }, other: oversized }) }); // badReceipt missing "path"
    const outcome = await specEngineExecute(spec, dispatch);
    check('a malformed receipt with an oversized sibling field halts with status "failed"', outcome.status === 'failed');
    check(
      'a malformed receipt with an oversized sibling field uses the spill-receipt-malformed diagnostic',
      outcome.halt !== null && outcome.halt.diagnostic === 'spill-receipt-malformed'
    );
    check(
      'a malformed receipt with an oversized sibling field never leaks that sibling into the FULL returned outcome (sentinel scan)',
      JSON.stringify(outcome).indexOf(sentinel) === -1
    );
  }

  // ======================================================================
  // Marker invariant: a scrubbed field's marker object must be
  // non-confusable with a real spill receipt -- {spillFailed: true, bytes}
  // present, {spilled: true, ...} shape absent.
  // ======================================================================
  {
    const oversized = 'w'.repeat(SPEC_ENGINE_SPILL_THRESHOLD_BYTES + 1);
    const spec = { steps: [{ id: 'report', type: 'agent' }], config: {} };
    const dispatch = makeDispatch({ agent: async () => ({ content: oversized }) });
    const outcome = await specEngineExecute(spec, dispatch);
    const traceEntry = outcome.trace[outcome.trace.length - 1];
    check('a scrubbed oversized field carries the literal spillFailed marker key', traceEntry.outcome.content.spillFailed === true);
    check('a scrubbed oversized field never carries the spilled key (non-confusable with a real receipt)', typeof traceEntry.outcome.content.spilled === 'undefined');
  }

  console.log(passCount + ' passed, ' + failCount + ' failed');
  process.exit(failCount === 0 ? 0 : 1);
}

main().catch(function (err) {
  console.error('test-carriage.js crashed: ' + (err && err.stack ? err.stack : err));
  process.exit(1);
});
