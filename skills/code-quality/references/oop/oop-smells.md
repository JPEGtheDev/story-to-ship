# Code Smells -- OOP Specific

Source: Martin Fowler's _Refactoring_. These smells require class or inheritance concepts.
Apply when working on class-based code. For universal smells see `../code-smells.md`.

---

### 1. Feature Envy

**What it looks like:** A method calls getters or accesses data on a different object more often than it uses its own data.

**Why it hurts:** The method is in the wrong class. Indicates misplaced responsibility.

**Primary Refactorings:** Move Method to the envied class

---

### 2. Data Clumps

**What it looks like:** The same group of variables appears together in multiple places -- method signatures, class fields, function calls.

**Why it hurts:** Reveals missing abstraction; domain concept is unnamed. Type safety is lost.

**Primary Refactorings:** Extract Class, introduce a Value Object (Point, DateRange, etc.)

---

### 3. Primitive Obsession

**What it looks like:** Domain concepts represented as primitives -- phone number as a string, currency as a double, date range as two integers.

**Why it hurts:** Validation scattered throughout. No compile-time guarantees about semantic correctness.

**Primary Refactorings:** Introduce Value Objects (Money, UserId, PhoneNumber)

---

### 4. Switch Statement Smell

**What it looks like:** Switch statements or if-chains recurring in multiple places, each branch handling a type or state.

**Why it hurts:** Logic duplicated across the codebase. Each new case requires changes in multiple places.

**Primary Refactorings:** Replace Conditional with Polymorphism, Replace Type Code with State/Strategy

---

### 5. Lazy Class

**What it looks like:** A class that does very little -- minimal methods, or acts as a pass-through to another class.

**Why it hurts:** Adds complexity without benefit. Readers must understand why it exists.

**Primary Refactorings:** Collapse Hierarchy, Inline Class

---

### 6. Temporary Field

**What it looks like:** An instance variable only populated in certain code paths; sometimes null, lifecycle unclear.

**Why it hurts:** Breaks encapsulation. Callers must understand which methods populate the field.

**Primary Refactorings:** Extract Class (move the temporary field and the methods that use it)

---

### 7. Message Chains

**What it looks like:** Long chains of method calls -- `a.getB().getC().getD().doSomething()`.

**Why it hurts:** Tight coupling to navigation structure. Violates Law of Demeter.

**Primary Refactorings:** Move Method, introduce a Facade method that hides the chain

---

### 8. Middle Man

**What it looks like:** A class that delegates most of its work to another class, adding little value.

**Why it hurts:** Adds indirection without benefit. (Exception: intentional Facade or Mediator.)

**Primary Refactorings:** Inline Class, unless the middle man is an intentional Facade

---

### 9. Inappropriate Intimacy

**What it looks like:** One class reaches into another class's private data or methods; the boundary is blurred.

**Why it hurts:** Tight coupling. Encapsulation violated. Harder to test in isolation.

**Primary Refactorings:** Move Method/Field, realign responsibilities

---

### 10. Data Class

**What it looks like:** A class with only fields and getters/setters; little to no behavior.

**Why it hurts:** Data separated from the behavior that operates on it. Callers implement business logic externally.

**Primary Refactorings:** Move behavior to the data class; encapsulate operations alongside data

---

### 11. Refused Bequest

**What it looks like:** A subclass doesn't use or need many of the methods from its parent.

**Why it hurts:** Liskov Substitution Principle violated. Inheritance hierarchy is wrong.

**Primary Refactorings:** Replace Inheritance with Delegation

---

### 12. Parallel Inheritance Hierarchies

**What it looks like:** For every subclass of A, you must create a corresponding subclass of B.

**Why it hurts:** Maintenance burden doubles. Creating a new type requires parallel changes.

**Primary Refactorings:** Collapse pairs, use composition over inheritance

---

## OOP Detection Heuristics

| Heuristic | Threshold | Indicates |
|-----------|-----------|-----------|
| Public methods per class | > 10 | Too many responsibilities (Divergent Change) |
| Data field access from other class | Frequent cross-class gets | Feature Envy |
| Null checks for a field | 3+ null checks in class | Temporary Field |
| Method call chains | 4+ in sequence | Message Chains |

---

## OOP Quick Checks

| Signal | Action |
|--------|--------|
| Method references another class's data more than its own | Apply MoveMethod (Feature Envy) |
| Abstract base class with only one concrete implementation | Remove until second arrives (Speculative Generality) |
| Two classes must change together every time | Collapse or use composition |
