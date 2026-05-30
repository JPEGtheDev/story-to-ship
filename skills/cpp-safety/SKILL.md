---
name: cpp-safety
license: MIT
description: Use when writing or reviewing any C++ class that owns resources, has a destructor, or acquires in a constructor.
---


## Iron Law

```
DESTRUCTORS NEVER THROW — EVERY RESOURCE IS OWNED BY A SCOPE-BOUND GUARD
YOU MUST wrap every destructor body in try/catch and ensure every resource acquisition is handed to an owning guard before the next acquisition begins. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the cpp-safety skill to review [class]."

---

## BEFORE PROCEEDING

1. Does this class own heap memory, handles, or OS resources?
2. Can its destructor fail or throw?
3. Does its constructor acquire multiple resources?

✓ No owned resources → skip this skill  ✗ Any owned resource → apply the rules below

---

## Destructor Rule

Throwing from a destructor during stack unwinding calls `std::terminate` — no other destructors run. Wrap every destructor body in try/catch; never rethrow.

## Constructor Rule

If the constructor acquires resource A then throws while acquiring resource B, A leaks — the destructor is never called on a partially-constructed object. Each acquisition must be handed to its own scope-bound guard before the next acquisition begins.

**When acquisition happens in a factory method (not a constructor) using raw pointers:** if `unique_ptr` cannot be used (e.g., the pointer is a member reset by a helper method), wrap the second `new` in try-catch — delete and null the first pointer before rethrowing:

```cpp
void createResources() {
    executor_ = new Executor();
    try {
        cache_ = new Cache(*executor_);
    } catch (...) {
        delete executor_;
        executor_ = nullptr;
        throw;
    }
}
```

See the `cpp-patterns` skill for ownership patterns and OpenGL-specific examples.

---

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "The cleanup is simple, it won't throw" | Wrap now — that property must hold for all future edits. |
| "`std::terminate` is acceptable here" | Not during stack unwinding — it prevents all remaining destructors from running. |
| "The second allocation almost never fails" | "Almost never" is not a safety guarantee. Wrap in a scope-bound guard. |
| "Owning guards add boilerplate" | The boilerplate is the guarantee. Inline cleanup is a future leak. |
| "The partial construction case never happens in practice" | "Never in practice" is not a structural guarantee. Scope-bound guards prevent the case unconditionally -- no statistical argument required. |

---

## Red Flags -- STOP

- About to write a destructor that can throw -- **STOP. Wrap the entire body in try/catch. Never rethrow.**
- Constructor acquires two or more resources without scope-bound guards between each acquisition -- **STOP. Assign each resource to its own guard before the next `new` or open call.**
- About to use raw `delete` instead of a scope-bound guard -- **STOP. Replace with `unique_ptr` or a custom RAII wrapper.**
- "This resource is always released before the destructor runs" -- **STOP. Prove it structurally with a guard, not by argument.**
- Class owns handles (file, socket, GL buffer) with no custom destructor or deleter -- **STOP. Every owned resource needs a defined release path.**

---

## Related Skills

- `cpp-patterns` -- parent skill; OpenGL smell catalog and DRY patterns
- `oop-principles` -- sibling; resource-owning types also need the Is-A / Has-A gate
- `systematic-debugging` -- sibling; use when a crash points to destructor failure
