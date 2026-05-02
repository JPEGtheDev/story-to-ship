# Design Principles Reference

Source: Ward Cunningham's C2 wiki audit — principles for writing and evaluating clean code.

---

## Beck's Four Rules of Simple Design (in priority order)

1. **Tests pass** — all tests green; no broken behavior
2. **No duplication** — Once and Only Once; every concept expressed exactly once
3. **Expresses ideas clearly** — names and structure reveal intent; reader does not need comments to understand
4. **Minimizes classes and methods** — no unnecessary abstractions; fewest elements that satisfy the above three

The order is fixed. Do not minimize classes at the expense of clarity. Do not eliminate duplication at the expense of passing tests.

---

## Simply Understood Code

Code is simply understood when:
- It fits on one screen without scrolling
- Variables are assigned once (no mutation chains)
- Reading order is linear top-to-bottom
- Names are unambiguous in their immediate context

The goal of MeaningfulNames is that code reads as an executable description of what it does.

---

## Write Your Code Like Prose

Nouns name objects. Verbs name methods with side effects. Adjectives name decorators. Method names read as sentences in context:

```cpp
bool deviceIsPoweredOn();           // boolean accessor reads as predicate
void takeItemsFrom(int n, std::vector<Item>& source); // verb + preposition signals ownership transfer
window.moveTo(targetPoint);         // subject.verb(object)
```

When a method name requires a preposition ("from", "to", "with") or a conjunction ("and", "or"), it may signal that the behavior belongs in a different class (feature envy) or that the method is doing too much.

---

## Using Good Naming to Detect Bad Code

Method names that require prepositions or conjunctions are signals, not style choices:

- `applyUpdatesTo(Account)` → the method belongs on `Account`
- `getAddressesFrom(Message)` → feature envy; `Message` should provide its own addresses
- `validateAndSave()` → two responsibilities; extract two methods

Rename first. The right name often reveals the right design.

---

## Succinctness Reveals Inadequate Abstractions

When you cannot write terse code at the call site, the problem is the abstraction layer, not the calling code. Refactor the abstraction until calling code reads simply. Succinctness is an economic indicator — it signals that the abstraction is doing its job.

---

## Refactoring: What It Is and When to Stop

Refactoring is continuous, small-step reorganization that preserves behavior. It is not rewriting. It is safe only when tests catch mistakes.

**When to refactor:** when code is unclear, duplicated, or blocking a new feature.
**When to stop:** when the code no longer smells and the new feature is unblocked. Stop there — not at a theoretical canonical form.

Do not refactor stable, working code speculatively. Refactor the path you are walking, not hypothetical future paths.

---

## Well-Written Code

Well-written code is correct **and**: well-tested, well-formatted, well-factored, and well-commented. All five properties are required. Source code is a communication medium between developers — not a set of instructions for a compiler.

---

## Weinberg Test for Long Functions

To evaluate whether a function is too long: memorize a chunk of it, close the file, rewrite it from memory. If mistakes occur, the chunk is too long or too complex. This operationalizes the 7±2 cognitive load principle as a concrete test.

---

## YAGNI Applies to Features, Not Cleanliness

YAGNI (You Are Not Going to Need It) governs feature additions — not refactoring, not naming, not structural clarity. Once and Only Once and YAGNI sit at opposite ends of a continuum. Refactoring moves code between them. Clean structure is foundational, not optional.

## Global State Is a Smell

A global variable is a hidden parameter to every function that reads it and a hidden side effect in every function that writes it. When code breaks after a change that "shouldn't have touched anything," a global is usually implicated. If shared state is required, make it explicit: pass it as a parameter, or encapsulate it in a single owner. Source: C2 Wiki "GlobalVariablesAreBad".

## Do No Harm

Every change to working code carries a risk. Before making a change, establish that it is necessary. "This could be better" is not sufficient justification. The burden of proof is on the change, not on the status quo. Source: C2 Wiki "FirstDoNoHarm".

## What You Produce, Others Consume

Code is not written for the compiler — it is written for the next person who reads it. That person is frequently yourself in three months. Optimize for readability by the reader, not for cleverness by the writer. Source: C2 Wiki "CodeForTheMaintainer".

