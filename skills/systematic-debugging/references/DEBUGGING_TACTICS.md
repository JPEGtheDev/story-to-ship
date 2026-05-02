# Debugging Tactics Reference

Source: Ward Cunningham's C2 wiki audit — tactics for investigating failures, working with legacy code, and designing for testability.

---

## Design for Testability: Instrumented Test Modes

Build test instrumentation into code during initial development, not after. Add test-mode hooks that expose timing, state, and control flow:

```cpp
class ParticleUpdater {
#ifdef TEST_MODE
    std::chrono::milliseconds testingDelay{0};
public:
    void setTestDelay(std::chrono::milliseconds d) { testingDelay = d; }
#endif

    void update() {
#ifdef TEST_MODE
        std::this_thread::sleep_for(testingDelay);
#endif
        // ... actual update logic
    }
};
```

Configurable delays expose race conditions. Extracting timing-sensitive operations into small methods makes them individually testable. The `#ifdef TEST_MODE` trade-off is accepted — correctness outweighs purity.

Diagnostic pattern: reproduce the bug with a failing test **first**, then fix. The test becomes the regression guard.

---

## Software Seams (Legacy Code)

A seam is a place where behavior can be changed without editing the code at that location. Michael Feathers: legacy code is code without unit tests.

**Finding seams in GL code:**
- GL state mutation functions (texture binding, buffer upload) are seams if wrapped behind an interface
- Event dispatch callbacks are seams if the handler is injected rather than hardcoded
- Shader compilation is a seam if `IOpenGLContext::compileShader()` is mockable

To add tests to legacy code: identify a seam, inject a test double through it, SafeGuard the existing behavior with characterization tests before refactoring.

---

## Characterization Tests Before Refactoring

Before refactoring untested code, record its current output as "golden" values:

1. Run the code and capture its current output (pixel values, log lines, state transitions)
2. Write tests that assert the golden output — these are characterization tests
3. Refactor until the characterization tests pass
4. Discard the characterization tests once the feature under development is covered by intent-driven tests

This verifies behavioral identity through the refactor without requiring deep understanding of the original code first.

---

## Spike Before Large Refactors

Distinguish small smell-driven refactors (do them inline) from large structural refactors (require a spike):

1. **Small refactor:** code smell visible, fix is local, tests still pass → do it now
2. **Large refactor:** requires touching 5+ files, unclear whether approach works → spike on a branch first

Spike: minimal proof-of-concept that answers the structural question. If it works, roll out via simple refactorings. If it fails, discard the branch — no harm done.

---

## White-Box Testing for Failure Paths

White-box testing accesses implementation internals to verify boundary conditions and failure handling:

- **Fault injection:** trigger GL error states (`GL_OUT_OF_MEMORY`, invalid enum) to verify error-handling code
- **Interface robustness:** analyze the implementation for precondition violations; write tests that trigger each one
- **Seam-based injection:** replace real GL context with a fault-injecting mock for specific failure scenarios

Test coverage is one form of white-box testing, but not the only one. Structural analysis of code identifies cases that random coverage misses.

---

## Virtual Functions Across Process Boundaries

See `cpp-patterns/references/SAFETY_PATTERNS.md — Virtual Functions and Shared Memory Hazard` for full structural explanation.

**Detection signal:** segfault on first virtual method call when the object was received via IPC — the vtable pointer is invalid in the receiving process's address space.
**Fix:** serialize to a plain-data structure on the sending side; reconstruct the polymorphic object on the receiving side.

---

## When to Refactor vs When to Spike

| Situation | Response |
|---|---|
| Code smell is local, fix is obvious | Refactor now (MercilessRefactoring) |
| Smell requires touching many files | Spike on branch first |
| Architecture change, unclear outcome | Spike, timebox to 20 minutes |
| Spike succeeds | Roll out via simple refactorings |
| Spike fails | Discard branch, try a different approach |

---

## Feynman Algorithm (Write It Down First)

Before running a debugger, opening a code editor, or dispatching an agent: write down the problem.

Write one paragraph containing:
1. What was expected to happen
2. What actually happened
3. Where the divergence was first observed
4. What you have already ruled out

If you cannot write this paragraph, you do not understand the problem yet. Return to observation. The act of writing forces the precision that silent thought avoids. "Writing exposes what you don't know" — Feynman.

Corollary: if a subagent cannot restate the problem in its own words at the start of its output, its diagnosis is likely to be wrong. Source: C2 Wiki "FeynmanAlgorithm".

---

## BandAid Detection (Fix vs. Root Cause)

Before committing any fix, run the BandAid check:

A **BandAid** addresses the symptom without removing the cause. Signals:
- The fix works but requires a qualifier: "this shouldn't happen anyway"
- The fix changes caller behavior: "callers should not pass null here"
- The fix is not testable in isolation — it only works with specific surrounding state
- A new symptom appears after the fix

A **real fix** can be explained in terms of the root cause: "This failed because X; removing X prevents the failure."

If you cannot explain the fix in terms of the root cause, stop. Find the root cause first. See also: `code-quality/references/DESIGN_PRINCIPLES.md — BandAid Anti-Pattern` for the design-level definition. Source: C2 Wiki "BandAid".

---

## RubberDucking (Explain the Problem Aloud)

Explaining a problem to an external listener — a rubber duck, a colleague, or an agent — forces sufficient precision that the solution often becomes apparent without further investigation.

Why it works: speaking (or writing for an imaginary listener) engages different cognitive processes than silent thought. The friction slows down racing assumptions. You must sequence the facts in a communicable order, which surfaces gaps you didn't notice.

Writing an unsent message achieves most of the benefit without acoustic feedback.

The test: "Once a problem is described in sufficient detail, its solution is obvious." If the solution is not obvious after describing the problem, the description is not yet detailed enough. Keep describing.

Applied to agent-assisted debugging: prompt the agent to explain the problem before proposing a fix. The explanation pass replicates rubber-ducking at scale. Source: C2 Wiki "RubberDucking".

---

## Fail Fast

Terminate immediately on encountering irrecoverable state corruption rather than allowing corrupt state to propagate. General principle; see `cpp-patterns/references/SAFETY_PATTERNS.md — Fail Fast` for C++ implementation details (assertions, `std::terminate`, structured logging).

---

## Related Skills

- `systematic-debugging` — four-phase root cause protocol; HeisenBug patterns
- `testing` — test taxonomy; saw-test-fail gate
- `cpp-safety` — resource ownership patterns; exception-safe destructors
