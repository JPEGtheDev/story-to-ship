# code-quality References Index

Universal reference files fire for every code task. OOP tier fires only when the trigger condition in SKILL.md Step 2 matches.

---

## Universal Tier

- `code-smells.md` -- 6 universal smells from Fowler's _Refactoring_ that apply to all paradigms (Long Method, Duplicated Code, Long Parameter List, Speculative Generality, Divergent Change, Shotgun Surgery)
- `design-principles.md` -- design heuristics from Ward Cunningham's C2 wiki: DRY, YAGNI, Composed Method, Beck's Rules; all paradigms

---

## Object-Oriented Programming (OOP) Tier (`oop/`)

- `oop/index.md` -- dispatch table: trigger conditions + ordered 5-check list for OOP code; pass/fail gate
- `oop/review-checklist.md` -- full pre-commit checklist for OOP/C++ (format, build, tests, RAII, headers)
- `oop/oop-smells.md` -- 12 OOP-specific smells from Fowler's _Refactoring_ (Feature Envy, Data Clumps, Primitive Obsession, etc.)
- `oop/cpp-toolchain.md` -- clang-format and clang-tidy configuration for C++ projects
- `oop/formatting-rules.md` -- human-reviewable formatting patterns that clang-format does not catch
- `oop/naming-tables.md` -- naming convention tables by category for OOP identifiers
- `oop/invocation.md` -- how the OOP tier is invoked; maps to the tier's check sequence

---

## Related

- `SKILL.md` -- enforcement gate; drives both universal and OOP tiers
- `writing-skills/references/TIERED_REFERENCE_MODEL.md` -- model this structure follows; read when adding a new paradigm tier
