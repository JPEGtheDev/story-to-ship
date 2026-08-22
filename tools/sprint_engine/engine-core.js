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
//
// specEngineRenderTemplate(value, results, values) is a runtime evaluator
// for the "Template forms and reference resolution" section, sibling to
// specEngineEvalPredicate: it walks a template value (a string, or an
// object/array of such strings, matching the shape a shape step's own
// "template" field carries) and substitutes every {{step.field}},
// {{values.PATH}}, and {{#if}} placeholder it finds against `results` (the
// same flat namespaced-key map specEngineEvalPredicate reads) and `values`
// (the spec's config.values object). It reuses specEngineResolveFieldPath
// for dotted-path walks and specEngineMakeHalt for its halt shape, and
// applies the same spilled-content-is-illegal check specEngineEvalPredicate
// applies, under its own template-prefixed diagnostic name. Rendering is
// fail-fast: the first unresolved reference or spilled-content violation
// halts the whole render (this document's "halts the run" wording, unlike
// validateSpec/resolveReferences' collect-everything static passes), and
// its return shape -- { halted: false, value: <rendered> } or { halted:
// true, path, diagnostic, message, value? } -- mirrors
// specEngineEvalPredicate's own runtime-evaluator return shape.
//
// specEngineTokenOverlap, specEngineExtractLabeledLine,
// specEngineSliceFromMarker, specEngineFirstMatchOf, and
// specEngineRegexExtract are five pure text-extraction primitives -- no
// halt machinery, no results-map lookups, no dispatch. Each returns an
// explicit, documented miss value on a no-match or empty-input case
// instead of throwing or returning undefined-by-accident. See each
// function's own header comment below for its contract sourcing (only
// specEngineTokenOverlap is named in SPEC_SCHEMA.md; the other four are
// fully INFERRED, disclosed individually). Purity here means identical
// arguments always produce identical results: specEngineFirstMatchOf and
// specEngineRegexExtract accept caller-supplied RegExp objects, and a
// global-flag ('g') RegExp carries mutable match-position state
// (lastIndex) on that same object across calls -- left unhandled, a
// second call with the identical pattern and text would silently resume
// from wherever the first call's match left off, rather than repeating
// the same match. Both functions reset lastIndex to 0 on every pattern
// immediately before using it, so a caller-supplied global-flag pattern
// is tolerated without breaking either function's own purity.

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
// in order, for the three leaf step kinds only: agent, gate, shape.
// Container step kinds (parallel, map, scored-retry, branch) are a later
// capability -- meeting one at execute time is never a silent skip; the
// loop halts immediately with a named 'container-step-not-supported'
// diagnostic, the same {path, diagnostic, message} halt shape every other
// halt in this file uses.
//
// Dispatch capability is injected, not owned by this file: the caller
// supplies `dispatch`, an async function `dispatch(step, context) ->
// outcome`, called once per agent or gate step, in step order, and always
// awaited before the loop moves to the next step -- this is what makes
// dispatch order observable to a caller-supplied stub. `context` is
// `{ results, values }`: `results` is the SAME flat namespaced-key results
// map object specEngineEvalPredicate and specEngineRenderTemplate read
// elsewhere in this file (not a copy), so a dispatcher can itself resolve
// further references if it needs to; `values` is spec.config.values (or an
// empty object when absent), the same config-values object
// specEngineRenderTemplate's `values` parameter reads for {{values.PATH}}.
// specEngineExecute carries no dispatch primitive of its own -- shape steps
// are the only leaf kind that never calls `dispatch`, since a shape step's
// output is computed in-engine by rendering its own `template` field.
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
// step id, per the "Result-key namespacing grammar" section (this loop
// only ever produces top-level, unnamespaced keys, since it does not
// recurse into any container step): an agent step's result is whatever its
// dispatch outcome was; a shape step's result is its rendered template
// value; a gate step's result is its raw dispatch outcome, but ONLY when
// that gate's verdict resolved to "pass" -- a gate that halts the run
// (verdict "fail" or "uncertain") is not a completed step, so its own
// outcome is deliberately left out of the returned results map (it is
// still visible in the halt object and in the trace entry for that step).
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
// `status` is one of "completed" (every step ran, no halt), "gated" (a
// gate's verdict was "fail"), "uncertain" (a gate's verdict could not be
// trusted, by any of the three causes above), or "failed" (every other
// halt cause: a container step kind, a predicate-form gate, a
// null/undefined dispatch outcome for an agent step, a malformed spec, or
// a template-render halt for an agent step's prompt or a shape step's
// template). `results` is the accumulated results map, partial on any
// non-"completed" status. `trace` is an ordered array with one entry per
// step actually attempted -- a container step or a predicate-form gate
// that halts the loop is NOT added to the trace, since neither was ever
// attempted as a leaf step; each entry is
// { step, kind, status, outcome, flags }, `flags` non-empty only for a
// gate step whose say-vs-do check tripped. `halt` is null when `status`
// is "completed", otherwise the halt object every halt-returning function
// in this file returns -- built with specEngineMakeHalt (so it carries
// the same {path, diagnostic, message, halted: true} shape as every other
// halt in this file), or forwarded directly from a render halt, which
// already carries that shape.
//
// Malformed-spec guards reuse validateSpec's own 'spec-not-object' and
// 'steps-not-array' diagnostics for the same defect classes, since
// specEngineExecute is not itself a structural validator (that is
// validateSpec's job, expected to run before execute) but must still fail
// loudly rather than throw on a spec that never got validated.

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

