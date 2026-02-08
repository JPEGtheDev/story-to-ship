# Story Templates

Template examples for different story types. Customize based on your domain and writing style.

---

## Feature Story Template

```markdown
**Title:** [Feature name – user-centric outcome]

**Type:** Feature  
**Size:** S | M | L  
**Epic:** [Parent feature or initiative]  
**Priority:** P0/P1/P2

---

### User Story

**As a** [user role: developer, tester, product manager]  
**I want to** [action/capability]  
**So that** [business value or outcome]

---

### Acceptance Criteria

- [ ] **Given** [precondition], **When** [action], **Then** [expected result]
- [ ] [Measurable outcome with metrics if applicable]
- [ ] [Edge case or error handling]
- [ ] [Performance or quality target]

### Example for Framebuffer Capture:

- [ ] **Given** an OpenGL context with a bound framebuffer, **When** `captureFrame()` is called, **Then** a PPM file is written to disk within 16ms
- [ ] Image data is captured with correct RGBA format and proper vertical flip (OpenGL origin compensation)
- [ ] Handles edge cases: no active framebuffer, resolution changes mid-capture
- [ ] File I/O succeeds with no memory leaks (validated with Valgrind)

---

### Technical Notes

**Dependencies:**
- None (or list upstream stories)

**Tech Stack:**
- Language, frameworks, libraries

**Files to Create/Modify:**
- `src/FramebufferCapture.hpp` (or target-state: `src/graphics/framebuffer_capture.hpp`)
- `src/FramebufferCapture.cpp` (or target-state: `src/graphics/framebuffer_capture.cpp`)
- `tests/FramebufferCaptureTests.cpp`

**Constraints:**
- Must work in headless mode (no display)
- Performance budget: <20ms per frame capture
- Compatible with Mesa drivers on Linux CI

---

### Definition of Done

- [ ] Code peer-reviewed and approved
- [ ] Unit tests pass (min 85% coverage on new code)
- [ ] Integration tested on Linux CI with Xvfb
- [ ] No new compiler warnings or linter errors
- [ ] Comments/docs for public API
- [ ] CHANGELOG.md updated
- [ ] Ready to merge to main branch
```

---

## Refactoring Story Template

```markdown
**Title:** [Refactoring target – specific outcome]

**Type:** Refactor  
**Size:** S | M  
**Component:** [Module/subsystem being refactored]  
**Motivation:** Technical Debt | Maintainability | Performance | Testing

---

### User Story

**As a** developer  
**I want to** [extract/reorganize/simplify this code]  
**So that** [make it easier to test/maintain/extend]

---

### Acceptance Criteria

- [ ] Extracted code is in a new class/module with clear responsibilities
- [ ] All existing tests pass without modification
- [ ] Cyclomatic complexity reduced from N to M
- [ ] No behavioral changes – refactoring only
- [ ] Code coverage maintained or improved

---

### Technical Notes

**Current State (Before):**
- Global variables: `framebuffer`, `window`, `particle_set`
- Issue: Hard to test in isolation, can't run tests in parallel

**Target State (After):**
- `FramebufferManager` class encapsulating framebuffer state
- `WindowManager` class managing window lifecycle
- All state passed as constructor dependencies

**Files to Create/Modify:**
- `src/graphics/FramebufferManager.hpp` (new)
- `src/graphics/FramebufferManager.cpp` (new)
- `src/main.cpp` (refactored to use new manager)

---

### Definition of Done

- [ ] Old code deleted (no dead code left behind)
- [ ] All tests pass on CI
- [ ] Code review completed
- [ ] No performance regression (benchmark before/after)
- [ ] Refactoring checklist applied (remove duplication, improve names, etc.)
```

---

## Spike Story Template

