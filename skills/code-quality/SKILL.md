---
name: code-quality
license: MIT
description: Use when writing or reviewing code in any paradigm to apply universal and paradigm-specific quality standards before committing.
---


## Iron Law

```
NO CODE SHIPS WITHOUT PASSING UNIVERSAL CHECKS AND PARADIGM CHECKS.
YOU MUST: (1) verify all universal tier checks pass; (2) verify your paradigm's checks pass
(see references/oop/index.md for OOP/C++). No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the code-quality skill to [format/lint/review] [description]."

---

## BEFORE PROCEEDING

Before every commit:

### Step 1: Universal Tier (all code, no exceptions)

1. `references/code-smells.md` Universal Smells section -- none of smells 1, 2, 7, 9, 16, 17 present in changed code
2. `references/design-principles.md` -- no principle violations (DRY, YAGNI, Composed Method, Beck's Rules)
3. Self-documenting check: no comment substitutes for a poor name; no magic numbers; no clever code

[+] All 3 pass -> continue to Step 2
[-] Any failing -> fix before proceeding

### Step 2: Identify Paradigm

Run in order; stop at first match:
1. `.cpp` or `.hpp` files modified -> OOP tier
2. `grep -rn "^class " <modified .py files>` returns results -> OOP tier
3. `.sh`, `.ps1`, or `.bash` files modified -> scripting tier
4. No match -> universal only (skip Step 3)

### Step 3: Paradigm Tier

Load `references/[paradigm]/index.md` and apply all checks listed there.

[+] All paradigm checks pass -> proceed to commit
[-] Any failing -> fix before committing

---

## Self-Documenting Code

**Readability is more important than development speed or execution speed.**

**Comments are not intent.** When a comment exists to explain what a value means, rewrite the code -- not the comment.

| Signal | Wrong fix | Right fix |
|--------|-----------|-----------|
| `// 0=Fullscreen, 1=AutoCOM...` above a switch | Add a better comment | Replace magic numbers with a named enum |
| `magic_value = 42; // timeout in ms` | Document the constant | `constexpr int kTimeoutMs = 42;` |
| Function with a `bool` parameter | Comment at the call site | Replace with an enum or named overloads |

**Rule:** If a comment explains what a value *is*, the comment is a code smell. Make the code say it.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll check quality at the end before the PR" | Run universal checks after every meaningful change. Catch issues early. |
| "The paradigm tier does not apply to this small change" | Paradigm tier fires on file extension. No exceptions for small changes. |
| "This code is too simple to need smell checks" | Universal smells (Long Method, Duplicated Code) appear in simple code. Run the check. |
| "The auto-formatter will handle it" | Run your project's formatter explicitly -- it does not run itself. |
| "I'll clean up style in a follow-up PR" | Style debt compounds. Clean now while context is fresh. |

---

## Red Flags -- STOP

- About to commit without running Step 1 -- **STOP. Run universal tier checks first.**
- Skipping paradigm tier because it is a small change -- **STOP. File extension determines the tier.**
- Comment explaining what a value is -- **STOP. Rename or refactor. Do not improve the comment.**
- Writing code and planning to format "later in this session" -- **STOP. Run your project's formatter now.**

---

## Reference

- `references/code-smells.md` -- universal + OOP smells (Universal: smells 1, 2, 7, 9, 16, 17)
- `references/design-principles.md` -- design heuristics (all paradigms)
- `references/oop/index.md` -- OOP tier dispatch table
- `references/oop/cpp-toolchain.md` -- clang-format, clang-tidy, cmake
- `references/oop/formatting-rules.md` -- human-reviewable C++ formatting patterns
- `references/oop/naming-tables.md` -- OOP naming conventions
- `references/oop/review-checklist.md` -- full OOP pre-commit checklist
- `references/oop/invocation.md` -- OOP tier invocation instructions
- Commit format: `versioning` skill
- Testing patterns: `testing` skill
- C++ runtime patterns: `cpp-patterns` skill
