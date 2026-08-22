// Sprint engine core module.
//
// This file is the sprint engine's single-file implementation. Everything
// between the ENGINE-CORE-BEGIN and ENGINE-CORE-END markers below is a
// dialect-neutral region: it uses no import, export, require, or top-level
// return, so the same source text can be byte-copied into a plain
// CommonJS file or into a module-wrapped async execution context and
// parse standalone in either. Only top-level const/function declarations
// and ordinary statements appear inside the markers; later work adds more
// functions to this same region without disturbing what is here.
//
// Everything outside the markers is CommonJS-only plumbing (a guarded
// module.exports footer) that lets Node test files load the core region's
// functions directly; that footer is never copied anywhere.
//
// validateSpec(spec) is the first function in this file. It walks a
// parsed spec's step tree and returns the full list of structural
// violations it finds -- not fail-fast -- each violation carrying a JSON
// path to the offending location and a named diagnostic. An empty list
// means the spec is structurally valid. It performs zero dispatch: no
// agent calls, no filesystem access, pure data validation against the
// rules in SPEC_SCHEMA.md.
//
// Container-body field names (tracks/cases/default/steps/step, the
// outputSchema.properties shape, the predicate shape) follow the
// "Container authoring syntax" section of SPEC_SCHEMA.md; see that section
// for the full convention and its inferred-not-ratified disclosure.
//
// resolveReferences(spec) runs after validateSpec has already accepted a
// spec structurally. It walks the same step tree collecting two things:
// every reference site (a gate/branch-case predicate's {step, field} pair,
// and every {{...}} template placeholder in a shape step's template) and
// every result key the spec declares, per the "Result-key namespacing
// grammar" section of SPEC_SCHEMA.md. It returns the full list of
// references that do not resolve against the declared keys -- not
// fail-fast -- plus any reference that resolves to a real key but violates
// the parallel-track join ordering rule from that same section. It
// performs zero dispatch, exactly like validateSpec.
//
// specEngineEvalPredicate(predicate, results) is a runtime evaluator, not a
// static pass: it takes one already-resolved predicate object and the run's
// results-so-far map (a flat "namespaced result key -> that step's result
// value" object, per the same namespacing grammar) and applies the
// "Predicate operator vocabulary" and "Oversized-output spill contract"
// sections of SPEC_SCHEMA.md. Its return shape -- { halted, result } on a
// clean comparison, or { halted: true, path, diagnostic, message, value? }
// on a halt -- is this implementation's own choice, reusing the file's
// existing {path, diagnostic, message} violation shape; no ratified wording
// fixes a runtime-evaluator return type.

// ===ENGINE-CORE-BEGIN===

const SPEC_ENGINE_KNOWN_STEP_KINDS = ['agent', 'gate', 'shape', 'parallel', 'map', 'scored-retry', 'branch'];
const SPEC_ENGINE_CONTAINER_STEP_KINDS = ['parallel', 'map', 'scored-retry', 'branch'];
const SPEC_ENGINE_PREDICATE_OPERATORS = ['equals', 'lte', 'gte'];
const SPEC_ENGINE_SCORED_RETRY_MODES = ['first-passing', 'keep-best'];
const SPEC_ENGINE_RESERVED_LITERAL_SEGMENT = 'attempts';
const SPEC_ENGINE_MAX_CONTAINER_DEPTH = 3;
const SPEC_ENGINE_NUMERIC_SEGMENT_RE = /^[0-9]+$/;
const SPEC_ENGINE_UNDEFINED_SENTINEL = '<<undefined>>';

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

  // declaredAtOrder is the DFS order at which the declaring step STARTS
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

// ===ENGINE-CORE-END===

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    validateSpec: validateSpec,
    resolveReferences: resolveReferences,
    specEngineEvalPredicate: specEngineEvalPredicate,
  };
}
