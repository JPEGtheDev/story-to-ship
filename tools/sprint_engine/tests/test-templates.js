// Runtime template-rendering suite for sprint engine specs.
//
// Runs as: node tools/sprint_engine/tests/test-templates.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test. Each case below calls specEngineRenderTemplate(templateValue,
// results, values) directly against a hand-built results map (the flat
// "namespaced result key -> that step's result value" shape the
// "Result-key namespacing grammar" section of SPEC_SCHEMA.md describes) and
// a hand-built config-values object, and asserts on the returned outcome.
//
// specEngineRenderTemplate is a runtime renderer, not a static pass: it
// walks a template value (a string, or an object/array of such strings, per
// "A shape step's own `template` field ... is an object whose string leaves
// may contain {{...}} placeholders") and substitutes each placeholder with
// a value read out of `results` or `values`, per the "Template forms and
// reference resolution" section of SPEC_SCHEMA.md. Its return shape mirrors
// specEngineEvalPredicate's own runtime-evaluator shape (this file's
// existing convention for a runtime evaluator, not carried from a ratified
// wording): { halted: false, value: <rendered> } on a clean render, or
// { halted: true, path, diagnostic, message, value? } on a halt -- reusing
// the {path, diagnostic, message} violation shape via specEngineMakeHalt.
//
// Rendering is fail-fast: the first unresolved reference or spilled-content
// violation halts the whole render, matching the contract's "halts the run"
// wording (a run-level halt, not a collect-everything static pass like
// validateSpec/resolveReferences).

'use strict';

const { specEngineRenderTemplate } = require('../engine-core.js');

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

// A results map fixture reused across cases below:
//  - "top1": a plain top-level step result.
//  - "trackA": a top-level leaf step whose id happens to be a literal
//    prefix of another declared key below ("trackA.foo") -- the
//    longest-prefix split case the "Template split rule" section names:
//    "a declared step key that happens to be a prefix of another declared
//    step key -- the longest match wins."
//  - "trackA.foo": a namespaced key, as if track "trackA" ran a nested step
//    "foo", per the "parallel" bullet of the "Result-key namespacing
//    grammar" section ("<trackId>.<stepId>").
//  - "trackB.sr2.attempts.0": a composite namespaced key, as if a
//    scored-retry step "sr2" nested inside parallel track "trackB" ran its
//    first attempt, per the "composites" bullet of the same section
//    ("<trackId>.<retryId>.attempts.<n>").
//  - "A": a step whose "content" field has already spilled (per the
//    "Oversized-output spill contract" section's worked example), leaving
//    only the receipt -- {spilled, path, sha256, bytes} -- in the results
//    map at that key.
const results = {
  top1: { greeting: 'hello', score: 5 },
  trackA: 'leaf-value',
  'trackA.foo': { someField: 'nested-value' },
  'trackB.sr2.attempts.0': { score: 42 },
  A: {
    content: {
      spilled: true,
      path: '/tmp/spill/A.content',
      sha256: 'deadbeef',
      bytes: 45000,
    },
  },
};

const values = { region: 'us-east', nested: { flag: true } };

// -- {{step.field}} substitution: a plain declared key -----------------
{
  const outcome = specEngineRenderTemplate('say {{top1.greeting}}', results, values);
  check('a plain {{step.field}} reference renders without halting', outcome.halted === false);
  check('the plain reference substitutes the field value into the string', outcome.value === 'say hello');
}

// -- {{step.field}} substitution: longest-prefix split, one declared key -
// -- is a prefix of another -----------------------------------------------
// "Template split rule": "a template reference resolves by matching the
// longest declared step key that is a prefix of the reference ... This
// also covers a declared step key that happens to be a prefix of another
// declared step key -- the longest match wins."
{
  const shortKey = specEngineRenderTemplate('{{trackA}}', results, values);
  check('the shorter declared key "trackA" resolves to its own leaf value', shortKey.halted === false && shortKey.value === 'leaf-value');

  const longKey = specEngineRenderTemplate('{{trackA.foo.someField}}', results, values);
  check('a reference under the longer declared key "trackA.foo" splits against THAT key, not "trackA"', longKey.halted === false);
  check('the longest-prefix split reads the field off the longer key\'s own result', longKey.value === 'nested-value');
}