## Essential vs Accidental Complexity

Essential complexity is inherent in the problem. Accidental complexity is introduced by the solution. Every line of code, every abstraction layer, every framework dependency is a cost. Justify each by pointing to the essential complexity it addresses. If you cannot, it is accidental and should be removed. Source: C2 Wiki "EssentialComplexity" / "AccidentalComplexity".

## Actionable Error Messages

An error message that says "something went wrong" forces the reader to reproduce the problem to diagnose it. An actionable error message says: what happened, what data caused it, and what the caller should do. Write every error message as if the only person reading it is a tired engineer at 2am with no access to the source code. Source: C2 Wiki "ActionableMistakeNotice".

## No Clever Code

Clever code is code that requires the reader to hold a mental model not derivable from the code's structure or names. Clever code is not a compliment — it is a future maintenance cost. If a solution requires a comment to explain its mechanism, replace it with a solution that does not. Source: C2 Wiki "CleverCode".

## BandAid Anti-Pattern

A BandAid fix applies a patch at the symptom site without addressing the origin of the problem. Signs: the fix must be applied in multiple places; the fix requires a comment explaining why it exists; the fix breaks under edge cases the original bug did not trigger. When a fix requires touching more than two callsites, stop — find the origin. Diagnostic use: see systematic-debugging/references/DEBUGGING_TACTICS.md — BandAid Detection. Source: C2 Wiki "BandAidSolution".

## Bloated Reuse

Reuse is not inherently good. A reused component that carries more dependencies than the caller needs is an anchor: it slows builds, creates implicit coupling, and forces unrelated upgrades. Prefer duplication of small, stable code over reuse of large, unstable components. Source: C2 Wiki "ReusabilitySmell".

---

## Don't Repeat Yourself as Knowledge, Not Code

The full principle: "Every piece of knowledge must have a single, unambiguous, authoritative representation in the system." This is broader than code deduplication. It applies to:
- **Business rules** — logic encoded in multiple places diverges over time
- **Data schemas** — same structure defined in DB, API contract, and UI model separately
- **Configuration** — the same value hardcoded in three places

Violating DRY on *knowledge* causes the system to have no single source of truth. When a rule changes, every copy must change — and at least one will be missed.

**Acceptable mechanical duplication:** Some structural repetition is acceptable when:
- The duplicated code serves different purposes that happen to look the same today (coincidental similarity)
- The duplication lives in a test file asserting the same known value in multiple tests
- Abstracting it would require a worse abstraction than the duplication

The rule: eliminate duplication of *knowledge* relentlessly; tolerate duplication of *structure* when the alternative is a forced abstraction.

---

## Composed Method

Organize methods so that each method does one thing at one level of abstraction. A method that mixes high-level coordination with low-level mechanics is harder to read than two methods — one that coordinates, one that executes.

**Signal:** A method body that contains steps at different abstraction levels (e.g., a loop over records *and* raw string formatting *and* a database call) is a candidate for decomposition via Composed Method.

**Result:** Each method can be read and understood in isolation. The top-level method reads like a specification; the detail lives one level down.

---

## Design Smell

A design smell is a structural signal that a system's design is accumulating technical debt — analogous to code smells in Martin Fowler's catalog but operating at the module or subsystem level.

Common design smells:
- **Divergent Change** — one module changes for many unrelated reasons (SRP violation at module level)
- **Shotgun Surgery** — one logical change requires editing many unrelated modules
- **Parallel Inheritance Hierarchies** — adding a class in one hierarchy requires adding a corresponding class in another
- **Middle Man** — a module that exists only to delegate to another

Design smells are not fixable by local refactoring alone. They require architectural review and restructuring. Use `references/ANTIPATTERNS.md` in the architecture-review skill for higher-level structural failures.

---

## Related Skills

- `code-quality` — clang-format, naming conventions, smell checklist, pre-commit gate
- `cpp-patterns` — C++-specific idioms for these principles
- `writing-plans` — Simplicity Principles reference for planning with YAGNI
