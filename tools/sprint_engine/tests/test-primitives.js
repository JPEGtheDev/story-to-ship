// Text-extraction primitive suite for sprint engine specs.
//
// Runs as: node tools/sprint_engine/tests/test-primitives.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test. Covers five pure text functions: specEngineTokenOverlap,
// specEngineExtractLabeledLine, specEngineSliceFromMarker,
// specEngineFirstMatchOf, specEngineRegexExtract. All five are pure text
// functions -- no halt machinery, no results-map lookups, no dispatch.
// Each returns an explicit, documented miss value on a no-match or
// empty-input case; never undefined-by-accident, never a throw.
//
// specEngineTokenOverlap is named in SPEC_SCHEMA.md's "Say-vs-do
// cross-check" section: "The engine computes the token overlap between
// the claim and the evidence; if it falls below minTokenOverlap, the
// engine records a trace flag named verdict-unsupported". That section
// names the comparison and its threshold but does not define what a
// "token" is or how "overlap" is computed as a number -- see the
// function's own header comment in engine-core.js for the INFERRED
// reading this suite pins.
//
// The other four primitives -- extractLabeledLine, sliceFromMarker,
// firstMatchOf, regexExtract -- are not named or described anywhere in
// SPEC_SCHEMA.md or RUNTIME_FACTS.md (confirmed by a full-text grep of
// both files for each name). All behavior this suite pins for those four
// is INFERRED: the minimal reading implied by the function's own name,
// disclosed in each function's header comment in engine-core.js.

'use strict';

