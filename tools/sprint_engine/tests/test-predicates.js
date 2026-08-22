// Runtime predicate-evaluation suite for sprint engine specs.
//
// Runs as: node tools/sprint_engine/tests/test-predicates.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test. Each case below calls specEngineEvalPredicate(predicate, results)
// directly against a hand-built results map (the flat "namespaced result
// key -> that step's result value" shape the "Result-key namespacing
// grammar" section of SPEC_SCHEMA.md describes) and asserts on the returned
// outcome.
//
// specEngineEvalPredicate is a runtime evaluator, not a structural pass: it
// takes one already-resolved predicate object ({ step, field, operator,
// value }, per the "Container authoring syntax" section) and the run's
// results-so-far map, and either returns a comparison result or halts,
// per the "Predicate operator vocabulary" and "Oversized-output spill
// contract" sections. Its return shape is this implementation's own
// choice, not carried from a ratified wording: { halted: false, result:
// <boolean> } on a clean comparison, or { halted: true, path, diagnostic,
// message, value? } on a halt -- reusing this file's existing
// {path, diagnostic, message} violation shape, extended with `halted` and
// (for the sentinel case) the literal sentinel value.

'use strict';

const { specEngineEvalPredicate } = require('../engine-core.js');

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

// A results map fixture reused across cases below: a plain step with a
// numeric and a string field, and a step whose "content" field has already
// spilled (per the "Oversized-output spill contract" section's worked
// example), leaving only the receipt -- {spilled, path, sha256, bytes} --
// in the results map at that key.
const results = {
  step1: { score: 5, name: 'alpha' },
  A: {
    content: {
      spilled: true,
      path: '/tmp/spill/A.content',
      sha256: 'deadbeef',
      bytes: 45000,
    },
  },
};

// -- equals: numeric operand, match and mismatch --------------------------
{
  const match = specEngineEvalPredicate({ step: 'step1', field: 'score', operator: 'equals', value: 5 }, results);
  check('equals matches an identical numeric operand', match.halted === false && match.result === true);

  const mismatch = specEngineEvalPredicate({ step: 'step1', field: 'score', operator: 'equals', value: 6 }, results);
  check('equals reports false for a differing numeric operand', mismatch.halted === false && mismatch.result === false);
}

// -- equals: non-numeric string operand, match and mismatch ---------------
{
  const match = specEngineEvalPredicate({ step: 'step1', field: 'name', operator: 'equals', value: 'alpha' }, results);
  check('equals matches an identical non-numeric string operand', match.halted === false && match.result === true);

  const mismatch = specEngineEvalPredicate({ step: 'step1', field: 'name', operator: 'equals', value: 'beta' }, results);
  check('equals reports false for a differing string operand', mismatch.halted === false && mismatch.result === false);
}

// -- lte: below, at the boundary, and above --------------------------------
{
  const below = specEngineEvalPredicate({ step: 'step1', field: 'score', operator: 'lte', value: 6 }, results);
  check('lte reports true when the operand is below the comparison value', below.halted === false && below.result === true);

  const boundary = specEngineEvalPredicate({ step: 'step1', field: 'score', operator: 'lte', value: 5 }, results);
  check('lte reports true on the boundary-equal case', boundary.halted === false && boundary.result === true);

  const above = specEngineEvalPredicate({ step: 'step1', field: 'score', operator: 'lte', value: 4 }, results);
  check('lte reports false when the operand is above the comparison value', above.halted === false && above.result === false);
}

// -- gte: above, at the boundary, and below --------------------------------
{
  const above = specEngineEvalPredicate({ step: 'step1', field: 'score', operator: 'gte', value: 4 }, results);
  check('gte reports true when the operand is above the comparison value', above.halted === false && above.result === true);

  const boundary = specEngineEvalPredicate({ step: 'step1', field: 'score', operator: 'gte', value: 5 }, results);
  check('gte reports true on the boundary-equal case', boundary.halted === false && boundary.result === true);

  const below = specEngineEvalPredicate({ step: 'step1', field: 'score', operator: 'gte', value: 6 }, results);
  check('gte reports false when the operand is below the comparison value', below.halted === false && below.result === false);
}

// -- undefined-sentinel rule: an lte predicate whose FIELD does not -------
// -- resolve halts with the "<<undefined>>" sentinel, not a silently ------
// -- false comparison ------------------------------------------------------
// "the engine records the literal sentinel value '<<undefined>>' for the
// unresolved operand and halts the run ... This sentinel-and-halt rule
// applies to lte and gte the same way it applies to equals."
{
  const outcome = specEngineEvalPredicate({ step: 'step1', field: 'missingField', operator: 'lte', value: 5 }, results);
  check('an lte predicate over a missing field halts', outcome.halted === true);
  check('the halt is reported under the operand-unresolved diagnostic', outcome.diagnostic === 'predicate-operand-unresolved');
  check('the halt records the literal "<<undefined>>" sentinel value', outcome.value === '<<undefined>>');
}

// -- undefined-sentinel rule: a gte predicate whose STEP does not resolve -
// -- halts the same way -----------------------------------------------------
{
  const outcome = specEngineEvalPredicate({ step: 'ghostStep', field: 'score', operator: 'gte', value: 5 }, results);
  check('a gte predicate naming an undeclared step halts', outcome.halted === true);
  check('the halt is reported under the operand-unresolved diagnostic', outcome.diagnostic === 'predicate-operand-unresolved');
  check('the halt records the literal "<<undefined>>" sentinel value', outcome.value === '<<undefined>>');
}

// -- pointer sub-fields are legal: a predicate reaching into a spill ------
// -- pointer's own subfields evaluates normally -----------------------------
// "Pointer sub-fields are first-class referents ... a predicate reading
// A.content.bytes" is explicitly named as legal in the spill contract.
{
  const bytesCheck = specEngineEvalPredicate({ step: 'A', field: 'content.bytes', operator: 'gte', value: 1000 }, results);
  check('a predicate over a spill pointer\'s .bytes subfield resolves normally', bytesCheck.halted === false);
  check('the .bytes subfield comparison evaluates correctly', bytesCheck.result === true);

  const pathCheck = specEngineEvalPredicate(
    { step: 'A', field: 'content.path', operator: 'equals', value: '/tmp/spill/A.content' },
    results
  );
  check('a predicate over a spill pointer\'s .path subfield resolves normally', pathCheck.halted === false);
  check('the .path subfield comparison evaluates correctly', pathCheck.result === true);
}

// -- referencing spilled CONTENT directly (not a pointer subfield) is a ---
// -- named halt, distinct from the undefined-sentinel halt -----------------
// "Referencing the raw field directly -- {{A.content}}, or a predicate over
// A.content itself -- after it has spilled is illegal and halts the run
// with a named diagnostic, because that raw value no longer exists in the
// results map; only its receipt does."
{
  const outcome = specEngineEvalPredicate({ step: 'A', field: 'content', operator: 'equals', value: 'whatever' }, results);
  check('a predicate reading a spilled field directly halts', outcome.halted === true);
  check(
    'the direct-spilled-content halt uses a diagnostic distinct from the operand-unresolved one',
    outcome.diagnostic === 'predicate-spilled-content-reference' && outcome.diagnostic !== 'predicate-operand-unresolved'
  );
}

console.log(passCount + ' passed, ' + failCount + ' failed');
process.exit(failCount === 0 ? 0 : 1);
