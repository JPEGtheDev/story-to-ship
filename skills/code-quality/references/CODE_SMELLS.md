# Code Smells Catalog

Source: Martin Fowler's _Refactoring_ — canonical code smells that signal deeper design problems and indicate where refactoring is needed.

---

## The 18 Canonical Code Smells

### 1. Long Method

**What it looks like:** A method that exceeds 10–20 lines, or mixes multiple levels of abstraction, or has nested control structures three or more levels deep.

**Why it hurts:**
- Hard to understand, test, and reuse
- Mixing abstraction levels confuses readers about intent
- Business logic scattered across the method makes it fragile to change

**Primary Refactorings:** Extract Method, Replace Temp with Query

---

### 2. Long Parameter List

**What it looks like:** A function or method signature with more than three parameters; callers struggle to remember the order and meaning.

**Why it hurts:**
- Difficult to remember parameter order and purpose
- Type mismatch errors at call sites
- Changes to signature propagate widely

**Primary Refactorings:** Introduce Parameter Object, Replace Parameter with Method, introduce a lightweight context object

---

### 3. Feature Envy

**What it looks like:** A method calls getters or accesses data on a different object more often than it uses its own data.

**Why it hurts:**
- The method is in the wrong class; it envies another's behavior
- Indicates misplaced responsibility
- Makes the envied class harder to change

**Primary Refactorings:** Move Method to the envied class, Extract Method to create a more focused responsibility

---

### 4. Data Clumps

**What it looks like:** The same group of variables (e.g., `startX`, `startY`, `endX`, `endY`) appears together in multiple places — method signatures, class fields, function calls.

