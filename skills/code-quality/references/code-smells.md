# Code Smells -- Universal

Source: Martin Fowler's _Refactoring_. These smells apply to all paradigms and languages.
For OOP-specific smells (Feature Envy, Data Clumps, etc.) see `oop/oop-smells.md`.

---

### 1. Long Method

**What it looks like:** A function exceeding 20 lines, or mixing multiple levels of abstraction, or with nested control structures three or more levels deep.

**Why it hurts:** Hard to understand, test, and reuse. Mixing abstraction levels confuses intent.

**Primary Refactorings:** Extract Function, Replace Temp with Query

---

### 2. Long Parameter List

**What it looks like:** A function signature with more than three parameters.

**Why it hurts:** Difficult to remember order and purpose. Type mismatch errors at call sites. Changes propagate widely.

**Primary Refactorings:** Introduce Parameter Object, Replace Parameter with Method

---

### 3. Duplicated Code

**What it looks like:** The same code structure appears in two or more places.

**Why it hurts:** Bug fixes must be applied in multiple places; inconsistencies emerge. Maintenance burden scales with the number of copies.

**Primary Refactorings:** Extract Function, extract shared utility

---

### 4. Speculative Generality

**What it looks like:** Abstractions, parameters, or functions added "just in case" for scenarios that may never occur.

**Why it hurts:** Dead code accumulates. Future-proofing creates cognitive burden without present-day value.

**Primary Refactorings:** Remove unused code and layers (YAGNI)

---

### 5. Divergent Change

**What it looks like:** A single module must be modified for different unrelated reasons.

**Why it hurts:** Violates Single Responsibility. Unrelated changes are entangled; modifying for one reason risks breaking another.

**Primary Refactorings:** Extract Module, organize by reason to change

---

### 6. Shotgun Surgery

**What it looks like:** One logical change requires editing many small pieces in many different places.

**Why it hurts:** Easy to miss a location and introduce inconsistencies. High cost of change.

**Primary Refactorings:** Move Function/Field, concentrate related changes together

---

## Detection Heuristics (Universal)

Triggers to investigate -- not absolute violations.

| Heuristic | Threshold | Indicates |
|-----------|-----------|-----------|
| Function length | > 20 lines | Long Method |
| Nesting depth | > 2 levels | Complex control flow; Extract Function |
| Parameter count | > 3 | Long Parameter List |
| Duplication ratio | Same code in 2+ locations | Duplicated Code |
| Cyclic dependencies | Module A -> B -> A | Architectural problem |
| Unused code paths | Code only executed in rare scenarios | Speculative Generality |

---

## Universal Quick Checks

| Signal | Action |
|--------|--------|
| Magic number in code | Name it as a constant |
| Nesting > 3 levels | Introduce guard clauses |
| Comment explains WHAT the code does | Rename or refactor instead |

---

## Key Principles

All code smells trace back to three root violations:
1. **DRY (Don't Repeat Yourself)** -- Duplication of logic, structure, or intent
2. **OAOO (Once and Only Once)** -- A concept or responsibility appears in multiple places
3. **Single Responsibility** -- A module or function has more than one reason to change

---

## DRY vs OAOO

| Principle | Targets | Fix |
|-----------|---------|-----|
| Once And Only Once | Same *code logic* in two or more places | Extract a function |
| Don't Repeat Yourself | Same *knowledge* encoded in two or more places | Single authoritative source |

Key distinction: two code blocks can look identical but not violate DRY if they represent independent domain concepts. Merging them creates false coupling.
