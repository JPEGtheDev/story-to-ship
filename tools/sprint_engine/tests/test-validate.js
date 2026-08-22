// Structural validation suite for sprint engine specs.
//
// Runs as: node tools/sprint_engine/tests/test-validate.js
//
// Plain Node, no test framework, no dependencies beyond the module under
// test. Each case below builds a spec object shaped per SPEC_SCHEMA.md,
// calls validateSpec(spec), and asserts on the returned violation list. A
// violation is { path, diagnostic, message }: path is a JSON path into the
// spec pointing at the offending location, diagnostic is a short named
// code, message is human-readable detail.
//
// Container internals (tracks/cases/default/steps/step, outputSchema, and
// predicate shapes) follow the "Container authoring syntax" section of
// SPEC_SCHEMA.md; see that section for the full convention.

'use strict';

const { validateSpec } = require('../engine-core.js');

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

// -- unknown step kind -------------------------------------------------
{
  const spec = {
    steps: [{ id: 's1', type: 'bogus' }],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'unknown step kind is reported at steps[0].type',
    hasViolation(violations, 'unknown-step-kind', 'steps[0].type')
  );
  check('unknown step kind produces exactly one violation', violations.length === 1);
}

// -- missing required field: config.spillDir when an agent step exists --
{
  const spec = {
    steps: [{ id: 'a1', type: 'agent' }],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'missing config.spillDir with an agent step present is reported at config.spillDir',
    hasViolation(violations, 'spilldir-required', 'config.spillDir')
  );
  check('missing spillDir produces exactly one violation', violations.length === 1);
}

// -- config.spillDir must be absolute -----------------------------------
{
  const spec = {
    steps: [{ id: 'a1', type: 'agent' }],
    config: { spillDir: 'relative/path' },
  };
  const violations = validateSpec(spec);
  check(
    'relative config.spillDir is reported at config.spillDir',
    hasViolation(violations, 'spilldir-not-absolute', 'config.spillDir')
  );
}

// -- config.spillDir absolute and present: no violation ------------------
{
  const spec = {
    steps: [{ id: 'a1', type: 'agent' }],
    config: { spillDir: '/tmp/spill' },
  };
  const violations = validateSpec(spec);
  check('absolute config.spillDir with an agent step is valid', violations.length === 0);
}

