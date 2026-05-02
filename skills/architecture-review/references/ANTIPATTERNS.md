# Anti-Patterns Reference

An anti-pattern is an attractive-but-harmful solution. It appears to solve a problem and may even deliver short-term gains, but it backfires over time. Documenting anti-patterns is as important as documenting patterns — recognizing them early prevents design debt.

---

## Analysis Paralysis

**What:** A team stuck in endless analysis, never able to decide, causing the project to stall.

**Symptoms:**
- Constant revisiting of prior decisions
- No clear goals or success criteria
- Risk avoidance justifying every delay
- "Let's study this more" becomes the default response

**Remediation:**
- Set clear goals with measurable outcomes
- Timebox analysis phases with hard deadlines
- Encourage incremental progress and learning by doing
- Empower someone to call "analysis complete" and move forward

---

## Design By Committee

**What:** No single vision guides the system; all stakeholders must approve everything, leading to slow, incoherent decisions.

**Symptoms:**
- Political infighting over every technical choice
- No clear ownership or accountability
- Incoherent feature set reflecting competing agendas
- Consensus-seeking delays every decision

**Remediation:**
- Empower a small team or single architect to make final decisions
- Separate input (stakeholders provide context) from decision-making
- Document decisions clearly so everyone understands the reasoning
- Rotate decision authority to prevent bottlenecks

---

## Big Design Up Front (BDUF)

**What:** Detailed system design is completed and frozen before coding; rigid plans resist change as requirements evolve.

**Symptoms:**
- Wasted effort when requirements change (they always do)
- Code diverges significantly from the original design
- Late discovery that the design doesn't match reality
- Architecture feels imposed, not emergent

**Remediation:**
- Favor iterative design with frequent validation
- Allow architecture to emerge from refactoring as you learn
- Design in layers: sketch the boundary (coarse), code the interior (fine)
- Revisit assumptions regularly; update the design as understanding improves

---

## Big Ball of Mud

**What:** A haphazardly structured system with no recognizable architecture; unregulated growth creates tangled dependencies.

**Symptoms:**
- Information is shared promiscuously across the system
- No clear module boundaries or ownership
- Global or duplicated state everywhere
- Changes ripple unpredictably across the codebase

**Remediation:**
- Begin architectural refactoring: identify distinct subsystems
- Enforce module boundaries through build structure and dependency rules
- Introduce seams (abstractions) for testing and extensibility
- Gradually migrate toward a coherent layer structure

---

## God Class

**What:** A class that controls too many other objects and grows beyond all logic, becoming a grab-bag of unrelated responsibilities.

**Symptoms:**
- One class is referenced everywhere in the codebase
- Changes to it ripple throughout the system
- High fan-in; the class is tightly coupled to many others
- Often misapplied as a Mediator pattern

**Remediation:**
- Redistribute responsibilities to smaller, cohesive classes
- Extract related methods and data to separate classes
- Use composition to delegate work rather than centralize it
- Apply the Single Responsibility Principle strictly

---

## Spaghetti Code

**What:** Tangled, unstructured control flow making maintenance extremely difficult.

**Symptoms:**
- Deeply nested conditionals and loops
- Ad-hoc control flow resembling goto-style jumps
- No modularity; monolithic procedures doing multiple things
- Hard to reason about program state at any point

**Remediation:**
- Apply structured programming constructs: clear if/else, loops, functions
- Use Extract Method to break apart large functions
- Introduce guard clauses to handle edge cases early and reduce nesting
- Separate data structure logic from control flow

---

## Arrow Anti-Pattern

**What:** Deeply nested conditionals forming a rightward-drifting "arrow" shape, collapsing comprehension.

**Symptoms:**
- Code indentation drifts right with each conditional
- Comprehension collapses beyond 3 levels of nesting
- Hard to reason about the main flow
- Often indicates missing abstraction

**Remediation:**
- Use Guard Clauses (early exit on error conditions) to flatten structure
- Extract Method for loop bodies and nested blocks
- Consider a state machine or strategy pattern if logic is complex
- Refactor conditionals into polymorphic dispatch when appropriate

---

## Jumble Anti-Pattern

**What:** Horizontal (generic, cross-application) and vertical (app-specific) design elements intermixed without separation.

**Symptoms:**
- Architecture is unstable and non-reusable
- Dependencies between horizontal and vertical layers blur
- Changing shared infrastructure affects application code unexpectedly
- Hard to extract reusable components

**Remediation:**
- Separate horizontal layers (shared infrastructure, utilities) from vertical layers (application-specific logic)
- Enforce layer boundaries through build structure and abstraction
- Horizontal layers depend on nothing; vertical layers depend on horizontal, not vice versa
- Use Dependency Inversion to break cycles

---

## Stovepipe Anti-Pattern

**What:** Isolated systems built independently with no interoperability or shared services, leading to duplication and fragmentation.

**Symptoms:**
- Point-to-point integration everywhere; each system talks directly to each other
- Duplication of infrastructure, configuration, and utility logic across subsystems
- Difficult to add new systems (each must integrate with all existing ones)
- Low reusability

**Remediation:**
- Design for shared horizontal services; identify common infrastructure needs
- Extract reusable layers and build them once
- Introduce integration points (event buses, message queues) rather than direct coupling
- Define clear contracts between subsystems

---

## Global State Anti-Pattern

**What:** Excessive use of global variables creating hidden dependencies throughout the system.

**Symptoms:**
- Bugs appear when "nothing should have changed" (something mutated global state)
- Test isolation breaks; tests interfere with each other due to shared state
- Order dependencies; test success depends on execution sequence
- Hard to reason about preconditions at any point in the code

**Remediation:**
- Pass state explicitly as function parameters
- Encapsulate state in a single owner class (not scattered globals)
- Inject dependencies via constructor or factory
- Use thread-local or scope-bound storage where isolation is needed

---

## Anti-Pattern Taxonomy

Anti-patterns occur at all levels — development (code style), architecture (module structure), and management (process). The same root cause manifests differently at each level:

- **Root cause: unclear ownership** → God Class (architecture), Analysis Paralysis (process)
- **Root cause: fear of change** → Big Design Up Front, Big Ball of Mud (architecture debt)
- **Root cause: premature optimization** → Global State, Jumble Anti-Pattern (coupling)

Recognizing the root cause helps address the true problem, not just the symptom.

---

## Related Skills

- `oop-principles` — complementary; OOP provides patterns for sound design; anti-patterns document what to avoid
- `code-quality` — works at the code level; anti-patterns operate at module and system level
