// Sprint runner: a workflow-runtime script that executes a sprint-engine
// spec end to end. This file has three parts, in order: this header (the
// workflow runtime's own `export const meta` dialect, plain literal data
// only), the engine-core region below (byte-identical to the region between
// the ===ENGINE-CORE-BEGIN=== / ===ENGINE-CORE-END=== markers in
// engine-core.js -- verified by skills/sprint-runner/tools/tests/inline-copy-check.sh,
// never hand-edited here), and the runner glue after it (small on purpose:
// the engine above owns all spec semantics: parsing, validation,
// step-sequencing, namespacing, spill handling, digest verification; this
// glue only wires the runtime's injected dispatch capability to the
// engine's own dispatch(step, context) contract and returns the outcome).
//
// Dialect note: this file is loaded by the workflow runtime, not by node
// directly. `node --check` is NOT a valid way to test whether the runtime
// will accept this file as loadable, in either direction: run-verified on
// Node v24 (this file, no package "type" set), `node --check` exits 0 on
// it -- ambiguous-module auto-detection accepts the `export const meta`
// header and the bare top-level `return` this dialect allows outside any
// function, so a passing `node --check` here is not evidence the runtime
// will load this file, and (per skills/sprint-runner/tools/RUNTIME_FACTS.md's
// "Runtime script dialect" section) a FAILING one on some other Node
// version or module-type configuration would not be evidence it won't,
// either. This is a non-signal, not a rejection: `node --check`'s result
// on this file must never be used as a gate either way. Runtime
// loadability is verified by the runtime itself, a separate later
// deliverable; the syntax evidence for the glue portion here is that it
// stays small enough to read by eye, plus the marker-region byte-match the
// inline-copy-check gate enforces on every run.

export const meta = {
  name: 'sprint-runner',
  description: 'Executes a sprint-engine spec end to end: parses the spec from args, dispatches every agent/gate/spill-writer/digest-verify step through the runtime, and returns the run outcome.',
  phases: [{ title: 'Run' }],
}

// ===ENGINE-CORE-BEGIN===

