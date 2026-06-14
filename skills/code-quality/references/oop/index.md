# OOP Tier -- Dispatch Table

Apply this tier when any of the following are true:
- Modified files include `.cpp` or `.hpp` extensions
- `grep -rn "^class " <modified .py files>` returns results
- Task description references classes, inheritance, or polymorphism

## Checks to Apply (in order)

1. **Formatting** -- `cpp-toolchain.md` -- run clang-format and clang-tidy before committing
2. **Naming** -- `naming-tables.md` -- verify all new identifiers follow OOP naming conventions
3. **Formatting rules** -- `formatting-rules.md` -- human-reviewable patterns clang-format does not catch
4. **Review checklist** -- `review-checklist.md` -- full pre-commit checklist for OOP code
5. **OOP smells** -- `references/code-smells.md` OOP Smells section -- check for class-level design problems

[+] All 5 pass -> OOP tier complete; proceed to commit
[-] Any failing -> fix before committing
