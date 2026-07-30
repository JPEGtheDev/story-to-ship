# Code Smells -- Universal

Source: Martin Fowler's _Refactoring_. These smells apply to all paradigms and languages.
For OOP-specific smells (Feature Envy, Data Clumps, etc.) see `oop/cpp/oop-smells.md`.

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

**Extraction trigger (contested):** One practical compromise: tolerate a single duplicate, but leave a comment at each copy cross-referencing the other so the next person to copy it has enough context to factor out every occurrence at once; treat a second or third copy as the point to stop tolerating and extract. This is informed convention rather than a settled rule -- other practitioners argue for deduplicating at the very first repetition instead.

---

### 4. Speculative Generality

**What it looks like:** Abstractions, parameters, or functions added "just in case" for scenarios that may never occur.

**Why it hurts:** Dead code accumulates. Future-proofing creates cognitive burden without present-day value.

**Primary Refactorings:** Remove unused code and layers (You Aren't Gonna Need It (YAGNI))

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

### 7. Implicit State Through an Unstructured Jump

**What it looks like:** A goto, or any equivalent unstructured jump, whose destination reads local-variable state that was set earlier at or near the jump site, with nothing in the code spelling out that dependency as an explicit contract.

**Why it hurts:** Carrying state this way puts a jump in the same failure category as scattered global flags -- both hide a dependency instead of stating it, and a jump offers little structural cue about intent compared with an if or a loop's condition. That gap in signal is exactly what let a stray, duplicated goto pass review undetected in the widely-known "goto fail" defect. C/C++'s goto is already narrower than the unrestricted jump found in early languages -- it cannot land inside a block, cannot skip past a declaration, and its label must sit within the same function that jumps to it -- so escaping several levels of nested control flow with it, the construct's most ordinary use, stays relatively benign on its own; the danger sits specifically in the undocumented state dependency, not in the jump itself.

**Primary Refactorings:** Restructure the jump into structured control flow (if/loop) so the state dependency becomes visible, or document the contract the destination relies on.

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