const SPEC_ENGINE_KNOWN_STEP_KINDS = ['agent', 'gate', 'shape', 'parallel', 'map', 'scored-retry', 'branch'];
const SPEC_ENGINE_CONTAINER_STEP_KINDS = ['parallel', 'map', 'scored-retry', 'branch'];
const SPEC_ENGINE_PREDICATE_OPERATORS = ['equals', 'lte', 'gte'];
const SPEC_ENGINE_SCORED_RETRY_MODES = ['first-passing', 'keep-best'];
const SPEC_ENGINE_GATE_VERDICTS = ['pass', 'fail', 'uncertain'];
const SPEC_ENGINE_RESERVED_LITERAL_SEGMENT = 'attempts';
const SPEC_ENGINE_MAX_CONTAINER_DEPTH = 3;
const SPEC_ENGINE_NUMERIC_SEGMENT_RE = /^[0-9]+$/;
const SPEC_ENGINE_UNDEFINED_SENTINEL = '<<undefined>>';
const SPEC_ENGINE_IF_BLOCK_RE = /\{\{#if\s+([^}]+?)\s*\}\}([\s\S]*?)\{\{\/if\}\}/;
const SPEC_ENGINE_PLACEHOLDER_RE = /\{\{\s*([^}]+?)\s*\}\}/;
const SPEC_ENGINE_IF_TOKEN_RE = /\{\{\s*(#if\b[^}]*|\/if)\s*\}\}/g;
// SPEC_ENGINE_SPILL_THRESHOLD_BYTES -- see the "Oversized-output spill
// contract" section of SPEC_SCHEMA.md: "exactly 40,000 bytes." No config
// knob overrides this; it is a module constant by design (the threshold is
// part of the contract every producer agent is told to honor, not a
// per-run tuning surface). Used by specEngineApplySpillGuard below as the
// engine-side backstop boundary: a string outcome field's UTF-8 byte length
// (via specEngineUtf8Encode, never str.length) strictly GREATER than this
// constant is a producer-contract violation; a field at exactly this many
// bytes is legal and never triggers the guard.
const SPEC_ENGINE_SPILL_THRESHOLD_BYTES = 40000;
// SPEC_ENGINE_SHA256_HEX_RE -- a 64-character lowercase hex string, the
// shape both a spill receipt's own "sha256" field and a digest-verify
// agent's returned digest must match. Shared by specEngineApplySpillGuard
// and the by-path digest-verify guard below so both accept and reject the
// identical shape.
const SPEC_ENGINE_SHA256_HEX_RE = /^[0-9a-f]{64}$/;
// specEngineIsUnsafePathSegment(segment) -- the containment rule for every
// RAW (pre-composition) segment that participates in a spill target path
// this engine constructs. validateSpec places NO charset restriction on a
// step id beyond non-empty-string and the reserved-segment rules (see
// visitStep above): a step id of "a b" (a space) or "date: 2026" is
// validator-legal and must still be able to spill. This function is
// therefore a DENYLIST, not an allowlist -- it rejects only content that
// is genuinely unsafe for a path segment, not content the validator itself
// would reject:
//   - not a string (a missing/non-string id reaching this point despite
//     validateSpec -- e.g. specEngineExecute called directly, bypassing
//     validation -- must fail closed here rather than throw downstream);
//   - the empty string;
//   - contains '/' or '\' (would let the constructed path escape
//     `spillDir` via an extra path separator);
//   - contains '.' (the namespace separator this engine's own composed
//     keys use -- see the "raw segments, not a composed string" note on
//     specEngineApplySpillGuard below for why a raw segment must never
//     itself contain one). This one rule ALSO subsumes any '..'
//     containment concern: a '..' segment always contains at least one
//     '.', so it is already rejected by the dot ban above -- no separate
//     '..' check is needed.
// Applied to every RAW segment (never to an already-'.'-joined string) and
// to the oversized field's own name (both are untrusted -- a spec author
// controls step/track/branch ids, and a dispatched agent's own return
// value controls field names). Engine-generated segments (a map
// iteration's numeric index, the literal "attempts" for scored-retry) are
// passed through the SAME check as author-controlled ones rather than
// being special-cased out of it -- they always pass, since neither a
// digit string nor the literal "attempts" ever contains '.', '/', '\', or
// is empty.
function specEngineIsUnsafePathSegment(segment) {
  return typeof segment !== 'string' || segment.length === 0 || segment.indexOf('/') !== -1 || segment.indexOf('\\') !== -1 || segment.indexOf('.') !== -1;
}

function specEngineIsPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

// specEngineIsFiniteNumber(value) -- strict type check, no string-to-number
// coercion: true only for an actual finite JS number (not NaN, not
// +/-Infinity, not a numeric string). Backs the lte/gte non-numeric-operand
// halt in specEngineEvalPredicate below.
function specEngineIsFiniteNumber(value) {
  return typeof value === 'number' && isFinite(value);
}

function specEngineIsReservedSegment(segment) {
  return segment === SPEC_ENGINE_RESERVED_LITERAL_SEGMENT || SPEC_ENGINE_NUMERIC_SEGMENT_RE.test(String(segment));
}

function specEngineMakeViolation(path, diagnostic, message) {
  return { path: path, diagnostic: diagnostic, message: message };
}

// validateSpec(spec) -- see file header for the contract. Traces every
// diagnostic below to a specific section of SPEC_SCHEMA.md; the section is
// named in each comment beside the check it backs.
function validateSpec(spec) {
  const violations = [];

  if (!specEngineIsPlainObject(spec)) {
    violations.push(
      specEngineMakeViolation('', 'spec-not-object', 'A spec must be a JSON object with "steps" and "config".')
    );
    return violations;
  }

  // "A spec has two top-level parts: a steps array ... and a config object."
  const stepsIsArray = Array.isArray(spec.steps);
  if (!stepsIsArray) {
    violations.push(
      specEngineMakeViolation('steps', 'steps-not-array', 'spec.steps must be an array of step objects.')
    );
  }

  // Result-key namespacing grammar: "Every step's result lands in the
  // run's results map under a key." Two different steps computing to the
  // same key is exactly the collision the reserved-segments rule below
  // guards the engine's own namespacing against; a registry generalizes
  // that same collision check to author-declared step IDs colliding with
  // each other (plain duplicates) or with another step's namespaced key
  // (dotted collisions).
  //
  // Per the "Container authoring syntax" section's scoping rule, a step ID
  // must be unique within its addressing scope, not across the whole
  // spec: the top-level spec is one scope; a parallel track and a branch
  // step's cases-and-default reuse their enclosing scope's registry
  // (their results are still distinguished within it, by trackId/branchId
  // prefixing); a map body and a scored-retry's wrapped step each open a
  // brand new, isolated registry, because no ratified wording gives their
  // contents a namespaced key that would let two different map/
  // scored-retry steps' identical subtrees collide in reality.
  const rootRegistry = Object.create(null);
  let hasAgentStep = false;

  function checkPredicateOperator(predicate, predicatePath) {
    // "Predicate operator vocabulary": equals, lte, gte are the only
    // three legal operators.
    const operator = predicate.operator;
    if (SPEC_ENGINE_PREDICATE_OPERATORS.indexOf(operator) === -1) {
      violations.push(
        specEngineMakeViolation(
          predicatePath + '.operator',
          'unknown-predicate-operator',
          'Predicate operator "' + operator + '" is not one of the three recognized operators (equals, lte, gte).'
        )
      );
    }
  }

  function checkScoredRetryFields(step, path) {
    // Field-optionality table: scored-retry.mode REQUIRED (first-passing
    // or keep-best); scored-retry.threshold REQUIRED for first-passing,
    // OPTIONAL for keep-best.
    const mode = step.mode;
    if (SPEC_ENGINE_SCORED_RETRY_MODES.indexOf(mode) === -1) {
      if (typeof mode === 'undefined') {
        violations.push(
          specEngineMakeViolation(
            path + '.mode',
            'scored-retry-mode-required',
            'scored-retry step "' + step.id + '" is missing the required "mode" field.'
          )
        );
      } else {
        violations.push(
          specEngineMakeViolation(
            path + '.mode',
            'scored-retry-mode-invalid',
            'scored-retry step "' + step.id + '" has mode "' + mode + '", which is not "first-passing" or "keep-best".'
          )
        );
      }
    } else if (mode === 'first-passing' && typeof step.threshold === 'undefined') {
      violations.push(
        specEngineMakeViolation(
          path + '.threshold',
          'scored-retry-threshold-required',
          'scored-retry step "' + step.id + '" uses mode "first-passing" and must declare "threshold".'
        )
      );
    }
  }

  function checkOutputSchemaReservedSegments(step, type, path) {
    // Reserved segments: "attempts" and any bare-numeric segment are
    // illegal "as a top-level output-schema field name on a scored-retry
    // step or a map step."
    if (type !== 'map' && type !== 'scored-retry') {
      return;
    }
    const outputSchema = step.outputSchema;
    if (!specEngineIsPlainObject(outputSchema) || !specEngineIsPlainObject(outputSchema.properties)) {
      return;
    }
    const propertyNames = Object.keys(outputSchema.properties);
    for (let i = 0; i < propertyNames.length; i += 1) {
      const propertyName = propertyNames[i];
      if (specEngineIsReservedSegment(propertyName)) {
        violations.push(
          specEngineMakeViolation(
            path + '.outputSchema.properties.' + propertyName,
            'reserved-segment',
            'Output-schema top-level field "' +
              propertyName +
              '" on a ' +
              type +
              ' step uses a reserved segment ("attempts" or a bare-numeric segment).'
          )
        );
      }
    }
  }

  // registry is the id-uniqueness scope this step's own key is checked
  // and registered against (see the scoping note above). resultKeyPrefix
  // is null when this step's namespaced result key is not defined by the
  // grammar at this granularity (a track or branch step with no usable
  // id of its own -- an edge case, since a missing id is already reported
  // separately); '' means "top of this scope, key is the id itself"; any
  // other string is the dotted prefix this step's id is appended to.
  function visitStep(step, path, containerDepth, registry, resultKeyPrefix) {
    if (!specEngineIsPlainObject(step)) {
      violations.push(specEngineMakeViolation(path, 'step-not-object', 'Each step must be a JSON object.'));
      return;
    }

    const id = step.id;
    if (typeof id !== 'string' || id.length === 0) {
      violations.push(
        specEngineMakeViolation(path + '.id', 'missing-step-id', 'Every step must declare a non-empty string "id".')
      );
    } else {
      // Reserved segments: "attempts" and any bare-numeric segment are
      // illegal "as a spec step ID anywhere in the spec."
      if (specEngineIsReservedSegment(id)) {
        violations.push(
          specEngineMakeViolation(
            path + '.id',
            'reserved-segment',
            'Step ID "' +
              id +
              '" uses the reserved segment "attempts" or a bare-numeric segment, which collides with the engine\'s own result-key namespacing.'
          )
        );
      }
      if (resultKeyPrefix !== null) {
        const resultKey = resultKeyPrefix === '' ? id : resultKeyPrefix + '.' + id;
        if (Object.prototype.hasOwnProperty.call(registry, resultKey)) {
          violations.push(
            specEngineMakeViolation(
              path,
              'duplicate-result-key',
              'Step ID "' +
                id +
                '" produces the result-key "' +
                resultKey +
                '", which collides with the step already at "' +
                registry[resultKey] +
                '" within the same addressing scope.'
            )
          );
        } else {
          registry[resultKey] = path;
        }
      }
    }

    // "Step kinds": seven kinds are recognized; anything else is rejected.
    const type = step.type;
    if (SPEC_ENGINE_KNOWN_STEP_KINDS.indexOf(type) === -1) {
      violations.push(
        specEngineMakeViolation(
          path + '.type',
          'unknown-step-kind',
          'Step kind "' + type + '" is not one of the seven recognized step kinds.'
        )
      );
      return;
    }

    if (type === 'agent') {
      hasAgentStep = true;
    }

    checkOutputSchemaReservedSegments(step, type, path);

    if (type === 'gate' && specEngineIsPlainObject(step.predicate)) {
      checkPredicateOperator(step.predicate, path + '.predicate');
    }

    const isContainer = SPEC_ENGINE_CONTAINER_STEP_KINDS.indexOf(type) !== -1;
    const childDepth = isContainer ? containerDepth + 1 : containerDepth;
    if (isContainer && childDepth > SPEC_ENGINE_MAX_CONTAINER_DEPTH) {
      // "Nesting depth cap": rejected "with an error naming where the
      // excess nesting occurs" -- that is this step, the one whose own
      // container depth exceeds the cap of 3.
      violations.push(
        specEngineMakeViolation(
          path,
          'nesting-depth-exceeded',
          'Container step "' +
            (typeof id === 'string' ? id : '?') +
            '" nests to depth ' +
            childDepth +
            ', exceeding the cap of ' +
            SPEC_ENGINE_MAX_CONTAINER_DEPTH +
            ' container levels.'
        )
      );
    }

    if (type === 'parallel') {
      if (Array.isArray(step.tracks)) {
        for (let ti = 0; ti < step.tracks.length; ti += 1) {
          const track = step.tracks[ti];
          const trackPath = path + '.tracks[' + ti + ']';
          if (specEngineIsPlainObject(track) && Array.isArray(track.steps)) {
            const trackId = typeof track.id === 'string' ? track.id : null;
            for (let si = 0; si < track.steps.length; si += 1) {
              // Same registry: a track's results are namespaced within
              // the enclosing scope by trackId, not isolated from it.
              visitStep(track.steps[si], trackPath + '.steps[' + si + ']', childDepth, registry, trackId);
            }
          }
        }
      }
    } else if (type === 'map') {
      if (Array.isArray(step.steps)) {
        // Fresh, isolated registry: no ratified wording gives a map
        // body's steps a namespaced key distinct per map step, so two
        // different map steps' identical bodies must not collide with
        // each other -- but IDs must still be unique within one body.
        const mapBodyRegistry = Object.create(null);
        for (let mi = 0; mi < step.steps.length; mi += 1) {
          visitStep(step.steps[mi], path + '.steps[' + mi + ']', childDepth, mapBodyRegistry, '');
        }
      }
    } else if (type === 'scored-retry') {
      checkScoredRetryFields(step, path);
      if (specEngineIsPlainObject(step.step)) {
        // Fresh, isolated registry, for the same reason as a map body.
        const retryBodyRegistry = Object.create(null);
        visitStep(step.step, path + '.step', childDepth, retryBodyRegistry, '');
      }
    } else if (type === 'branch') {
      const branchId = typeof id === 'string' ? id : null;
      if (Array.isArray(step.cases)) {
        for (let ci = 0; ci < step.cases.length; ci += 1) {
          const branchCase = step.cases[ci];
          const casePath = path + '.cases[' + ci + ']';
          if (specEngineIsPlainObject(branchCase)) {
            if (specEngineIsPlainObject(branchCase.when)) {
              checkPredicateOperator(branchCase.when, casePath + '.when');
            }
            if (Array.isArray(branchCase.steps)) {
              for (let bsi = 0; bsi < branchCase.steps.length; bsi += 1) {
                // Same registry: a branch step's cases and default are
                // namespaced within the enclosing scope by the branch
                // step's own id, not isolated from it.
                visitStep(branchCase.steps[bsi], casePath + '.steps[' + bsi + ']', childDepth, registry, branchId);
              }
            }
          }
        }
      }
      if (specEngineIsPlainObject(step.default) && Array.isArray(step.default.steps)) {
        for (let dsi = 0; dsi < step.default.steps.length; dsi += 1) {
          visitStep(step.default.steps[dsi], path + '.default.steps[' + dsi + ']', childDepth, registry, branchId);
        }
      }
    }
  }

  if (stepsIsArray) {
    for (let i = 0; i < spec.steps.length; i += 1) {
      visitStep(spec.steps[i], 'steps[' + i + ']', 0, rootRegistry, '');
    }
  }

  if (hasAgentStep) {
    // Field-optionality table: config.spillDir REQUIRED whenever the spec
    // contains any agent step; "spillDir must be an absolute path; a
    // relative path is rejected at validation with a named diagnostic."
    const config = specEngineIsPlainObject(spec.config) ? spec.config : null;
    const spillDir = config ? config.spillDir : undefined;
    if (typeof spillDir !== 'string' || spillDir.length === 0) {
      violations.push(
        specEngineMakeViolation(
          'config.spillDir',
          'spilldir-required',
          'config.spillDir is required whenever the spec contains any agent step.'
        )
      );
    } else if (spillDir.charAt(0) !== '/') {
      violations.push(
        specEngineMakeViolation(
          'config.spillDir',
          'spilldir-not-absolute',
          'config.spillDir must be an absolute path; "' + spillDir + '" is relative.'
        )
      );
    }
  }

  return violations;
}

// resolveReferences(spec) -- see file header for the contract. Traces every
// diagnostic below to a specific section of SPEC_SCHEMA.md; the section is
// named in each comment beside the check it backs.
function resolveReferences(spec) {
  const violations = [];

  if (!specEngineIsPlainObject(spec) || !Array.isArray(spec.steps)) {
    return violations;
  }

  // Every declared result key, per the "Result-key namespacing grammar"
  // section. Two shapes:
  //  - an EXACT key (a plain step id, a parallel step's own aggregate key,
  //    or a scored-retry step's winner key).
  //  - a PATTERN key (a map step's "<mapId>.<index>" or a scored-retry
  //    step's "<retryId>.attempts.<n>"): the item count / attempt count is
  //    a runtime fact this static pass does not know, so any bare-numeric
  //    segment after the declared base is accepted.
  // Both carry ordering metadata: ownerTrackId/joinOrderRef/declaredAtOrder
  // are non-null only for a key declared while inside a parallel track,
  // and back the "parallel ordering rule" checked below.
  const declaredExactKeys = [];
  const declaredPatternKeys = [];

  // Every reference site: a predicate's {step, field} (gate.predicate or a
  // branch case's "when"), or one {{...}} template placeholder found in a
  // shape step's "template" field.
  const referenceSites = [];

  let visitOrderCounter = 0;

  // declaredAtOrder is the depth-first search (DFS) order at which the declaring step STARTS
  // (when the entry is created); availableAtOrder is the DFS order at
  // which the declared key's value actually becomes readable. For a leaf
  // step (agent/gate/shape) these are the same instant -- its result is
  // whatever it is as soon as it is visited, since it has no subtree.
  // For a container step's own key (a parallel's aggregate, a
  // scored-retry's winner/attempts), the value depends on that
  // container's own subtree finishing -- its own join -- so
  // availableAtOrder starts equal to declaredAtOrder here and is
  // overwritten by the caller once that subtree's end order is known (see
  // the parallel/map/scored-retry recursion blocks below). The entry
  // object is returned so the caller can make that later update.
  function declareExactKey(key, trackCtx, visitOrder) {
    const entry = {
      key: key,
      ownerTrackId: trackCtx.trackId,
      joinOrderRef: trackCtx.joinOrderRef,
      declaredAtOrder: visitOrder,
      availableAtOrder: visitOrder,
    };
    declaredExactKeys.push(entry);
    return entry;
  }

  function declarePatternKey(base, trackCtx, visitOrder) {
    const entry = {
      base: base,
      ownerTrackId: trackCtx.trackId,
      joinOrderRef: trackCtx.joinOrderRef,
      declaredAtOrder: visitOrder,
      availableAtOrder: visitOrder,
    };
    declaredPatternKeys.push(entry);
    return entry;
  }

  // "Template forms and reference resolution": three forms are recognized.
  // {{step.field}} and {{values.PATH}} are single placeholders; {{#if}} is
  // a block form whose condition is a reference in the same vocabulary --
  // "this document does not extend their behavior beyond that literal
  // syntax," so the closing {{/if}} carries no reference and the
  // condition is read out and checked exactly like any other placeholder.
  function extractPlaceholders(text) {
    const refs = [];
    const re = /\{\{\s*([^}]+?)\s*\}\}/g;
    let m = re.exec(text);
    while (m !== null) {
      const inner = m[1];
      if (inner !== '/if') {
        if (inner.indexOf('#if') === 0) {
          // Checking this condition as a resolvable reference is this
          // implementation's own extension: SPEC_SCHEMA.md names {{#if}}
          // as "recognized template syntax" but states "this document does
          // not extend their behavior beyond that literal syntax," and
          // does not itself specify that the condition must resolve.
          const cond = inner.slice(3).trim();
          if (cond.length > 0) {
            refs.push(cond);
          }
        } else {
          refs.push(inner);
        }
      }
      m = re.exec(text);
    }
    return refs;
  }

  // A shape step's "template" field is "an object whose string leaves may
  // contain {{...}} placeholders" -- walk every string leaf.
  function collectTemplateSites(value, path, visitOrder, trackCtx) {
    if (typeof value === 'string') {
      extractPlaceholders(value).forEach(function (ref) {
        referenceSites.push({
          path: path,
          kind: 'template',
          ref: ref,
          visitOrder: visitOrder,
          ancestorTrackIds: trackCtx.ancestorTrackIds,
        });
      });
    } else if (Array.isArray(value)) {
      for (let i = 0; i < value.length; i += 1) {
        collectTemplateSites(value[i], path + '[' + i + ']', visitOrder, trackCtx);
      }
    } else if (specEngineIsPlainObject(value)) {
      const keys = Object.keys(value);
      for (let i = 0; i < keys.length; i += 1) {
        collectTemplateSites(value[keys[i]], path + '.' + keys[i], visitOrder, trackCtx);
      }
    }
  }

  function collectPredicateSite(predicate, path, visitOrder, trackCtx) {
    // A predicate's "step" names the step/result key it reads; "field" is
    // a separate attribute (possibly itself dotted, e.g. a spilled
    // pointer's "content.bytes"), so unlike a template placeholder,
    // predicate.step needs no split -- it must equal a declared key
    // exactly.
    if (typeof predicate.step !== 'string') {
      return;
    }
    referenceSites.push({
      path: path,
      kind: 'predicate',
      ref: predicate.step,
      visitOrder: visitOrder,
      ancestorTrackIds: trackCtx.ancestorTrackIds,
    });
  }

  // namespacePrefix: '' at the top of an addressing scope whose steps key
  // by their own id; a non-empty string is the dotted prefix a step's id
  // is appended to (a trackId or a branch step's own id, per the
  // "Container authoring syntax" scoping rule -- this prefix REPLACES
  // whatever prefix was already in effect, it does not compose with it,
  // matching the grammar's literal "<trackId>.<stepId>" / "<branchId>.
  // <stepId>" formats). null means this step's own key is not defined by
  // the grammar at all -- inside a map step's body, or a scored-retry
  // step's wrapped step, per the "Map-body addressing below the iteration
  // boundary is not specified" caveat -- so nothing is declared for it,
  // though its own reference sites are still collected and checked.
  //
  // trackCtx: { trackId, joinOrderRef, ancestorTrackIds } identifies the
  // nearest enclosing parallel track, if any (trackId, used when a key is
  // DECLARED here -- a key's own namespace is always relative to its
  // nearest track, per the grammar's single-level "<trackId>.<stepId>"
  // format), the shared mutable holder for that nearest track's own
  // parallel step's join point (joinOrderRef, filled in once every track
  // of that parallel step has been visited), and the full chain of every
  // track this step is nested within at any depth, outermost first
  // (ancestorTrackIds, used when a step is a REFERRER -- a parallel step
  // nested inside a track does not sever that track's membership for its
  // own tracks' descendants, so the same-track-later carve-out below must
  // check the whole chain, not just the nearest track). trackCtx.trackId
  // is null outside any track, meaning keys declared there carry no
  // ordering restriction.
  function visitStep(step, path, namespacePrefix, trackCtx) {
    if (!specEngineIsPlainObject(step)) {
      return;
    }
    const visitOrder = visitOrderCounter;
    visitOrderCounter += 1;

    const id = step.id;
    const ownKey =
      typeof id === 'string' && id.length > 0 && namespacePrefix !== null
        ? namespacePrefix === ''
          ? id
          : namespacePrefix + '.' + id
        : null;
    const type = step.type;

    // "Predicate operator vocabulary" / branch case predicates: reference
    // sites live on a gate step's own predicate and a branch case's "when".
    if (type === 'gate' && specEngineIsPlainObject(step.predicate)) {
      collectPredicateSite(step.predicate, path + '.predicate', visitOrder, trackCtx);
    }
    // "Template forms and reference resolution": a shape step's template.
    if (type === 'shape' && specEngineIsPlainObject(step.template)) {
      collectTemplateSites(step.template, path + '.template', visitOrder, trackCtx);
    }

    // ownKeyEntry / attemptsPatternEntry: captured so the container
    // recursion blocks below can push their availableAtOrder out to the
    // container's own subtree-end order, once that order is known.
    let ownKeyEntry = null;
    let attemptsPatternEntry = null;

    if (ownKey !== null) {
      if (type === 'parallel') {
        // "A parallel step's own result also carries aggregate counts
        // alongside the per-track results: {failures, successes, total}."
        // Not available until this parallel step's own join, below.
        ownKeyEntry = declareExactKey(ownKey, trackCtx, visitOrder);
      } else if (type === 'scored-retry') {
        // "the attempt the step actually kept ... is additionally
        // recorded at the plain <retryId> key" plus the per-attempt
        // "<retryId>.attempts.<n>" pattern. Neither is available until
        // the wrapped step's own subtree finishes, below.
        ownKeyEntry = declareExactKey(ownKey, trackCtx, visitOrder);
        attemptsPatternEntry = declarePatternKey(ownKey + '.attempts', trackCtx, visitOrder);
      } else if (type === 'map') {
        // "<mapId>.<index>" -- the item count is a runtime fact, not
        // statically known, so any bare-numeric index is accepted. Not
        // available until the map body's own subtree finishes, below.
        ownKeyEntry = declarePatternKey(ownKey, trackCtx, visitOrder);
      } else if (type !== 'branch') {
        // agent, gate, shape: "the key is just its own step ID," available
        // as soon as this leaf step is visited -- no subtree to wait on.
        declareExactKey(ownKey, trackCtx, visitOrder);
      }
      // branch: no key of its own is documented for the branch step
      // itself -- only for the steps nested in its cases/default, below.
    }

    if (type === 'parallel' && Array.isArray(step.tracks)) {
      // Ordering rule: "a step positioned after the parallel step can
      // reference any track's namespaced results once the parallel step
      // has completed; referencing a track's step result from a step
      // positioned before the parallel step's join ... is invalid." One
      // shared joinOrderRef is filled in once every track has been
      // visited; every key declared inside any of this parallel step's
      // tracks points at it.
      const joinOrderRef = { value: null };
      for (let ti = 0; ti < step.tracks.length; ti += 1) {
        const track = step.tracks[ti];
        if (specEngineIsPlainObject(track) && Array.isArray(track.steps)) {
          const trackId = typeof track.id === 'string' ? track.id : null;
          // Extend, don't replace: a track nested inside an outer track
          // (via an inner parallel step) is still a member of that outer
          // track too, for same-track-later reference purposes.
          const ancestorTrackIds = trackId !== null ? trackCtx.ancestorTrackIds.concat([trackId]) : trackCtx.ancestorTrackIds;
          const childTrackCtx = { trackId: trackId, joinOrderRef: joinOrderRef, ancestorTrackIds: ancestorTrackIds };
          for (let si = 0; si < track.steps.length; si += 1) {
            visitStep(track.steps[si], path + '.tracks[' + ti + '].steps[' + si + ']', trackId, childTrackCtx);
          }
        }
      }
      joinOrderRef.value = visitOrderCounter - 1;
      // This parallel step's own aggregate key (failures/successes/total)
      // is not readable until this same join point -- a descendant inside
      // any of its own tracks referencing it is a circular reference.
      if (ownKeyEntry !== null) {
        ownKeyEntry.availableAtOrder = joinOrderRef.value;
      }
    } else if (type === 'map' && Array.isArray(step.steps)) {
      for (let mi = 0; mi < step.steps.length; mi += 1) {
        visitStep(step.steps[mi], path + '.steps[' + mi + ']', null, trackCtx);
      }
      // This map step's own per-item key is not readable until its body's
      // own subtree finishes.
      if (ownKeyEntry !== null) {
        ownKeyEntry.availableAtOrder = visitOrderCounter - 1;
      }
    } else if (type === 'scored-retry' && specEngineIsPlainObject(step.step)) {
      visitStep(step.step, path + '.step', null, trackCtx);
      // Neither the winner key nor any attempt is readable until the
      // wrapped step's own subtree finishes.
      const retrySubtreeEnd = visitOrderCounter - 1;
      if (ownKeyEntry !== null) {
        ownKeyEntry.availableAtOrder = retrySubtreeEnd;
      }
      if (attemptsPatternEntry !== null) {
        attemptsPatternEntry.availableAtOrder = retrySubtreeEnd;
      }
    } else if (type === 'branch') {
      const branchId = typeof id === 'string' ? id : null;
      if (Array.isArray(step.cases)) {
        for (let ci = 0; ci < step.cases.length; ci += 1) {
          const branchCase = step.cases[ci];
          const casePath = path + '.cases[' + ci + ']';
          if (specEngineIsPlainObject(branchCase)) {
            if (specEngineIsPlainObject(branchCase.when)) {
              collectPredicateSite(branchCase.when, casePath + '.when', visitOrder, trackCtx);
            }
            if (Array.isArray(branchCase.steps)) {
              for (let bsi = 0; bsi < branchCase.steps.length; bsi += 1) {
                visitStep(branchCase.steps[bsi], casePath + '.steps[' + bsi + ']', branchId, trackCtx);
              }
            }
          }
        }
      }
      if (specEngineIsPlainObject(step.default) && Array.isArray(step.default.steps)) {
        for (let dsi = 0; dsi < step.default.steps.length; dsi += 1) {
          visitStep(step.default.steps[dsi], path + '.default.steps[' + dsi + ']', branchId, trackCtx);
        }
      }
    }
  }

  const rootTrackCtx = { trackId: null, joinOrderRef: null, ancestorTrackIds: [] };
  for (let i = 0; i < spec.steps.length; i += 1) {
    visitStep(spec.steps[i], 'steps[' + i + ']', '', rootTrackCtx);
  }

  // "Template split rule": "a template reference resolves by matching the
  // longest declared step key that is a prefix of the reference;
  // everything after that matched prefix is the field path ... This also
  // covers a declared step key that happens to be a prefix of another
  // declared step key -- the longest match wins."
  function resolveDotted(ref) {
    let best = null;
    function considerMatch(matchedKey, fieldPath, entry) {
      if (best === null || matchedKey.length > best.matchedKey.length) {
        best = { matchedKey: matchedKey, fieldPath: fieldPath, entry: entry };
      }
    }
    for (let i = 0; i < declaredExactKeys.length; i += 1) {
      const entry = declaredExactKeys[i];
      if (ref === entry.key) {
        considerMatch(entry.key, '', entry);
      } else if (ref.indexOf(entry.key + '.') === 0) {
        considerMatch(entry.key, ref.slice(entry.key.length + 1), entry);
      }
    }
    for (let i = 0; i < declaredPatternKeys.length; i += 1) {
      const entry = declaredPatternKeys[i];
      const prefix = entry.base + '.';
      if (ref.indexOf(prefix) === 0) {
        const rest = ref.slice(prefix.length);
        const m = /^([0-9]+)(?:\.(.*))?$/.exec(rest);
        if (m) {
          considerMatch(entry.base + '.' + m[1], m[2] || '', entry);
        }
      }
    }
    return best;
  }

  function declaredKeysSummary() {
    const parts = declaredExactKeys.map(function (e) {
      return e.key;
    });
    declaredPatternKeys.forEach(function (e) {
      parts.push(e.base + '.<n>');
    });
    return parts.length > 0 ? parts.join(', ') : '(no result keys declared)';
  }

  for (let si = 0; si < referenceSites.length; si += 1) {
    const site = referenceSites[si];

    // "{{values.PATH}} references resolve against config values, not step
    // results" -- a different namespace this static pass does not check,
    // since no ratified wording specifies config.values' structure.
    if (site.kind === 'template' && site.ref.indexOf('values.') === 0) {
      continue;
    }

    const match = resolveDotted(site.ref);
    // A predicate's "step" is a standalone attribute (not a dotted
    // path with a field suffix baked in, per collectPredicateSite above),
    // so it must equal a declared key exactly -- no leftover field path.
    const resolved = site.kind === 'predicate' ? match !== null && match.fieldPath === '' && match.matchedKey === site.ref : match !== null;

    if (!resolved) {
      violations.push(
        specEngineMakeViolation(
          site.path,
          site.kind === 'predicate' ? 'dangling-predicate-reference' : 'dangling-template-reference',
          (site.kind === 'predicate' ? 'Predicate' : 'Template') +
            ' reference at "' +
            site.path +
            '" names "' +
            site.ref +
            '", which does not resolve to any declared result key. Declared keys: ' +
            declaredKeysSummary() +
            '.'
        )
      );
      continue;
    }

    // Ordering rule: only keys declared inside a parallel track carry this
    // restriction (entry.ownerTrackId !== null); every other key kind
    // (plain, branch-nested, map, scored-retry) is unrestricted.
    const entry = match.entry;
    if (entry.ownerTrackId !== null) {
      const joinOrder = entry.joinOrderRef ? entry.joinOrderRef.value : null;
      const afterJoin = joinOrder !== null && site.visitOrder > joinOrder;
      // The referrer may be nested inside the owning track at any depth
      // (e.g. inside an inner parallel step that is itself one of that
      // track's steps) -- membership is chain-wide, not nearest-track-only.
      // The gate is availableAtOrder, not declaredAtOrder: a container
      // key's value isn't readable until that container's own subtree
      // (its own join) finishes, so a site nested inside the declaring
      // container's own still-open subtree can never satisfy this carve-
      // out for that container's key, even though it is chain-wide a
      // member of the same track.
      const sameTrackLater =
        site.ancestorTrackIds.indexOf(entry.ownerTrackId) !== -1 && site.visitOrder > entry.availableAtOrder;
      if (!afterJoin && !sameTrackLater) {
        violations.push(
          specEngineMakeViolation(
            site.path,
            'parallel-track-reference-before-join',
            (site.kind === 'predicate' ? 'Predicate' : 'Template') +
              ' reference at "' +
              site.path +
              '" names "' +
              site.ref +
              '", a result from track "' +
              entry.ownerTrackId +
              '" of a parallel step that has not joined yet at this point in the spec.'
          )
        );
      }
    }
  }

  return violations;
}

// specEngineResolveFieldPath(root, fieldPath) walks a dotted field path
// (e.g. "content.bytes") into a step's result object, the same
// hasOwnProperty-guarded walk validateSpec/resolveReferences use elsewhere
// in this file. Returns { resolved: false } as soon as any segment is
// missing or the value being indexed into is not a plain object; otherwise
// { resolved: true, value } with the final value reached.
function specEngineResolveFieldPath(root, fieldPath) {
  if (typeof fieldPath !== 'string' || fieldPath.length === 0) {
    return { resolved: false };
  }
  const segments = fieldPath.split('.');
  let cur = root;
  for (let i = 0; i < segments.length; i += 1) {
    const segment = segments[i];
    if (!specEngineIsPlainObject(cur) || !Object.prototype.hasOwnProperty.call(cur, segment)) {
      return { resolved: false };
    }
    cur = cur[segment];
  }
  return { resolved: true, value: cur };
}

// specEngineMakeHalt(path, diagnostic, message, sentinelValue) builds a
// halt outcome for specEngineEvalPredicate, reusing specEngineMakeViolation
// for the shared {path, diagnostic, message} shape and adding the `halted`
// flag plus, for the undefined-sentinel case, the literal recorded value.
function specEngineMakeHalt(path, diagnostic, message, sentinelValue) {
  const halt = specEngineMakeViolation(path, diagnostic, message);
  halt.halted = true;
  if (typeof sentinelValue !== 'undefined') {
    halt.value = sentinelValue;
  }
  return halt;
}

// specEngineEvalPredicate(predicate, results) -- see file header for the
// contract. Traces every diagnostic below to a specific section of
// SPEC_SCHEMA.md, the same way validateSpec and resolveReferences do.
//
// `predicate.step` is looked up as an exact key into `results`, matching
// how resolveReferences treats a predicate's "step" attribute (a
// standalone key, not a dotted reference needing the longest-prefix split
// a template placeholder needs). `predicate.field` is then walked,
// segment by segment, into that step's result value.
function specEngineEvalPredicate(predicate, results) {
  const resultsMap = specEngineIsPlainObject(results) ? results : Object.create(null);
  const step = specEngineIsPlainObject(predicate) ? predicate.step : undefined;
  const field = specEngineIsPlainObject(predicate) ? predicate.field : undefined;
  const operator = specEngineIsPlainObject(predicate) ? predicate.operator : undefined;
  const expected = specEngineIsPlainObject(predicate) ? predicate.value : undefined;

  const stepKnown = typeof step === 'string' && Object.prototype.hasOwnProperty.call(resultsMap, step);
  const fieldResolution = stepKnown ? specEngineResolveFieldPath(resultsMap[step], field) : { resolved: false };

  if (!stepKnown || !fieldResolution.resolved) {
    // "Undefined-sentinel rule": "A predicate's step/field lookup can fail
    // to resolve -- the named step was never declared, or the field does
    // not exist on that step's result. ... the engine records the literal
    // sentinel value <<undefined>> for the unresolved operand and halts
    // the run ... This sentinel-and-halt rule applies to lte and gte the
    // same way it applies to equals."
    return specEngineMakeHalt(
      step + '.' + field,
      'predicate-operand-unresolved',
      'Predicate operand for step "' + step + '", field "' + field + '" does not resolve; recording the ' +
        SPEC_ENGINE_UNDEFINED_SENTINEL + ' sentinel and halting.',
      SPEC_ENGINE_UNDEFINED_SENTINEL
    );
  }

  const operand = fieldResolution.value;

  if (specEngineIsPlainObject(operand) && operand.spilled === true) {
    // "Pointer sub-fields are first-class referents ... Referencing the
    // raw field directly ... after it has spilled is illegal and halts the
    // run with a named diagnostic, because that raw value no longer exists
    // in the results map; only its receipt does."
    return specEngineMakeHalt(
      step + '.' + field,
      'predicate-spilled-content-reference',
      'Predicate field "' + field + '" on step "' + step + '" resolves to a spilled field\'s receipt directly; ' +
        'reference a pointer sub-field (.path, .sha256, .bytes) instead.'
    );
  }

  let result;
  if (operator === 'equals') {
    result = operand === expected;
  } else if (operator === 'lte' || operator === 'gte') {
    // INFERRED: "Predicate operator vocabulary" defines lte/gte as numeric
    // ordering ("less than or equal", "greater than or equal") but does not
    // define ordering over non-numeric operands. Rather than fall through
    // to JavaScript's coercing "<="/">=" (which would silently treat a
    // string as a number, or NaN-compare it to always-false), this
    // evaluator halts on either side of a non-numeric ordering comparison --
    // the resolved operand or the predicate's own literal "value" -- by a
    // strict typeof+isFinite check, no string-to-number coercion. This is
    // the same "broken reference must never masquerade as a legitimate
    // failing check" rationale the undefined-sentinel rule states, applied
    // to a non-numeric operand instead of a missing one.
    if (!specEngineIsFiniteNumber(operand) || !specEngineIsFiniteNumber(expected)) {
      return specEngineMakeHalt(
        step + '.' + field,
        'predicate-operand-not-numeric',
        'Predicate operator "' + operator + '" requires both the resolved operand and the literal "value" to be ' +
          'finite numbers (no string-to-number coercion); step "' + step + '", field "' + field + '" did not satisfy that.'
      );
    }
    result = operator === 'lte' ? operand <= expected : operand >= expected;
  } else {
    // Runtime enforcement of the same rule validateSpec's
    // checkPredicateOperator already applies structurally: an operator
    // outside equals/lte/gte must never silently evaluate (and so
    // masquerade as a legitimate failing gate) -- it halts here too,
    // reusing the same diagnostic name validateSpec uses for this defect
    // class.
    return specEngineMakeHalt(
      step + '.' + field,
      'unknown-predicate-operator',
      'Predicate operator "' + operator + '" is not one of the three recognized operators (equals, lte, gte).'
    );
  }

  return { halted: false, result: result };
}

// specEngineResolveTemplateRef(ref, results, values) resolves one dotted
// template reference (the text inside one pair of {{...}} braces, or an
// {{#if}} condition) against the run's results-so-far map or the spec's
// config values, per the "Template forms and reference resolution" section.
//
// {{values.PATH}} form: PATH is walked into `values` with
// specEngineResolveFieldPath, the same dotted-path walker
// specEngineEvalPredicate uses for a predicate's own field path.
//
// {{step.field}} form: "Template split rule" -- "a template reference
// resolves by matching the longest declared step key that is a prefix of
// the reference; everything after that matched prefix is the field path
// read from that step's result. This also covers a declared step key that
// happens to be a prefix of another declared step key -- the longest match
// wins." resolveReferences applies this same rule statically, against the
// spec's DECLARED keys (unknown at validation time whether a map/
// scored-retry pattern key's index will exist at runtime); at render time
// the run's actual `results` map already carries every concrete namespaced
// key (including realized map/scored-retry indices), so this function
// applies the identical longest-match rule directly against
// Object.keys(results) instead of a separately-tracked declared-key list.
// Returns { resolved: false } if no declared key is a prefix (or exact
// match), matching specEngineResolveFieldPath's own return shape so callers
// can treat both failure modes the same way.
//
// Empty path segments (a trailing dot, as in "step.", or a double dot, as
// in "step..field") are unresolvable, the same halt-don't-guess class as an
// absent field: this function tracks the EXACT-match case (bare "step",
// legal, whole result value) separately from the prefix-match case ("step."
// plus a field path, possibly empty), so a bare key never gets conflated
// with a key followed by a trailing dot and nothing else. A bare key's
// field path is never walked through specEngineResolveFieldPath (there is
// no path to walk); a trailing-dot key's empty remainder IS routed through
// specEngineResolveFieldPath, which already rejects a zero-length field
// path as unresolved -- no separate empty-segment check is needed here. A
// double dot produces a field path with a literal empty segment between
// two dots, which specEngineResolveFieldPath's own hasOwnProperty walk
// already rejects (an empty-string property practically never exists),
// covered by its existing segment-by-segment walk without any change.
function specEngineResolveTemplateRef(ref, results, values) {
  if (ref.indexOf('values.') === 0) {
    const valuesRoot = specEngineIsPlainObject(values) ? values : Object.create(null);
    return specEngineResolveFieldPath(valuesRoot, ref.slice('values.'.length));
  }

  const resultsMap = specEngineIsPlainObject(results) ? results : Object.create(null);
  const keys = Object.keys(resultsMap);
  let bestKey = null;
  let bestFieldPath = null;
  let bestIsExactKey = false;
  for (let i = 0; i < keys.length; i += 1) {
    const key = keys[i];
    if (ref === key) {
      if (bestKey === null || key.length > bestKey.length) {
        bestKey = key;
        bestFieldPath = '';
        bestIsExactKey = true;
      }
    } else if (ref.indexOf(key + '.') === 0) {
      if (bestKey === null || key.length > bestKey.length) {
        bestKey = key;
        bestFieldPath = ref.slice(key.length + 1);
        bestIsExactKey = false;
      }
    }
  }

  if (bestKey === null) {
    return { resolved: false };
  }
  if (bestIsExactKey) {
    return { resolved: true, value: resultsMap[bestKey] };
  }
  return specEngineResolveFieldPath(resultsMap[bestKey], bestFieldPath);
}

// specEngineStringifyTemplateValue(value) -- INFERRED: SPEC_SCHEMA.md
// specifies what a template reference resolves TO, not how a non-string
// resolved value (a number, boolean, or an object/array field) is turned
// into the substituted text; no ratified wording settles this. The minimal
// reading applied here: a string substitutes as itself; null/undefined
// substitute as an empty string; any other primitive uses JS's own String()
// conversion; a plain object or array uses JSON.stringify so a template
// author can still see the shape of what was substituted.
function specEngineStringifyTemplateValue(value) {
  if (typeof value === 'string') {
    return value;
  }
  if (value === null || typeof value === 'undefined') {
    return '';
  }
  if (typeof value === 'object') {
    return JSON.stringify(value);
  }
  return String(value);
}

// specEngineRenderTemplateRef(ref, path, results, values) resolves one
// template reference and applies the two runtime-halt rules shared with
// specEngineEvalPredicate, under this function's own template-prefixed
// diagnostic names (disclosed in the file-header comment above): an
// unresolved reference halts under 'template-operand-unresolved' (the
// runtime counterpart to resolveReferences' static 'dangling-template-
// reference' diagnostic, matching the existing predicate-operand-unresolved
// / dangling-predicate-reference static-vs-runtime naming pair already in
// this file), and a reference resolving to a spilled field's receipt
// directly (not one of its pointer sub-fields) halts under
// 'template-spilled-content-reference' (the runtime counterpart to
// specEngineEvalPredicate's own 'predicate-spilled-content-reference' for
// the identical defect class, per the "Pointer sub-fields are first-class
// referents" paragraph of the spill contract). Returns
// { resolved: true, value } on success, or a halt object (see
// specEngineMakeHalt) on either rule firing.
function specEngineRenderTemplateRef(ref, path, results, values) {
  const resolution = specEngineResolveTemplateRef(ref, results, values);

  if (!resolution.resolved) {
    // "Undefined-sentinel rule (templates)": "if a template's dotted path
    // does not resolve ... the engine does not silently substitute the
    // literal text "undefined" into the rendered prompt and continue. It
    // records the sentinel <<undefined>> and halts the run, exactly as an
    // unresolved predicate operand does."
    return specEngineMakeHalt(
      path,
      'template-operand-unresolved',
      'Template reference "{{' + ref + '}}" at "' + path + '" does not resolve; recording the ' +
        SPEC_ENGINE_UNDEFINED_SENTINEL + ' sentinel and halting.',
      SPEC_ENGINE_UNDEFINED_SENTINEL
    );
  }

  if (specEngineIsPlainObject(resolution.value) && resolution.value.spilled === true) {
    // "Referencing the raw field directly -- {{A.content}}, or a predicate
    // over A.content itself -- after it has spilled is illegal and halts
    // the run with a named diagnostic, because that raw value no longer
    // exists in the results map; only its receipt does."
    return specEngineMakeHalt(
      path,
      'template-spilled-content-reference',
      'Template reference "{{' + ref + '}}" at "' + path + '" resolves to a spilled field\'s receipt directly; ' +
        'reference a pointer sub-field (.path, .sha256, .bytes) instead.'
    );
  }

  return resolution;
}

// specEngineDetectUnsupportedIfNesting(str) scans a string leaf for two
// structural defects in its {{#if}}/{{/if}} tokens, before any block is
// evaluated or replaced: an {{#if}} block whose own body contains another
// {{#if}} (unsupported nesting), or a bare {{/if}} with no {{#if}} open at
// that point (an unmatched closer). Both are detected the same way -- by
// walking every {{#if ...}}/{{/if}} token left-to-right and tracking open-
// block depth: seeing a second {{#if}} while depth is already > 0 is
// nesting; seeing a {{/if}} while depth is 0 is an unmatched closer.
// Returns true if either defect is present, false otherwise. Runs before
// SPEC_ENGINE_IF_BLOCK_RE's own pairing regex ever executes, so a nested or
// unmatched structure never reaches (and is never mis-paired by) that
// regex in the first place.
function specEngineDetectUnsupportedIfNesting(str) {
  const re = new RegExp(SPEC_ENGINE_IF_TOKEN_RE.source, 'g');
  let depth = 0;
  let m = re.exec(str);
  while (m !== null) {
    const token = m[1];
    if (token.indexOf('#if') === 0) {
      if (depth > 0) {
        return true;
      }
      depth += 1;
    } else {
      if (depth === 0) {
        return true;
      }
      depth -= 1;
    }
    m = re.exec(str);
  }
  return false;
}

// specEngineRenderTemplateString(str, path, results, values) renders one
// string leaf of a template value. Two passes, in order:
//
// 1. {{#if COND}}...{{/if}} blocks. INFERRED: SPEC_SCHEMA.md names {{#if}}
//    as "recognized template syntax" but states "this document does not
//    extend their behavior beyond that literal syntax" -- the condition
//    grammar and nesting behavior are not specified. This function reads
//    COND as a reference in the same {{step.field}}/{{values.PATH}}
//    vocabulary (consistent with this file's own existing extension in
//    resolveReferences' extractPlaceholders, which already reads an
//    {{#if}} condition as a reference for static-resolution purposes) and
//    tests the resolved value with plain JS truthiness. Nested {{#if}}
//    blocks and unmatched {{/if}} closers are NOT silently mis-paired: a
//    naive non-greedy pairing regex pairs an outer {{#if}} with the FIRST
//    {{/if}} it finds, which silently drops trailing content when that
//    first {{/if}} belongs to an inner block, or leaves a stray {{/if}}
//    token behind that gets misreported as a dangling reference named
//    "/if". specEngineDetectUnsupportedIfNesting runs first and halts
//    under the 'template-if-nesting-unsupported' diagnostic for either
//    case, before SPEC_ENGINE_IF_BLOCK_RE's pairing regex ever runs -- the
//    minimal reading this renderer supports is one {{#if}} level per
//    string leaf, well-matched.
// 2. Remaining {{step.field}} / {{values.PATH}} placeholders, substituted
//    with specEngineStringifyTemplateValue's rendering of the resolved
//    value.
//
// Both passes are fail-fast: the first halt (from the nesting check, an
// {{#if}} condition, or a plain placeholder) returns immediately.
function specEngineRenderTemplateString(str, path, results, values) {
  if (specEngineDetectUnsupportedIfNesting(str)) {
    return specEngineMakeHalt(
      path,
      'template-if-nesting-unsupported',
      'Template string at "' + path + '" contains a nested {{#if}} block or an unmatched {{/if}}, neither of ' +
        'which this renderer supports; only single-level, well-matched {{#if}}...{{/if}} blocks are rendered.'
    );
  }

  let working = str;
  let ifMatch = SPEC_ENGINE_IF_BLOCK_RE.exec(working);
  while (ifMatch !== null) {
    const cond = ifMatch[1].trim();
    const inner = ifMatch[2];
    const outcome = specEngineRenderTemplateRef(cond, path, results, values);
    if (outcome.halted) {
      return outcome;
    }
    const replacement = outcome.value ? inner : '';
    working = working.slice(0, ifMatch.index) + replacement + working.slice(ifMatch.index + ifMatch[0].length);
    ifMatch = SPEC_ENGINE_IF_BLOCK_RE.exec(working);
  }

  let result = working;
  let placeholderMatch = SPEC_ENGINE_PLACEHOLDER_RE.exec(result);
  while (placeholderMatch !== null) {
    const ref = placeholderMatch[1];
    const outcome = specEngineRenderTemplateRef(ref, path, results, values);
    if (outcome.halted) {
      return outcome;
    }
    const substitution = specEngineStringifyTemplateValue(outcome.value);
    result =
      result.slice(0, placeholderMatch.index) + substitution + result.slice(placeholderMatch.index + placeholderMatch[0].length);
    placeholderMatch = SPEC_ENGINE_PLACEHOLDER_RE.exec(result);
  }

  return { halted: false, value: result };
}

// specEngineRenderTemplate(value, results, values) -- see file header for
// the contract. Walks `value` the same shape collectTemplateSites (in
// resolveReferences above) walks a shape step's "template" field -- string
// leaves, array entries, and plain-object properties -- rendering every
// string leaf with specEngineRenderTemplateString and reassembling the
// same tree shape. `path` (default '') accumulates the same dotted/
// bracketed JSON-path format this file's other functions use, so a halt
// deep in the tree still names the specific leaf where it happened.
function specEngineRenderTemplate(value, results, values, path) {
  const currentPath = typeof path === 'string' ? path : '';

  if (typeof value === 'string') {
    return specEngineRenderTemplateString(value, currentPath, results, values);
  }

  if (Array.isArray(value)) {
    const renderedArray = [];
    for (let i = 0; i < value.length; i += 1) {
      const child = specEngineRenderTemplate(value[i], results, values, currentPath + '[' + i + ']');
      if (child.halted) {
        return child;
      }
      renderedArray.push(child.value);
    }
    return { halted: false, value: renderedArray };
  }

  if (specEngineIsPlainObject(value)) {
    const renderedObject = {};
    const keys = Object.keys(value);
    for (let i = 0; i < keys.length; i += 1) {
      const key = keys[i];
      const child = specEngineRenderTemplate(value[key], results, values, currentPath + '.' + key);
      if (child.halted) {
        return child;
      }
      renderedObject[key] = child.value;
    }
    return { halted: false, value: renderedObject };
  }

  // Numbers, booleans, null, undefined: no placeholder syntax to render,
  // pass through unchanged.
  return { halted: false, value: value };
}

// specEngineTokenSet(text) -- helper for specEngineTokenOverlap below.
// Lowercases `text` and splits it on runs of whitespace into a Set of
// distinct tokens. A non-string input, or a string that is empty or
// whitespace-only, yields an empty Set rather than throwing.
function specEngineTokenSet(text) {
  if (typeof text !== 'string' || text.trim().length === 0) {
    return new Set();
  }
  return new Set(text.trim().toLowerCase().split(/\s+/));
}

// specEngineTokenOverlap(claim, evidence) computes the token overlap named
// in the "Say-vs-do cross-check" section: "The engine computes the token
// overlap between the claim and the evidence; if it falls below
// minTokenOverlap, the engine records a trace flag named
// verdict-unsupported". That section names the comparison and the
// minTokenOverlap threshold it is measured against, but does not define
// what a "token" is or how "overlap" is computed as a number -- INFERRED
// here, the minimal reading implied by the name: both strings are
// lowercased and split on whitespace into token sets (so word order and
// repeat count do not matter), and the return value is the size of the
// set intersection -- the count of distinct tokens present in both the
// claim and the evidence. A non-string input contributes an empty token
// set rather than throwing. Miss value: 0 (no shared tokens) -- which is
// also the correct, non-distinguishable answer for two disjoint inputs,
// so this primitive has no separate not-found value distinct from "found
// zero shared tokens"; 0 serves as the explicit miss value the same way
// null does for the string-returning primitives below.
function specEngineTokenOverlap(claim, evidence) {
  const claimTokens = specEngineTokenSet(claim);
  const evidenceTokens = specEngineTokenSet(evidence);
  let overlap = 0;
  claimTokens.forEach(function (token) {
    if (evidenceTokens.has(token)) {
      overlap += 1;
    }
  });
  return overlap;
}

// specEngineExtractLabeledLine(text, label) -- INFERRED: neither
// SPEC_SCHEMA.md nor RUNTIME_FACTS.md names or describes this primitive
// (confirmed by a full-text grep of both files); this is contract-silent
// territory, picked to the minimal reading implied by the name. Scans
// `text` line by line (splitting on "\n") for the first line whose
// content, after stripping leading whitespace, starts with the literal
// `label` text followed by optional whitespace and a colon; returns the
// remainder of that line after the colon, trimmed. A label that appears
// mid-line -- not at that line's own start, once indentation is stripped
// -- does not count as a labeled line and is skipped, so a decoy
// occurrence elsewhere on a line never wins over a true line-start label
// on a later line. Returns null -- the explicit miss value -- when no
// line matches, or when `text`/`label` are not both non-empty strings.
function specEngineExtractLabeledLine(text, label) {
  if (typeof text !== 'string' || typeof label !== 'string' || label.length === 0) {
    return null;
  }
  const lines = text.split('\n');
  for (let i = 0; i < lines.length; i += 1) {
    const lineStart = lines[i].replace(/^\s+/, '');
    if (lineStart.indexOf(label) === 0) {
      const afterLabel = lineStart.slice(label.length);
      const colonMatch = /^\s*:\s*(.*)$/.exec(afterLabel);
      if (colonMatch) {
        return colonMatch[1].trim();
      }
    }
  }
  return null;
}

// specEngineSliceFromMarker(text, marker) -- INFERRED: contract-silent,
// same disclosure as specEngineExtractLabeledLine above. Finds the first
// occurrence of the literal `marker` substring in `text` and returns
// everything AFTER it (not including the marker itself) to the end of the
// string. If the marker is present but sits at the very end of `text`,
// the slice after it is the empty string '' -- a FOUND result, distinct
// in kind from the marker not being present at all. Returns null -- the
// explicit miss value -- when the marker does not occur in `text`, or
// when `text`/`marker` are not both non-empty strings.
function specEngineSliceFromMarker(text, marker) {
  if (typeof text !== 'string' || typeof marker !== 'string' || marker.length === 0) {
    return null;
  }
  const index = text.indexOf(marker);
  if (index === -1) {
    return null;
  }
  return text.slice(index + marker.length);
}

// specEngineFirstMatchOf(text, patterns) -- INFERRED: contract-silent,
// same disclosure as specEngineExtractLabeledLine above. `patterns` is an
// array of RegExp objects, tried in ARRAY ORDER -- not by which one would
// match earliest in `text`: returns the matched substring of the first
// pattern in the array that matches anywhere in `text`, even when a later
// pattern in the array would have matched at an earlier position in the
// string. A non-RegExp array entry is skipped rather than throwing.
// Returns null -- the explicit miss value -- when no pattern in the array
// matches, or when `patterns` is empty or not an array. Each RegExp
// entry's `lastIndex` is reset to 0 immediately before it is tried, so a
// caller-supplied global-flag ('g') entry cannot carry mutated match-
// position state from a previous call (or a previous entry in the same
// array) into this attempt -- identical arguments always produce
// identical results, per this file's pure-primitives purity claim above.
function specEngineFirstMatchOf(text, patterns) {
  if (typeof text !== 'string' || !Array.isArray(patterns)) {
    return null;
  }
  for (let i = 0; i < patterns.length; i += 1) {
    const pattern = patterns[i];
    if (!(pattern instanceof RegExp)) {
      continue;
    }
    pattern.lastIndex = 0;
    const match = pattern.exec(text);
    if (match) {
      return match[0];
    }
  }
  return null;
}

// specEngineRegexExtract(text, pattern) -- INFERRED: contract-silent,
// same disclosure as specEngineExtractLabeledLine above. Runs `pattern` (a
// RegExp) against `text` once. When `pattern` declares at least one
// capture group and the match succeeds, returns the first capture group's
// text (match[1]) -- which may itself be undefined if that particular
// group did not participate in the match, in which case this function
// returns null so a non-participating group still yields the explicit
// miss value rather than the literal string "undefined" or a raw
// undefined. When `pattern` declares no capture groups, returns the whole
// match (match[0]) instead. Returns null -- the explicit miss value --
// when the pattern does not match `text` at all, or when `text`/`pattern`
// are not the expected types. `pattern.lastIndex` is reset to 0
// immediately before use, so a caller-supplied global-flag ('g') pattern
// cannot carry mutated match-position state from a previous call into
// this one -- identical arguments always produce identical results, per
// this file's pure-primitives purity claim above.
function specEngineRegexExtract(text, pattern) {
  if (typeof text !== 'string' || !(pattern instanceof RegExp)) {
    return null;
  }
  pattern.lastIndex = 0;
  const match = pattern.exec(text);
  if (!match) {
    return null;
  }
  if (match.length > 1) {
    return typeof match[1] === 'undefined' ? null : match[1];
  }
  return match[0];
}

// specEngineExecute(spec, dispatch) runs the execute loop over spec.steps,
// in order, for the three leaf step kinds (agent, gate, shape) plus all
// four container kinds: "parallel", "map", "scored-retry", and "branch",
// per the "Container authoring syntax" and "Result-key namespacing
// grammar" sections of SPEC_SCHEMA.md, and the PROBE_RESULTS.md
// observation that a failing gate verdict inside one branch does not
// disrupt the other branch's result delivery or the overall join ("branch"
// there is a parallel step's own track, in PROBE_RESULTS.md's own
// terminology -- see SPEC_SCHEMA.md's "Result-key namespacing grammar"
// section for why this file otherwise reserves the word "branch" for the
// if/else step kind). Meeting an UNRECOGNIZED container step kind at
// execute time -- one absent from SPEC_ENGINE_CONTAINER_STEP_KINDS
// entirely, or present there but without its own explicit handling below
// -- is never a silent skip; the loop halts immediately with a named
// 'container-step-not-supported' diagnostic, the same {path, diagnostic,
// message} halt shape every other halt in this file uses (today this is a
// defensive guard only, unreachable in practice, since all four declared
// container kinds now have their own explicit handling -- see the comment
// on that guard's own branch below). A parallel step's own malformed
// shapes (a missing/non-array `tracks`, a track that is not a plain
// object, or a track missing its own `id`/`steps`) are guarded here too,
// under their own named diagnostics, since validateSpec does not itself
// flag those defects (see specEngineExecuteParallelStep below); a map
// step's own malformed shapes (a missing/non-array `steps`, or a
// missing/unresolvable/non-array `list`) get the same treatment (see
// specEngineExecuteMapStep below); a scored-retry step's own malformed
// shapes (mode/threshold -- reusing validateSpec's own diagnostics for the
// same defects it already checks, duplicated here for an unvalidated spec
// the same way spec-not-object/steps-not-array are -- plus `maxAttempts`
// and a non-object wrapped `step`, neither of which validateSpec checks)
// get the same treatment (see specEngineExecuteScoredRetryStep below); a
// branch step's own malformed shapes (a missing/non-array `cases`, a case
// that is not a plain object or is missing its own `when`/`steps`, or a
// present-but-malformed `default`) get the same treatment too (see
// specEngineExecuteBranchStep below).
//
// A map step's own list-source field, `list: { step, field? }`, is this
// implementation's own disclosed choice -- SPEC_SCHEMA.md's map bullet
// documents `steps` (the repeated body) and `merge` (an optional,
// unimplemented combination field) but never names the field a map step
// declares its LIST under. A `{{...}}` template string was rejected for
// this: specEngineRenderTemplateString always stringifies its resolved
// value (via specEngineStringifyTemplateValue), which would turn an actual
// array into JSON text and break iteration outright. `list` instead reuses
// the same `{step, field}` reference shape a predicate already carries
// (minus predicate's own operator/value), resolved with the existing
// specEngineResolveFieldPath primitive, which preserves the resolved
// value's own type. `field` is optional; when absent, the named step's
// entire result is the list.
//
// A map step's own per-iteration item, exposed to that iteration's body as
// the bare-name reference `{{item}}` (or `{{item.someField}}`, the
// ordinary split-rule field-path case), is this implementation's own
// disclosed choice too -- SPEC_SCHEMA.md's own vocabulary names the map's
// per-run unit "one item... of the list" (the map-body-addressing section)
// but never names a field a body step reads that item through.
//
// A map step's own iteration order is SEQUENTIAL, not concurrent -- the
// opposite of a parallel step's own tracks (see specEngineExecuteParallelStep
// below). This is this implementation's own disclosed, owner-reversible
// design: SPEC_SCHEMA.md's step-kind table describes parallel as running
// "several tracks AT ONCE" but describes map only as repeating "steps once
// per item in a list," with no concurrency language anywhere in the map
// bullet or the map-body-addressing section -- this implementation reads
// that omission as deliberate.
//
// A map step's own iteration containment mirrors track containment (one
// iteration's own halt does not escalate to a whole-run halt; other
// iterations still run; the run continues past the map step) -- but,
// unlike a parallel step, a map step's own execution never writes an
// aggregate object under the map step's own bare id: no ratified wording
// defines aggregate counts for map, and the namespacing grammar never
// declares a plain `<mapId>` key at all (only the `<mapId>.<index>`
// pattern) -- inventing a `{failures, successes, total}`-shaped object
// there the way parallel's own aggregate is written would put an
// unaddressed object at a key the contract never names. A failed
// iteration is instead inspectable only via the map step's own trace
// entry, under a new `iterations` array (one `{ index, status, trace,
// halt }` summary per iteration, mirroring parallel's own `tracks` trace
// field) -- see specEngineExecuteMapStep below.
//
// Track execution is delegated to specEngineExecuteSequence, the same
// step-sequence runner this function itself is now a thin wrapper around:
// a parallel step's each track runs its own `steps` list as a full
// sequence, with the exact same agent/gate/shape (and nested-parallel)
// semantics the top-level loop uses, seeded with a private clone of the
// results collected so far (so a track's steps can resolve an earlier,
// pre-parallel step by bare name, and a later step in the SAME track can
// resolve an earlier step in that same track by bare name too) but
// isolated from every other track's own steps (so two tracks' bare-named
// steps never collide with each other). See specEngineExecuteTrack and
// specEngineExecuteParallelStep below for the full per-track contract:
// tracks are dispatched concurrently (Promise.all over each track's own
// sub-execution, sharing this call's single injected `dispatch` function),
// a track's own internal halt (a gate fail, a gate "uncertain", or any
// other leaf-halt cause, including a nested container-step-not-supported
// halt) is CONTAINED to that track -- it fails only that track, is counted
// in the parallel step's own aggregate, and the run continues past the
// join rather than halting the whole run -- and each track's completed
// steps land in the results map under `<trackId>.<stepId>` (the parallel
// step's own id never prefixes a nested key), with the parallel step's own
// aggregate counts {failures, successes, total} landing under its own id.
//
// Dispatch capability is injected, not owned by this file: the caller
// supplies `dispatch`, an async function `dispatch(step, context) ->
// outcome`, called once per agent or gate step (including one inside a
// track), in step order within whichever sequence it belongs to, and
// always awaited before that sequence moves to its next step -- this is
// what makes dispatch order observable to a caller-supplied stub, and,
// across tracks, what makes concurrent dispatch observable too (nothing in
// one track's own await chain blocks another track's dispatch calls from
// starting). `context` is `{ results, values }`: `results` is the SAME
// flat namespaced-key results map object specEngineEvalPredicate and
// specEngineRenderTemplate read elsewhere in this file (not a copy) for a
// top-level or post-join step; a step dispatched from inside a track
// instead receives that track's own private results object (bare-named,
// per the isolation described above), so a dispatcher can itself resolve
// further references if it needs to, scoped exactly the way that step
// itself resolves them; `values` is spec.config.values (or an empty object
// when absent), the same config-values object specEngineRenderTemplate's
// `values` parameter reads for {{values.PATH}}. specEngineExecute carries
// no dispatch primitive of its own -- shape steps are the only leaf kind
// that never calls `dispatch`, since a shape step's output is computed
// in-engine by rendering its own `template` field.
//
// Timeout ownership: this function starts no internal timer and races no
// promise against a clock. A dispatcher that never settles leaves the
// returned promise pending forever -- the caller that constructs
// `dispatch` owns any timeout policy (racing its own promise, wrapping its
// own dispatch calls) and is expected to always resolve (possibly to
// null/undefined on its own failure) rather than hang. What this loop DOES
// guarantee is that it never hangs on a dispatch outcome it already has: a
// null/undefined outcome is recognized immediately and turned into a halt
// (see below) rather than treated as a valid result or silently retried.
//
// Before dispatching an agent or gate step whose own `prompt` field is a
// string, that prompt is rendered through the existing
// specEngineRenderTemplate evaluator against the results collected so far
// (and spec.config.values) -- reusing the same resolution logic every
// other template site in this file uses, per the "Template forms and
// reference resolution" section of SPEC_SCHEMA.md ("most commonly inside
// an agent step's prompt"). A step with no `prompt` field, or a non-string
// one, is dispatched unchanged. A halt from that render (an unresolved
// reference, or a direct reference to a spilled field) halts the whole run
// under that render's own existing diagnostic, before any dispatch call is
// made for that step. Both this prompt render and a shape step's own
// template render (below) start specEngineRenderTemplate's own `path`
// parameter at this loop's 'steps[i]' locator for that step, suffixed
// with the specific field being rendered ('steps[i].prompt' for an agent
// or gate step, 'steps[i].template' for a shape step) -- so the sub-path
// specEngineRenderTemplate's own recursion appends beneath that (walking
// into a shape step's template object) is APPENDED to the step's own
// locator, not left to stand alone; a halt this render produces always
// carries the full 'steps[i]...' locator, matching every other halt this
// loop returns, instead of a bare renderer sub-path with no step of its
// own to point back to.
//
// Each completed leaf step's result lands in the results map under its own
// step id, per the "Result-key namespacing grammar" section: a top-level
// leaf step's key is its own step id (unnamespaced); a step inside a
// track's key is namespaced as `<trackId>.<stepId>` once that track's own
// sub-execution merges back into the enclosing results map, per the
// parallel-step handling described above. An agent step's result is
// whatever its dispatch outcome was; a shape step's result is its rendered
// template value; a gate step's result is its raw dispatch outcome, but
// ONLY when that gate's verdict resolved to "pass" -- a gate that halts
// its own sequence (verdict "fail" or "uncertain") is not a completed
// step, so its own outcome is deliberately left out of the results map
// (it is still visible in the halt object and in the trace entry for that
// step, and, for a gate inside a track, in that track's own halt detail
// under the enclosing parallel step's trace entry).
//
// Gate verdict handling, per the "Gate verdict domain" and "Say-vs-do
// cross-check" sections of SPEC_SCHEMA.md: a gate step's dispatch outcome
// must be a plain object carrying a `verdict` field equal to one of
// "pass", "fail", or "uncertain" -- anything else (a null/undefined
// outcome, a non-object outcome, a missing verdict field, or a verdict
// value outside that domain) cannot be parsed into a known verdict and
// halts under the 'gate-verdict-unparseable' diagnostic, with status
// "uncertain". A verdict reported as the literal "uncertain" schema member
// halts under 'gate-verdict-reported-uncertain', also status "uncertain".
// A verdict of "fail" halts under 'gate-verdict-failed', with the
// DISTINCT status "gated" (not "uncertain"), naming the failing gate in
// the halt's own `path`. When a gate step's own config carries
// `claimField`, `evidenceField`, and a finite-number `minTokenOverlap`,
// the existing specEngineTokenOverlap primitive computes the overlap
// between those two named fields of the gate's dispatch outcome; an
// overlap below `minTokenOverlap` overrides whatever verdict was reported
// (per SPEC_SCHEMA.md: "regardless of what verdict the agent itself
// reported") to "uncertain", under the 'verdict-unsupported' diagnostic --
// the same literal name SPEC_SCHEMA.md gives the trace flag this halt also
// records on that step's trace entry. Only a "pass" verdict that also
// clears the say-vs-do check (or carries no say-vs-do config at all) lets
// the run continue past the gate.
//
// A gate step that carries a `predicate` field (the deterministic
// {step, field, operator, value} form the "Container authoring syntax"
// section of SPEC_SCHEMA.md shows on a gate nested inside a parallel
// step's worked example) is recognized but not run by this executor: it
// is never dispatched, and the existing specEngineEvalPredicate evaluator
// is never called on it either, because that worked example reads a
// container step's own aggregate result (a parallel step's
// failures/successes/total), and container execution is a later
// capability this loop does not yet implement -- dispatching a
// predicate-form gate today would mislabel the halt as an unparseable
// dispatcher verdict, and silently ignoring the field would be exactly
// the silent-skip this file's halt-loudly discipline forbids elsewhere.
// A predicate-form gate instead halts immediately, before any dispatch
// call is made for that step, under the
// 'gate-predicate-form-not-supported' diagnostic, status "failed".
// specEngineEvalPredicate will be consumed by this loop once
// predicate-form gates are implemented alongside container support; of
// the existing evaluators, this loop today reuses only
// specEngineRenderTemplate (agent/gate prompt rendering, shape-template
// rendering) and specEngineTokenOverlap (the say-vs-do cross-check).
//
// Return shape: { status, results, trace, halt }. `status` -- not the
// `halted: true` flag every halt object below also carries, matching
// every other halt-returning function in this file -- is this loop's
// primary discriminator, because one execute run can halt for reasons a
// bare boolean cannot tell apart from each other (a gate's own verdict
// domain versus a structural failure elsewhere), and a caller branching
// on the run's outcome needs that distinction, not just "did it halt".
// `status` is one of "completed" (every top-level step ran, no whole-run
// halt -- a parallel step whose OWN tracks contained one or more internal
// failures still reports "completed" at this top level, per the
// containment rule above), "gated" (a top-level, non-contained gate's
// verdict was "fail"), "uncertain" (a top-level, non-contained gate's
// verdict could not be trusted, by any of the three causes above), or
// "failed" (every other whole-run halt cause: an unsupported container
// step kind reached outside any track, a malformed parallel step's own
// shape, a predicate-form gate, a null/undefined dispatch outcome for a
// top-level agent step, a malformed spec, or a template-render halt for a
// top-level agent step's prompt or a shape step's template). `results` is
// the accumulated results map, partial on any non-"completed" status.
// `trace` is an ordered array with one entry per top-level step actually
// attempted -- an unsupported container step or a predicate-form gate that
// halts the loop is NOT added to the trace, since neither was ever
// attempted as a leaf step; each leaf entry is
// { step, kind, status, outcome, flags }, `flags` non-empty only for a
// gate step whose say-vs-do check tripped; a parallel step's own trace
// entry additionally carries `tracks`, an array of one summary per track
// ({ trackId, status, trace, halt }, that track's own leaf-style trace and
// halt/status, exactly as specEngineExecuteTrack below returns them) --
// this is where a track-contained halt's detail stays inspectable even
// though it never reaches this function's own top-level `halt`. `halt` is
// null when `status` is "completed", otherwise the halt object every
// halt-returning function in this file returns -- built with
// specEngineMakeHalt (so it carries the same {path, diagnostic, message,
// halted: true} shape as every other halt in this file), or forwarded
// directly from a render halt, which already carries that shape.
//
// Malformed-spec guards reuse validateSpec's own 'spec-not-object' and
// 'steps-not-array' diagnostics for the same defect classes, since
// specEngineExecute is not itself a structural validator (that is
// validateSpec's job, expected to run before execute) but must still fail
// loudly rather than throw on a spec that never got validated. A malformed
// parallel step's own shape gets the same treatment under its own new
// diagnostics ('parallel-tracks-not-array', 'parallel-track-not-object',
// 'parallel-track-id-missing', 'parallel-track-steps-not-array'), since
// validateSpec does not check a track's own `id`/`steps` shape or whether
// `tracks` itself is an array (see specEngineExecuteParallelStep). A
// malformed map step's own shape gets the analogous treatment under its
// own diagnostics ('map-steps-not-array', 'map-list-malformed',
// 'map-list-unresolved', 'map-list-not-array'), since validateSpec's own
// `type === 'map'` branch only recurses into `step.steps` when it is
// already an array (silently doing nothing otherwise) and has no
// knowledge of `list` at all -- that field name is this implementation's
// own invention, documented above (see specEngineExecuteMapStep). A map
// step declaring `merge` (a real, OPTIONAL contract field whose
// combination semantics SPEC_SCHEMA.md explicitly declines to specify) is
// a recognized-but-rejected form, mirroring the existing
// gate-predicate-form-not-supported precedent: it halts immediately, under
// 'map-merge-not-supported', before any iteration runs. A malformed branch
// step's own shape gets the analogous treatment under its own diagnostics
// ('branch-cases-not-array', 'branch-case-not-object',
// 'branch-case-when-missing', 'branch-case-steps-not-array',
// 'branch-default-malformed'), since validateSpec's own `type === 'branch'`
// branch only checks a present-and-plain-object case's `when` operator and
// recurses into `case.steps`/`default.steps` when they already happen to
// be arrays -- silently doing nothing otherwise, the same gap parallel's
// own `tracks` and map's own `steps` have (see specEngineExecuteBranchStep
// below). A branch step that matches no case and declares no `default`
// halts too, under 'branch-no-match-no-default', naming every evaluated
// case predicate in its message -- this one is a genuine RUNTIME outcome
// (it depends on the actual values a run produced), not a malformed-shape
// defect, so unlike the five diagnostics above it is not escalated as a
// whole-run halt unconditionally; it becomes this branch step's own
// returned status instead, contained or escalated exactly the way a
// scored-retry step's own 'scored-retry-no-winner' halt already is (see
// specEngineExecuteBranchStep's own header comment, gap-fill A, for the
// full disclosure).

function specEngineMakeExecuteResult(status, results, trace, halt) {
  return { status: status, results: results, trace: trace, halt: halt || null };
}

// specEngineRenderStepForDispatch(step, results, values, path) -- see the
// specEngineExecute header comment above for the contract (renders a
// string `prompt` field through specEngineRenderTemplate, leaves every
// other step field untouched). `path` is the loop's own 'steps[i]'
// locator for this step; it is threaded in as the render's starting path
// (as 'steps[i].prompt', naming the specific field being rendered) so a
// halt this render produces carries the full locator -- the step-prefix
// PLUS whatever sub-path the renderer's own recursion appended beneath
// it -- rather than just the renderer's bare sub-path on its own (a
// top-level string like `prompt` has no sub-path of its own, so its halt
// path is exactly 'steps[i].prompt'). Returns { halted: false, step:
// <step, with prompt rendered if it had one> } on success, or the
// render's own halt object directly (its existing diagnostic, now
// carrying the full locator) on failure.
function specEngineRenderStepForDispatch(step, results, values, path) {
  if (typeof step.prompt !== 'string') {
    return { halted: false, step: step };
  }
  const rendered = specEngineRenderTemplate(step.prompt, results, values, path + '.prompt');
  if (rendered.halted) {
    return rendered;
  }
  const dispatchStep = {};
  const keys = Object.keys(step);
  for (let i = 0; i < keys.length; i += 1) {
    dispatchStep[keys[i]] = step[keys[i]];
  }
  dispatchStep.prompt = rendered.value;
  return { halted: false, step: dispatchStep };
}

// specEngineResolveGateVerdict(step, outcome, path) -- see the
// specEngineExecute header comment above for the full contract this
// backs. Returns { verdict: 'pass' | 'fail' | 'uncertain', halt, flags };
// `halt` is null for a "pass" verdict, otherwise a full halt object built
// with specEngineMakeHalt (path, diagnostic, message) -- so it already
// carries the halted: true discriminator, ready for specEngineExecute to
// return directly without any further construction.
function specEngineResolveGateVerdict(step, outcome, path) {
  const stepId = step.id;

  if (!specEngineIsPlainObject(outcome) || SPEC_ENGINE_GATE_VERDICTS.indexOf(outcome.verdict) === -1) {
    return {
      verdict: 'uncertain',
      halt: specEngineMakeHalt(
        path,
        'gate-verdict-unparseable',
        'Gate step "' +
          stepId +
          '" dispatch outcome did not carry a verdict field equal to "pass", "fail", or "uncertain"; recording uncertain rather than guessing.'
      ),
      flags: [],
    };
  }

  if (outcome.verdict === 'uncertain') {
    return {
      verdict: 'uncertain',
      halt: specEngineMakeHalt(path, 'gate-verdict-reported-uncertain', 'Gate step "' + stepId + '" reported the verdict "uncertain" directly.'),
      flags: [],
    };
  }

  if (
    typeof step.claimField === 'string' &&
    typeof step.evidenceField === 'string' &&
    specEngineIsFiniteNumber(step.minTokenOverlap)
  ) {
    const overlap = specEngineTokenOverlap(outcome[step.claimField], outcome[step.evidenceField]);
    if (overlap < step.minTokenOverlap) {
      return {
        verdict: 'uncertain',
        halt: specEngineMakeHalt(
          path,
          'verdict-unsupported',
          'Gate step "' +
            stepId +
            '" claim/evidence token overlap (' +
            overlap +
            ') is below minTokenOverlap (' +
            step.minTokenOverlap +
            '); the reported verdict "' +
            outcome.verdict +
            '" is downgraded to uncertain regardless of what was reported.'
        ),
        flags: ['verdict-unsupported'],
      };
    }
  }

  if (outcome.verdict === 'fail') {
    return {
      verdict: 'fail',
      halt: specEngineMakeHalt(path, 'gate-verdict-failed', 'Gate step "' + stepId + '" reported verdict "fail"; halting the run.'),
      flags: [],
    };
  }

  return { verdict: 'pass', halt: null, flags: [] };
}

// specEngineScrubOversizedFieldsForTrace(outcome) -- every spill-guard halt
// path (spill-receipt-malformed, spill-guard-spilldir-unavailable,
// spill-writer-outcome-malformed) must push a trace-safe copy of its
// outcome into the run's own trace, never the raw pre-guard dispatch
// outcome: the full oversized string this whole guard exists to keep out
// of the engine's own output must never land in `outcome.trace`.
// specEngineApplySpillGuard below returns this trace-safe copy, built by
// this function, on every halted path, instead of letting its caller push
// the raw `outcome` closure variable. Scans only top-level fields (matching
// the guard's own
// non-recursive scope, per the guard's own "never receipt sub-fields" scan-
// scope exclusion): any
// STRING field whose UTF-8 byte length (specEngineUtf8Encode, the same
// primitive the guard itself uses) exceeds SPEC_ENGINE_SPILL_THRESHOLD_BYTES
// is replaced with a compact marker object, DISCLOSED here: `{spillFailed:
// true, bytes: N}` -- deliberately NOT shaped like a normal spill receipt
// (`{spilled: true, ...}`), so a trace reader can never mistake "this field
// failed to spill and its content was dropped from the trace" for "this
// field spilled successfully and here is its receipt." Every other field
// (small strings, numbers, objects, already-well-formed receipts) passes
// through unchanged. Never mutates its argument -- always returns a fresh
// object, or the original value unchanged when it is not a plain object.
function specEngineScrubOversizedFieldsForTrace(outcome) {
  if (!specEngineIsPlainObject(outcome)) {
    return outcome;
  }
  const scrubbed = {};
  Object.keys(outcome).forEach(function (field) {
    const value = outcome[field];
    if (typeof value === 'string') {
      const byteLength = specEngineUtf8Encode(value).length;
      if (byteLength > SPEC_ENGINE_SPILL_THRESHOLD_BYTES) {
        scrubbed[field] = { spillFailed: true, bytes: byteLength };
        return;
      }
    }
    scrubbed[field] = value;
  });
  return scrubbed;
}

// specEngineApplySpillGuard(stepId, outcome, dispatch, values, spillDir,
// path, namespacedSegments) -- backs producer-pointer recording (malformed-
// receipt detection), the engine-side oversized-output guard and its writer
// backstop, and the guard's own status/trace/receipt-sub-field scan-scope
// exclusion, together forming the oversized-output carriage design. Called
// ONLY for a completed AGENT step's own dispatch outcome (never a gate's,
// never the engine's own status/halt/trace bookkeeping) -- this scoping
// mirrors the "Oversized-output spill contract" section's own scope ("An
// agent step's result can contain a content field too large to return
// directly"), a disclosed, owner-reversible reading. Scans only OUTCOME's
// own top-level fields, never recursing into a nested object -- this is
// what makes the guard's own "never receipt sub-fields" scan-scope
// exclusion fall out for free: a receipt's own `.path` string lives one
// level deeper than the top-level field that holds the receipt object, so
// it is never visited by either pass below.
//
// Pass 1 (producer-pointer recording, malformed-receipt detection): every
// top-level field whose value is a plain object carrying `spilled: true`
// must be a WELL-FORMED receipt -- non-empty string `path`, a 64-char
// lowercase-hex `sha256`, a finite-number `bytes`. A malformed one
// (spilled:true present but any of those three missing or mistyped) halts
// immediately, naming the missing piece, under 'spill-receipt-malformed' --
// never silently accepted, and never reached by pass 2 below (a
// receipt-shaped object is never a string, so pass 2's own string-only scan
// would have skipped it anyway; this pass exists to catch the PRODUCER's
// own malformed receipt, a defect pass 2 cannot detect). A well-formed
// receipt is recorded as-is: this function does nothing further to it
// (this is the "as the field value as-is" behavior producer-pointer
// recording calls for -- no code path below ever touches a well-formed
// receipt field).
//
// Pass 2 (engine-side oversized-output guard): every top-level STRING
// field's UTF-8 byte length (via the existing specEngineUtf8Encode primitive
// -- never str.length, which counts UTF-16 code units, not bytes) is
// compared against SPEC_ENGINE_SPILL_THRESHOLD_BYTES. A field at OR UNDER
// the threshold is untouched (boundary: exactly 40,000 bytes never
// triggers). A field OVER the threshold is a producer-contract violation:
// the agent should have spilled it per the contract but returned it inline
// instead. For each such field (MULTIPLE oversized fields in one outcome
// each get their OWN writer dispatch -- one writer per field, processed in
// Object.keys(outcome) declaration order, a disclosed, owner-reversible
// reading with no contract signal to do otherwise), this function dispatches
// EXACTLY ONE writer agent via the SAME injected `dispatch` function used
// for every other dispatch in this file -- never a second dispatcher, and
// this engine module itself never opens a file handle anywhere in this
// call. The writer dispatch is a special step envelope, DISCLOSED here:
// `{ id: '<namespacedKey>.<field>.spill-writer', type: 'spill-writer', path:
// '<spillDir>/<namespacedKey>.<field>', prompt: <the oversized string> }` --
// `namespacedKey` here is `namespacedSegments.join('.')`, computed AFTER
// the containment guard below validates every RAW segment (identical to
// `[stepId]` at the top level; see SPEC_SCHEMA.md's own "Producer-side
// spill" paragraph for what that means inside a container) -- the
// content travels on the PROMPT/input side of this dispatch call, exactly
// like every other agent/gate step's prompt in this file, never through
// this function's own return value or through the engine's own output;
// `type: 'spill-writer'` is a synthetic, engine-internal step kind that
// never appears in an authored spec and is never routed through
// specEngineExecuteSequence's own step-kind dispatch (it is dispatched
// directly, right here, bypassing that loop entirely) -- so a caller's
// dispatch function must recognize this one extra type alongside 'agent'/
// 'gate' to serve as the writer backstop. Its contract: write `prompt`'s
// text to `path` (creating spillDir if needed, exactly like the
// contract's own producer-side spill paragraph describes for a producer
// agent), and return `{ written: true, path, sha256, bytes }` -- the
// FILE WRITE HAPPENS ON THE WRITER-AGENT SIDE, never inside this engine
// module, matching the locked "the engine itself never writes files"
// design (this function only ever RECEIVES a receipt-shaped return value;
// it never touches a filesystem API).
//
// On a well-formed `{written: true, path, sha256, bytes}` return, the
// oversized field is SWAPPED (a fresh object built via assign-never-mutate,
// per this file's own convention elsewhere -- `outcome` itself, and any
// object already assigned to `workingOutcome`, is never mutated in place)
// for a normal spill receipt `{spilled: true, path, sha256, bytes}` --
// indistinguishable, from this point on, from a receipt a well-behaved
// producer returned directly per pass 1 above -- and a trace entry naming
// the violation (the field, its byte count, and the writer's own outcome)
// is queued in `traceEntries`, for the caller (specEngineExecuteSequence)
// to push into the run's own trace array right after this step's own leaf
// entry. On a null/undefined/malformed writer return (missing `written:
// true`, or any of path/sha256/bytes missing or mistyped), this function
// halts under 'spill-writer-outcome-malformed', status "failed" -- the
// step surfaces as a failed halt, the oversized payload is NEVER folded
// into `results` (this function's caller only writes `results[stepId]` on
// this function's own non-halted return, so a halt here means that write
// never happens at all -- "never the payload in results" holds by
// construction, not by a separate scrub step). A missing/relative
// `spillDir` (this function's own caller passes whatever specEngineExecute
// resolved from config.spillDir, `null` when absent or invalid) is guarded
// too, LAZILY -- only when an actual oversized field is found needing a
// writer dispatch, so a run with no oversized output never demands
// spillDir at all -- under 'spill-guard-spilldir-unavailable', status
// "failed", before any writer dispatch is attempted.
async function specEngineApplySpillGuard(stepId, outcome, dispatch, values, spillDir, path, namespacedSegments) {
  if (!specEngineIsPlainObject(outcome)) {
    return { halted: false, outcome: outcome, traceEntries: [] };
  }

  const fieldNames = Object.keys(outcome);

  // Pass 1 (producer-pointer recording): malformed-receipt detection, over
  // every field, before any writer dispatch -- a malformed receipt is a
  // producer bug that must never be silently accepted or papered over by
  // pass 2 below. DISCLOSED, OWNER-REVERSIBLE: this pass records a
  // producer-supplied receipt's own `path` as opaque data -- it never
  // builds a filesystem path from it and never passes it to a dispatch
  // this engine issues. Pass 2's own containment guard (below) therefore
  // does not apply here: there is no engine-constructed path in this pass
  // for an unsafe segment to corrupt. A receipt's `path` is not otherwise
  // validated for shape here beyond non-empty-string (see the `problems`
  // check below); a spec/producer that hands a later step a bogus path via
  // a receipt is a contract violation the CONSUMER of that pointer is
  // responsible for handling, not this engine.
  for (let i = 0; i < fieldNames.length; i += 1) {
    const field = fieldNames[i];
    const value = outcome[field];
    if (specEngineIsPlainObject(value) && value.spilled === true) {
      const problems = [];
      if (typeof value.path !== 'string' || value.path.length === 0) {
        problems.push('path');
      }
      if (typeof value.sha256 !== 'string' || !SPEC_ENGINE_SHA256_HEX_RE.test(value.sha256)) {
        problems.push('sha256');
      }
      if (!specEngineIsFiniteNumber(value.bytes)) {
        problems.push('bytes');
      }
      if (problems.length > 0) {
        return {
          halted: true,
          status: 'failed',
          halt: specEngineMakeHalt(
            path + '.' + field,
            'spill-receipt-malformed',
            'Agent step "' +
              stepId +
              '" field "' +
              field +
              '" declares a spilled receipt (spilled: true) but is missing or mistyped: ' +
              problems.join(', ') +
              '.'
          ),
          safeOutcomeForTrace: specEngineScrubOversizedFieldsForTrace(outcome),
        };
      }
    }
  }

  // Pass 2 (engine-side oversized-output guard): oversized-field guard +
  // writer backstop.
  let workingOutcome = outcome;
  const traceEntries = [];

  for (let i = 0; i < fieldNames.length; i += 1) {
    const field = fieldNames[i];
    const value = workingOutcome[field];
    if (typeof value !== 'string') {
      continue;
    }
    const byteLength = specEngineUtf8Encode(value).length;
    if (byteLength <= SPEC_ENGINE_SPILL_THRESHOLD_BYTES) {
      continue;
    }

    if (typeof spillDir !== 'string' || spillDir.length === 0) {
      return {
        halted: true,
        status: 'failed',
        halt: specEngineMakeHalt(
          path + '.' + field,
          'spill-guard-spilldir-unavailable',
          'Agent step "' +
            stepId +
            '" field "' +
            field +
            '" (' +
            byteLength +
            ' bytes) exceeded the ' +
            SPEC_ENGINE_SPILL_THRESHOLD_BYTES +
            '-byte inline threshold, but config.spillDir is missing or empty, so the writer-agent backstop has nowhere to write.'
        ),
        safeOutcomeForTrace: specEngineScrubOversizedFieldsForTrace(workingOutcome),
      };
    }

    // The target path and the writer step's own id are built by joining
    // `namespacedSegments` -- the RAW (unjoined) segments that make up this
    // field's step's own FULL namespaced result key (identical to
    // `[stepId]` at the top level; the caller composes it via
    // namespaceKeyFor, see specEngineExecuteSequence below) -- NEVER the
    // bare, possibly-repeated `stepId`. Two parallel tracks (or two map
    // iterations) that both happen to declare a step called "inner" spill
    // to "<spillDir>/t1.inner.<field>" and "<spillDir>/t2.inner.<field>"
    // (or "<spillDir>/mp.0.inner.<field>" / "<spillDir>/mp.1.inner.<field>")
    // respectively, never to the SAME path -- see SPEC_SCHEMA.md's own
    // "Producer-side spill" paragraph.
    //
    // Containment guard: `namespacedSegments` arrives as an ARRAY of RAW,
    // pre-composition segments (never a single already-'.'-joined string)
    // specifically so this check can tell an author-supplied dot apart
    // from the engine's own namespace-separator dot. If this guard instead
    // received one composed string and split it on '.', a step id of "a.b"
    // would split into segments that look identical to a genuinely
    // composed "track a, step b" key -- an unrelated legal spec would spill
    // to the exact same file, and the per-segment check could not tell the
    // two apart after the fact. Validating each RAW segment (and the field
    // name) BEFORE any join happens is what makes that collision
    // impossible. specEngineIsUnsafePathSegment above is the actual rule
    // (a denylist, not an allowlist -- validator-legal characters like a
    // space remain legal here); every element of
    // `namespacedSegments.concat([field])` is checked against it. A
    // violation halts under 'spill-path-unsafe', scrubbed like every other
    // spill-guard halt, before any writer dispatch and before any join.
    // findIndex(), not find(): find() returns undefined both when nothing
    // matches AND when the matching element's own value is undefined (a
    // missing/non-string step id produces exactly that element), so find()
    // cannot signal "found" reliably here -- the index can.
    const allSegments = namespacedSegments.concat([field]);
    const unsafeIndex = allSegments.findIndex(specEngineIsUnsafePathSegment);
    if (unsafeIndex !== -1) {
      const unsafeSegment = allSegments[unsafeIndex];
      return {
        halted: true,
        status: 'failed',
        halt: specEngineMakeHalt(
          path + '.' + field,
          'spill-path-unsafe',
          'Agent step "' +
            stepId +
            '" field "' +
            field +
            '" would spill to a path built from an unsafe segment (' +
            JSON.stringify(unsafeSegment) +
            '); every raw name that participates in the path (step/track/branch ids and the field name) must be a non-empty string containing no ".", "/", or "\\" -- refusing to construct the target path.'
        ),
        safeOutcomeForTrace: specEngineScrubOversizedFieldsForTrace(workingOutcome),
      };
    }

    const namespacedKey = namespacedSegments.join('.');
    const targetPath = spillDir + '/' + namespacedKey + '.' + field;
    const writerStep = { id: namespacedKey + '.' + field + '.spill-writer', type: 'spill-writer', path: targetPath, prompt: value };
    const writerOutcome = await dispatch(writerStep, { results: {}, values: values });

    const writerWellFormed =
      specEngineIsPlainObject(writerOutcome) &&
      writerOutcome.written === true &&
      typeof writerOutcome.path === 'string' &&
      writerOutcome.path.length > 0 &&
      typeof writerOutcome.sha256 === 'string' &&
      SPEC_ENGINE_SHA256_HEX_RE.test(writerOutcome.sha256) &&
      specEngineIsFiniteNumber(writerOutcome.bytes);

    if (!writerWellFormed) {
      return {
        halted: true,
        status: 'failed',
        halt: specEngineMakeHalt(
          path + '.' + field,
          'spill-writer-outcome-malformed',
          'Agent step "' +
            stepId +
            '" field "' +
            field +
            '" (' +
            byteLength +
            ' bytes) exceeded the ' +
            SPEC_ENGINE_SPILL_THRESHOLD_BYTES +
            '-byte inline threshold; the writer-agent backstop dispatch did not return a well-formed {written: true, path, sha256, bytes} outcome.'
        ),
        safeOutcomeForTrace: specEngineScrubOversizedFieldsForTrace(workingOutcome),
      };
    }

    const receipt = { spilled: true, path: writerOutcome.path, sha256: writerOutcome.sha256, bytes: writerOutcome.bytes };
    const swapped = {};
    Object.keys(workingOutcome).forEach(function (key) {
      swapped[key] = key === field ? receipt : workingOutcome[key];
    });
    workingOutcome = swapped;

    traceEntries.push({
      step: stepId,
      kind: 'spill-guard',
      status: 'completed',
      outcome: null,
      flags: ['engine-side-spill'],
      field: field,
      bytes: byteLength,
      writerOutcome: writerOutcome,
    });
  }

  return { halted: false, outcome: workingOutcome, traceEntries: traceEntries };
}

// specEngineExecuteSequence(steps, dispatch, values, results, trace,
// pathPrefix) runs one step-sequence loop -- the shared engine this file's
// two callers (the top-level specEngineExecute wrapper below, and
// specEngineExecuteTrack's own per-track sub-execution) both drive. `steps`
// is the sequence to run; `dispatch`/`values` are threaded straight through
// to every agent/gate dispatch and every template render, unchanged from
// caller to caller; `results` and `trace` are the caller-owned, MUTATED IN
// PLACE accumulators this loop writes into (never replaced with a new
// object), so a caller can seed `results` with whatever should be visible
// to this sequence's own bare-name template/prompt resolution before this
// function is ever called (the top-level wrapper seeds an empty object;
// specEngineExecuteTrack seeds a private clone of the results collected so
// far, per the parallel-step contract in the specEngineExecute header
// comment above); `pathPrefix` is this sequence's own locator base (e.g.
// 'steps' for the top level, or 'steps[i].tracks[ti].steps' for a track),
// so every halt this loop returns still names its offending step with a
// full, unambiguous path. Returns { status, halt }: `status` is
// "completed" once every step in `steps` has run, or one of "gated" /
// "uncertain" / "failed" the moment a step halts this sequence; `halt` is
// null on "completed", otherwise the halt object (see specEngineMakeHalt)
// for whichever step halted. This is exactly the loop body
// specEngineExecute owned directly before parallel-step support existed;
// its only new branch is the `type === 'parallel'` case below, which
// delegates to specEngineExecuteParallelStep and, on success, merges that
// parallel step's own aggregate and namespaced per-track results into
// `results` before continuing this same sequence -- every other branch
// (shape, agent, gate, and the malformed-step/unknown-kind guards) is
// unchanged from before; the `type === 'map'`, `type === 'scored-retry'`,
// and `type === 'branch'` cases below were added the same way, each
// delegating to its own executor (specEngineExecuteMapStep,
// specEngineExecuteScoredRetryStep, specEngineExecuteBranchStep) and
// merging its own namespaced results back into `results` before
// continuing this same sequence.
async function specEngineExecuteSequence(steps, dispatch, values, results, trace, pathPrefix, spillDir, namespaceKeyFor) {
  for (let i = 0; i < steps.length; i += 1) {
    const step = steps[i];
    const path = pathPrefix + '[' + i + ']';

    if (!specEngineIsPlainObject(step)) {
      return { status: 'failed', halt: specEngineMakeHalt(path, 'step-not-object', 'Each step must be a JSON object.') };
    }

    const stepId = step.id;
    const type = step.type;

    if (type === 'parallel') {
      const parallelOutcome = await specEngineExecuteParallelStep(step, dispatch, values, path, results, spillDir, namespaceKeyFor);
      if (parallelOutcome.wholeRunHalt) {
        return { status: 'failed', halt: parallelOutcome.wholeRunHalt };
      }
      Object.keys(parallelOutcome.namespacedResults).forEach(function (namespacedKey) {
        results[namespacedKey] = parallelOutcome.namespacedResults[namespacedKey];
      });
      results[stepId] = parallelOutcome.aggregate;
      trace.push({
        step: stepId,
        kind: type,
        status: 'completed',
        outcome: parallelOutcome.aggregate,
        flags: [],
        tracks: parallelOutcome.trackSummaries,
      });
      continue;
    }

    if (type === 'map') {
      const mapOutcome = await specEngineExecuteMapStep(step, dispatch, values, path, results, spillDir, namespaceKeyFor);
      if (mapOutcome.wholeRunHalt) {
        return { status: 'failed', halt: mapOutcome.wholeRunHalt };
      }
      Object.keys(mapOutcome.namespacedResults).forEach(function (namespacedKey) {
        results[namespacedKey] = mapOutcome.namespacedResults[namespacedKey];
      });
      // No plain `results[stepId]` is ever written for a map step: the
      // namespacing grammar only defines the `<mapId>.<index>` pattern key,
      // never a bare `<mapId>` key, so there is nothing ratified to write
      // there -- see the specEngineExecute header comment above.
      trace.push({
        step: stepId,
        kind: type,
        status: 'completed',
        outcome: null,
        flags: [],
        iterations: mapOutcome.iterations,
      });
      continue;
    }

    if (type === 'scored-retry') {
      const retryOutcome = await specEngineExecuteScoredRetryStep(step, dispatch, values, path, results, spillDir, namespaceKeyFor);
      // Attempts data is merged regardless of ok/fail, mirroring the
      // existing "partial results collected before a failure are still
      // returned" convention elsewhere in this file (a parallel step's own
      // per-track localResults are merged the same way, unconditionally).
      Object.keys(retryOutcome.namespacedResults).forEach(function (namespacedKey) {
        results[namespacedKey] = retryOutcome.namespacedResults[namespacedKey];
      });
      if (!retryOutcome.ok) {
        trace.push({
          step: stepId,
          kind: type,
          status: retryOutcome.status,
          outcome: typeof retryOutcome.rawOutcome !== 'undefined' ? retryOutcome.rawOutcome : null,
          flags: [],
          attempts: retryOutcome.attemptsTrace,
        });
        return { status: retryOutcome.status, halt: retryOutcome.halt };
      }
      results[stepId] = retryOutcome.winnerValue;
      trace.push({
        step: stepId,
        kind: type,
        status: 'completed',
        outcome: retryOutcome.winnerValue,
        flags: [],
        attempts: retryOutcome.attemptsTrace,
      });
      continue;
    }

    if (type === 'branch') {
      const branchOutcome = await specEngineExecuteBranchStep(step, dispatch, values, path, results, spillDir, namespaceKeyFor);
      if (branchOutcome.wholeRunHalt) {
        return { status: 'failed', halt: branchOutcome.wholeRunHalt };
      }
      // Merged regardless of ok/fail, mirroring the existing "partial
      // results collected before a failure are still returned" convention
      // scored-retry's own attempts-merging already applies (see the
      // `type === 'scored-retry'` branch just above) -- see
      // specEngineExecuteBranchStep's own header comment above.
      Object.keys(branchOutcome.namespacedResults).forEach(function (namespacedKey) {
        results[namespacedKey] = branchOutcome.namespacedResults[namespacedKey];
      });
      if (!branchOutcome.ok) {
        trace.push({
          step: stepId,
          kind: type,
          status: branchOutcome.status,
          outcome: null,
          flags: [],
          selected: branchOutcome.selectedLabel,
          pathTrace: branchOutcome.trace,
        });
        // GAP-FILL A (propagation, not containment): this branch step's
        // own status/halt becomes THIS sequence's own status/halt, exactly
        // like a gate's own fail/uncertain or scored-retry's own failure
        // already does -- see specEngineExecuteBranchStep's own header
        // comment above for the full disclosure.
        return { status: branchOutcome.status, halt: branchOutcome.halt };
      }
      // No plain `results[stepId]` is ever written for a branch step
      // (GAP-FILL C, disclosed in specEngineExecuteBranchStep's own header
      // comment above) -- only the namespaced `<branchId>.<stepId>` keys
      // just merged above.
      trace.push({
        step: stepId,
        kind: type,
        status: 'completed',
        outcome: null,
        flags: [],
        selected: branchOutcome.selectedLabel,
        pathTrace: branchOutcome.trace,
      });
      continue;
    }

    if (SPEC_ENGINE_CONTAINER_STEP_KINDS.indexOf(type) !== -1) {
      // Unreachable in practice today: every container kind in
      // SPEC_ENGINE_CONTAINER_STEP_KINDS ("parallel", "map",
      // "scored-retry", "branch") now has its own explicit `type === ...`
      // branch above. Kept as a defensive, fail-loud guard -- never a
      // silent skip -- should a fifth container kind ever be added to that
      // constant without its own explicit handling landing alongside it.
      return {
        status: 'failed',
        halt: specEngineMakeHalt(
          path,
          'container-step-not-supported',
          'Step "' +
            stepId +
            '" is a container step kind ("' +
            type +
            '") not yet given its own explicit handling in this loop.'
        ),
      };
    }

    if (type === 'shape') {
      const templateValue = specEngineIsPlainObject(step.template) ? step.template : {};
      const rendered = specEngineRenderTemplate(templateValue, results, values, path + '.template');
      if (rendered.halted) {
        return { status: 'failed', halt: rendered };
      }
      results[stepId] = rendered.value;
      trace.push({ step: stepId, kind: type, status: 'completed', outcome: rendered.value, flags: [] });
      continue;
    }

    if (type === 'agent' || type === 'gate') {
      if (type === 'gate' && specEngineIsPlainObject(step.predicate)) {
        // Recognized-but-rejected form: never dispatched, never added to
        // the trace (it was never attempted as a leaf step) -- see the
        // specEngineExecute header comment above for the full rationale.
        return {
          status: 'failed',
          halt: specEngineMakeHalt(
            path,
            'gate-predicate-form-not-supported',
            'Gate step "' +
              stepId +
              '" carries a "predicate" field; predicate-form gates are not dispatched by this executor and are rejected until container support lands.'
          ),
        };
      }

      // By-path digest-verify guard. DISCLOSED, OWNER-REVERSIBLE
      // (gap-fill): SPEC_SCHEMA.md names no field for a spec-declared
      // "verify this on-disk file's digest before dispatching" input (grep
      // confirmed silence), so this implementation invents `verifyDigest:
      // { path, sha256 }` on an agent step, the same way `list: { step,
      // field }` invents map's own list-source field above -- a real,
      // execute-time-only-enforced field never folded into validateSpec,
      // the same scope boundary map.list/scored-retry.maxAttempts already
      // have. When present, a SEPARATE digest-verification dispatch runs
      // BEFORE this step's own prompt render/dispatch: a synthetic
      // `{ type: 'digest-verify', path }` step envelope goes through the
      // SAME injected `dispatch` function (never a second dispatcher, never
      // a filesystem read this engine performs itself -- the engine never
      // writes OR reads files directly, per the locked design), and its
      // contract is to return the file's digest in a structured `digest`
      // field. The engine then compares IN-ENGINE against the declared
      // sha256 -- fail CLOSED on either a mismatch or an unparseable
      // return, in both cases dispatching zero further steps for this
      // consuming step (the render/dispatch below never runs). A mismatch
      // is a deterministic, already-known-bad result (status "failed",
      // 'digest-verify-mismatch' -- mirroring gate-verdict-failed's own
      // deterministic-failure status); an unparseable/null/malformed
      // digest-agent return is the "broken reference must never masquerade
      // as a legitimate result" class the undefined-sentinel rule already
      // establishes elsewhere (status "uncertain",
      // 'digest-verify-outcome-unparseable' -- mirroring
      // gate-verdict-unparseable's own status). A malformed `verifyDigest`
      // DECLARATION itself (present but not a well-formed { path, sha256 })
      // is guarded too, spend-free, under 'digest-verify-declaration-
      // malformed', before any dispatch for this step at all -- silently
      // ignoring a malformed declaration would silently skip the safety
      // check it was meant to add, the same silent-skip class this file
      // forbids elsewhere.
      if (type === 'agent' && typeof step.verifyDigest !== 'undefined') {
        const declared = step.verifyDigest;
        const declaredWellFormed =
          specEngineIsPlainObject(declared) &&
          typeof declared.path === 'string' &&
          declared.path.length > 0 &&
          typeof declared.sha256 === 'string' &&
          SPEC_ENGINE_SHA256_HEX_RE.test(declared.sha256);

        if (!declaredWellFormed) {
          return {
            status: 'failed',
            halt: specEngineMakeHalt(
              path + '.verifyDigest',
              'digest-verify-declaration-malformed',
              'Agent step "' + stepId + '" declares "verifyDigest", but it is not a well-formed { path, sha256 } object (a non-empty string path, a 64-character lowercase-hex sha256).'
            ),
          };
        }

        const digestStep = { id: stepId + '.verify-digest', type: 'digest-verify', path: declared.path };
        const digestOutcome = await dispatch(digestStep, { results: results, values: values });
        const digestWellFormed = specEngineIsPlainObject(digestOutcome) && typeof digestOutcome.digest === 'string' && SPEC_ENGINE_SHA256_HEX_RE.test(digestOutcome.digest);

        if (!digestWellFormed) {
          // Scrub before pushing, the same way every spill-guard halt does
          // (specEngineScrubOversizedFieldsForTrace above): digestOutcome is
          // an untrusted dispatch return value and can carry an oversized
          // field alongside its malformed `digest`.
          trace.push({ step: stepId, kind: type, status: 'uncertain', outcome: specEngineScrubOversizedFieldsForTrace(digestOutcome), flags: [] });
          return {
            status: 'uncertain',
            halt: specEngineMakeHalt(
              path + '.verifyDigest',
              'digest-verify-outcome-unparseable',
              'Agent step "' + stepId + '" digest-verify dispatch for path "' + declared.path + '" did not return a well-formed { digest } outcome (a 64-character lowercase-hex string); recording uncertain rather than guessing.'
            ),
          };
        }

        if (digestOutcome.digest !== declared.sha256) {
          // Scrub here too -- digestOutcome can carry an oversized sibling
          // field even when its own `digest` field is well-formed.
          trace.push({ step: stepId, kind: type, status: 'failed', outcome: specEngineScrubOversizedFieldsForTrace(digestOutcome), flags: [] });
          return {
            status: 'failed',
            halt: specEngineMakeHalt(
              path + '.verifyDigest',
              'digest-verify-mismatch',
              'Agent step "' + stepId + '" digest-verify for path "' + declared.path + '" returned "' + digestOutcome.digest + '", which does not match the declared sha256 "' + declared.sha256 + '"; refusing to dispatch this step.'
            ),
          };
        }
        // Match: this step proceeds to its own normal render/dispatch
        // below, exactly as if verifyDigest had never been declared -- the
        // literal path string is already present in this step's own spec-
        // authored fields (e.g. its prompt), so "the path available to the
        // consuming agent's render" needs no further engine-side wiring.
      }

      const dispatchPrep = specEngineRenderStepForDispatch(step, results, values, path);
      if (dispatchPrep.halted) {
        return { status: 'failed', halt: dispatchPrep };
      }

      const outcome = await dispatch(dispatchPrep.step, { results: results, values: values });

      if (type === 'agent') {
        if (outcome === null || typeof outcome === 'undefined') {
          trace.push({ step: stepId, kind: type, status: 'failed', outcome: outcome, flags: [] });
          return {
            status: 'failed',
            halt: specEngineMakeHalt(
              path,
              'agent-dispatch-null-result',
              'Agent step "' +
                stepId +
                '" dispatch returned no result (null/undefined); halting rather than hanging or silently continuing.'
            ),
          };
        }

        const namespacedSegments = namespaceKeyFor([stepId]);
        const spillGuardOutcome = await specEngineApplySpillGuard(stepId, outcome, dispatch, values, spillDir, path, namespacedSegments);
        if (spillGuardOutcome.halted) {
          // Push the guard's own trace-safe scrub (see
          // specEngineScrubOversizedFieldsForTrace above), never the raw
          // pre-guard `outcome` -- that closure variable can still carry the
          // full oversized string this whole guard exists to keep out of
          // the engine's own output.
          trace.push({ step: stepId, kind: type, status: spillGuardOutcome.status, outcome: spillGuardOutcome.safeOutcomeForTrace, flags: [] });
          return { status: spillGuardOutcome.status, halt: spillGuardOutcome.halt };
        }
        spillGuardOutcome.traceEntries.forEach(function (entry) {
          trace.push(entry);
        });

        results[stepId] = spillGuardOutcome.outcome;
        trace.push({ step: stepId, kind: type, status: 'completed', outcome: spillGuardOutcome.outcome, flags: [] });
        continue;
      }

      // type === 'gate'
      const verdictOutcome = specEngineResolveGateVerdict(step, outcome, path);

      if (verdictOutcome.verdict === 'uncertain') {
        trace.push({ step: stepId, kind: type, status: 'uncertain', outcome: outcome, flags: verdictOutcome.flags });
        return { status: 'uncertain', halt: verdictOutcome.halt };
      }

      if (verdictOutcome.verdict === 'fail') {
        trace.push({ step: stepId, kind: type, status: 'gated', outcome: outcome, flags: verdictOutcome.flags });
        return { status: 'gated', halt: verdictOutcome.halt };
      }

      results[stepId] = outcome;
      trace.push({ step: stepId, kind: type, status: 'completed', outcome: outcome, flags: verdictOutcome.flags });
      continue;
    }

    // Any other declared type (including an unrecognized one) is a
    // structural defect validateSpec is responsible for catching before
    // execute ever runs; guarded here so this loop still fails loudly
    // instead of silently falling through if it is ever called on an
    // unvalidated spec.
    return {
      status: 'failed',
      halt: specEngineMakeHalt(
        path + '.type',
        'unknown-step-kind',
        'Step kind "' + type + '" is not one of the seven recognized step kinds.'
      ),
    };
  }

  return { status: 'completed', halt: null };
}

// specEngineExecuteTrack(track, trackIndex, dispatch, values, baseResults,
// parentPath) runs one parallel step's single track as a full sequence,
// via specEngineExecuteSequence, seeded with a private clone of
// `baseResults` (the results collected so far at the point this parallel
// step was reached) -- per the "Within one track, bare step-name
// references resolve to that track's own earlier steps" contract: a
// shallow clone means a bare-named template/prompt reference inside this
// track resolves against both every step that ran before the parallel
// step AND this same track's own earlier steps, while mutations this
// track makes (its own steps' results, added under their bare ids) never
// leak into `baseResults` itself or into any sibling track's own clone --
// each track's clone is independent. Returns
// { trackId, status, halt, trace, localResults }: `status`/`halt`/`trace`
// are exactly what this track's own specEngineExecuteSequence run
// produced (a non-"completed" status here is this track's OWN internal
// halt -- a gate fail, a gate "uncertain", or any other leaf-halt cause,
// including a nested container-step-not-supported halt -- CONTAINED to
// this track by the caller, specEngineExecuteParallelStep, never escalated
// to a whole-run halt); `localResults` is this track's own contribution
// only -- every key present in the post-run clone that was NOT already
// present in `baseResults` before this track ran, i.e. exactly the bare-id
// results this track's own steps produced (including, for a nested
// container step, whatever namespaced sub-keys that container's own
// execution already wrote into this track's local map) -- ready for the
// caller to re-namespace under this track's own `<trackId>.` prefix.
async function specEngineExecuteTrack(track, trackIndex, dispatch, values, baseResults, parentPath, spillDir, namespaceKeyFor) {
  // Object.assign only clones the KEY SET into a new top-level object; the
  // values it copies are the SAME result objects `baseResults` already
  // holds (shared references, not deep copies). Isolation across tracks
  // holds only because this file's own convention is to always ASSIGN a
  // new key (results[stepId] = outcome) and never mutate an existing
  // result object's own fields in place -- a future change that mutated a
  // shared result object in place would leak that mutation across every
  // track (and the outer scope) holding the same reference.
  const localResults = Object.assign({}, baseResults);
  const baseKeys = Object.keys(baseResults);
  const localTrace = [];
  const trackPath = parentPath + '.tracks[' + trackIndex + '].steps';

  // Compose a namespaceKeyFor for this track's own steps: prepend this
  // track's own RAW id to whatever raw segments the inner call contributes
  // -- never string-concatenated with the namespace-separator dot -- run
  // through the OUTER namespaceKeyFor this function was handed (so a track
  // nested inside further containers still gets the full composed segment
  // array). This is what makes two tracks that both declare a step called
  // "inner" spill to two DIFFERENT paths instead of colliding on the same
  // file, and (per specEngineApplySpillGuard's own containment guard) what
  // lets a raw track id containing '.' be caught as unsafe rather than
  // silently merging with the namespace separator.
  const trackNamespaceKeyFor = function (bareSegments) {
    return namespaceKeyFor([track.id].concat(bareSegments));
  };

  const seqOutcome = await specEngineExecuteSequence(track.steps, dispatch, values, localResults, localTrace, trackPath, spillDir, trackNamespaceKeyFor);

  const ownResults = {};
  Object.keys(localResults).forEach(function (key) {
    if (baseKeys.indexOf(key) === -1) {
      ownResults[key] = localResults[key];
    }
  });

  return {
    trackId: track.id,
    status: seqOutcome.status,
    halt: seqOutcome.halt,
    trace: localTrace,
    localResults: ownResults,
  };
}

// specEngineExecuteParallelStep(step, dispatch, values, path, baseResults)
// runs one "parallel" step's own `tracks`, per the "Container authoring
// syntax" and "Result-key namespacing grammar" sections of
// SPEC_SCHEMA.md, and the PROBE_RESULTS.md observation this design is
// built on (a failing gate verdict inside one branch does not disrupt the
// other branch's result delivery or the overall join).
//
// Malformed-shape guards run first, before any track is dispatched:
// validateSpec's own parallel-step handling checks a track's NESTED
// steps' ids/types (via the same registry every other container kind
// uses) but never checks `tracks` itself is an array, that each
// tracks[] entry is a plain object, or that a track declares its own
// `id`/`steps` -- so those four defects can reach this function on an
// otherwise-validated spec. Each is rejected here under its own
// diagnostic ('parallel-tracks-not-array', 'parallel-track-not-object',
// 'parallel-track-id-missing', 'parallel-track-steps-not-array'), and any
// one of them halts the WHOLE run (returned as `wholeRunHalt`) -- this is
// a structural defect in the parallel step's own declaration, not a
// track's runtime failure, so it does not get the per-track containment
// the rest of this function's own tracks get.
//
// Once every track passes that guard, every track's own sub-execution
// runs CONCURRENTLY: `dispatch` is a single function shared across every
// track (per the specEngineExecute header comment's dispatch-injection
// contract), and every track's specEngineExecuteTrack call is started
// (via Array.prototype.map) before any of them is awaited, so Promise.all
// resolves them together -- nothing in one track's own await chain blocks
// another track's dispatch calls from starting, which is what makes
// concurrent dispatch order observable to a caller-supplied stub.
//
// On success (wholeRunHalt: null), returns
// { wholeRunHalt: null, namespacedResults, aggregate, trackSummaries }:
// `namespacedResults` is every track's own `localResults` entries,
// re-keyed as `<trackId>.<stepId>` (the parallel step's own id never
// prefixes a nested key, per the namespacing grammar); `aggregate` is
// { failures, successes, total } -- a track counts as a success only when
// its own status is "completed", and as a failure for every other status
// ("gated", "uncertain", or "failed") -- this is where gate "uncertain"
// inside a track is deliberately treated the same as a gate fail: BOTH
// are contained to that track and counted as failures here, never
// escalated to a whole-run "uncertain" or "gated" halt, since nothing
// about this aggregation re-inspects a track's own internal status beyond
// "did it complete"; `trackSummaries` is one { trackId, status, trace,
// halt } entry per track, in track-declaration order, exactly as
// specEngineExecuteTrack returned it -- this is where a track-contained
// halt's own diagnostic stays inspectable from the enclosing parallel
// step's own trace entry (see specEngineExecuteSequence's `type ===
// 'parallel'` branch above, which threads this array through as that
// trace entry's own `tracks` field).
async function specEngineExecuteParallelStep(step, dispatch, values, path, baseResults, spillDir, namespaceKeyFor) {
  if (!Array.isArray(step.tracks)) {
    return {
      wholeRunHalt: specEngineMakeHalt(
        path + '.tracks',
        'parallel-tracks-not-array',
        'Parallel step "' + step.id + '" must declare "tracks" as an array of { id, steps }; none was found.'
      ),
    };
  }

  for (let ti = 0; ti < step.tracks.length; ti += 1) {
    const track = step.tracks[ti];
    const trackPath = path + '.tracks[' + ti + ']';

    if (!specEngineIsPlainObject(track)) {
      return {
        wholeRunHalt: specEngineMakeHalt(
          trackPath,
          'parallel-track-not-object',
          'Parallel step "' + step.id + '" track at "' + trackPath + '" must be a JSON object with "id" and "steps".'
        ),
      };
    }
    if (typeof track.id !== 'string' || track.id.length === 0) {
      return {
        wholeRunHalt: specEngineMakeHalt(
          trackPath + '.id',
          'parallel-track-id-missing',
          'Parallel step "' + step.id + '" track at "' + trackPath + '" is missing a non-empty string "id".'
        ),
      };
    }
    if (!Array.isArray(track.steps)) {
      return {
        wholeRunHalt: specEngineMakeHalt(
          trackPath + '.steps',
          'parallel-track-steps-not-array',
          'Parallel step "' + step.id + '" track "' + track.id + '" must declare "steps" as an array of step objects.'
        ),
      };
    }
  }

  const trackPromises = step.tracks.map(function (track, trackIndex) {
    return specEngineExecuteTrack(track, trackIndex, dispatch, values, baseResults, path, spillDir, namespaceKeyFor);
  });
  const trackOutcomes = await Promise.all(trackPromises);

  let failures = 0;
  let successes = 0;
  const namespacedResults = {};
  const trackSummaries = [];

  trackOutcomes.forEach(function (trackOutcome) {
    if (trackOutcome.status === 'completed') {
      successes += 1;
    } else {
      failures += 1;
    }
    Object.keys(trackOutcome.localResults).forEach(function (key) {
      namespacedResults[trackOutcome.trackId + '.' + key] = trackOutcome.localResults[key];
    });
    trackSummaries.push({
      trackId: trackOutcome.trackId,
      status: trackOutcome.status,
      trace: trackOutcome.trace,
      halt: trackOutcome.halt,
    });
  });

  return {
    wholeRunHalt: null,
    namespacedResults: namespacedResults,
    aggregate: { failures: failures, successes: successes, total: trackOutcomes.length },
    trackSummaries: trackSummaries,
  };
}

// specEngineExecuteMapIteration(bodySteps, index, item, dispatch, values,
// baseResults, parentPath) runs one map step's single iteration -- one run
// of `bodySteps` over one `item` of the resolved list -- as a full
// sequence, via specEngineExecuteSequence, seeded with a private clone of
// `baseResults` (the results collected so far at the point this map step
// was reached) PLUS a synthetic bare-name `item` key holding this
// iteration's own current item (this implementation's own disclosed choice
// for how a body step reads "the current item" -- see the
// specEngineExecute header comment above). This mirrors
// specEngineExecuteTrack's own seeding contract exactly, with `item`
// playing the same role a track's own earlier steps play: a bare-named
// reference inside this iteration's body resolves against both every step
// that ran before the map step AND this iteration's own earlier body steps
// AND `item` itself, while mutations this iteration makes never leak into
// `baseResults` or into any sibling iteration's own clone -- each
// iteration's clone is independent, matching the "sibling iterations
// isolated" requirement (a shallow clone, not a deep one -- the same
// Object.assign-key-set-only caveat specEngineExecuteTrack's own header
// comment documents applies here identically). Returns { index, status,
// halt, trace, localResults }: `status`/`halt`/`trace` are exactly what
// this iteration's own specEngineExecuteSequence run produced (a
// non-"completed" status here is this iteration's OWN internal halt,
// CONTAINED to it by the caller, specEngineExecuteMapStep, never escalated
// to a whole-run halt); `localResults` is this iteration's own
// contribution only -- every key present in the post-run clone that was
// NOT already present in the seed (`baseResults` plus `item`), i.e.
// exactly the bare-id results this iteration's own body steps produced --
// ready for the caller to re-namespace under this iteration's own
// `<mapId>.<index>.` prefix.
//
// SHADOW-RISK NOTE: `item` is not itself a reserved segment in
// SPEC_SCHEMA.md's own reserved-segments rule (that rule reserves only
// `attempts` and bare-numeric segments), so nothing in the contract's own
// static-validation vocabulary stops a spec author from declaring a map
// body step with the literal id `item`. Without a guard, that step's own
// result would overwrite -- and then be excluded from -- this synthetic
// seed key, since the seed's key set is captured once, before the body
// runs (the shared-reference caveat above still applies regardless: this
// clone is shallow, and isolation across iterations holds only because
// this file's own convention is to always assign a new key rather than
// mutate a shared result object in place). specEngineExecuteMapStep's own
// pre-dispatch guard (its 'map-body-step-id-item-reserved' diagnostic)
// now catches this collision at the engine level, ahead of any dispatch,
// before this function is ever reached with a colliding body -- so the
// collision this paragraph describes can no longer occur in practice.
// Reserving `item` in SPEC_SCHEMA.md's own reserved-segments rule (the
// contract-level counterpart to this engine-level guard) remains an open
// item for owner ratification, out of this engine's own scope.
async function specEngineExecuteMapIteration(bodySteps, index, item, dispatch, values, baseResults, parentPath, spillDir, namespaceKeyFor) {
  const seedResults = Object.assign({}, baseResults);
  seedResults.item = item;
  const seedKeys = Object.keys(seedResults);
  const localTrace = [];
  const itemPath = parentPath + '.items[' + index + '].steps';

  // `namespaceKeyFor` here is already fully composed by the caller
  // (specEngineExecuteMapStep, which owns both the map step's own id and
  // this iteration's own index) -- forwarded unchanged, the same way
  // `spillDir` already is.
  const seqOutcome = await specEngineExecuteSequence(bodySteps, dispatch, values, seedResults, localTrace, itemPath, spillDir, namespaceKeyFor);

  const ownResults = {};
  Object.keys(seedResults).forEach(function (key) {
    if (seedKeys.indexOf(key) === -1) {
      ownResults[key] = seedResults[key];
    }
  });

  return {
    index: index,
    status: seqOutcome.status,
    halt: seqOutcome.halt,
    trace: localTrace,
    localResults: ownResults,
  };
}

// specEngineExecuteMapStep(step, dispatch, values, path, baseResults) runs
// one "map" step's own body once per item of its resolved list, per the
// "Container authoring syntax", "Map-body addressing", and "Result-key
// namespacing grammar" sections of SPEC_SCHEMA.md, plus this
// implementation's own disclosed design choices documented in full in the
// specEngineExecute header comment above (the `list: { step, field? }`
// field, the `{{item}}` per-iteration reference, sequential-not-concurrent
// iteration order, and no map-level aggregate object).
//
// Malformed-shape and recognized-but-rejected-form guards run first,
// before any iteration is dispatched, in this order:
//   1. `merge` present at all -> 'map-merge-not-supported' (recognized but
//      rejected, mirroring gate-predicate-form-not-supported).
//   2. `steps` missing or not an array -> 'map-steps-not-array'.
//   3. any top-level body step declared with the literal id "item" ->
//      'map-body-step-id-item-reserved' -- "item" is the synthetic
//      bare-name key every iteration is seeded with (see
//      specEngineExecuteMapIteration's own header comment); left
//      unguarded, that step would still dispatch (spend occurs) and then
//      have its own result silently excluded from this map step's
//      results, the spend-attached silent-data-loss class the
//      undefined-sentinel rule forbids elsewhere.
//   4. `list` missing or not a well-formed `{step, field?}` object (a
//      non-empty string `step`) -> 'map-list-malformed'.
//   5. `list.step` names a step with no result in `baseResults` at this
//      point in the spec, OR `list.field` (when declared) does not resolve
//      against that step's result -> 'map-list-unresolved'.
//   6. the resolved list value is not an array -> 'map-list-not-array'.
// Any one of these halts the WHOLE run (returned as `wholeRunHalt`) --
// these are structural defects in the map step's own declaration, not an
// iteration's runtime failure, so none of them get the per-iteration
// containment the rest of this function's own iterations get.
//
// Once every guard passes, iterations run SEQUENTIALLY (see the
// specEngineExecute header comment for why this is a disclosed,
// owner-reversible reading rather than Promise.all-style concurrency): a
// later item's dispatch calls do not begin until the earlier item's own
// full sequence has settled. An EMPTY resolved list runs zero iterations,
// dispatches nothing, and contributes no namespaced result keys at all --
// the run continues past the map step exactly as if it had never been
// declared, other than its own (empty-`iterations`) trace entry.
//
// On success (wholeRunHalt: null), returns
// { wholeRunHalt: null, namespacedResults, iterations }:
// `namespacedResults` carries, per completed step of every iteration, the
// `<mapId>.<index>.<stepId>` key (per the namespacing grammar, written
// whenever that step actually produced a result -- a step that halted its
// own iteration contributes nothing, the same contained-result rule the
// top-level loop and specEngineExecuteTrack both already apply to a
// failing gate), PLUS the plain `<mapId>.<index>` key per iteration, whose
// shape depends on the map body's own DECLARED step count (not how many of
// its steps actually completed): a single-step body's plain key is that
// one step's own result directly (only written when that step completed);
// a multi-step body's plain key is the same step-ID-keyed object
// `localResults` already is (partial when the iteration halted partway
// through, matching "the plain key refers to everything that iteration
// produced" read literally); `iterations` is one { index, status, trace,
// halt } entry per resolved list item, in list order, exactly as
// specEngineExecuteMapIteration returned it -- this is where a contained
// iteration's own halt detail stays inspectable from the enclosing map
// step's own trace entry (see specEngineExecuteSequence's `type === 'map'`
// branch above, which threads this array through as that trace entry's
// own `iterations` field).
async function specEngineExecuteMapStep(step, dispatch, values, path, baseResults, spillDir, namespaceKeyFor) {
  if (typeof step.merge !== 'undefined') {
    return {
      wholeRunHalt: specEngineMakeHalt(
        path + '.merge',
        'map-merge-not-supported',
        'Map step "' +
          step.id +
          '" declares a "merge" field; map.merge combination semantics are a known contract gap (SPEC_SCHEMA.md declines to specify a default) and are not implemented by this executor.'
      ),
    };
  }

  if (!Array.isArray(step.steps)) {
    return {
      wholeRunHalt: specEngineMakeHalt(
        path + '.steps',
        'map-steps-not-array',
        'Map step "' + step.id + '" must declare "steps" as an array of step objects.'
      ),
    };
  }

  // "item" is the synthetic bare-name key specEngineExecuteMapIteration
  // seeds every iteration with (the current list item -- see the
  // specEngineExecute header comment's own disclosed-design paragraph on
  // this). A body step legally declared with that same literal id would
  // still dispatch (spend occurs) and then have its own result silently
  // excluded from the results this map step writes -- the seed's key set
  // is captured before the body runs, so that step's own write to `item`
  // never distinguishes itself from the synthetic seed value the ownResults
  // diff already excludes. That is spend-attached silent data loss, the
  // same class the "Undefined-sentinel rule" sections of SPEC_SCHEMA.md
  // forbid elsewhere (halt loudly rather than let a broken reference --or
  // here, a broken body -- masquerade as a normal completed run). Checked
  // for every top-level body step, before any of them dispatches; nested
  // container steps inside the body are not checked here, since a nested
  // container's own steps are namespaced under ITS OWN scope (a track id,
  // a further map's own index), never written as a bare `item` key at this
  // map step's own iteration level.
  for (let bsi = 0; bsi < step.steps.length; bsi += 1) {
    const bodyStep = step.steps[bsi];
    if (specEngineIsPlainObject(bodyStep) && bodyStep.id === 'item') {
      return {
        wholeRunHalt: specEngineMakeHalt(
          path + '.steps[' + bsi + ']',
          'map-body-step-id-item-reserved',
          'Map step "' +
            step.id +
            '" body step at "' +
            path +
            '.steps[' +
            bsi +
            ']" declares id "item"; "item" is the map iteration\'s current-item key and cannot be used as a body step ID.'
        ),
      };
    }
  }

  const listSpec = step.list;
  if (!specEngineIsPlainObject(listSpec) || typeof listSpec.step !== 'string' || listSpec.step.length === 0) {
    return {
      wholeRunHalt: specEngineMakeHalt(
        path + '.list',
        'map-list-malformed',
        'Map step "' +
          step.id +
          '" must declare "list" as { step, field? } naming the earlier step (and optional dotted field path) whose result is the list to iterate over.'
      ),
    };
  }

  if (!Object.prototype.hasOwnProperty.call(baseResults, listSpec.step)) {
    return {
      wholeRunHalt: specEngineMakeHalt(
        path + '.list',
        'map-list-unresolved',
        'Map step "' + step.id + '" list source names step "' + listSpec.step + '", which has no result at this point in the spec.'
      ),
    };
  }

  let listValue;
  if (typeof listSpec.field === 'string' && listSpec.field.length > 0) {
    const fieldResolution = specEngineResolveFieldPath(baseResults[listSpec.step], listSpec.field);
    if (!fieldResolution.resolved) {
      return {
        wholeRunHalt: specEngineMakeHalt(
          path + '.list',
          'map-list-unresolved',
          'Map step "' +
            step.id +
            '" list source field "' +
            listSpec.field +
            '" does not resolve on step "' +
            listSpec.step +
            '"\'s result.'
        ),
      };
    }
    listValue = fieldResolution.value;
  } else {
    listValue = baseResults[listSpec.step];
  }

  if (!Array.isArray(listValue)) {
    return {
      wholeRunHalt: specEngineMakeHalt(
        path + '.list',
        'map-list-not-array',
        'Map step "' + step.id + '" list source resolved to a non-array value; a map step can only iterate over an array.'
      ),
    };
  }

  const namespacedResults = {};
  const iterations = [];
  const bodyStepCount = step.steps.length;
  const onlyStepId = bodyStepCount === 1 && specEngineIsPlainObject(step.steps[0]) ? step.steps[0].id : null;

  for (let index = 0; index < listValue.length; index += 1) {
    // Compose this iteration's own namespaceKeyFor: prepend this map
    // step's own RAW id and this iteration's own index (an ENGINE-
    // GENERATED segment, safe by construction -- a digit string never
    // contains '.', '/', or '\') to whatever raw segments the inner call
    // contributes, run through the OUTER namespaceKeyFor -- so two
    // iterations of the same map body, both declaring a step called
    // "inner", spill to two DIFFERENT paths
    // ("<spillDir>/mp.0.inner.<field>" vs "<spillDir>/mp.1.inner.<field>"),
    // each embedding its own iteration index. `index` is a `let` binding
    // scoped fresh per for-loop iteration, so this closure correctly
    // captures THIS iteration's own value, not the loop's final one.
    const iterationNamespaceKeyFor = function (bareSegments) {
      return namespaceKeyFor([step.id, String(index)].concat(bareSegments));
    };

    const iterationOutcome = await specEngineExecuteMapIteration(
      step.steps,
      index,
      listValue[index],
      dispatch,
      values,
      baseResults,
      path,
      spillDir,
      iterationNamespaceKeyFor
    );

    Object.keys(iterationOutcome.localResults).forEach(function (key) {
      namespacedResults[step.id + '.' + index + '.' + key] = iterationOutcome.localResults[key];
    });

    if (bodyStepCount === 1) {
      if (typeof onlyStepId === 'string' && Object.prototype.hasOwnProperty.call(iterationOutcome.localResults, onlyStepId)) {
        namespacedResults[step.id + '.' + index] = iterationOutcome.localResults[onlyStepId];
      }
    } else if (bodyStepCount > 1) {
      namespacedResults[step.id + '.' + index] = iterationOutcome.localResults;
    }

    iterations.push({
      index: index,
      status: iterationOutcome.status,
      trace: iterationOutcome.trace,
      halt: iterationOutcome.halt,
    });
  }

  return {
    wholeRunHalt: null,
    namespacedResults: namespacedResults,
    iterations: iterations,
  };
}

// specEngineExecuteScoredRetryStep(step, dispatch, values, path, baseResults)
// runs one "scored-retry" step's own wrapped `step` repeatedly, up to a
// bound, scoring each attempt and keeping a winner, per the "Container
// authoring syntax" and "Result-key namespacing grammar" sections of
// SPEC_SCHEMA.md. Unlike parallel/map, a scored-retry step has no fan-out of
// independently-continuing siblings to contain -- one wrapped step is
// retried, one winner (or none) comes out -- so this function's own return
// shape and its caller's handling (the `type === 'scored-retry'` branch in
// specEngineExecuteSequence below) mirror a GATE step's own contract, not
// parallel/map's `wholeRunHalt`-vs-contained split: on success it reports a
// single completed result to be written under the step's own id; on
// failure it reports a `{status, halt}` pair that specEngineExecuteSequence
// folds into ITS OWN status exactly the way a gate's own fail/uncertain
// verdict is folded in -- contained when this scored-retry step sits inside
// a track's or a map iteration's own sequence (specEngineExecuteTrack /
// specEngineExecuteMapIteration only ever capture their own sequence's
// status, never re-escalate it), escalated to the whole run when it sits at
// the top level. This is also what makes the nested-in-a-track composite
// key `<trackId>.<retryId>.attempts.<n>` fall out for free: this function
// writes plain `<retryId>` / `<retryId>.attempts.<n>` keys into whatever
// `results` object its caller passed as `baseResults` (the track's own
// private results object when nested, the top-level results object
// otherwise), and the enclosing track's own re-namespacing (already
// written for parallel steps) prefixes every one of those keys with
// `<trackId>.` the same way it prefixes any other step's key -- no
// scored-retry-specific composite-key logic is needed here at all.
//
// SEVEN CONTRACT-GAP FILLS this function makes and discloses (SPEC_SCHEMA.md
// is silent on all seven; each is this implementation's own choice,
// consistent with the contract's own idioms elsewhere in this file, and
// owner-reversible):
//
// 1. SCORE SOURCE: an attempt's numeric score is read from a field named
//    `score` on the wrapped step's own completed result -- the same field
//    name the contract's own predicate example reads off a step's result
//    (SPEC_SCHEMA.md's `{ step: 'par', field: 'failures', operator: 'gte',
//    value: 1 }` worked example). This fixed field name is this
//    implementation's own disclosed, owner-reversible choice -- an earlier
//    revision of this function also accepted a per-step `scoreField`
//    override, but that surface carried zero test coverage and went beyond
//    what the contract's own silence requires, so it was removed; `score`
//    is the only field name this executor reads an attempt's score from.
//    The resolved value is validated with the existing
//    specEngineIsFiniteNumber (the same strict, no-coercion check
//    specEngineEvalPredicate already applies to lte/gte operands) --
//    missing, unresolvable, or non-numeric halts the whole scored-retry
//    step under 'scored-retry-score-unparseable', status "uncertain" (the
//    plan-pinned behavior), with the wrapped step's raw result recorded as
//    this halt's own `outcome` in the trace, mirroring how a gate's own
//    "uncertain" verdict records its raw dispatch outcome in the trace.
// 2. ATTEMPT BOUND: `maxAttempts` is REQUIRED (a positive integer),
//    consistent with `mode` and `threshold` (first-passing) already being
//    REQUIRED fields on this step kind, and with the step-kind table's own
//    one-clause definition of scored-retry as running "up to a BOUNDED
//    number of times" -- the bound is intrinsic to what this step kind
//    means, not an optional refinement with a sensible default (inventing a
//    default here would invent contract surface SPEC_SCHEMA.md does not
//    offer). Required-but-malformed is guarded here under
//    'scored-retry-max-attempts-required' (missing) /
//    'scored-retry-max-attempts-invalid' (present but not a positive
//    integer) -- BUT, unlike `mode`/`threshold`, this check is NOT added to
//    validateSpec: `maxAttempts` is this implementation's own invented
//    field name (SPEC_SCHEMA.md's field-optionality table never names it),
//    exactly the same status `map.list` already has in this file (see the
//    specEngineExecuteMapStep header comment above) -- a real,
//    execute-time-only-enforced field for a genuinely REQUIRED contract
//    concept (the bound) whose exact field name and JSON shape SPEC_SCHEMA.md
//    leaves to the implementation. Duplicating validateSpec's own
//    mode/threshold checks here (guards 1-1b below) follows the existing
//    'spec-not-object'/'steps-not-array' precedent instead: those two
//    fields ARE named and required by the contract itself, so validateSpec
//    already rejects a spec missing them, and this function re-checks them
//    only so execute() still fails loudly (never throws) if ever called on
//    a spec that skipped validateSpec.
// 3. AUGMENT MECHANICS: `step.augment`, when a non-empty string, is
//    concatenated onto the wrapped step's own `prompt` field (separated by
//    a blank line) for RETRY attempts only -- attempt index 0 (the first
//    attempt) always runs the wrapped step's `prompt` unchanged. This
//    matches SPEC_SCHEMA.md's own field-optionality-table wording read
//    literally: "if absent, a RETRY ATTEMPT runs without augmentation" --
//    naming retry attempts specifically implies the first attempt (not yet
//    a retry of anything) is never augmented. The augmented prompt is
//    concatenated BEFORE this attempt's own sequence run, so it flows
//    through the exact same specEngineRenderTemplate pipeline
//    specEngineRenderStepForDispatch already applies to every agent/gate
//    prompt -- augment text may itself carry `{{...}}` references, resolved
//    the same way the rest of the prompt is, with no separate rendering
//    path invented for it. Augmentation only ever applies to a wrapped step
//    that declares a string `prompt` field; a wrapped gate/shape step with
//    no `prompt` field is unaffected by `augment` on any attempt.
// 4. THRESHOLD SEMANTICS (first-passing): an attempt clears the threshold
//    when its score is greater than or EQUAL to it (`score >= threshold`),
//    reusing the `gte` operator's own name and meaning from the "Predicate
//    operator vocabulary" section, since first-passing's own one-clause
//    definition ("stop and keep the first attempt that clears the
//    threshold") is exactly the shape of a gte comparison already named
//    elsewhere in this contract. A `threshold` that is PRESENT but not a
//    finite number (either mode) is guarded against before any attempt
//    dispatches, under 'scored-retry-threshold-invalid' -- see that guard's
//    own inline comment, just below the mode/threshold-required checks,
//    for the full disclosure (an owner-reversible, execute-time-only
//    addition, never folded into validateSpec, the same scope boundary
//    `maxAttempts` already has).
// 5. KEEP-BEST TIE-BREAKING: when two or more attempts share the top score,
//    the EARLIEST one (the lowest attempt index) wins -- the deterministic
//    default with no further contract signal to prefer any other attempt,
//    and the one that requires no extra bookkeeping beyond "replace the
//    current best only on a STRICTLY greater score."
// 6. WINNER STORAGE AND THE NO-WINNER RULING: every attempt whose wrapped
//    step actually COMPLETED (produced a result, whether or not that
//    result's score parsed) gets its own `<retryId>.attempts.<n>` key
//    written -- "attempts that ran are recorded regardless" -- mirroring
//    the existing convention elsewhere in this file that a track's or a
//    map iteration's own completed-so-far results are still merged into
//    the outer results map even when that track/iteration (or, here, the
//    whole scored-retry step) ultimately fails as a whole ("partial results
//    collected... are still returned"). An attempt whose wrapped step never
//    completed at all (see gap-fill 7 below) contributes no attempts key,
//    since there is no completed result to address. The plain `<retryId>`
//    key is written ONLY when a winner was actually kept (a clearing
//    first-passing attempt, or keep-best's own highest scorer) -- and its
//    value is always IDENTICAL to that winning attempt's own
//    `<retryId>.attempts.<n>` entry, the same object reference, per the
//    "additionally recorded at the plain <retryId> key" wording. When
//    EVERY attempt is exhausted with no winner -- first-passing never
//    cleared its threshold, or keep-best ran to its bound with zero
//    attempts that ever completed with a parseable score -- this function
//    halts under 'scored-retry-no-winner', status "failed": a no-winner
//    scored-retry step has no result for a later step to reference, and
//    SPEC_SCHEMA.md's own field-optionality table already pins the sibling
//    case of "branch, no case matches and no default" to the same loud-halt
//    reading ("the run stops loudly with a diagnostic instead of guessing")
//    rather than a silent skip -- this ruling applies that same reading to
//    scored-retry's own no-winner case.
// 7. ATTEMPT-FAILURE CONTAINMENT: an attempt whose wrapped step's own
//    sub-sequence does not reach "completed" status (a nested gate fails or
//    reports "uncertain", the wrapped step's dispatch resolves to
//    null/undefined, or its own prompt-template render halts) is a
//    SCORELESS ATTEMPT: it consumes one attempt slot, is recorded in this
//    function's own attempts trace (not in the results map, since it
//    produced no completed result), and the loop CONTINUES to the next
//    attempt, subject to the same maxAttempts bound as every other attempt
//    -- it never halts the scored-retry step by itself. This is
//    deliberately distinct from gap-fill 1's score-PARSE failure (a wrapped
//    step that DID complete but whose result carried no valid score field):
//    a parse failure is the "broken reference must never masquerade as a
//    legitimate result" class the undefined-sentinel rule already
//    establishes elsewhere in this file (the engine genuinely cannot tell
//    whether the attempt was good or bad, so it must halt loudly, not
//    guess), whereas a wrapped step's own internal failure (a nested gate
//    verdict, a dispatch outcome) IS a legitimate, already-meaningful
//    "this attempt did not produce usable output" signal -- the same kind
//    of per-unit runtime failure a track's own contained gate-fail or a map
//    iteration's own contained halt already represents elsewhere in this
//    file, and is handled the same contained-but-not-fatal way here. A
//    score-parse failure on one attempt ALWAYS halts (per gap-fill 1),
//    regardless of how many attempts remain -- this distinction is never
//    blurred by the attempt-failure containment described here.
async function specEngineExecuteScoredRetryStep(step, dispatch, values, path, baseResults, spillDir, namespaceKeyFor) {
  const mode = step.mode;
  if (SPEC_ENGINE_SCORED_RETRY_MODES.indexOf(mode) === -1) {
    const diagnostic = typeof mode === 'undefined' ? 'scored-retry-mode-required' : 'scored-retry-mode-invalid';
    const message =
      typeof mode === 'undefined'
        ? 'scored-retry step "' + step.id + '" is missing the required "mode" field.'
        : 'scored-retry step "' + step.id + '" has mode "' + mode + '", which is not "first-passing" or "keep-best".';
    return { ok: false, status: 'failed', halt: specEngineMakeHalt(path + '.mode', diagnostic, message), namespacedResults: {}, attemptsTrace: [] };
  }

  if (mode === 'first-passing' && typeof step.threshold === 'undefined') {
    return {
      ok: false,
      status: 'failed',
      halt: specEngineMakeHalt(
        path + '.threshold',
        'scored-retry-threshold-required',
        'scored-retry step "' + step.id + '" uses mode "first-passing" and must declare "threshold".'
      ),
      namespacedResults: {},
      attemptsTrace: [],
    };
  }

  // A PRESENT-but-non-numeric threshold (either mode -- "threshold" is
  // legal, if pointless, on keep-best too) is its own malformed-shape
  // defect, distinct from a MISSING threshold: without this guard, a
  // string threshold like "5" would silently never clear (gap-fill 4's
  // gte comparison is gated on specEngineIsFiniteNumber(step.threshold),
  // so a non-numeric threshold simply never lets any attempt pass),
  // masking the real defect (a malformed threshold) behind a generic
  // scored-retry-no-winner halt only after every attempt had already
  // dispatched. This mirrors the existing predicate-operand-not-numeric
  // precedent in specEngineEvalPredicate above (a non-numeric lte/gte
  // operand halts loudly rather than being coerced or silently
  // mis-evaluated) and the maxAttempts type-check idiom immediately below
  // -- checked here, spend-free, before any attempt dispatches. Like
  // maxAttempts, this check is NOT added to validateSpec: it is this
  // implementation's own execute-time-only guard over a value validateSpec
  // never inspects for type, the same scope boundary maxAttempts already
  // has (see this function's own header comment, gap-fill 2) -- an
  // owner-reversible choice, disclosed here rather than folded into
  // validateSpec's own structural checks.
  if (typeof step.threshold !== 'undefined' && !specEngineIsFiniteNumber(step.threshold)) {
    return {
      ok: false,
      status: 'failed',
      halt: specEngineMakeHalt(
        path + '.threshold',
        'scored-retry-threshold-invalid',
        'scored-retry step "' + step.id + '" has "threshold" ' + JSON.stringify(step.threshold) + ', which is not a finite number.'
      ),
      namespacedResults: {},
      attemptsTrace: [],
    };
  }

  const maxAttempts = step.maxAttempts;
  if (typeof maxAttempts === 'undefined') {
    return {
      ok: false,
      status: 'failed',
      halt: specEngineMakeHalt(
        path + '.maxAttempts',
        'scored-retry-max-attempts-required',
        'scored-retry step "' + step.id + '" is missing the required "maxAttempts" field.'
      ),
      namespacedResults: {},
      attemptsTrace: [],
    };
  }
  if (!Number.isInteger(maxAttempts) || maxAttempts < 1) {
    return {
      ok: false,
      status: 'failed',
      halt: specEngineMakeHalt(
        path + '.maxAttempts',
        'scored-retry-max-attempts-invalid',
        'scored-retry step "' + step.id + '" has "maxAttempts" ' + JSON.stringify(maxAttempts) + ', which is not a positive integer.'
      ),
      namespacedResults: {},
      attemptsTrace: [],
    };
  }

  if (!specEngineIsPlainObject(step.step)) {
    return {
      ok: false,
      status: 'failed',
      halt: specEngineMakeHalt(
        path + '.step',
        'scored-retry-step-not-object',
        'scored-retry step "' + step.id + '" must declare "step" as a single nested step object.'
      ),
      namespacedResults: {},
      attemptsTrace: [],
    };
  }

  const wrappedStepId = step.step.id;
  const augment = typeof step.augment === 'string' && step.augment.length > 0 ? step.augment : null;
  const attemptPath = path + '.step';

  const attemptsTrace = [];
  const namespacedResults = {};
  let bestIndex = -1;
  let bestScore = null;
  let bestValue = null;

  for (let n = 0; n < maxAttempts; n += 1) {
    // Gap-fill 3: augment is concatenated onto the wrapped step's own
    // `prompt` field for retry attempts only (n >= 1); attempt 0 always
    // runs the wrapped step unchanged.
    let attemptStep = step.step;
    if (n >= 1 && augment !== null && typeof step.step.prompt === 'string') {
      attemptStep = Object.assign({}, step.step, { prompt: step.step.prompt + '\n\n' + augment });
    }

    // Isolated per-attempt scope, mirroring specEngineExecuteTrack /
    // specEngineExecuteMapIteration: a fresh clone of baseResults per
    // attempt (not accumulated attempt-to-attempt), so an attempt's own
    // bare-name references resolve against the enclosing scope but never
    // against a PRIOR attempt's own result.
    const seedResults = Object.assign({}, baseResults);
    const seedKeys = Object.keys(seedResults);
    const attemptLocalTrace = [];

    // Compose this attempt's own namespaceKeyFor. The wrapped step's OWN
    // bare id (wrappedStepId) is discarded here, not appended -- the
    // namespacing grammar records the wrapped step's WHOLE result directly
    // at the plain `<retryId>.attempts.<n>` key
    // ("namespacedResults[step.id + '.attempts.' + n] = attemptResult",
    // below), never at a further `<retryId>.attempts.<n>.<wrappedStepId>`
    // sub-key -- so when this attempt's own leaf dispatch asks for ITS
    // namespaced key (the common case: a plain agent/gate/shape wrapped
    // step), the answer is exactly `<retryId>.attempts.<n>`, matching where
    // its result actually lands. A wrapped step that is ITSELF a container
    // (nested parallel/map/etc.) is a narrower case: this file's own
    // scored-retry handling only ever propagates `ownResults[wrappedStepId]`
    // (see `attemptResult` below) into the outer results map, so any deeper
    // namespaced sub-key a nested container would produce is already
    // dropped before it reaches the run's own results. For that narrower,
    // already-unreachable case this still avoids colliding with the
    // attempt's own winner key by appending the sub-key rather than
    // discarding it outright.
    const attemptNamespaceKeyFor = function (bareSegments) {
      const attemptSegments = [step.id, 'attempts', String(n)];
      const isWrappedLeaf = bareSegments.length === 1 && bareSegments[0] === wrappedStepId;
      return namespaceKeyFor(isWrappedLeaf ? attemptSegments : attemptSegments.concat(bareSegments));
    };

    const seqOutcome = await specEngineExecuteSequence([attemptStep], dispatch, values, seedResults, attemptLocalTrace, attemptPath, spillDir, attemptNamespaceKeyFor);

    const ownResults = {};
    Object.keys(seedResults).forEach(function (key) {
      if (seedKeys.indexOf(key) === -1) {
        ownResults[key] = seedResults[key];
      }
    });

    if (seqOutcome.status !== 'completed') {
      // Gap-fill 7: a scoreless attempt -- contained, recorded, the loop
      // continues subject to the same maxAttempts bound.
      attemptsTrace.push({ index: n, status: seqOutcome.status, halt: seqOutcome.halt, trace: attemptLocalTrace, score: null, result: null });
      continue;
    }

    const attemptResult = ownResults[wrappedStepId];
    namespacedResults[step.id + '.attempts.' + n] = attemptResult;

    const scoreResolution = specEngineResolveFieldPath(attemptResult, 'score');
    if (!scoreResolution.resolved || !specEngineIsFiniteNumber(scoreResolution.value)) {
      // Gap-fill 1: a score-parse failure always halts the whole
      // scored-retry step, "uncertain," regardless of attempts remaining.
      attemptsTrace.push({ index: n, status: 'uncertain', halt: null, trace: attemptLocalTrace, score: null, result: attemptResult });
      return {
        ok: false,
        status: 'uncertain',
        halt: specEngineMakeHalt(
          attemptPath,
          'scored-retry-score-unparseable',
          'scored-retry step "' +
            step.id +
            '" attempt ' +
            n +
            '\'s wrapped step result does not carry a finite numeric "score" field; recording uncertain rather than guessing.'
        ),
        namespacedResults: namespacedResults,
        attemptsTrace: attemptsTrace,
        rawOutcome: attemptResult,
      };
    }

    const scoreValue = scoreResolution.value;
    attemptsTrace.push({ index: n, status: 'completed', halt: null, trace: attemptLocalTrace, score: scoreValue, result: attemptResult });

    if (bestIndex === -1 || scoreValue > bestScore) {
      // Gap-fill 5: strictly-greater replacement means the EARLIEST
      // top-scoring attempt wins any tie.
      bestIndex = n;
      bestScore = scoreValue;
      bestValue = attemptResult;
    }

    if (mode === 'first-passing' && specEngineIsFiniteNumber(step.threshold) && scoreValue >= step.threshold) {
      // Gap-fill 4: gte semantics -- clears at score >= threshold. Stops
      // immediately: later attempts are never dispatched.
      return {
        ok: true,
        status: 'completed',
        halt: null,
        namespacedResults: namespacedResults,
        winnerValue: attemptResult,
        attemptsTrace: attemptsTrace,
      };
    }
  }

  if (mode === 'keep-best' && bestIndex !== -1) {
    return {
      ok: true,
      status: 'completed',
      halt: null,
      namespacedResults: namespacedResults,
      winnerValue: bestValue,
      attemptsTrace: attemptsTrace,
    };
  }

  // Gap-fill 6: no winner -- every attempt exhausted (first-passing never
  // cleared, or keep-best never completed a single parseable-score
  // attempt) -- a loud halt, mirroring branch's own no-match-no-default
  // pin, since a no-winner scored-retry has no result for a later step to
  // reference.
  return {
    ok: false,
    status: 'failed',
    halt: specEngineMakeHalt(
      path,
      'scored-retry-no-winner',
      'scored-retry step "' + step.id + '" exhausted all ' + maxAttempts + ' attempt(s) without keeping a winner.'
    ),
    namespacedResults: namespacedResults,
    attemptsTrace: attemptsTrace,
  };
}

// specEngineExecuteBranchStep(step, dispatch, values, path, baseResults)
// runs one "branch" step's if/else path selection, per the "Container
// authoring syntax", "Predicate operator vocabulary", and "Result-key
// namespacing grammar" sections of SPEC_SCHEMA.md.
//
// Malformed-shape guards run first, before any predicate is evaluated or
// any step dispatched, in this order: `cases` missing/not-an-array
// ('branch-cases-not-array'); then, for EVERY entry in `cases` -- not just
// the one selection will eventually reach -- not a plain object
// ('branch-case-not-object'), a missing/non-object `when`
// ('branch-case-when-missing'), or a missing/non-array `steps`
// ('branch-case-steps-not-array'); and, only when `default` is present at
// all, not a plain object or its own `steps` not an array
// ('branch-default-malformed'). Scanning every case's shape upfront (even
// ones selection would never reach) mirrors specEngineExecuteParallelStep's
// own "check every track's shape, not just the one that will run"
// convention: these are structural defects in the branch step's own
// declaration, not a runtime selection outcome, so all five diagnostics
// above always escalate as `wholeRunHalt`, the same unconditional tier
// parallel's and map's own malformed-shape guards use, regardless of
// whether this branch step sits at the top level or inside a track/
// iteration/attempt/another branch's own path. validateSpec does not
// itself catch any of these five: its own `type === 'branch'` handling
// only checks a present-and-plain-object `when`'s operator (via
// checkPredicateOperator) and recurses into `case.steps`/`default.steps`
// when they already happen to be arrays -- silently doing nothing
// otherwise, the exact same gap parallel's own `tracks`/map's own `steps`
// handling has (see specEngineExecuteParallelStep's and
// specEngineExecuteMapStep's own header comments above).
//
// `when.step`/`when.field` are deliberately NOT separately guarded here:
// a missing or wrong-typed operand resolves through the existing
// specEngineEvalPredicate's own undefined-sentinel rule (the same
// evaluator this function reuses for every case, unmodified -- see below),
// which already halts loudly on an unresolvable operand. Reinventing that
// check here would duplicate, not reuse, the comparison semantics
// specEngineEvalPredicate already owns.
//
// Once every guard passes, cases are evaluated in DECLARED ORDER via the
// existing specEngineEvalPredicate(when, baseResults) -- no comparison
// semantics of its own; this function only decides SELECTION from that
// evaluator's boolean `result`. The first case whose predicate evaluates
// to `true` is selected immediately; every later case is left completely
// unevaluated (both its own `when` and its own `steps`), matching "later
// cases are NOT evaluated... their steps never dispatch." If a case's
// predicate HALTS instead of resolving to a clean true/false (an unknown
// operator, an unresolved operand, a non-numeric lte/gte operand, or a
// spilled-content reference -- all specEngineEvalPredicate's own existing
// diagnostics), that halt is forwarded to this function's own caller
// EXACTLY as specEngineEvalPredicate returned it, unmodified -- per the
// instruction to propagate the evaluator's existing halts with their
// existing diagnostics. Its `path` field is the OPERAND locator
// (`<step>.<field>`) specEngineEvalPredicate always builds itself, not a
// locator this function constructs -- unlike specEngineRenderTemplate,
// specEngineEvalPredicate takes no `path` parameter to prefix, so there is
// nothing here to rebuild without duplicating logic that already exists.
// This halt path is spend-free: it can only occur before ANY case's own
// `steps` has run, since predicate evaluation always precedes running the
// selected path.
//
// If every case's predicate resolves cleanly (no halt) but none matches,
// `default` is taken when declared (already guard-verified above); when it
// is not declared, this function returns a loud 'branch-no-match-no-default'
// halt whose message names EVERY evaluated case predicate -- its step,
// field, operator, and declared "value", plus the ACTUAL value read off
// that step's result (re-resolved via the existing
// specEngineResolveFieldPath primitive, purely for the message; this
// mirrors, not replaces, specEngineEvalPredicate's own internal resolution)
// -- so a broken/unexpected spec is always diagnosable from the halt text
// alone, never just a bare diagnostic name. An empty `cases` array
// (GAP-FILL B, disclosed) reaches this same halt with zero evaluated
// predicates, worded distinctly ("(none -- \"cases\" is empty)"): nothing
// in SPEC_SCHEMA.md's "Container authoring syntax" section requires
// `cases` to be non-empty, only that it "is an array" -- a zero-length
// array is still a legal array, read here as "no case can ever match,"
// falling straight through to `default` (or this halt) exactly like a
// populated-but-all-non-matching `cases` would.
//
// GAP-FILL A (selected-path failure PROPAGATES, is never independently
// contained): once a path (a case's own `steps`, or `default.steps`) is
// selected, it runs via the shared specEngineExecuteSequence, seeded with
// a private clone of `baseResults` (the exact same seeding contract
// specEngineExecuteTrack/specEngineExecuteMapIteration already use: a
// step inside the path resolves both everything that ran before the
// branch step AND this same path's own earlier steps by bare name, while
// this path's own mutations never leak into `baseResults` or into a
// sibling case's clone -- there is no sibling clone here, since only ONE
// path ever runs). Unlike parallel/map, a branch step has no fan-out of
// independently-continuing siblings left to protect once one path is
// selected -- the same "no sibling to contain" shape
// specEngineExecuteScoredRetryStep's own header comment already cites for
// why ITS return shape mirrors a gate step's own contract instead of
// parallel/map's wholeRunHalt-vs-contained split ("one wrapped step is
// retried, one winner (or none) comes out"). A branch step is the same
// shape: one path is selected, one outcome comes out, so THIS function's
// own `status`/`halt` -- whatever the selected path's own
// specEngineExecuteSequence run produced -- becomes exactly what
// specEngineExecuteSequence's own `type === 'branch'` branch below returns
// as ITS sequence's status, precisely mirroring how a gate step's own
// "fail"/"uncertain" verdict or a scored-retry step's own failure already
// propagate. This means a branch step's own failure is contained only by
// whatever ALREADY wraps the ENCLOSING specEngineExecuteSequence call (a
// track, a map iteration, another branch's own selected path, or nothing
// at all at the top level) -- never by this function itself. This choice
// is owner-reversible: nothing in SPEC_SCHEMA.md rules out an alternative
// reading where a branch step contains its own path's failure the way a
// track contains its own steps' failure; this implementation reads
// "if/else path selection" as choosing which steps run next in the SAME
// sequence, not as spawning an independently-recoverable unit.
//
// GAP-FILL C (no plain `results[branchId]` key is ever written): mirrors
// specEngineExecuteMapStep's own disclosed choice for the identical gap --
// the "Result-key namespacing grammar" section only defines
// `<branchId>.<stepId>` for a branch step's nested results; there is no
// ratified plain `<branchId>` key the way parallel's own aggregate
// ({failures, successes, total}) or scored-retry's own winner exist.
// Inventing one here would put an unaddressed value at a key the contract
// never names -- see specEngineExecuteMapStep's own header comment above
// for the identical reasoning, applied there to map's own missing
// aggregate.
//
// On success (wholeRunHalt: null, ok: true), returns
// { wholeRunHalt: null, ok: true, status: 'completed', halt: null,
// namespacedResults, selectedLabel, trace }: `namespacedResults` is the
// selected path's own contribution, re-keyed as `<branchId>.<stepId>` (the
// same diff-against-the-seed technique specEngineExecuteTrack and
// specEngineExecuteMapIteration already use); `selectedLabel` is
// `'cases[<ci>]'` or `'default'`, naming which path ran (used only for
// this function's own path-locator construction and the caller's trace
// entry, never written into `results` itself); `trace` is the selected
// path's own ordered step-trace, exactly as specEngineExecuteSequence
// produced it. On a selected-path failure (ok: false), the same shape
// carries whatever non-"completed" `status`/`halt`
// specEngineExecuteSequence's own run returned, plus `namespacedResults`
// merged UNCONDITIONALLY regardless of ok/fail (mirroring the existing
// "partial results collected so far are still returned" convention
// scored-retry's own attempts merging already applies -- see the
// `type === 'scored-retry'` branch in specEngineExecuteSequence below,
// whose own comment states this precedent explicitly).
async function specEngineExecuteBranchStep(step, dispatch, values, path, baseResults, spillDir, namespaceKeyFor) {
  if (!Array.isArray(step.cases)) {
    return {
      wholeRunHalt: specEngineMakeHalt(
        path + '.cases',
        'branch-cases-not-array',
        'Branch step "' + step.id + '" must declare "cases" as an array of { when, steps }; none was found.'
      ),
    };
  }

  for (let ci = 0; ci < step.cases.length; ci += 1) {
    const branchCase = step.cases[ci];
    const casePath = path + '.cases[' + ci + ']';

    if (!specEngineIsPlainObject(branchCase)) {
      return {
        wholeRunHalt: specEngineMakeHalt(
          casePath,
          'branch-case-not-object',
          'Branch step "' + step.id + '" case at "' + casePath + '" must be a JSON object with "when" and "steps".'
        ),
      };
    }
    if (!specEngineIsPlainObject(branchCase.when)) {
      return {
        wholeRunHalt: specEngineMakeHalt(
          casePath + '.when',
          'branch-case-when-missing',
          'Branch step "' + step.id + '" case at "' + casePath + '" is missing a "when" predicate object.'
        ),
      };
    }
    if (!Array.isArray(branchCase.steps)) {
      return {
        wholeRunHalt: specEngineMakeHalt(
          casePath + '.steps',
          'branch-case-steps-not-array',
          'Branch step "' + step.id + '" case at "' + casePath + '" must declare "steps" as an array of step objects.'
        ),
      };
    }
  }

  if (typeof step.default !== 'undefined') {
    if (!specEngineIsPlainObject(step.default) || !Array.isArray(step.default.steps)) {
      return {
        wholeRunHalt: specEngineMakeHalt(
          path + '.default',
          'branch-default-malformed',
          'Branch step "' + step.id + '" declares "default", but it is not a { steps: [...] } object.'
        ),
      };
    }
  }

  const evaluated = [];
  let selectedSteps = null;
  let selectedLabel = null;

  for (let ci = 0; ci < step.cases.length; ci += 1) {
    const branchCase = step.cases[ci];
    const evalOutcome = specEngineEvalPredicate(branchCase.when, baseResults);

    if (evalOutcome.halted) {
      // Forwarded exactly as specEngineEvalPredicate returned it -- see
      // this function's own header comment above for why its path is the
      // operand locator, not a locator this function builds.
      return {
        wholeRunHalt: null,
        ok: false,
        status: 'failed',
        halt: evalOutcome,
        namespacedResults: {},
        selectedLabel: null,
        trace: [],
      };
    }

    const readResolution = specEngineResolveFieldPath(baseResults[branchCase.when.step], branchCase.when.field);
    evaluated.push({
      caseIndex: ci,
      when: branchCase.when,
      readValue: readResolution.resolved ? readResolution.value : undefined,
    });

    if (evalOutcome.result === true) {
      selectedSteps = branchCase.steps;
      selectedLabel = 'cases[' + ci + ']';
      break;
    }
  }

  if (selectedSteps === null) {
    if (typeof step.default !== 'undefined') {
      selectedSteps = step.default.steps;
      selectedLabel = 'default';
    } else {
      // JSON.stringify here assumes the declared "value" and the read
      // operand are JSON-safe (a circular object throws) -- the same
      // engine-wide assumption specEngineStringifyTemplateValue's own
      // JSON.stringify branch already makes for rendered template values;
      // not re-guarded here for the same reason.
      const predicateSummaries = evaluated
        .map(function (ep) {
          return (
            'cases[' +
            ep.caseIndex +
            '].when {step: "' +
            ep.when.step +
            '", field: "' +
            ep.when.field +
            '", operator: "' +
            ep.when.operator +
            '", value: ' +
            JSON.stringify(ep.when.value) +
            '} read ' +
            JSON.stringify(ep.readValue) +
            ' -> no match'
          );
        })
        .join('; ');
      return {
        wholeRunHalt: null,
        ok: false,
        status: 'failed',
        halt: specEngineMakeHalt(
          path,
          'branch-no-match-no-default',
          'Branch step "' +
            step.id +
            '" matched none of its ' +
            evaluated.length +
            ' case predicate(s) and declares no "default"; evaluated predicates: ' +
            (predicateSummaries.length > 0 ? predicateSummaries : '(none -- "cases" is empty)') +
            '.'
        ),
        namespacedResults: {},
        selectedLabel: null,
        trace: [],
      };
    }
  }

  const seedResults = Object.assign({}, baseResults);
  const seedKeys = Object.keys(seedResults);
  const localTrace = [];
  const selectedPath = path + '.' + selectedLabel + '.steps';

  // Compose this branch's own namespaceKeyFor -- prepend this branch
  // step's own RAW id to the inner call's raw segments -- the same pattern
  // a track's own composition uses, since a branch step's nested steps
  // namespace identically (`<branchId>.<stepId>`, per the "Result-key
  // namespacing grammar" section's own branch-step bullet).
  const branchNamespaceKeyFor = function (bareSegments) {
    return namespaceKeyFor([step.id].concat(bareSegments));
  };

  const seqOutcome = await specEngineExecuteSequence(selectedSteps, dispatch, values, seedResults, localTrace, selectedPath, spillDir, branchNamespaceKeyFor);

  const ownResults = {};
  Object.keys(seedResults).forEach(function (key) {
    if (seedKeys.indexOf(key) === -1) {
      ownResults[key] = seedResults[key];
    }
  });

  const namespacedResults = {};
  Object.keys(ownResults).forEach(function (key) {
    namespacedResults[step.id + '.' + key] = ownResults[key];
  });

  return {
    wholeRunHalt: null,
    ok: seqOutcome.status === 'completed',
    status: seqOutcome.status,
    halt: seqOutcome.halt,
    namespacedResults: namespacedResults,
    selectedLabel: selectedLabel,
    trace: localTrace,
  };
}

// specEngineExecute(spec, dispatch) -- see the header comment above for the
// full contract. This function is now a thin wrapper: it owns only the
// malformed-spec guards ('spec-not-object', 'steps-not-array') and the
// top-level results/trace accumulators, then delegates the actual
// step-sequence loop to specEngineExecuteSequence, seeded with an empty
// results object (the top level has no enclosing scope to inherit bare
// names from) and the 'steps' path prefix.
// specEngineParseSpecInput(spec) -- DISCLOSED, OWNER-REVERSIBLE (gap-fill,
// spec input forms): a measured platform fact is that the caller channel that hands a
// spec to specEngineExecute can deliver either a plain object or the raw
// JSON text of that same spec (a string). Neither validateSpec nor
// resolveReferences takes this same string-or-object input today -- both
// remain object-only, unchanged by this addition, because neither shares
// an entry point with specEngineExecute (each is called directly by its
// own caller elsewhere, never routed through this function) -- so this
// parsing step lives here, at specEngineExecute's own entry, not as a
// shared primitive the other two static passes also call through.
// Returns { halted: false, spec: <object> } on success, or a halt object
// (see specEngineMakeHalt) under the 'spec-json-unparseable' diagnostic
// when a string input is not valid JSON. An object input passes through
// completely unchanged (not even re-serialized), so this function never
// masks a downstream spec-not-object diagnostic behind a parsing step that
// already assumed a particular shape. specEngineExecute's own inline-spec
// integrity check (specEngineCheckSpecIntegrity below) canonicalizes via
// JSON.stringify of the already-parsed spec, identically for both string-
// and object-arrival forms, so this function has no need to also hand back
// the original raw string.
function specEngineParseSpecInput(spec) {
  if (typeof spec !== 'string') {
    return { halted: false, spec: spec };
  }
  try {
    return { halted: false, spec: JSON.parse(spec) };
  } catch (err) {
    return {
      halted: true,
      halt: specEngineMakeHalt(
        '',
        'spec-json-unparseable',
        'The spec was received as a string and could not be parsed as JSON: ' +
          (err && err.message ? err.message : String(err)) +
          '.'
      ),
    };
  }
}

// specEngineCanonicalizeSpecForIntegrity(parsedSpec) -- helper for
// specEngineCheckSpecIntegrity below. Builds the string that gets hashed
// for the expectedSha256 comparison: a JSON.stringify of `parsedSpec` with
// `config.expectedSha256` itself REMOVED first (a shallow clone of the
// top-level object and of `config`; every other field, and every other
// object/array by reference, is untouched). Removing the field being
// compared against is required, not optional -- see the header comment on
// specEngineCheckSpecIntegrity below for why hashing it IN is a
// self-referential check that can never honestly pass.
function specEngineCanonicalizeSpecForIntegrity(parsedSpec) {
  if (!specEngineIsPlainObject(parsedSpec)) {
    return JSON.stringify(parsedSpec);
  }
  const clone = {};
  Object.keys(parsedSpec).forEach(function (key) {
    clone[key] = parsedSpec[key];
  });
  if (specEngineIsPlainObject(parsedSpec.config)) {
    const configClone = {};
    Object.keys(parsedSpec.config).forEach(function (key) {
      if (key !== 'expectedSha256') {
        configClone[key] = parsedSpec.config[key];
      }
    });
    clone.config = configClone;
  }
  return JSON.stringify(clone);
}

// specEngineCheckSpecIntegrity(parsedSpec) -- DISCLOSED, OWNER-REVERSIBLE
// (gap-fill, inline-spec integrity): config.expectedSha256 is OPTIONAL, and
// is named in SPEC_SCHEMA.md's field-optionality table under the
// "Inline-spec integrity" addition. When present, it is checked BEFORE any
// structural validation below -- an integrity mismatch is its own, distinct
// failure mode, never masked by (or racing) a spec-not-object /
// steps-not-array diagnostic.
//
// CANONICAL-FORM RULING, disclosed here because the reasoning is
// load-bearing: the literal reading "hash the exact raw string as
// received, including config.expectedSha256's own text" is REJECTED --
// under that reading, the value written into expectedSha256 is PART OF the
// very string being hashed to check it, so a "match" requires
// expectedSha256 to equal the sha256 of a string that contains that exact
// expectedSha256 value as a substring: a hash preimage-of-itself. SHA-256's
// own preimage resistance (the property that makes it a useful hash at
// all) makes that fixed point practically unconstructible by any real
// caller or by this function's own test suite -- the "matching digest
// runs" case would be permanently unreachable, which fails the contract's
// own "never-guess" idiom in a different way: a check that can never
// honestly pass is not a meaningful gate, it is a decoration. This
// function instead hashes a CANONICAL form that excludes expectedSha256
// itself from what is hashed (specEngineCanonicalizeSpecForIntegrity
// above), the same self-exclusion idiom every other real content-addressed
// integrity format uses for the same structural reason (a git tree
// object's own hash is computed over its content, not over itself; a
// signed JSON Web Token (JWT)'s signature covers the payload, not the
// signature field). This is computed IDENTICALLY whether the spec arrived
// as a raw string (then parsed, per the spec-input-forms parsing step
// above) or as an already-parsed object -- the "object-form" fork is
// resolved by NOT forking: both paths
// canonicalize via JSON.stringify(parsedSpec-minus-expectedSha256) the same
// way, rather than rejecting the object-form path outright, since once the
// self-referential field is excluded there is no remaining reason the two
// arrival forms should be checked differently. KNOWN LIMITATION, disclosed:
// this canonical form is JSON.stringify's own key-insertion-order
// serialization, not the caller's original raw bytes when the spec arrived
// as a string -- a caller who wants a byte-stable expectedSha256 across
// runs must compute it the same way (JSON.stringify a parsed copy of their
// own spec with expectedSha256 stripped), not by hashing their own
// pre-serialization source text directly.
function specEngineCheckSpecIntegrity(parsedSpec) {
  const expectedSha256 =
    specEngineIsPlainObject(parsedSpec) && specEngineIsPlainObject(parsedSpec.config)
      ? parsedSpec.config.expectedSha256
      : undefined;

  if (typeof expectedSha256 !== 'string' || expectedSha256.length === 0) {
    return { halted: false };
  }

  const canonical = specEngineCanonicalizeSpecForIntegrity(parsedSpec);
  const actualSha256 = specEngineSha256(canonical);
  if (actualSha256 !== expectedSha256) {
    return {
      halted: true,
      halt: specEngineMakeHalt(
        'config.expectedSha256',
        'spec-integrity-mismatch',
        'config.expectedSha256 ("' +
          expectedSha256 +
          '") does not match the sha256 of the spec\'s own canonical form, computed with expectedSha256 itself excluded ("' +
          actualSha256 +
          '"); refusing to run.'
      ),
    };
  }

  return { halted: false };
}

async function specEngineExecute(spec, dispatch) {
  const parseOutcome = specEngineParseSpecInput(spec);
  if (parseOutcome.halted) {
    return specEngineMakeExecuteResult('failed', {}, [], parseOutcome.halt);
  }
  const parsedSpec = parseOutcome.spec;

  const integrityOutcome = specEngineCheckSpecIntegrity(parsedSpec);
  if (integrityOutcome.halted) {
    return specEngineMakeExecuteResult('failed', {}, [], integrityOutcome.halt);
  }

  if (!specEngineIsPlainObject(parsedSpec)) {
    return specEngineMakeExecuteResult(
      'failed',
      {},
      [],
      specEngineMakeHalt('', 'spec-not-object', 'A spec must be a JSON object with "steps" and "config".')
    );
  }
  if (!Array.isArray(parsedSpec.steps)) {
    return specEngineMakeExecuteResult(
      'failed',
      {},
      [],
      specEngineMakeHalt('steps', 'steps-not-array', 'spec.steps must be an array of step objects.')
    );
  }

  const values = specEngineIsPlainObject(parsedSpec.config) && specEngineIsPlainObject(parsedSpec.config.values) ? parsedSpec.config.values : {};
  const spillDir =
    specEngineIsPlainObject(parsedSpec.config) && typeof parsedSpec.config.spillDir === 'string' && parsedSpec.config.spillDir.length > 0
      ? parsedSpec.config.spillDir
      : null;
  const results = {};
  const trace = [];

  // Top-level namespaceKeyFor is the identity function over the raw
  // segments array -- a top-level step's namespaced result key IS its own
  // bare id (a single-element segments array, `[stepId]`), so a top-level
  // step always spills to "<spillDir>/<stepId>.<field>".
  const topLevelNamespaceKeyFor = function (bareSegments) {
    return bareSegments;
  };

  const outcome = await specEngineExecuteSequence(parsedSpec.steps, dispatch, values, results, trace, 'steps', spillDir, topLevelNamespaceKeyFor);

  return specEngineMakeExecuteResult(outcome.status, results, trace, outcome.halt);
}

// SPEC_ENGINE_SHA256_K: the 64 round constants FIPS 180-4 defines for
// SHA-256 -- the first 32 bits of the fractional parts of the cube roots of
// the first 64 prime numbers. Read-only for the whole life of this module:
// specEngineSha256Compress below only ever reads this array by index, so
// two calls (even interleaved ones) never observe each other's state
// through it.
const SPEC_ENGINE_SHA256_K = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

// SPEC_ENGINE_SHA256_H0: the eight initial hash values FIPS 180-4 defines
// for SHA-256 -- the first 32 bits of the fractional parts of the square
// roots of the first eight prime numbers. specEngineSha256 below copies
// these into a fresh call-local array on every call; this module-level
// array itself is never mutated.
const SPEC_ENGINE_SHA256_H0 = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];

// specEngineSha256Rotr(x, n) -- 32-bit right-rotation, the one bitwise
// primitive both the SHA-256 message schedule and the compression round
// share. `>>> 0` on the result keeps the value in the unsigned 32-bit range
// every other SHA-256 helper below assumes.
function specEngineSha256Rotr(x, n) {
  return ((x >>> n) | (x << (32 - n))) >>> 0;
}

// specEngineUtf8Encode(str) converts a JS string to a plain array of its
// UTF-8 bytes, by hand: no TextEncoder (not guaranteed to exist in every
// dialect this region may be copied into), no Buffer (Node-specific).
// Walks the string one UTF-16 code unit at a time; when a high surrogate
// (0xd800-0xdbff) is immediately followed by a low surrogate
// (0xdc00-0xdfff), the pair is combined into the single code point above
// U+FFFF it encodes before the UTF-8 byte-count table is applied, exactly
// as UTF-16 requires. An UNPAIRED surrogate -- a high surrogate not
// immediately followed by a low surrogate, or a low surrogate encountered
// on its own -- is substituted with U+FFFD (the replacement character)
// before encoding, rather than encoded on its own numeric value. This is
// not an arbitrary choice: it is exactly what node's own
// Buffer.from(str, 'utf8') does (confirmed against node's "crypto" module
// in this function's test suite), and what a UTF-8 file write performs on
// the same malformed input. specEngineSha256 exists to verify spilled text
// against digests of on-disk bytes, so matching that substitution -- not
// encoding the lone surrogate's own value -- is the correct property for
// this function to have.
function specEngineUtf8Encode(str) {
  const bytes = [];
  for (let i = 0; i < str.length; i += 1) {
    let codePoint = str.charCodeAt(i);
    if (codePoint >= 0xd800 && codePoint <= 0xdbff && i + 1 < str.length) {
      const low = str.charCodeAt(i + 1);
      if (low >= 0xdc00 && low <= 0xdfff) {
        codePoint = (codePoint - 0xd800) * 0x400 + (low - 0xdc00) + 0x10000;
        i += 1;
      }
    }
    if (codePoint >= 0xd800 && codePoint <= 0xdfff) {
      // Still in the surrogate range after the pairing attempt above:
      // either a high surrogate that found no valid low surrogate to pair
      // with, or a low surrogate reached directly (never eligible for the
      // pairing branch, which only fires when the CURRENT code unit is a
      // high surrogate). Both are unpaired by definition -- substitute the
      // replacement character.
      codePoint = 0xfffd;
    }
    if (codePoint <= 0x7f) {
      bytes.push(codePoint);
    } else if (codePoint <= 0x7ff) {
      bytes.push(0xc0 | (codePoint >> 6));
      bytes.push(0x80 | (codePoint & 0x3f));
    } else if (codePoint <= 0xffff) {
      bytes.push(0xe0 | (codePoint >> 12));
      bytes.push(0x80 | ((codePoint >> 6) & 0x3f));
      bytes.push(0x80 | (codePoint & 0x3f));
    } else {
      bytes.push(0xf0 | (codePoint >> 18));
      bytes.push(0x80 | ((codePoint >> 12) & 0x3f));
      bytes.push(0x80 | ((codePoint >> 6) & 0x3f));
      bytes.push(0x80 | (codePoint & 0x3f));
    }
  }
  return bytes;
}

// specEngineSha256Pad(bytes) applies the SHA-256 padding rule (FIPS 180-4
// section 5.1.1) to a plain byte array and returns a NEW array -- the
// input array is never mutated, keeping this a pure function of its
// argument. Appends a single 0x80 byte, then as many 0x00 bytes as needed
// so the length is congruent to 56 mod 64, then the original bit length of
// `bytes` as a big-endian 64-bit integer (split into a high/low 32-bit
// half; every input this module hashes is far below 2^32 bytes, but the
// split itself is unconditional so the function's own correctness does not
// depend on that being true).
function specEngineSha256Pad(bytes) {
  const byteLength = bytes.length;
  const bitLengthLow = (byteLength * 8) >>> 0;
  const bitLengthHigh = Math.floor((byteLength * 8) / 0x100000000) >>> 0;

  const padded = bytes.slice();
  padded.push(0x80);
  while (padded.length % 64 !== 56) {
    padded.push(0x00);
  }
  padded.push((bitLengthHigh >>> 24) & 0xff, (bitLengthHigh >>> 16) & 0xff, (bitLengthHigh >>> 8) & 0xff, bitLengthHigh & 0xff);
  padded.push((bitLengthLow >>> 24) & 0xff, (bitLengthLow >>> 16) & 0xff, (bitLengthLow >>> 8) & 0xff, bitLengthLow & 0xff);
  return padded;
}

// specEngineSha256Compress(paddedBytes) runs the SHA-256 compression
// function (FIPS 180-4 section 6.2.2) over an already-padded byte array
// (paddedBytes.length is always a multiple of 64, per
// specEngineSha256Pad's own contract) and returns the eight-element array
// of unsigned 32-bit hash words this message digests to. Starts from a
// fresh copy of SPEC_ENGINE_SHA256_H0 on every call and never writes back
// to either module-level constant array, so this function is as pure as
// its argument: identical bytes in always produce identical words out.
function specEngineSha256Compress(paddedBytes) {
  const h = SPEC_ENGINE_SHA256_H0.slice();
  const w = new Array(64);

  for (let chunkStart = 0; chunkStart < paddedBytes.length; chunkStart += 64) {
    for (let t = 0; t < 16; t += 1) {
      const o = chunkStart + t * 4;
      w[t] =
        ((paddedBytes[o] << 24) | (paddedBytes[o + 1] << 16) | (paddedBytes[o + 2] << 8) | paddedBytes[o + 3]) >>> 0;
    }
    for (let t = 16; t < 64; t += 1) {
      const s0 = specEngineSha256Rotr(w[t - 15], 7) ^ specEngineSha256Rotr(w[t - 15], 18) ^ (w[t - 15] >>> 3);
      const s1 = specEngineSha256Rotr(w[t - 2], 17) ^ specEngineSha256Rotr(w[t - 2], 19) ^ (w[t - 2] >>> 10);
      w[t] = (w[t - 16] + s0 + w[t - 7] + s1) >>> 0;
    }

    let a = h[0];
    let b = h[1];
    let c = h[2];
    let d = h[3];
    let e = h[4];
    let f = h[5];
    let g = h[6];
    let hh = h[7];

    for (let t = 0; t < 64; t += 1) {
      const bigS1 = specEngineSha256Rotr(e, 6) ^ specEngineSha256Rotr(e, 11) ^ specEngineSha256Rotr(e, 25);
      const ch = (e & f) ^ (~e & g);
      const temp1 = (hh + bigS1 + ch + SPEC_ENGINE_SHA256_K[t] + w[t]) >>> 0;
      const bigS0 = specEngineSha256Rotr(a, 2) ^ specEngineSha256Rotr(a, 13) ^ specEngineSha256Rotr(a, 22);
      const maj = (a & b) ^ (a & c) ^ (b & c);
      const temp2 = (bigS0 + maj) >>> 0;

      hh = g;
      g = f;
      f = e;
      e = (d + temp1) >>> 0;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) >>> 0;
    }

    h[0] = (h[0] + a) >>> 0;
    h[1] = (h[1] + b) >>> 0;
    h[2] = (h[2] + c) >>> 0;
    h[3] = (h[3] + d) >>> 0;
    h[4] = (h[4] + e) >>> 0;
    h[5] = (h[5] + f) >>> 0;
    h[6] = (h[6] + g) >>> 0;
    h[7] = (h[7] + hh) >>> 0;
  }

  return h;
}

// specEngineSha256Word(word) renders one unsigned 32-bit hash word as an
// 8-character lowercase hex string, zero-padded on the left -- the one
// formatting step specEngineSha256 applies eight times to turn
// specEngineSha256Compress's word array into the final digest string.
function specEngineSha256Word(word) {
  const hex = (word >>> 0).toString(16);
  return '00000000'.slice(hex.length) + hex;
}

// specEngineSha256(str) -- see the file header comment above for the full
// contract. Encodes `str` to UTF-8 bytes, pads per FIPS 180-4, runs the
// compression function, and renders the resulting eight words as one
// lowercase hex string. Deterministic and side-effect-free: every value
// this function touches is either a call-local variable or a read-only
// module-level constant, so two calls -- with the same input, or
// interleaved with different inputs -- never influence each other.
function specEngineSha256(str) {
  const bytes = specEngineUtf8Encode(String(str));
  const padded = specEngineSha256Pad(bytes);
  const words = specEngineSha256Compress(padded);
  let digest = '';
  for (let i = 0; i < words.length; i += 1) {
    digest += specEngineSha256Word(words[i]);
  }
  return digest;
}

// ===ENGINE-CORE-END===

// --- Runner glue ---------------------------------------------------------
//
// spillDir: SPEC_SCHEMA.md's field-optionality table carries this at
// spec.config.spillDir. specEngineExecute (in the region above) reads that
// field itself and resolves it before any dispatch happens, so this glue
// never extracts or threads spillDir on its own -- a spill-writer step's
// own `path` field (below) always arrives with spillDir already baked in,
// built by the engine as `<spillDir>/<namespacedKey>.<field>`.
//
// model: SPEC_SCHEMA.md documents an optional `model` field on agent/gate
// steps and an optional run-wide `config.model` default (a PRESENT step
// `model` overrides config unconditionally, regardless of its type; both
// absent means inherit the invoking session's model, today's behavior,
// unchanged). specEngineRenderStepForDispatch (in the region above) copies
// every step field into the dispatch envelope, so a step's own `model`
// already reaches sprintRunnerDispatch below with no glue changes needed to
// carry it. The run default lives at spec.config.model, which the dispatch
// context argument does not carry (only `{results, values}`), so it is read
// once below, near `const specInput = args`, straight from the raw workflow
// args instead. This glue never validates a model value at either level --
// pass-through only, presence decides the override, not type; an
// unrecognized or malformed model value fails loudly at the runtime's own
// agent() call, not here. An engine-synthesized envelope (spill-writer,
// digest-verify) carries no step.model of its own, so it always falls
// through to the run default.
//
// sprintRunnerAgentOpts(step, effectiveModel, schema) builds the opts
// object every agent() call below passes, so the `model` -> opts.model
// wiring and its omit-when-unset behavior live in one place instead of
// three near-identical copies across the three call arms below.
function sprintRunnerAgentOpts(step, effectiveModel, schema) {
  const opts = { label: step.id, phase: 'Run', schema: schema };
  if (typeof effectiveModel !== 'undefined') {
    opts.model = effectiveModel;
  }
  return opts;
}

// sprintRunnerDispatch(step, context) is the `dispatch(step, context) ->
// outcome` function specEngineExecute's own header comment (in the region
// above) requires: an async function called once per step, mapping every
// envelope the engine can hand it to one runtime agent() call. Three
// envelope shapes reach it, all read from engine-core.js above, none
// invented here:
//   - type 'agent' / 'gate' -- an author-declared spec step; `step.prompt`
//     is already rendered by the engine before dispatch. `step.outputSchema
//     .properties`, when the spec declares one, becomes the agent() call's
//     schema.
//   - type 'spill-writer' -- `{ path, prompt: <oversized content> }`; the
//     writer contract (specEngineApplySpillGuard above) requires the
//     returned outcome to be `{ written: true, path, sha256, bytes }`.
//   - type 'digest-verify' -- `{ path }`; the by-path digest-verify guard
//     above requires the returned outcome to be `{ digest }` (64-char
//     lowercase-hex).
// Any other `step.type` falls through to the same handling as 'agent'/
// 'gate' -- specEngineExecute never emits one today, but a forward-default
// keeps this glue from silently dropping an envelope a future engine
// addition introduces, rather than guessing at a new contract it was never
// told about.
async function sprintRunnerDispatch(step, context) {
  const effectiveModel = step.model !== undefined ? step.model : runDefaultModel;
  log(
    'dispatch: ' +
      step.id +
      ' (' +
      step.type +
      ')' +
      (typeof effectiveModel !== 'undefined' ? ' [' + effectiveModel + ']' : '')
  );

  if (step.type === 'spill-writer') {
    const schema = {
      type: 'object',
      properties: {
        written: { type: 'boolean' },
        path: { type: 'string' },
        sha256: { type: 'string' },
        bytes: { type: 'integer' },
      },
      required: ['written', 'path', 'sha256', 'bytes'],
      additionalProperties: false,
    };
    const prompt =
      'Write the content below, exactly as given between the two marker lines (no marker lines themselves), to the absolute path "' +
      step.path +
      '" -- create the containing directory first if it does not exist. Then compute the sha256 digest and byte count of the file you just wrote. Return {written: true, path: the absolute path you wrote, sha256: the 64-character lowercase-hex digest, bytes: the byte count}. If the write fails for any reason, return {written: false, path: "", sha256: "", bytes: 0}.\n' +
      '---CONTENT-BEGIN---\n' +
      step.prompt +
      '\n---CONTENT-END---';
    return agent(prompt, sprintRunnerAgentOpts(step, effectiveModel, schema));
  }

  if (step.type === 'digest-verify') {
    const schema = {
      type: 'object',
      properties: { digest: { type: 'string' } },
      required: ['digest'],
      additionalProperties: false,
    };
    const prompt = 'Compute the sha256 digest of the file at the absolute path "' + step.path + '". Return {digest: the 64-character lowercase-hex digest}.';
    return agent(prompt, sprintRunnerAgentOpts(step, effectiveModel, schema));
  }

  const schema =
    specEngineIsPlainObject(step.outputSchema) && specEngineIsPlainObject(step.outputSchema.properties)
      ? { type: 'object', properties: step.outputSchema.properties }
      : undefined;
  return agent(step.prompt, sprintRunnerAgentOpts(step, effectiveModel, schema));
}

const specInput = args;
// runDefaultModel: config.model, read once here (see the "model" comment
// above). args can arrive as an already-parsed object or as the spec's own
// raw JSON string (a measured platform fact -- the engine parses its own
// copy internally, independent of this read), so both shapes are read
// defensively; a parse failure on the string shape is swallowed into
// `undefined` here rather than thrown -- an actually-malformed spec is
// surfaced loudly by the engine's own validation/dispatch, not by this
// glue's own defaulting read.
let runDefaultModel;
if (specEngineIsPlainObject(specInput)) {
  runDefaultModel = specEngineIsPlainObject(specInput.config) ? specInput.config.model : undefined;
} else if (typeof specInput === 'string') {
  let parsedSpecInputForModel;
  try {
    parsedSpecInputForModel = JSON.parse(specInput);
  } catch (err) {
    parsedSpecInputForModel = undefined;
  }
  runDefaultModel =
    specEngineIsPlainObject(parsedSpecInputForModel) && specEngineIsPlainObject(parsedSpecInputForModel.config)
      ? parsedSpecInputForModel.config.model
      : undefined;
}
const runOutcome = await specEngineExecute(specInput, sprintRunnerDispatch);
return runOutcome;
