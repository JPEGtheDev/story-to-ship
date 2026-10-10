---
name: cpp-safety
license: MIT
description: Use when writing or reviewing any C++ class that owns resources, has a destructor, or acquires in a constructor.
---


## Iron Law

```
DESTRUCTORS NEVER THROW -- EVERY RESOURCE IS OWNED BY A SCOPE-BOUND GUARD
YOU MUST wrap every destructor body in try/catch and ensure every resource acquisition is handed to an owning guard before the next acquisition begins. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the cpp-safety skill to review [class]."

---

## BEFORE PROCEEDING

1. Does this class own heap memory, handles, or OS resources?
2. Can its destructor fail or throw?
3. Does its constructor acquire multiple resources?

[-] Any question answered yes -> apply the rules below. [+] All three answered no -> skip this skill.

---

## Destructor Rule

Since C++11 destructors are implicitly noexcept; any escaping throw terminates the process. Wrap every destructor body in try/catch; never rethrow.

## Constructor Rule

If the constructor acquires resource A then throws while acquiring resource B, A leaks -- the destructor is never called on a partially-constructed object. Each acquisition must be handed to its own scope-bound guard before the next acquisition begins.

**When acquisition happens in a factory method (not a constructor) into raw pointer members:** hold the first acquisition in a local `std::unique_ptr`, assign the members only after the last acquisition, and `release()` last.

```cpp
auto executor = std::make_unique<Executor>();
cache_ = new Cache(*executor);
executor_ = executor.release();
```

See the `cpp-patterns` skill for ownership patterns and OpenGL-specific examples.

---

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "The cleanup is simple, it won't throw" | Wrap now -- that property must hold for all future edits. |
| "`std::terminate` is acceptable here" | Since C++11 destructors are implicitly noexcept; any escaping throw terminates the process. |
| "The second allocation almost never fails" | "Almost never" is not a safety guarantee. Wrap in a scope-bound guard. |
| "Owning guards add boilerplate" | The boilerplate is the guarantee. Inline cleanup is a future leak. |
| "The partial construction case never happens in practice" | "Never in practice" is not a structural guarantee. Scope-bound guards prevent the case unconditionally -- no statistical argument required. |

---

## Red Flags -- STOP

- About to write a destructor that can throw -- **STOP. Wrap the entire body in try/catch. Never rethrow.**
- Constructor acquires two or more resources without scope-bound guards between each acquisition -- **STOP. Assign each resource to its own guard before the next `new` or open call.**
- About to use raw `delete` instead of a scope-bound guard -- **STOP. Replace with `unique_ptr` or a custom Resource Acquisition Is Initialization (RAII) wrapper.**
- "This resource is always released before the destructor runs" -- **STOP. Prove it structurally with a guard, not by argument.**
- Class owns handles (file, socket, OpenGL buffer) with no custom destructor or deleter -- **STOP. Every owned resource needs a defined release path.**

---

## Related Skills

- `cpp-patterns` -- parent skill; OpenGL smell catalog and Don't Repeat Yourself (DRY) patterns
- `oop-principles` -- sibling; resource-owning types also need the Is-A / Has-A gate
- `systematic-debugging` -- sibling; use when a crash points to destructor failure
