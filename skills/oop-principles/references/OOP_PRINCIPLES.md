# OOP Principles Reference

Source: Ward Cunningham's C2 wiki audit — patterns applicable to class hierarchy and interface design.

---

## Good Object-Oriented Code

Good OO code provides meaningful abstractions — methods do domain work (`ship product`, `point in polygon`), not property access (`getX`, `setY`). Cohesion is high within classes; coupling is low between them. Substituting one implementation for another requires no client changes.

**Anti-signals:** a class whose public API is entirely getters and setters is a data bag, not an object.

---

## Is-A vs Has-A Hierarchy Gate

Before approving any class hierarchy, answer these two questions:

1. **Is-A:** Is every derived type substitutable everywhere the base is used (Liskov Substitution)?
2. **Has-A:** Would a composition relationship be clearer and less brittle?

If the answer to (1) is "not always" → redesign to composition.
If the answer to (2) is "yes, actually" → redesign to composition.

---

## Single Choice Principle

When a system supports an exhaustive set of alternatives (particle emitter types, render modes, shader variants), exactly **one** module owns the complete list. All other modules ask that one module which alternative to use.

Benefits: adding a new alternative requires changing exactly one place. Directly supports Open/Closed Principle.

---

## Speculative Hierarchy Anti-Pattern

Creating abstract subclasses for scenarios not yet needed ("WhatIfNonSharableComponent?") violates YAGNI and adds indirection with no payoff. Resist introducing a base class until three or more real, concrete variants exist and are actively in use.

Applies to template meta-hierarchies: CRTP-style base classes are only justified when proven necessary by real polymorphism needs.

---

## Uniform Access Principle

Clients should not know or care whether accessing a value requires a field read or a computed operation. Expose a uniform accessor; hide the implementation detail.

---

## Value Interface Over Reference Exposure

When internal implementation uses reference semantics (pointers, handles), expose a value-like interface to callers. Handle-based OpenGL resource wrappers should present stable value semantics — callers never hold raw GL integer handles.

---

## Weakened Interface Anti-Pattern

Operations on result objects must not have fewer capabilities than the objects they were derived from. If a "download queue" lacks the search capability that the underlying filesystem has, the interface has been weakened. Extend rather than embed; preserve interface richness through transformations.

---

## Write Interfaces Before Classes

Define the interface (abstract class / concept) before the concrete implementation. This forces clarity about expected behavior and prevents implementation bias from shaping the contract. The interface enables test doubles and makes multiple implementations straightforward.

Pattern: one `IRenderer` / one `Renderer`. The test suite works against `IRenderer`.

---

## Virtual Constructor (Factory Method)

When the concrete type to instantiate is determined at runtime, use a factory method rather than a direct constructor call. This decouples the caller from the concrete type and makes substitution testable.

---

## Coupling and Cohesion

**Coupling:** Code A and code B are coupled when B must change its behavior ONLY because A changed. High coupling means changes ripple unpredictably.

**Cohesion:** Code is cohesive when changes to A allow B to also change such that both add new value. High cohesion means related things evolve together.

**The goal:** High cohesion within modules, low coupling between modules.

**Practical test:** If you can change module A without touching module B, they are loosely coupled. If A and B tend to change together for the same reasons, they are cohesive and belong together.

Source: C2 Wiki "CouplingAndCohesion".

---

## Dependency Injection Mechanics

Two primary techniques for providing dependencies to an object:

**Constructor Injection** — pass all required dependencies at object creation time:
- Dependencies are always present; object is fully initialized on construction
- Makes required dependencies explicit and visible
- Preferred for dependencies that the object cannot function without

**Setter Injection** — provide optional or late-bound dependencies after construction:
- Allows partial initialization; dependencies can be changed after creation
- Useful for optional features or when circular dependencies exist
- Risk: object may be in an incomplete state between construction and injection

**Dependency Injection Containers** (frameworks that manage wiring):
- Centralize configuration; decouple modules from each other
- Risk: over-coupling to the container itself; the system becomes opaque
- Rule: if you cannot wire the dependencies by hand in a test, the container is hiding too much

**Service Locator** (alternative pattern):
- Centralizes service lookup; can cache or encapsulate vendor-specific details
- Drawback: obscures dependencies — callers don't declare what they need
- Prefer explicit DI over Service Locator for testability

Source: C2 Wiki "DependencyInjection", "ServiceLocator".

---

## Ubiquitous Language

In a system, developers and domain experts should share a single vocabulary for the same concepts. This shared language is the Ubiquitous Language.

**Why it matters:** When developers use different names than domain experts (renaming "Customer" to "User", calling an "Invoice" an "Order"), the translation cost compounds at every conversation, code review, and handoff. Bugs hide in translation gaps.

**Mechanics:**
- Use the same term in code, tests, documentation, and conversations
- When a term becomes ambiguous or contested, refactor toward deeper insight: rename in code, update tests, update documentation
- If the language must evolve (the business changes its terminology), update the code to match — do not maintain two vocabularies

**Signal of violation:** a glossary document that maps "what we call it in code" to "what the business calls it" — this document is evidence of a language gap, not a solution to one.

Source: C2 Wiki "UbiquitousLanguage", "DomainDrivenDesign".

---

## Related Skills

- `oop-principles` — iron law, Is-A/Has-A gate, SOLID check (load before any hierarchy decision)
- `contract-testing` — testing abstract types via typed test fixtures
- `cpp-safety` — scope-bound resource ownership applies to all object lifetimes
