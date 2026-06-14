---
title: "code-quality References Index"
description: "Index of all reference files for the code-quality skill -- universal smells and design principles, plus Object-Oriented Programming (OOP) tier dispatch table, checklists, naming conventions, and toolchain config."
domain: skills
subdomain: code-quality
tags: [skills, code-quality, references, index]
related:
  - "../SKILL.md"
---

# code-quality References Index

Universal files fire for every code task. OOP tier fires only when the trigger in SKILL.md Step 2 matches.

---

## Universal Tier

| File | Covers |
|------|--------|
| `code-smells.md` | 6 universal smells from Fowler's _Refactoring_ -- Long Method, Duplicated Code, Long Parameter List, Speculative Generality, Divergent Change, Shotgun Surgery |
| `design-principles.md` | Design heuristics from Ward Cunningham's C2 wiki -- DRY, YAGNI, Composed Method, Beck's Rules; all paradigms |

---

## OOP Tier (`oop/`)

| File | Covers |
|------|--------|
| `oop/index.md` | Dispatch table: trigger conditions + ordered 5-check list + pass/fail gate |
| `oop/review-checklist.md` | Full pre-commit checklist -- format, build, tests, RAII, headers |
| `oop/oop-smells.md` | 12 OOP-specific smells from Fowler's _Refactoring_ -- Feature Envy, Data Clumps, Primitive Obsession, etc. |
| `oop/cpp-toolchain.md` | clang-format and clang-tidy configuration |
| `oop/formatting-rules.md` | Human-reviewable formatting patterns clang-format does not catch |
| `oop/naming-tables.md` | Naming convention tables by category for OOP identifiers |
| `oop/invocation.md` | How the OOP tier is invoked; maps to the tier check sequence |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives both tiers; see the `writing-skills` skill's `TIERED_REFERENCE_MODEL` reference for the model this structure follows
