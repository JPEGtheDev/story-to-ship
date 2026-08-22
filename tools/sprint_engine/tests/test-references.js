// Static reference-graph resolution suite for sprint engine specs.
//
// Runs as: node tools/sprint_engine/tests/test-references.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test. Each case below builds a spec object shaped per SPEC_SCHEMA.md,
// calls resolveReferences(spec), and asserts on the returned violation
// list. A violation is { path, diagnostic, message }, matching the shape
// validateSpec uses: path is a JSON path to the referring site, diagnostic
// is a short named code, message is human-readable detail.
//
// resolveReferences(spec) is a static, zero-dispatch pass over a spec that
// has already passed validateSpec: it checks every predicate step/field
// reference and every {{...}} template reference against the result keys
// the spec declares, per the "Template forms and reference resolution" and
// "Result-key namespacing grammar" sections of SPEC_SCHEMA.md. An empty
// list means every reference resolves.

'use strict';

const { resolveReferences } = require('../engine-core.js');

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

function hasViolation(violations, diagnostic, jsonPath) {
  return violations.some(function (v) {
    return v.diagnostic === diagnostic && v.path === jsonPath;
  });
}

function countOf(violations, diagnostic) {
  return violations.filter(function (v) {
    return v.diagnostic === diagnostic;
  }).length;
}