const {
  specEngineTokenOverlap,
  specEngineExtractLabeledLine,
  specEngineSliceFromMarker,
  specEngineFirstMatchOf,
  specEngineRegexExtract,
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

// ===========================================================================
// specEngineTokenOverlap(claim, evidence)
// ===========================================================================

// -- hit case: some shared tokens, some not -------------------------------
{
  const overlap = specEngineTokenOverlap('the answer is alpha', 'alpha was the reported answer');
  check('tokenOverlap counts shared tokens between claim and evidence', overlap === 3);
}

// -- no-match case: disjoint token sets -> explicit miss value 0 ----------
{
  const overlap = specEngineTokenOverlap('alpha beta gamma', 'delta epsilon zeta');
  check('tokenOverlap returns the explicit miss value 0 for disjoint token sets', overlap === 0);
}

// -- edge case: identical token sets -> full overlap -----------------------
{
  const overlap = specEngineTokenOverlap('alpha beta gamma', 'alpha beta gamma');
  check('tokenOverlap returns the full token count for identical token sets', overlap === 3);
}

// -- edge case: empty-input strings -> explicit miss value 0 --------------
{
  const overlap = specEngineTokenOverlap('', '');
  check('tokenOverlap returns the explicit miss value 0 for two empty strings', overlap === 0);
}

// -- edge case: case-insensitive and whitespace-collapsing tokenization ---
{
  const overlap = specEngineTokenOverlap('Alpha   BETA', 'alpha beta');
  check('tokenOverlap is case-insensitive and collapses repeated whitespace', overlap === 2);
}

// -- edge case: a repeated token on the claim side dedups rather than -----
// -- inflating the count -- 'alpha' appears twice in the claim but the ----
// -- shared-token count is still 1, not 2 ----------------------------------
{
  const overlap = specEngineTokenOverlap('alpha alpha beta', 'alpha gamma');
  check('tokenOverlap dedups a repeated token rather than inflating the shared-token count', overlap === 1);
}

// ===========================================================================
// specEngineExtractLabeledLine(text, label)
// ===========================================================================

// -- hit case: label at line-start ------------------------------------------
{
  const value = specEngineExtractLabeledLine('Name: alpha\nStatus: pass\n', 'Status');
  check('extractLabeledLine extracts the trimmed value after a line-start label', value === 'pass');
}

// -- no-match case: label never appears -> explicit miss value null -------
{
  const value = specEngineExtractLabeledLine('Name: alpha\nStatus: pass\n', 'Missing');
  check('extractLabeledLine returns the explicit miss value null when the label never appears', value === null);
}

// -- edge case: empty-input text -> explicit miss value null --------------
{
  const value = specEngineExtractLabeledLine('', 'Status');
  check('extractLabeledLine returns the explicit miss value null for empty input text', value === null);
}

// -- edge case: label mid-line (not at line-start) does not count as a ----
// -- labeled line, even though the label text is present somewhere in ------
// -- the string --------------------------------------------------------------
{
  const value = specEngineExtractLabeledLine('Some other Status: nope\n', 'Status');
  check('extractLabeledLine does not match a label that appears mid-line rather than at line-start', value === null);
}

// -- edge case: label at line-start still resolves when a mid-line ---------
// -- decoy line precedes it, and indentation before the label is -----------
// -- tolerated -----------------------------------------------------------------
{
  const value = specEngineExtractLabeledLine('Some other Status: nope\n  Status: real\n', 'Status');
  check('extractLabeledLine skips a mid-line decoy and matches an indented line-start label', value === 'real');
}

// ===========================================================================
// specEngineSliceFromMarker(text, marker)
// ===========================================================================

// -- hit case: marker present mid-string -----------------------------------
{
  const slice = specEngineSliceFromMarker('preamble ---MARKER--- payload text', '---MARKER---');
  check('sliceFromMarker returns everything after the marker', slice === ' payload text');
}

// -- no-match case: marker absent -> explicit miss value null -------------
{
  const slice = specEngineSliceFromMarker('preamble payload text', '---MARKER---');
  check('sliceFromMarker returns the explicit miss value null when the marker is absent', slice === null);
}

// -- edge case: empty-input text -> explicit miss value null --------------
{
  const slice = specEngineSliceFromMarker('', '---MARKER---');
  check('sliceFromMarker returns the explicit miss value null for empty input text', slice === null);
}

// -- edge case: marker present at end-of-string -> FOUND, empty slice, ----
// -- distinct from marker-absent's null -------------------------------------
{
  const slice = specEngineSliceFromMarker('preamble ---MARKER---', '---MARKER---');
  check('sliceFromMarker returns the empty string (not null) when the marker sits at end-of-string', slice === '');
  check('the end-of-string empty slice is distinct in kind from the marker-absent null miss value', slice !== null);
}

// ===========================================================================
// specEngineFirstMatchOf(text, patterns)
// ===========================================================================

// -- hit case: single matching pattern ---------------------------------------
{
  const match = specEngineFirstMatchOf('the answer is alpha', [/alpha/]);
  check('firstMatchOf returns the matched substring for a single matching pattern', match === 'alpha');
}

// -- no-match case: no pattern matches -> explicit miss value null --------
{
  const match = specEngineFirstMatchOf('the answer is alpha', [/beta/, /gamma/]);
  check('firstMatchOf returns the explicit miss value null when no pattern matches', match === null);
}

// -- edge case: empty patterns array -> explicit miss value null ----------
{
  const match = specEngineFirstMatchOf('the answer is alpha', []);
  check('firstMatchOf returns the explicit miss value null for an empty patterns array', match === null);
}

// -- edge case: multiple candidates prove FIRST (array-order) wins, not ---
// -- earliest text position -- /beta/ is listed first even though /alpha/ -
// -- occurs earlier in the string ------------------------------------------
{
  const match = specEngineFirstMatchOf('alpha beta', [/beta/, /alpha/]);
  check('firstMatchOf honors array order over text position: /beta/ (listed first) wins', match === 'beta');
}

// -- edge case: a mixed array with a non-RegExp entry alongside a ---------
// -- matching RegExp -- the non-RegExp entry is skipped without throwing --
// -- and the RegExp still wins --------------------------------------------
{
  const match = specEngineFirstMatchOf('the answer is alpha', ['alpha', /alpha/]);
  check(
    'firstMatchOf skips a non-RegExp array entry without throwing and the RegExp still matches',
    match === 'alpha'
  );
}

// -- edge case: repeat-call determinism with a global-flag ('g') entry ----
// -- a global-flag RegExp carries mutable state (lastIndex) on the caller's
// -- own object; two calls with the SAME arguments (same array, same text)
// -- must return the IDENTICAL match, not a second, different match driven
// -- by the entry's lastIndex advancing from the first call --------------
{
  const patterns = [/\d+/g];
  const first = specEngineFirstMatchOf('123 456', patterns);
  const second = specEngineFirstMatchOf('123 456', patterns);
  check('firstMatchOf with a global-flag pattern entry returns the expected match on a first call', first === '123');
  check(
    'firstMatchOf with a global-flag pattern entry returns the IDENTICAL match on a repeated call with the same arguments (not driven by the entry\'s mutated lastIndex)',
    second === '123'
  );
}

// ===========================================================================
// specEngineRegexExtract(text, pattern)
// ===========================================================================

// -- hit case: pattern WITH a capture group returns the captured text -----
{
  const value = specEngineRegexExtract('Status: pass', /Status:\s*(\w+)/);
  check('regexExtract returns the first capture group when the pattern declares one', value === 'pass');
}

// -- hit case: pattern WITHOUT a capture group returns the whole match ----
{
  const value = specEngineRegexExtract('Status: pass', /Status:\s*\w+/);
  check('regexExtract returns the whole match when the pattern declares no capture group', value === 'Status: pass');
}

// -- no-match case: pattern does not match -> explicit miss value null ----
{
  const value = specEngineRegexExtract('Status: pass', /Missing:\s*(\w+)/);
  check('regexExtract returns the explicit miss value null when the pattern does not match', value === null);
}

// -- edge case: empty-input text -> explicit miss value null --------------
{
  const value = specEngineRegexExtract('', /Status:\s*(\w+)/);
  check('regexExtract returns the explicit miss value null for empty input text', value === null);
}

// -- edge case: a capture group that exists syntactically but does not ----
// -- participate in the match (the optional group never matched) returns --
// -- the explicit miss value null, never JS's own undefined -- the direct -
// -- pin of the never-accidental-undefined rule ----------------------------
{
  const value = specEngineRegexExtract('b', /(a)?b/);
  check(
    'regexExtract returns the explicit miss value null (not undefined) for a non-participating capture group',
    value === null
  );
}

// -- edge case: repeat-call determinism with a global-flag ('g') pattern --
// -- a global-flag RegExp carries mutable state (lastIndex) on the caller's
// -- own object; two calls with the SAME arguments (same pattern object,
// -- same text) must return the IDENTICAL match, not a second, different
// -- match driven by the pattern's lastIndex advancing from the first call
{
  const pattern = /\d+/g;
  const first = specEngineRegexExtract('123 456', pattern);
  const second = specEngineRegexExtract('123 456', pattern);
  check('regexExtract with a global-flag pattern returns the expected match on a first call', first === '123');
  check(
    'regexExtract with a global-flag pattern returns the IDENTICAL match on a repeated call with the same arguments (not driven by the pattern\'s mutated lastIndex)',
    second === '123'
  );
}

console.log(passCount + ' passed, ' + failCount + ' failed');
process.exit(failCount === 0 ? 0 : 1);