async function specEngineExecute(spec, dispatch) {
  if (!specEngineIsPlainObject(spec)) {
    return specEngineMakeExecuteResult(
      'failed',
      {},
      [],
      specEngineMakeHalt('', 'spec-not-object', 'A spec must be a JSON object with "steps" and "config".')
    );
  }
  if (!Array.isArray(spec.steps)) {
    return specEngineMakeExecuteResult(
      'failed',
      {},
      [],
      specEngineMakeHalt('steps', 'steps-not-array', 'spec.steps must be an array of step objects.')
    );
  }

  const values = specEngineIsPlainObject(spec.config) && specEngineIsPlainObject(spec.config.values) ? spec.config.values : {};
  const results = {};
  const trace = [];

  for (let i = 0; i < spec.steps.length; i += 1) {
    const step = spec.steps[i];
    const path = 'steps[' + i + ']';

    if (!specEngineIsPlainObject(step)) {
      return specEngineMakeExecuteResult(
        'failed',
        results,
        trace,
        specEngineMakeHalt(path, 'step-not-object', 'Each step must be a JSON object.')
      );
    }

    const stepId = step.id;
    const type = step.type;

    if (SPEC_ENGINE_CONTAINER_STEP_KINDS.indexOf(type) !== -1) {
      // Loud failure, never a silent skip: container kinds are a later
      // capability this loop does not implement.
      return specEngineMakeExecuteResult(
        'failed',
        results,
        trace,
        specEngineMakeHalt(
          path,
          'container-step-not-supported',
          'Step "' +
            stepId +
            '" is a container step kind ("' +
            type +
            '"); specEngineExecute only runs the three leaf kinds (agent, gate, shape) -- container execution is a later capability.'
        )
      );
    }

    if (type === 'shape') {
      const templateValue = specEngineIsPlainObject(step.template) ? step.template : {};
      const rendered = specEngineRenderTemplate(templateValue, results, values, path + '.template');
      if (rendered.halted) {
        return specEngineMakeExecuteResult('failed', results, trace, rendered);
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
        return specEngineMakeExecuteResult(
          'failed',
          results,
          trace,
          specEngineMakeHalt(
            path,
            'gate-predicate-form-not-supported',
            'Gate step "' +
              stepId +
              '" carries a "predicate" field; predicate-form gates are not dispatched by this executor and are rejected until container support lands.'
          )
        );
      }

      const dispatchPrep = specEngineRenderStepForDispatch(step, results, values, path);
      if (dispatchPrep.halted) {
        return specEngineMakeExecuteResult('failed', results, trace, dispatchPrep);
      }

      const outcome = await dispatch(dispatchPrep.step, { results: results, values: values });

      if (type === 'agent') {
        if (outcome === null || typeof outcome === 'undefined') {
          trace.push({ step: stepId, kind: type, status: 'failed', outcome: outcome, flags: [] });
          return specEngineMakeExecuteResult(
            'failed',
            results,
            trace,
            specEngineMakeHalt(
              path,
              'agent-dispatch-null-result',
              'Agent step "' +
                stepId +
                '" dispatch returned no result (null/undefined); halting rather than hanging or silently continuing.'
            )
          );
        }
        results[stepId] = outcome;
        trace.push({ step: stepId, kind: type, status: 'completed', outcome: outcome, flags: [] });
        continue;
      }

      // type === 'gate'
      const verdictOutcome = specEngineResolveGateVerdict(step, outcome, path);

      if (verdictOutcome.verdict === 'uncertain') {
        trace.push({ step: stepId, kind: type, status: 'uncertain', outcome: outcome, flags: verdictOutcome.flags });
        return specEngineMakeExecuteResult('uncertain', results, trace, verdictOutcome.halt);
      }

      if (verdictOutcome.verdict === 'fail') {
        trace.push({ step: stepId, kind: type, status: 'gated', outcome: outcome, flags: verdictOutcome.flags });
        return specEngineMakeExecuteResult('gated', results, trace, verdictOutcome.halt);
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
    return specEngineMakeExecuteResult(
      'failed',
      results,
      trace,
      specEngineMakeHalt(
        path + '.type',
        'unknown-step-kind',
        'Step kind "' + type + '" is not one of the seven recognized step kinds.'
      )
    );
  }

  return specEngineMakeExecuteResult('completed', results, trace, null);
}

// ===ENGINE-CORE-END===

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    validateSpec: validateSpec,
    resolveReferences: resolveReferences,
    specEngineEvalPredicate: specEngineEvalPredicate,
    specEngineRenderTemplate: specEngineRenderTemplate,
    specEngineTokenOverlap: specEngineTokenOverlap,
    specEngineExtractLabeledLine: specEngineExtractLabeledLine,
    specEngineSliceFromMarker: specEngineSliceFromMarker,
    specEngineFirstMatchOf: specEngineFirstMatchOf,
    specEngineRegexExtract: specEngineRegexExtract,
    specEngineExecute: specEngineExecute,
  };
}