// -- bad predicate operator (gate step) ----------------------------------
{
  const spec = {
    steps: [
      {
        id: 'g1',
        type: 'gate',
        predicate: { step: 'x', field: 'y', operator: 'neq', value: 1 },
      },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'unknown predicate operator on a gate step is reported at steps[0].predicate.operator',
    hasViolation(violations, 'unknown-predicate-operator', 'steps[0].predicate.operator')
  );
}

// -- bad predicate operator (branch step case) ---------------------------
{
  const spec = {
    steps: [
      {
        id: 'b1',
        type: 'branch',
        cases: [
          {
            when: { step: 'x', field: 'y', operator: 'startswith', value: 'a' },
            steps: [],
          },
        ],
      },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'unknown predicate operator on a branch case is reported at steps[0].cases[0].when.operator',
    hasViolation(violations, 'unknown-predicate-operator', 'steps[0].cases[0].when.operator')
  );
}

// -- each of the three legal predicate operators is accepted -------------
{
  ['equals', 'lte', 'gte'].forEach(function (op) {
    const spec = {
      steps: [
        {
          id: 'g1',
          type: 'gate',
          predicate: { step: 'x', field: 'y', operator: op, value: 1 },
        },
      ],
      config: {},
    };
    const violations = validateSpec(spec);
    check(
      'predicate operator "' + op + '" is legal and produces no operator violation',
      countOf(violations, 'unknown-predicate-operator') === 0
    );
  });
}

// -- steps must be an array ----------------------------------------------
{
  const spec = { steps: {}, config: {} };
  const violations = validateSpec(spec);
  check(
    'non-array steps is reported at steps',
    hasViolation(violations, 'steps-not-array', 'steps')
  );
  check('non-array steps produces exactly one violation', violations.length === 1);
}

// -- duplicate step IDs (plain, top level) --------------------------------
{
  const spec = {
    steps: [
      { id: 'dup', type: 'shape', template: {} },
      { id: 'dup', type: 'shape', template: {} },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'a plain duplicate top-level step ID is reported at steps[1]',
    hasViolation(violations, 'duplicate-result-key', 'steps[1]')
  );
}

// -- duplicate step IDs: dotted collision ---------------------------------
// A step nested in track "trackA" with id "foo" namespaces to the
// result-key "trackA.foo" (per the parallel bullet of the result-key
// namespacing grammar). A separate top-level step literally declared with
// id "trackA.foo" collides with that namespaced key.
{
  const spec = {
    steps: [
      {
        id: 'par1',
        type: 'parallel',
        tracks: [
          {
            id: 'trackA',
            steps: [{ id: 'foo', type: 'shape', template: {} }],
          },
        ],
      },
      { id: 'trackA.foo', type: 'shape', template: {} },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'a declared ID colliding with a namespaced result key is reported at steps[1]',
    hasViolation(violations, 'duplicate-result-key', 'steps[1]')
  );
}

// -- reserved segment: step ID "attempts" ---------------------------------
{
  const spec = {
    steps: [{ id: 'attempts', type: 'shape', template: {} }],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'step ID "attempts" is reported as a reserved segment at steps[0].id',
    hasViolation(violations, 'reserved-segment', 'steps[0].id')
  );
}

// -- reserved segment: bare-numeric step ID --------------------------------
{
  const spec = {
    steps: [{ id: '7', type: 'shape', template: {} }],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'a bare-numeric step ID is reported as a reserved segment at steps[0].id',
    hasViolation(violations, 'reserved-segment', 'steps[0].id')
  );
}

// -- reserved segment: map output schema, bare-numeric top-level field ----
{
  const spec = {
    steps: [
      {
        id: 'm1',
        type: 'map',
        steps: [],
        outputSchema: { properties: { '0': {} } },
      },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'a bare-numeric top-level output-schema field on a map step is reported at steps[0].outputSchema.properties.0',
    hasViolation(violations, 'reserved-segment', 'steps[0].outputSchema.properties.0')
  );
}

// -- reserved segment: scored-retry output schema, top-level "attempts" ---
{
  const spec = {
    steps: [
      {
        id: 'sr1',
        type: 'scored-retry',
        mode: 'keep-best',
        outputSchema: { properties: { attempts: {} } },
      },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'a top-level "attempts" output-schema field on a scored-retry step is reported at steps[0].outputSchema.properties.attempts',
    hasViolation(violations, 'reserved-segment', 'steps[0].outputSchema.properties.attempts')
  );
}

// -- scored-retry.mode required --------------------------------------------
{
  const spec = {
    steps: [{ id: 'sr1', type: 'scored-retry' }],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'a scored-retry step without mode is reported at steps[0].mode',
    hasViolation(violations, 'scored-retry-mode-required', 'steps[0].mode')
  );
}

// -- scored-retry.mode must be one of the two legal values ------------------
{
  const spec = {
    steps: [{ id: 'sr1', type: 'scored-retry', mode: 'bogus-mode' }],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'an invalid scored-retry mode is reported at steps[0].mode',
    hasViolation(violations, 'scored-retry-mode-invalid', 'steps[0].mode')
  );
}

// -- scored-retry.threshold required for first-passing mode ------------------
{
  const spec = {
    steps: [{ id: 'sr1', type: 'scored-retry', mode: 'first-passing' }],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'first-passing mode without threshold is reported at steps[0].threshold',
    hasViolation(violations, 'scored-retry-threshold-required', 'steps[0].threshold')
  );
}

// -- scored-retry.threshold is optional for keep-best mode --------------------
{
  const spec = {
    steps: [{ id: 'sr1', type: 'scored-retry', mode: 'keep-best' }],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'keep-best mode without threshold produces no threshold violation',
    countOf(violations, 'scored-retry-threshold-required') === 0
  );
}

// -- nesting depth cap: three nested containers hold a fourth (rejected) ---
// parallel (depth 1) > map (depth 2) > scored-retry (depth 3) > branch
// (depth 4) -- the branch step is the one that exceeds the cap.
{
  const spec = {
    steps: [
      {
        id: 'par1',
        type: 'parallel',
        tracks: [
          {
            id: 'trackA',
            steps: [
              {
                id: 'map1',
                type: 'map',
                steps: [
                  {
                    id: 'sr1',
                    type: 'scored-retry',
                    mode: 'keep-best',
                    step: {
                      id: 'branch1',
                      type: 'branch',
                      cases: [
                        {
                          when: { step: 'x', field: 'y', operator: 'equals', value: 1 },
                          steps: [],
                        },
                      ],
                    },
                  },
                ],
              },
            ],
          },
        ],
      },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'a fourth nested container level is rejected at the offending branch step',
    hasViolation(
      violations,
      'nesting-depth-exceeded',
      'steps[0].tracks[0].steps[0].steps[0].step'
    )
  );
}

// -- nesting depth cap: exactly three nested containers is accepted --------
// parallel (depth 1) > map (depth 2) > scored-retry (depth 3), no fourth
// container level.
{
  const spec = {
    steps: [
      {
        id: 'par1',
        type: 'parallel',
        tracks: [
          {
            id: 'trackA',
            steps: [
              {
                id: 'map1',
                type: 'map',
                steps: [
                  {
                    id: 'sr1',
                    type: 'scored-retry',
                    mode: 'keep-best',
                    step: { id: 'leaf1', type: 'shape', template: {} },
                  },
                ],
              },
            ],
          },
        ],
      },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check('exactly three nested container levels produces no nesting-depth violation', violations.length === 0);
}

// -- several violations at once: all returned with correct paths -----------
{
  const spec = {
    steps: [
      { id: 's1', type: 'bogus' },
      { id: 'a1', type: 'agent' },
      {
        id: 'g1',
        type: 'gate',
        predicate: { step: 'x', field: 'y', operator: 'neq', value: 1 },
      },
      { id: 'dup', type: 'shape', template: {} },
      { id: 'dup', type: 'shape', template: {} },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'a multi-violation spec reports the unknown step kind',
    hasViolation(violations, 'unknown-step-kind', 'steps[0].type')
  );
  check(
    'a multi-violation spec reports the missing spillDir',
    hasViolation(violations, 'spilldir-required', 'config.spillDir')
  );
  check(
    'a multi-violation spec reports the bad predicate operator',
    hasViolation(violations, 'unknown-predicate-operator', 'steps[2].predicate.operator')
  );
  check(
    'a multi-violation spec reports the duplicate step ID',
    hasViolation(violations, 'duplicate-result-key', 'steps[4]')
  );
  check('a multi-violation spec is not fail-fast: all four violations present', violations.length === 4);
}

// -- duplicate-ID registry is scoped per container subtree: two map -------
// -- steps with identical nested subtrees do not collide -----------------
// Each map step's body is its own addressing scope. Two different map
// steps each wrapping an identical branch "b1" with inner step "x" must
// not report a collision on "b1.x" -- at runtime each map iteration
// namespaces under its own <mapId>.<index>, so the two "b1.x" paths never
// actually share a result key.
{
  const branchBody = function () {
    return {
      id: 'b1',
      type: 'branch',
      cases: [
        {
          when: { step: 'x', field: 'y', operator: 'equals', value: 1 },
          steps: [{ id: 'x', type: 'shape', template: {} }],
        },
      ],
    };
  };
  const spec = {
    steps: [
      { id: 'map1', type: 'map', steps: [branchBody()] },
      { id: 'map2', type: 'map', steps: [branchBody()] },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'two map steps with identical nested subtrees produce no duplicate-result-key violations',
    countOf(violations, 'duplicate-result-key') === 0
  );
}

// -- duplicate-ID registry is scoped per container subtree: two steps -----
// -- with the same literal ID directly inside one map body DO collide -----
// Within a single map step's body, step IDs must still be unique -- the
// per-subtree scope isolates different map steps from each other, it does
// not exempt steps within the same map body from the ordinary
// duplicate-ID check.
{
  const spec = {
    steps: [
      {
        id: 'map1',
        type: 'map',
        steps: [
          { id: 'x', type: 'shape', template: {} },
          { id: 'x', type: 'shape', template: {} },
        ],
      },
    ],
    config: {},
  };
  const violations = validateSpec(spec);
  check(
    'two same-ID steps directly inside one map body are reported at steps[0].steps[1]',
    hasViolation(violations, 'duplicate-result-key', 'steps[0].steps[1]')
  );
}

// -- minimal valid spec (from SPEC_SCHEMA.md) returns an empty list --------
{
  const spec = {
    steps: [{ id: 'pass_through', type: 'shape', template: {} }],
    config: {},
  };
  const violations = validateSpec(spec);
  check('the minimal valid spec from the contract produces no violations', violations.length === 0);
}

console.log(passCount + ' passed, ' + failCount + ' failed');
process.exit(failCount === 0 ? 0 : 1);
