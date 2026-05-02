---
name: code-quality
license: MIT
description: Use when writing or reviewing C++ code, running pre-commit checks, or addressing formatting, naming, or static analysis violations.
---

## Iron Law

```
NO UNFORMATTED OR UNTIDY CODE SHIPS
```

YOU MUST run clang-format AND clang-tidy BEFORE every commit. CI will reject violations. No exceptions.

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the code-quality skill to [format/lint/review] [description]."

---

## Core Principle: Tools Enforce Style, Humans Write Logic

Formatting and naming are automated via `.clang-format` and `.clang-tidy`. Never manually format code — run the tools.

---

## Pre-Commit Gate (MANDATORY)

Run before **every** commit:

```bash
# 1. Format ALL changed C++ files ONLY (never run clang-format on markdown/YAML/docs)
find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i

# 2. Check what changed
git diff --name-only | head -20

# 3. Spot-check any files you touched (don't trust silent tool output)
# Look for: trailing semicolons after function }, exception handling,
# multi-declaration statements, bracing consistency
```

**CRITICAL:** clang-format is C++ only. Never run it on markdown, YAML, or documentation files - it will corrupt them.
git diff src/[touched_file].cpp | head -100

# 4. Verify formatting passes (same check CI runs)
find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format --dry-run -Werror

# 5. Build and test
cmake --build build
./build/tests/ParticleViewerTests

# 6. (Optional) Static analysis
clang-tidy src/main.cpp -- -Isrc/glad/include
```

**⚠️ Critical:** Do NOT trust that `clang-format --dry-run -Werror` with no output means success. Always visually inspect `git diff` of modified files. Silent tool output can mask formatting issues.

See `references/FORMATTING_RULES.md` for formatting rule details.

---

## Naming Conventions (clang-tidy enforced)

`PascalCase` classes/enums · `camelCase` methods · `snake_case` vars/params · `snake_case_` private members · `UPPER_CASE` constants · `snake_case` files/namespaces · `<PROJECT>_<PATH>_<FILE>_H` guards

See `references/NAMING_TABLES.md` for full naming examples.

---

## Adding a Feature / Fixing a Bug

See `references/CPP_TOOLCHAIN.md` for PV-specific toolchain commands.

---

## Code Smell Review Checklist

Static analysis catches syntax violations. These structural smells require human review on every PR:

- **DuplicatedCode** — Same logic block in 2+ places? Extract it.
- **LongMethod** — Method longer than ~30 lines? Apply ExtractMethod.
- **GodClass** — One class controlling too many subsystems? Split responsibilities.
- **DataClumps** — Same 2+ variables always travelling together? Introduce a struct.
- **PrimitiveObsession** — Domain concepts as raw `int`, `float`, or `GLenum`? Introduce typed wrappers.

See `references/CODE_SMELLS.md` for the full code smells catalog.

✓ All checked → no structural smells found
✗ Any flagged → log `[BROKEN WINDOW NOTED]` or fix before commit (see `cpp-patterns` skill)

---

## Review Checklist

See `references/REVIEW_CHECKLIST.md` for the full numbered pre-commit checklist.

✓ All 10 met → proceed to commit
✗ Any unmet → complete the failing step before committing

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll run clang-format once at the end before the PR" | Format after every meaningful change. Catch issues early, not in bulk. |
| "clang-tidy has too many false positives, I'll skip it" | Fix or suppress with justification in code. Suppression without reason is tech debt. |
| "The naming is close enough to the convention" | Exact naming prevents confusion across sessions and contributors. |
| "Formatting is cosmetic, doesn't affect behavior" | Unformatted code gets rejected by CI. It's a hard gate, not a preference. |
| "I'll clean up the style in a follow-up PR" | Style debt compounds. Clean it now while context is fresh. |
| "The auto-formatter will handle it" | Run the auto-formatter explicitly — it doesn't run itself. |

---

## Red Flags — STOP

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
- `references/CPP_TOOLCHAIN.md` — formatting settings, clang-tidy, PV workflow patterns
- `references/FORMATTING_RULES.md` — human-reviewable formatting patterns
- `cpp-patterns` skill — C++ runtime patterns
- `references/DESIGN_PRINCIPLES.md` — design heuristics
- `references/CODE_SMELLS.md` — smells, refactoring map
- `references/NAMING_TABLES.md` — naming examples
- `references/REVIEW_CHECKLIST.md` — pre-review checklist
- `references/INVOCATION.md` — agent invocation instructions