```markdown
**Title:** [Investigation goal – specific question to answer]

**Type:** Spike  
**Size:** S  
**Timebox:** [Max hours/days to investigate]  
**Decision Required:** [What choice needs to be made?]

---

### User Story

**As a** developer  
**I want to** investigate [unknown area]  
**So that** we can decide whether to [build/adopt/refactor/migrate]

---

### Acceptance Criteria

- [ ] Research document created with findings
- [ ] Proof-of-concept code (if applicable) demonstrates [key concern]
- [ ] Recommendation provided: [Option A / Option B / Make more data available]
- [ ] Known limitations and open questions documented
- [ ] Timebox respected – no runaway research

---

### Technical Notes

**Open Questions:**
1. Does Framework X support headless rendering?
2. What's the performance overhead of capturing frames every frame?
3. Can we integrate this without breaking existing CI pipeline?

**Research Methods:**
- Proof-of-concept implementation (2 hours)
- Benchmark against alternatives
- Team discussion and decision

---

### Definition of Done

- [ ] Research document in `/docs/spikes/`
- [ ] PoC code (if any) in temporary branch
- [ ] Decision recorded with rationale
- [ ] Follow-up story created for chosen path
```

---

## Bug Story Template

```markdown
**Title:** [Bug symptom – user-visible issue]

**Type:** Bug  
**Size:** S  
**Severity:** Critical | High | Medium | Low  
**Reproducibility:** Always | Sometimes | Unknown

---

### User Story

**As a** [affected user/developer]  
**I want to** [expected behavior]  
**So that** [outcome when fixed]

---

### Reproduction Steps

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected:** [What should happen]  
**Actual:** [What actually happens]

---

### Acceptance Criteria

- [ ] Root cause identified and documented
- [ ] Fix applied to source code
- [ ] Regression test added (prevents future occurrences)
- [ ] Verified on all supported platforms/configurations
- [ ] No new issues introduced by fix

---

### Technical Notes

**Likely Cause:** [Your best hypothesis]  
**Files Affected:** [Probable location]  
**Dependencies:** [Any blockers or related issues]

---

### Definition of Done

- [ ] Bug fixed and tested locally
- [ ] Regression test passes
- [ ] Code review approved
- [ ] Merged to main and verified in CI
- [ ] Backported to release branches (if applicable)
```

---

## Sub-task/Breakdown Example

When a larger story is broken into subtasks, use this format:

```markdown
**Parent Story:** Create Framebuffer Capture Utility

### Subtask 1: Design FramebufferCapture Class
- [ ] Define public API (methods, error codes)
- [ ] Document memory ownership (who deletes buffers?)
- [ ] Sketch architecture: OpenGL initialization, capture, conversion

**Estimate:** S (2–3 hours)

---

### Subtask 2: Implement Frame Capture
- [ ] Write FramebufferCapture::captureFrame() method
- [ ] Test with manual OpenGL context in isolated test
- [ ] Handle edge cases (no framebuffer bound, resolution mismatch)

**Estimate:** M (4–6 hours)  
**Depends on:** Subtask 1

---

### Subtask 3: Implement PPM File Writing
- [ ] Write pixel data to PPM format
- [ ] Ensure vertical flip is correct
- [ ] Test with ImageMagick `display` to verify output

**Estimate:** S (2–3 hours)  
**Depends on:** Subtask 2

---

### Subtask 4: Unit Tests & Integration
- [ ] Write GoogleTest tests for FramebufferCapture
- [ ] Mock OpenGL calls
- [ ] Test in headless mode with Xvfb

**Estimate:** M (4–6 hours)  
**Depends on:** Subtasks 2–3
```

---

## Customization Examples

### BDD-Style (Given/When/Then)
```markdown
- [ ] **Given** a valid OpenGL context, **When** captureFrame() is called with resolution 1920x1080, **Then** a 1920x1080 PPM file is created within 16ms
```

### Metric-Based
```markdown
- [ ] Frame capture latency ≤16ms (60 FPS budget)
- [ ] Memory overhead ≤50MB per capture
- [ ] Zero memory leaks (Valgrind report)
```

### File/Component Specific
```markdown
- [ ] Tests in `tests/core/FramebufferCaptureTests.cpp` (or target-state: `tests/graphics/FramebufferCaptureTests.cpp`)
- [ ] Implementation in `src/FramebufferCapture.{hpp,cpp}` (or target-state: `src/graphics/framebuffer_capture.{hpp,cpp}`)
```

---

## Tips for Good Story Templates

1. **Keep titles short and user-centric** – action-oriented, not technical jargon
2. **Use "As a / I want to / So that"** – grounds the story in user perspective
3. **Break large acceptance criteria into bullets** – easier to track progress
4. **Include Definition of Done** – prevents "almost done" stories
5. **Reference files and components** – clarifies scope and touchpoints
6. **Estimate subtasks, not epics** – individual subtasks should be S/M
