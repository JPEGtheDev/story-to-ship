---
name: cpp-safety
license: MIT
description: Use when writing or reviewing any C++ class that owns resources, has a destructor, or acquires in a constructor.
---

## Iron Law

```
DESTRUCTORS NEVER THROW — EVERY RESOURCE IS OWNED BY A SCOPE-BOUND GUARD
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST wrap every destructor body in try/catch and ensure every resource acquisition is handed to an owning guard before the next acquisition begins. No exceptions.

**Announce at start:** "I am using the cpp-safety skill to review [class]."

---

## BEFORE PROCEEDING

- [ ] Does this class own heap memory, handles, or OS resources?
- [ ] Can its destructor fail or throw?
- [ ] Does its constructor acquire multiple resources?

✓ No owned resources → skip this skill  ✗ Any owned resource → apply the rules below

---

## Destructor Rule

Throwing from a destructor during stack unwinding calls `std::terminate` — no other destructors run. Wrap every destructor body in try/catch; never rethrow.

## Constructor Rule

If the constructor acquires resource A then throws while acquiring resource B, A leaks — the destructor is never called on a partially-constructed object. Each acquisition must be handed to its own scope-bound guard before the next acquisition begins.

See the `cpp-patterns` skill for ownership patterns and OpenGL-specific examples.

---

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "The cleanup is simple, it won't throw" | Wrap now — that property must hold for all future edits. |
| "`std::terminate` is acceptable here" | Not during stack unwinding — it prevents all remaining destructors from running. |
| "The second allocation almost never fails" | "Almost never" is not a safety guarantee. Wrap in a scope-bound guard. |
| "Owning guards add boilerplate" | The boilerplate is the guarantee. Inline cleanup is a future leak. |

---

## Related Skills

- [`cpp-patterns`](.github/skills/cpp-patterns/) — parent skill; OpenGL smell catalog and DRY patterns
- [`oop-principles`](.github/skills/oop-principles/) — sibling; resource-owning types also need the Is-A / Has-A gate
- [`systematic-debugging`](.github/skills/systematic-debugging/) — sibling; use when a crash points to destructor failure
