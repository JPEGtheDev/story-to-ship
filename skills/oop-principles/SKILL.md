---
name: oop-principles
license: MIT
description: Use when adding inheritance, designing interfaces, or reviewing any class hierarchy for Particle-Viewer.
---


## Iron Law

```
CHECK IS-A / HAS-A AND SOLID BEFORE APPROVING ANY CLASS HIERARCHY
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST run the Is-A / Has-A gate and verify all five SOLID principles before adding or approving any inheritance relationship. No exceptions.

**Announce at start:** "I am using the oop-principles skill to review [class/hierarchy]."

---

## BEFORE PROCEEDING

1. Is this a new inheritance relationship (B extends A)?
2. Does B pass a substitution test — can any code accepting A accept B without behavioral change?
3. Does the proposed hierarchy satisfy all five SOLID principles?
✓ All met → proceed  ✗ Any unmet → use composition or redesign

---

## Is-A / Has-A Gate

Before any inheritance: "Does B truly **is-a** A in all contexts, or does B merely **have** some of A's behaviors?" If the answer is "has," use composition.

## SOLID Quick Check

| Principle | Gate question |
|---|---|
| Single Responsibility | One reason to change? |
| Open / Closed | New behavior by extension, not editing? |
| Liskov Substitution | Does B replace A without behavioral surprise? |
| Interface Segregation | Do all clients use all interface methods? |
| Dependency Inversion | High-level module depends on an abstraction? |

See `references/OOP_PRINCIPLES.md` for violation signals and hierarchy anti-patterns.

---

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "Inheritance is the natural model here" | Natural is not correct. Run the Is-A test. |
| "The base class is just for code reuse" | Reuse is composition's job. Inheritance is for substitutability. |
| "The substitution test passes today" | Does it pass under all invariants, including error semantics? |
| "The derived class only adds methods; it doesn't change base behavior" | Adding methods can still tighten preconditions or weaken postconditions. Run the LSP check for every added method. |
| "Interface Segregation doesn't apply -- all clients need all methods" | Verify by inspection: find every caller of every interface method. If any caller never calls a method, the interface is too fat. |

---

## Red Flags -- STOP

- About to add inheritance for code reuse without checking Is-A -- **STOP. Is-A must hold unconditionally. If it doesn't, use composition.**
- A derived class overrides a non-virtual method -- **STOP. Overriding non-virtual methods silently hides base behavior. Make the method virtual or redesign.**
- A class with two or more unrelated responsibilities -- **STOP. Single Responsibility: one reason to change. Split the class before adding to the hierarchy.**
- A public interface method that only one client ever calls -- **STOP. Interface Segregation: remove the method from the interface or split into two interfaces.**
- About to add an implementation without a contract test fixture for the base type -- **STOP. Load `contract-testing` and write the fixture first.**

---

## Related Skills

- `architecture-review` -- parent; layer boundary rules apply to any hierarchy
- `contract-testing` -- sibling; every approved interface needs a contract test
- `cpp-safety` -- sibling; resource-owning hierarchy types need destructor review
