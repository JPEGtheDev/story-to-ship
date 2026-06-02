---
name: code-quality
license: MIT
description: Use when writing or reviewing C++ code, running pre-commit checks, or addressing formatting, naming, or static analysis violations.
---


## Iron Law

```
NO UNFORMATTED OR UNTIDY CODE SHIPS
YOU MUST run clang-format AND clang-tidy BEFORE every commit. CI will reject violations.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the code-quality skill to [format/lint/review] [description]."

---

## Core Principle: Tools Enforce Style, Humans Write Logic

Formatting and naming are automated via `.clang-format` and `.clang-tidy`. Never manually format code -- run the tools.

---

## BEFORE PROCEEDING

Before every commit, verify:

1. All C++ files formatted: `find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i`
2. Formatting passes CI check: `find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format --dry-run -Werror`
3. `git diff` of every modified C++ file visually inspected -- do not trust silent tool output
4. Build passes: `cmake --build build`
5. All tests pass: run your project's test suite

[+] All 5 met -> proceed to commit
[-] Any unmet -> fix the failing step; do not commit

**Note:** clang-format is C++ only. Never run it on Markdown, YAML, or documentation files -- it will corrupt them.

See `references/CPP_TOOLCHAIN.md` for full command reference and optional clang-tidy invocation.
See `references/FORMATTING_RULES.md` for formatting rule details.

---

## Naming Conventions (clang-tidy enforced)

`PascalCase` classes/enums - `camelCase` methods - `snake_case` vars/params - `snake_case_` private members - `UPPER_CASE` constants - `snake_case` files/namespaces - `<PROJECT>_<PATH>_<FILE>_H` guards

See `references/NAMING_TABLES.md` for full naming examples.

## Naming Pre-Flight

Before naming a new `enum`, struct field, or constant: consult your project's naming conventions. Enumerators: `UPPER_CASE`.

---

## Self-Documenting Code

**Readability is more important than development speed or execution speed.** Time spent on clarity is recovered many times over in maintenance, review, and debugging.

**Comments are not intent.** Comments can go stale; code cannot. When a comment exists to explain what a value means, that is a signal the code must be rewritten -- not the comment improved.

| Signal | Wrong fix | Right fix |
|--------|-----------|-----------|
| `// 0=Fullscreen, 1=AutoCOM...` comment above a switch | Add a better comment | Replace magic numbers with a named enum |
| `magic_value = 42; // timeout in ms` | Document the constant | `constexpr int kTimeoutMs = 42;` |
| Function with a `bool` parameter | Comment at the call site | Replace with an enum or named overloads |

**Rule:** If a comment is explaining what a value *is*, the comment is a code smell. Make the code say it directly.

---

## Adding a Feature / Fixing a Bug

See `references/CPP_TOOLCHAIN.md` for toolchain commands.

---

## Code Smell Review Checklist

Static analysis catches syntax violations. These structural smells require human review on every PR:

- **DuplicatedCode** -- Same logic block in 2+ places? Extract it.
- **LongMethod** -- Method longer than ~30 lines? Apply ExtractMethod.
- **GodClass** -- One class controlling too many subsystems? Split responsibilities.
- **DataClumps** -- Same 2+ variables always travelling together? Introduce a struct.
- **PrimitiveObsession** -- Domain concepts as raw `int`, `float`, or `GLenum`? Introduce typed wrappers.

See `references/CODE_SMELLS.md` for the full code smells catalog.

[+] All checked -> no structural smells found
[-] Any flagged -> log `[BROKEN WINDOW NOTED]` or fix before commit (see `cpp-patterns` skill)

---

## Review Checklist

See `references/REVIEW_CHECKLIST.md` for the full numbered pre-commit checklist.

[+] All 10 met -> proceed to commit
[-] Any unmet -> complete the failing step before committing

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll run clang-format once at the end before the PR" | Format after every meaningful change. Catch issues early, not in bulk. |
| "clang-tidy has too many false positives, I'll skip it" | Fix or suppress with justification in code. Suppression without reason is tech debt. |
| "The naming is close enough to the convention" | Exact naming prevents confusion across sessions and contributors. |
| "Formatting is cosmetic, doesn't affect behavior" | Unformatted code gets rejected by CI. It's a hard gate, not a preference. |
| "I'll clean up the style in a follow-up PR" | Style debt compounds. Clean it now while context is fresh. |
| "The auto-formatter will handle it" | Run the auto-formatter explicitly -- it doesn't run itself. |

---

## Red Flags -- STOP

If you catch yourself thinking any of these, stop and follow the rule:
- About to commit without running `clang-format -i`
- "clang-tidy warning but it seems like a false positive"
- "The naming is slightly different but close enough"
- "I'll clean up formatting in the next commit"
- "The CI will format it automatically"
- Writing code and planning to format "later in this session"

**All of these mean: Run `find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i` and `clang-tidy` before every commit. No exceptions.**

---

## Reference

- Full coding standards: [`docs/CODING_STANDARDS.md`](../../../docs/CODING_STANDARDS.md)
- Commit format: `versioning` skill
- Testing patterns: `testing` skill
- `references/CPP_TOOLCHAIN.md` -- formatting settings, clang-tidy, workflow patterns
- `references/FORMATTING_RULES.md` -- human-reviewable formatting patterns
- `cpp-patterns` skill -- C++ runtime patterns
- `references/DESIGN_PRINCIPLES.md` -- design heuristics
- `references/CODE_SMELLS.md` -- smells, refactoring map
- `references/NAMING_TABLES.md` -- naming examples
- `references/REVIEW_CHECKLIST.md` -- pre-review checklist
- `references/INVOCATION.md` -- agent invocation instructions