// -- {{step.field}} substitution: a composite namespaced key (a parallel --
// -- track's namespaced result, further composed with a scored-retry -----
// -- attempt key) -----------------------------------------------------------
{
  const outcome = specEngineRenderTemplate('{{trackB.sr2.attempts.0.score}}', results, values);
  check('a composite <trackId>.<retryId>.attempts.<n> key resolves', outcome.halted === false);
  check('the composite-key field value is substituted', outcome.value === '42');
}

// -- {{values.PATH}} substitution from the spec's config values -----------
{
  const outcome = specEngineRenderTemplate('region is {{values.region}}', results, values);
  check('a {{values.PATH}} reference resolves against config values, not step results', outcome.halted === false);
  check('the values.PATH reference substitutes the config value', outcome.value === 'region is us-east');

  const nested = specEngineRenderTemplate('{{values.nested.flag}}', results, values);
  check('a dotted {{values.PATH}} reference walks into a nested config-values object', nested.halted === false && nested.value === 'true');
}

// -- {{#if}} conditional blocks: truthy condition renders the block -------
// SPEC_SCHEMA.md's "Template forms and reference resolution" section names
// {{#if}} as a recognized form but does not extend its behavior beyond
// "that literal syntax" -- this suite pins the minimal reading: the
// condition inside {{#if COND}} is a reference in the same {{step.field}}/
// {{values.PATH}} vocabulary (consistent with this file's own existing
// extension in resolveReferences' extractPlaceholders, which already reads
// an {{#if}} condition as a reference for static-resolution purposes), and
// truthiness is plain JS truthiness of the resolved value.
{
  const outcome = specEngineRenderTemplate('{{#if top1.greeting}}shown{{/if}}', results, values);
  check('a truthy {{#if}} condition renders the enclosed block', outcome.halted === false && outcome.value === 'shown');
}

// -- {{#if}} conditional blocks: falsy condition omits the block ----------
{
  const falsyResults = Object.assign({}, results, { flag1: { on: false } });
  const outcome = specEngineRenderTemplate('before[{{#if flag1.on}}shown{{/if}}]after', falsyResults, values);
  check('a falsy {{#if}} condition halts cleanly (no halt) and omits the enclosed block', outcome.halted === false);
  check('the omitted block leaves no trace in the rendered string', outcome.value === 'before[]after');
}

// -- {{#if}} blocks compose with an outer placeholder around them ---------
{
  const outcome = specEngineRenderTemplate('{{top1.greeting}} {{#if top1.greeting}}yes{{/if}}', results, values);
  check('a plain placeholder and a truthy {{#if}} block in the same string both render', outcome.halted === false);
  check('both renders land in the expected combined string', outcome.value === 'hello yes');
}

// -- unresolvable template reference: the literal sentinel is recorded ----
// -- and the render halts ---------------------------------------------------
// "Undefined-sentinel rule (templates)": "if a template's dotted path does
// not resolve -- the named step was never declared, or the field is
// missing from its result -- the engine does not silently substitute the
// literal text "undefined" into the rendered prompt and continue. It
// records the sentinel `<<undefined>>` and halts the run, exactly as an
// unresolved predicate operand does."
{
  const outcome = specEngineRenderTemplate('hi {{ghostStep.field}}', results, values);
  check('an unresolvable {{step.field}} reference halts the render', outcome.halted === true);
  check('the halt records the literal "<<undefined>>" sentinel value', outcome.value === '<<undefined>>');
  check(
    'the halt is reported under a runtime template-specific diagnostic, distinct from the static dangling-template-reference one',
    outcome.diagnostic === 'template-operand-unresolved' && outcome.diagnostic !== 'dangling-template-reference'
  );
}

// -- unresolvable template reference: a declared step but a missing field -
{
  const outcome = specEngineRenderTemplate('{{top1.missingField}}', results, values);
  check('a declared step with a missing field halts the render the same way', outcome.halted === true);
  check('the missing-field halt also records the "<<undefined>>" sentinel', outcome.value === '<<undefined>>');
  check('the missing-field halt uses the same runtime diagnostic', outcome.diagnostic === 'template-operand-unresolved');
}

