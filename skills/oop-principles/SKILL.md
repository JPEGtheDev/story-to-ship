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

- [ ] Is this a new inheritance relationship (B extends A)?
- [ ] Does B pass a substitution test — can any code accepting A accept B without behavioral change?
- [ ] Does the proposed hierarchy satisfy all five SOLID principles?
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

---

## Related Skills

- [`architecture-review`](.github/skills/architecture-review/) — parent; layer boundary rules apply to any hierarchy
- [`contract-testing`](.github/skills/contract-testing/) — sibling; every approved interface needs a contract test
- [`cpp-safety`](.github/skills/cpp-safety/) — sibling; resource-owning hierarchy types need destructor review
