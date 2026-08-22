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

// ===ENGINE-CORE-BEGIN===

const SPEC_ENGINE_KNOWN_STEP_KINDS = ['agent', 'gate', 'shape', 'parallel', 'map', 'scored-retry', 'branch'];
const SPEC_ENGINE_CONTAINER_STEP_KINDS = ['parallel', 'map', 'scored-retry', 'branch'];
const SPEC_ENGINE_PREDICATE_OPERATORS = ['equals', 'lte', 'gte'];
const SPEC_ENGINE_SCORED_RETRY_MODES = ['first-passing', 'keep-best'];
const SPEC_ENGINE_RESERVED_LITERAL_SEGMENT = 'attempts';
const SPEC_ENGINE_MAX_CONTAINER_DEPTH = 3;
const SPEC_ENGINE_NUMERIC_SEGMENT_RE = /^[0-9]+$/;

function specEngineIsPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
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

// ===ENGINE-CORE-END===

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    validateSpec: validateSpec,
  };
}