// -- pointer sub-fields are legal: a template reaching into a spill -------
// -- pointer's own subfield resolves to the receipt's value -----------------
// "Pointer sub-fields are first-class referents ... {{A.content.path}} ...
// A later step's prompt containing {{report.content.path}} resolves
// legally -- it reads the path out of the receipt."
{
  const outcome = specEngineRenderTemplate('path={{A.content.path}}', results, values);
  check('a template reaching a spilled field\'s .path receipt subfield resolves without halting', outcome.halted === false);
  check('the .path receipt subfield value is substituted', outcome.value === 'path=/tmp/spill/A.content');

  const shaOutcome = specEngineRenderTemplate('{{A.content.sha256}}', results, values);
  check('a template reaching a spilled field\'s .sha256 receipt subfield resolves without halting', shaOutcome.halted === false);
  check('the .sha256 receipt subfield value is substituted', shaOutcome.value === 'deadbeef');
}

// -- referencing a spilled field directly (not a pointer subfield) is a ---
// -- named halt, consistent with the predicate evaluator's existing -------
// -- diagnostic naming for the same defect class ---------------------------
// "Referencing the raw field directly -- {{A.content}}, or a predicate over
// A.content itself -- after it has spilled is illegal and halts the run
// with a named diagnostic, because that raw value no longer exists in the
// results map; only its receipt does." specEngineEvalPredicate names this
// defect class 'predicate-spilled-content-reference'; this suite pins the
// template renderer's own diagnostic as 'template-spilled-content-
// reference' -- same defect class, same naming pattern, template-prefixed
// instead of predicate-prefixed, consistent with this file's existing
// dangling-predicate-reference / dangling-template-reference naming pair.
{
  const outcome = specEngineRenderTemplate('{{A.content}}', results, values);
  check('a template referencing a spilled field directly halts', outcome.halted === true);
  check(
    'the direct-spilled-content halt uses a diagnostic distinct from the operand-unresolved one',
    outcome.diagnostic === 'template-spilled-content-reference' && outcome.diagnostic !== 'template-operand-unresolved'
  );
  check(
    'the diagnostic name follows the same naming pattern as the predicate evaluator\'s own spilled-content diagnostic',
    outcome.diagnostic === 'template-spilled-content-reference'
  );
}

// -- an {{#if}} condition that references spilled content directly halts -
// -- the same way as any other direct spilled-content reference -----------
{
  const outcome = specEngineRenderTemplate('{{#if A.content}}shown{{/if}}', results, values);
  check('an {{#if}} condition referencing spilled content directly halts', outcome.halted === true);
  check('the {{#if}}-condition spill halt reuses the same diagnostic', outcome.diagnostic === 'template-spilled-content-reference');
}

// -- an {{#if}} condition that does not resolve halts the same way as any -
// -- other unresolved template reference -----------------------------------
{
  const outcome = specEngineRenderTemplate('{{#if ghostStep.field}}shown{{/if}}', results, values);
  check('an {{#if}} condition that does not resolve halts', outcome.halted === true);
  check('the {{#if}}-condition halt records the "<<undefined>>" sentinel', outcome.value === '<<undefined>>');
  check('the {{#if}}-condition halt reuses the runtime template-operand-unresolved diagnostic', outcome.diagnostic === 'template-operand-unresolved');
}

// -- whole-template-tree rendering: a shape step's "template" field is an -
// -- object whose string leaves may contain placeholders -- the renderer --
// -- walks arrays and nested objects, not just a single top-level string --
{
  const template = {
    greeting: 'hi {{top1.greeting}}',
    nested: { region: '{{values.region}}' },
    list: ['{{trackA}}', 'static text'],
  };
  const outcome = specEngineRenderTemplate(template, results, values);
  check('a nested object/array template tree renders without halting', outcome.halted === false);
  check(
    'every string leaf across the object/array tree is independently rendered',
    outcome.value.greeting === 'hi hello' &&
      outcome.value.nested.region === 'us-east' &&
      outcome.value.list[0] === 'leaf-value' &&
      outcome.value.list[1] === 'static text'
  );
}

// -- whole-template-tree rendering: fail-fast propagation ------------------
// The first unresolved reference anywhere in the tree halts the whole
// render (matching the contract's "halts the run" wording), and the halt's
// own "path" names the specific leaf where it happened.
{
  const template = { a: 'fine {{top1.greeting}}', b: 'broken {{ghostStep.field}}', c: 'never reached {{top1.greeting}}' };
  const outcome = specEngineRenderTemplate(template, results, values);
  check('the first unresolved reference in a multi-leaf tree halts the whole render', outcome.halted === true);
  check('the halt path names the specific leaf that failed to resolve', outcome.path === '.b');
}

console.log(passCount + ' passed, ' + failCount + ' failed');
process.exit(failCount === 0 ? 0 : 1);