// -- dangling predicate reference (gate) ----------------------------------
{
  const spec = {
    steps: [
      {
        id: 'g1',
        type: 'gate',
        predicate: { step: 'nonexistent', field: 'score', operator: 'gte', value: 1 },
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  check(
    'a gate predicate naming a step that does not exist is reported at steps[0].predicate',
    hasViolation(violations, 'dangling-predicate-reference', 'steps[0].predicate')
  );
  check('the dangling predicate reference produces exactly one violation', violations.length === 1);
}

// -- diagnostic content: referrer path, missing key, declared-key info ----
{
  const spec = {
    steps: [
      { id: 'known1', type: 'shape', template: {} },
      {
        id: 'g1',
        type: 'gate',
        predicate: { step: 'nonexistent', field: 'score', operator: 'gte', value: 1 },
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  const v = violations.filter(function (x) {
    return x.diagnostic === 'dangling-predicate-reference';
  })[0];
  check('a diagnostic violation exists to inspect', typeof v !== 'undefined');
  if (v) {
    check('the violation names the referrer path in its own "path" field', v.path === 'steps[1].predicate');
    check('the violation message names the missing reference', v.message.indexOf('nonexistent') !== -1);
    check('the violation message names the declared-key set', v.message.indexOf('known1') !== -1);
  }
}

// -- dangling template reference (shape step template) --------------------
{
  const spec = {
    steps: [
      {
        id: 'sh1',
        type: 'shape',
        template: { greeting: 'hello {{missing.field}}' },
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  check(
    'a dangling {{missing.field}} template reference is reported at steps[0].template.greeting',
    hasViolation(violations, 'dangling-template-reference', 'steps[0].template.greeting')
  );
  check('the dangling template reference produces exactly one violation', violations.length === 1);
}

// -- valid references at every namespacing grammar level -------------------
// plain top-level step key; <trackId>.<stepId> post-join; <branchId>.<stepId>;
// <mapId>.<index>; <retryId>.attempts.<n>; plain <retryId>; one composite
// <trackId>.<retryId>.attempts.<n>.
{
  const spec = {
    steps: [
      { id: 'top1', type: 'shape', template: {} },
      {
        id: 'par1',
        type: 'parallel',
        tracks: [{ id: 'trackA', steps: [{ id: 'ts1', type: 'shape', template: {} }] }],
      },
      {
        id: 'br1',
        type: 'branch',
        cases: [
          {
            when: { step: 'top1', field: 'x', operator: 'equals', value: 1 },
            steps: [{ id: 'bs1', type: 'shape', template: {} }],
          },
        ],
      },
      { id: 'map1', type: 'map', steps: [{ id: 'ms1', type: 'shape', template: {} }] },
      {
        id: 'sr1',
        type: 'scored-retry',
        mode: 'keep-best',
        step: { id: 'rs1', type: 'shape', template: {} },
      },
      {
        id: 'par2',
        type: 'parallel',
        tracks: [
          {
            id: 'trackB',
            steps: [
              {
                id: 'sr2',
                type: 'scored-retry',
                mode: 'keep-best',
                step: { id: 'rs2', type: 'shape', template: {} },
              },
            ],
          },
        ],
      },
      {
        id: 'checkAll',
        type: 'shape',
        template: {
          plainTopLevel: '{{top1}}',
          trackPostJoin: '{{trackA.ts1}}',
          branchNested: '{{br1.bs1}}',
          mapIndex: '{{map1.0}}',
          retryAttempt: '{{sr1.attempts.0}}',
          retryWinner: '{{sr1}}',
          composite: '{{trackB.sr2.attempts.0}}',
        },
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  check(
    'every namespacing-grammar-level reference resolves cleanly (no violations)',
    violations.length === 0
  );
}

// -- longest-prefix split rule: one declared key is a prefix of another ---
// A top-level leaf step "trackA" (no ordering restriction) and a parallel
// step whose track "trackA" holds a nested step "foo" (namespaced key
// "trackA.foo", ordering-restricted to that track) coexist: "trackA" is a
// literal prefix of "trackA.foo". A template referencing "{{trackA.foo}}"
// must split against the LONGER declared key "trackA.foo", not the shorter
// "trackA" -- proven by referencing it from a step positioned BEFORE the
// parallel step's join: if the split picked the shorter, ordering-free key
// "trackA", no violation would result; since it must pick "trackA.foo"
// (ordering-restricted to track "trackA"), an early reference is invalid.
{
  function specWithReferrerAt(position) {
    const referrer = {
      id: 'referrer',
      type: 'shape',
      template: { x: '{{trackA.foo}}' },
    };
    const steps = [
      { id: 'trackA', type: 'shape', template: {} },
      {
        id: 'par1',
        type: 'parallel',
        tracks: [{ id: 'trackA', steps: [{ id: 'foo', type: 'shape', template: {} }] }],
      },
    ];
    if (position === 'before') {
      steps.splice(1, 0, referrer);
    } else {
      steps.push(referrer);
    }
    return { steps: steps, config: {} };
  }

  const beforeViolations = resolveReferences(specWithReferrerAt('before'));
  check(
    'a longest-prefix-matched track key referenced before the parallel join is invalid',
    hasViolation(beforeViolations, 'parallel-track-reference-before-join', 'steps[1].template.x')
  );

  const afterViolations = resolveReferences(specWithReferrerAt('after'));
  check(
    'the same longest-prefix-matched track key referenced after the parallel join resolves cleanly',
    countOf(afterViolations, 'parallel-track-reference-before-join') === 0 &&
      countOf(afterViolations, 'dangling-template-reference') === 0
  );
}

// -- ordering rule: a step positioned before a parallel step referencing --
// -- one of its tracks' results is invalid; the same reference after is ---
// -- clean --------------------------------------------------------------
{
  const spec = {
    steps: [
      {
        id: 'early',
        type: 'gate',
        predicate: { step: 'trackA.someStep', field: 'score', operator: 'gte', value: 1 },
      },
      {
        id: 'par1',
        type: 'parallel',
        tracks: [{ id: 'trackA', steps: [{ id: 'someStep', type: 'shape', template: {} }] }],
      },
      {
        id: 'late',
        type: 'gate',
        predicate: { step: 'trackA.someStep', field: 'score', operator: 'gte', value: 1 },
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  check(
    'a step positioned before a parallel step referencing a track result is invalid',
    hasViolation(violations, 'parallel-track-reference-before-join', 'steps[0].predicate')
  );
  check(
    'the same reference from a step positioned after the parallel step is clean',
    !hasViolation(violations, 'parallel-track-reference-before-join', 'steps[2].predicate')
  );
  check('exactly one ordering violation is reported (the early one)', countOf(violations, 'parallel-track-reference-before-join') === 1);
}

// -- {{values.PATH}} resolves against config values, not step results -----
{
  const spec = {
    steps: [
      {
        id: 'sh1',
        type: 'shape',
        template: { greeting: '{{values.someConfigPath}}' },
      },
    ],
    config: { values: { someConfigPath: 'hello' } },
  };
  const violations = resolveReferences(spec);
  check('a {{values.PATH}} template reference is never reported as a dangling step reference', violations.length === 0);
}

// -- {{#if}} blocks: the condition inside is checked as a reference --------
{
  const spec = {
    steps: [
      {
        id: 'sh1',
        type: 'shape',
        template: { body: '{{#if missing.flag}}yes{{/if}}' },
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  check(
    'a dangling reference inside an {{#if}} condition is reported at the template field',
    hasViolation(violations, 'dangling-template-reference', 'steps[0].template.body')
  );
}

// -- several dangling references at once: all returned, not fail-fast -----
{
  const spec = {
    steps: [
      {
        id: 'g1',
        type: 'gate',
        predicate: { step: 'ghost1', field: 'x', operator: 'equals', value: 1 },
      },
      {
        id: 'sh1',
        type: 'shape',
        template: { a: '{{ghost2.field}}', b: '{{ghost3.field}}' },
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  check(
    'a multi-violation spec reports the dangling predicate reference',
    hasViolation(violations, 'dangling-predicate-reference', 'steps[0].predicate')
  );
  check(
    'a multi-violation spec reports the first dangling template reference',
    hasViolation(violations, 'dangling-template-reference', 'steps[1].template.a')
  );
  check(
    'a multi-violation spec reports the second dangling template reference',
    hasViolation(violations, 'dangling-template-reference', 'steps[1].template.b')
  );
  check('a multi-violation spec is not fail-fast: all three violations present', violations.length === 3);
}

console.log(passCount + ' passed, ' + failCount + ' failed');
process.exit(failCount === 0 ? 0 : 1);
