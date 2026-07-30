---
title: "oop-principles References Index"
description: "Index of all reference files for the oop-principles skill -- OOP patterns and anti-patterns for class hierarchy and interface design, plus the Design by Contract discipline for precondition/postcondition/invariant responsibility and its tie to Liskov substitution."
domain: skills
subdomain: oop-principles
tags: [skills, oop-principles, references, index]
related:
  - "../SKILL.md"
---

# oop-principles References Index

These files back the oop-principles gate: class hierarchy and interface patterns, and the
contract discipline that makes substitutability checkable rather than assumed.

---

## Reference Files

| File | Covers |
|------|--------|
| `OOP_PRINCIPLES.md` | Is-A/Has-A hierarchy gate, Single Choice Principle, Speculative Hierarchy anti-pattern, Uniform Access Principle, Value Interface over Reference Exposure, Weakened Interface anti-pattern, Write-Interfaces-Before-Classes, Virtual Constructor, Coupling and Cohesion, Dependency Injection mechanics, Ubiquitous Language |
| `DESIGN_BY_CONTRACT.md` | Precondition/postcondition/invariant triad, caller-vs-callee responsibility for preconditions (including the open trust-vs-recheck tension), contracts as executable documentation and an Open/Closed boundary, contracts and Liskov substitution, and the practical limits of contract-based reasoning |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill; Rationalization
  Prevention row on added methods tightening preconditions ties directly to
  `DESIGN_BY_CONTRACT.md`