**Why it hurts:**
- Reveals missing abstraction; domain concept is unnamed
- Changes to the cluster require updates in many places
- Type safety is lost (primitives don't enforce semantic meaning)

**Primary Refactorings:** Extract Class, introduce a Value Object (e.g., `Rectangle`, `Point`, `DateRange`)

---

### 5. Primitive Obsession

**What it looks like:** Domain concepts are represented as primitives instead of objects — e.g., a phone number as a string, a currency amount as a double, a date range as two separate integers.

**Why it hurts:**
- Validation scattered throughout the codebase
- Business logic leaks into unrelated functions
- No compile-time guarantees about semantic correctness
- Primitive comparisons lose meaning (is 42 a valid age? a valid ID?)

**Primary Refactorings:** Introduce Value Objects for domain concepts (Money, Date, UserId, PhoneNumber, etc.)

---

### 6. Switch Statement Smell

**What it looks like:** Switch statements or if-chains that recur in multiple places, each branch handling a type or state. New types force edits in multiple methods.

**Why it hurts:**
- Violates Once and Only Once (OAOO); logic is duplicated across the codebase
- Each new case requires changes in multiple places (shotgun surgery)
- Tight coupling between the type and its behavior handlers
- Hard to add new types without breaking existing code

**Primary Refactorings:** Replace Conditional with Polymorphism, Replace Type Code with State/Strategy Pattern

---

### 7. Duplicated Code

**What it looks like:** The same code structure appears in two or more places — identical or nearly identical blocks, loops, conditionals, or methods.

**Why it hurts:**
- Violates DRY (Don't Repeat Yourself)
- Bug fixes must be applied in multiple places; inconsistencies emerge
- Maintenance burden scales with the number of copies
- Harder to understand the intent when similar code diverges

**Primary Refactorings:** Extract Method, Extract Class, introduce a shared utility or base class (balance cost of fixing vs. maintaining)

---

### 8. Lazy Class

**What it looks like:** A class that does very little — minimal methods, minimal responsibility, or acts as a simple pass-through to another class.

**Why it hurts:**
- Adds complexity without proportional benefit
- Increases mental load; readers must understand why it exists
- Makes the codebase harder to navigate

**Primary Refactorings:** Collapse Hierarchy (merge with parent or child), Inline Class (remove unnecessary wrapper)

---

### 9. Speculative Generality

**What it looks like:** Abstractions, parameters, or methods added "just in case" — for scenarios that may never occur, or for frameworks that are not yet needed.

**Why it hurts:**
- Dead code accumulates; harder to understand what is actually used
- "Future-proofing" creates cognitive burden without present-day value
- The imagined scenario may never materialize or may materialize differently
- Increased surface area for bugs and maintenance

**Primary Refactorings:** Remove unused code and layers (embrace YAGNI — You Aren't Gonna Need It), Simplify design

---

### 10. Temporary Field

**What it looks like:** An instance variable that is only populated and used in certain code paths; sometimes null, sometimes set, lifecycle unclear.

**Why it hurts:**
- Breaks encapsulation; callers must understand which methods populate the field
- Makes the class's contract unclear and fragile
- Suggests the variable belongs elsewhere or has misplaced responsibility
- Null-checks scatter throughout the code

**Primary Refactorings:** Extract Class (move the temporary field and the methods that use it into a separate class), Replace with Parameter

---

### 11. Message Chains

**What it looks like:** Long chains of method calls — `a.getB().getC().getD().doSomething()` — where the caller must navigate the entire chain and depend on intermediate structure.

**Why it hurts:**
- Tight coupling to navigation structure; changes propagate
- Violates Law of Demeter (a method should talk to immediate neighbors, not traversing through them)
- Makes the client responsible for knowing the internal path
- Fragile: if `B` is refactored, all callers break

**Primary Refactorings:** Move Method (move the operation closer to the data), introduce a Facade method that hides the chain

---

### 12. Middle Man

**What it looks like:** A class that delegates most or all of its work to another class, adding little value — mostly forwarding calls without transformation.

**Why it hurts:**
- Adds a layer of indirection without benefit
- Increases maintenance burden; changes must propagate through the middle man
- Obscures intent; the reader doesn't understand why this class exists
- (Exception: intentional Facade or Mediator patterns add value through simplified interface)

**Primary Refactorings:** Inline Class (remove the middle man and call the delegate directly), unless the middle man is an intentional Facade/Mediator

---

### 13. Inappropriate Intimacy

**What it looks like:** One class reaches into another class's private or protected data or methods; the boundary is blurred — they know too much about each other's internals.

**Why it hurts:**
- Tight coupling between classes; changes break both
- Responsibility is unclear; data is accessed from multiple places
- Harder to test in isolation; the classes are intertwined
- Encapsulation is violated; internal details leak

**Primary Refactorings:** Move Method/Field (move methods or data to the class where they belong), realign responsibilities, introduce a cleaner interface

---

### 14. Data Class

**What it looks like:** A class that has only fields and getter/setter methods, with little to no behavior — a container for data.

**Why it hurts:**
- Violates object-oriented design; data is separated from the behavior that operates on it
- Callers implement business logic on the data externally, scattering behavior across the codebase
- The class is a "dumb container" that doesn't enforce invariants

**Primary Refactorings:** Move behavior to the data class (clients that call getters should move their logic here), encapsulate operations alongside the data

---

### 15. Refused Bequest

**What it looks like:** A subclass doesn't use or need many of the methods or data from its parent class; it refuses the inheritance.

**Why it hurts:**
- Inheritance is meant to model "is-a" relationships; refusing the parent's contract breaks that
- Readers are confused: the subclass type suggests it has parent behavior that it doesn't use
- May indicate the hierarchy is wrong
- Liskov Substitution Principle is violated

**Primary Refactorings:** Replace Inheritance with Delegation (use composition; the subclass wraps the parent as a collaborator rather than inheriting from it), or restructure the hierarchy

---

### 16. Divergent Change

**What it looks like:** A single class must be modified for different reasons — e.g., one change is for database schema updates, another for UI changes. The class has multiple reasons to change.

**Why it hurts:**
- Violates Single Responsibility Principle
- Unrelated changes are entangled; modifying the class for one reason risks breaking another
- Harder to understand and test the class's true responsibility
- Increasing fragility as each new reason multiplies the maintenance burden

**Primary Refactorings:** Extract Class (create separate classes for each responsibility), organize by reason to change

---

### 17. Shotgun Surgery

**What it looks like:** One small, logical change requires editing many small pieces in many different places — the change "spreads" across the codebase.

**Why it hurts:**
- Opposite of Divergent Change but same root cause: related responsibilities are scattered
- Easy to miss a location and introduce inconsistencies or bugs
- High cost of change; maintenance is error-prone
- Indicates poor encapsulation or cohesion

**Primary Refactorings:** Move Method/Field (concentrate related changes together), Extract Class, introduce shared abstractions

---

### 18. Parallel Inheritance Hierarchies

**What it looks like:** For every subclass of class A, you must create a corresponding subclass of class B — the hierarchies mirror each other.

**Why it hurts:**
- Maintenance burden doubles; creating a new type requires parallel changes
- Indicates artificial design; the coupling should be more explicit
- Violates Once and Only Once
- Harder to understand the relationship between the parallel classes

**Primary Refactorings:** Collapse pairs (eliminate the parallel hierarchy; use composition or delegation instead of inheritance), consolidate into a single hierarchy with better responsibility distribution

---

## When to Investigate: Detection Heuristics

These thresholds are **triggers to investigate**, not absolute violations. Use them as signals to review and assess whether refactoring is justified in your context.

| Heuristic | Threshold | Indicates |
|-----------|-----------|-----------|
| Method length | > 20 lines | Possible Long Method; review for extract opportunities |
| Cyclomatic complexity / nesting depth | > 2 levels | Complex control flow; candidate for Extract Method |
| Parameter count | > 3 parameters | Long Parameter List; consider Parameter Object |
| Public methods per class | > 10 | Class may have too many responsibilities (Divergent Change) |
| Data field access from other class | Frequent cross-class gets | Feature Envy; consider moving method |
| Duplication ratio | Same code in 2+ locations | Duplicated Code; extract common logic |
| Cyclic dependencies | Module A → B → A | Architectural problem; split responsibilities |
| Null checks for a field | 3+ null checks in class | Temporary Field; extract or refactor |
| Method call chains | 4+ in sequence | Message Chains; introduce intermediary method |
| Unused code paths | Code only executed in rare scenarios | Speculative Generality; consider removal |

---

## Key Principles

**All code smells trace back to three root violations:**
1. **DRY (Don't Repeat Yourself)** — Duplication of logic, structure, or intent
2. **OAOO (Once and Only Once)** — A concept or responsibility appears in multiple places
3. **Single Responsibility** — A class or method has more than one reason to change

When you detect a smell:
- **Understand the root cause** — Which principle is violated?
- **Assess the cost** — Is the code a temporary placeholder, core logic, or rarely touched? Fixing a core algorithm is more valuable than cosmetic refactoring.
- **Choose the appropriate refactoring** — Different smells have different remedies; applying the wrong one can make things worse.

**Design smells** (higher-level: Parallel Inheritance Hierarchies, Divergent Change, Shotgun Surgery, Message Chains) often point to architectural problems that cannot be solved by simple refactoring. These may require architectural review and larger restructuring.

---

## Extended Code Smells Checklist

| Smell | What to Look For |
|---|---|
| **FeatureEnvy** | Method references another class's data more than its own? Apply MoveMethod. |
| **MagicNumber** | Literals in GL calls or formulas? Name them as constants. |
| **ArrowAntiPattern** | More than 3 levels of nesting? Introduce guard clauses or RAII. |
| **SpeculativeGenerality** | Abstraction with exactly one implementation? Remove it until a second arrives. |
| **CommentSubstitutingForCode** | Comment explains WHAT the code does (not WHY)? Rename or refactor instead. |

---

## Code Duplication: Once And Only Once vs Don't Repeat Yourself

These two principles are frequently conflated but target different problems:

| Principle | Source | What it targets | How to fix |
|-----------|--------|-----------------|------------|
| **Once And Only Once** | Ward Cunningham / Extreme Programming | The same *code logic* appears in two or more places | Refactor: extract a method, function, or class |
| **Don't Repeat Yourself** | Hunt & Thomas, *The Pragmatic Programmer* | The same *knowledge or fact* is encoded in two or more places, even if the code looks different | Introduce a single authoritative source of truth |

**Key distinction:** Two code blocks can look identical yet not violate Don't Repeat Yourself if they represent two independent domain concepts that happen to look similar today. Merging them creates false coupling. Conversely, two code blocks can look completely different yet violate Don't Repeat Yourself if they both encode the same business rule.

| Situation | Principle violated | Correct action |
|-----------|-------------------|----------------|
| Same validation logic repeated in three `if` blocks | Once And Only Once | Extract a `validate()` function |
| Maximum buffer size duplicated as a constant and a comment | Don't Repeat Yourself | Remove the comment; the constant is the source of truth |
| Two classes share a 3-line helper computing screen coordinates | Once And Only Once | Extract to a shared utility |
| Database schema and response struct both define "a user has email and name" | Don't Repeat Yourself | Generate one from the other, or treat one as the source of truth |
| Two unrelated features happen to iterate in the same way | Neither | Leave them separate; forced unification creates accidental coupling |
