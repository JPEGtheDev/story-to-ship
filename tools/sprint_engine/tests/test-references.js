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

// -- same-track sequential reference: a later step in the same track ------
// -- referencing an earlier step in that same track resolves cleanly ------
// Pins the sameTrackLater carve-out: the ordering rule invalidates
// cross-track/concurrent references before the join, not an ordinary
// sequential reference within one track.
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
              { id: 'step1', type: 'shape', template: {} },
              {
                id: 'step2',
                type: 'gate',
                predicate: { step: 'trackA.step1', field: 'x', operator: 'equals', value: 1 },
              },
            ],
          },
        ],
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  check(
    'a same-track later step referencing an earlier step in the same track resolves cleanly',
    violations.length === 0
  );
}

// -- composite key referenced before the join is rejected ------------------
// Pins that the ordering restriction covers pattern/composite keys
// ("<trackId>.<retryId>.attempts.<n>"), not just exact ones.
{
  const spec = {
    steps: [
      {
        id: 'early',
        type: 'gate',
        predicate: { step: 'trackA.retry1.attempts.1', field: 'score', operator: 'gte', value: 1 },
      },
      {
        id: 'par1',
        type: 'parallel',
        tracks: [
          {
            id: 'trackA',
            steps: [
              {
                id: 'retry1',
                type: 'scored-retry',
                mode: 'keep-best',
                step: { id: 'rs1', type: 'shape', template: {} },
              },
            ],
          },
        ],
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  check(
    'a composite key referenced before its parallel step joins is reported at steps[0].predicate',
    hasViolation(violations, 'parallel-track-reference-before-join', 'steps[0].predicate')
  );
}

// -- nested-parallel track membership: a same-outer-track-later reference -
// -- through an inner parallel step still resolves cleanly ----------------
// outer (parallel) -> track A: [ a1 (shape), inner (parallel) -> track X:
// [ x1 (gate, predicate.step = 'A.a1') ] ]. x1 sits strictly after a1 in
// track A's own sequence -- a legal same-track-later reference -- even
// though x1 is additionally nested inside an inner parallel step's own
// track X, one level deeper.
{
  const spec = {
    steps: [
      {
        id: 'outer',
        type: 'parallel',
        tracks: [
          {
            id: 'A',
            steps: [
              { id: 'a1', type: 'shape', template: {} },
              {
                id: 'inner',
                type: 'parallel',
                tracks: [
                  {
                    id: 'X',
                    steps: [
                      {
                        id: 'x1',
                        type: 'gate',
                        predicate: { step: 'A.a1', field: 'x', operator: 'equals', value: 1 },
                      },
                    ],
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
  const violations = resolveReferences(spec);
  check(
    'a same-outer-track-later reference through a nested inner parallel step resolves cleanly',
    violations.length === 0
  );
}

// -- nested-parallel track membership: a genuinely cross-track reference --
// -- through an inner parallel step is still rejected ----------------------
// outer (parallel) -> track A: [ inner (parallel) -> track X: [ x1 (gate,
// predicate.step = 'B.b1') ] ], track B: [ b1 ]. x1 is nested inside track
// A (and track X), never inside track B -- referencing track B's result
// before the OUTER parallel's own join is still invalid, proving the fix
// does not over-allow genuinely cross-track references.
{
  const spec = {
    steps: [
      {
        id: 'outer',
        type: 'parallel',
        tracks: [
          {
            id: 'A',
            steps: [
              {
                id: 'inner',
                type: 'parallel',
                tracks: [
                  {
                    id: 'X',
                    steps: [
                      {
                        id: 'x1',
                        type: 'gate',
                        predicate: { step: 'B.b1', field: 'x', operator: 'equals', value: 1 },
                      },
                    ],
                  },
                ],
              },
            ],
          },
          { id: 'B', steps: [{ id: 'b1', type: 'shape', template: {} }] },
        ],
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  check(
    'a genuinely cross-track reference through a nested inner parallel step is still rejected',
    hasViolation(
      violations,
      'parallel-track-reference-before-join',
      'steps[0].tracks[0].steps[0].tracks[0].steps[0].predicate'
    )
  );
}

// -- container-key availability: a descendant nested inside a container's -
// -- own subtree cannot reference that container's own (not-yet-joined) ---
// -- result key --------------------------------------------------------
// outer (parallel) -> track A: [ inner (parallel) -> track X: [ x1 (gate,
// predicate.step = 'A.inner') ] ]. inner's own aggregate result cannot
// exist until inner's own join, which happens only after x1 finishes --
// x1 referencing inner's own key from inside inner's own subtree is a
// circular reference and must be rejected.
{
  const spec = {
    steps: [
      {
        id: 'outer',
        type: 'parallel',
        tracks: [
          {
            id: 'A',
            steps: [
              {
                id: 'inner',
                type: 'parallel',
                tracks: [
                  {
                    id: 'X',
                    steps: [
                      {
                        id: 'x1',
                        type: 'gate',
                        predicate: { step: 'A.inner', field: 'failures', operator: 'equals', value: 0 },
                      },
                    ],
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
  const violations = resolveReferences(spec);
  check(
    'a descendant inside a container\'s own subtree referencing that container\'s own key is rejected',
    hasViolation(
      violations,
      'parallel-track-reference-before-join',
      'steps[0].tracks[0].steps[0].tracks[0].steps[0].predicate'
    )
  );
}

// -- container-key availability: the same key referenced by the container's
// -- own later SIBLING in the same track (after the container has fully ---
// -- joined) resolves cleanly -- the fix must not over-reject -------------
// track A: [ inner (parallel with a track containing one step), a2 (gate,
// predicate.step = 'A.inner') ] -- a2 sits AFTER inner in the same track
// sequence, once inner has already joined.
{
  const spec = {
    steps: [
      {
        id: 'outer',
        type: 'parallel',
        tracks: [
          {
            id: 'A',
            steps: [
              {
                id: 'inner',
                type: 'parallel',
                tracks: [{ id: 'X', steps: [{ id: 'x1', type: 'shape', template: {} }] }],
              },
              {
                id: 'a2',
                type: 'gate',
                predicate: { step: 'A.inner', field: 'failures', operator: 'equals', value: 0 },
              },
            ],
          },
        ],
      },
    ],
    config: {},
  };
  const violations = resolveReferences(spec);
  check(
    'a later sibling in the same track referencing an already-joined inner container key resolves cleanly',
    violations.length === 0
  );
}

// -- container-key availability, deeper variant: the referencing site -----
// -- nested two containers down inside the open container is still --------
// -- rejected ------------------------------------------------------------
// inner -> track X -> innermost (parallel) -> track Y -> y1 referencing
// A.inner -- y1 is even more deeply nested inside inner's own open
// subtree than the shallow repro above.
{
  const spec = {
    steps: [
      {
        id: 'outer',
        type: 'parallel',
        tracks: [
          {
            id: 'A',
            steps: [
              {
                id: 'inner',
                type: 'parallel',
                tracks: [
                  {
                    id: 'X',
                    steps: [
                      {
                        id: 'innermost',
                        type: 'parallel',
                        tracks: [
                          {
                            id: 'Y',
                            steps: [
                              {
                                id: 'y1',
                                type: 'gate',
                                predicate: { step: 'A.inner', field: 'failures', operator: 'equals', value: 0 },
                              },
                            ],
                          },
                        ],
                      },
                    ],
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
  const violations = resolveReferences(spec);
  check(
    'a site nested two containers deeper inside the open container is still rejected',
    hasViolation(
      violations,
      'parallel-track-reference-before-join',
      'steps[0].tracks[0].steps[0].tracks[0].steps[0].tracks[0].steps[0].predicate'
    )
  );
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
