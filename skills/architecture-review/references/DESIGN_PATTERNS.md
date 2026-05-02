## Multiple Architecture Views
Architecture is not a single diagram or perspective; it consists of multiple views that each reveal different truths about the system. The structural view shows what components exist and how they are related, the behavioral view shows how the system moves and interacts over time, and the deployment view shows where components run in the real world. No single diagram can capture all aspects—each omits important details, so relying on one view alone is misleading. (Source: C2 Wiki "MultipleArchitecturalViews")

## Template Method vs Strategy
Template Method and Strategy are two ways to allow variation in algorithms. Template Method fixes the overall algorithm structure in a base class and lets subclasses override specific steps, making the sequence fixed but the details flexible. Strategy, on the other hand, allows the entire algorithm to be swapped out by composing with different strategy objects, making the whole process replaceable. Use Template Method when the sequence must remain constant but steps may vary; use Strategy when the entire algorithm may need to change. Each has tradeoffs: Template Method increases coupling to the base class, while Strategy requires an interface for each algorithm. (Source: C2 Wiki "TemplateMethodPattern" / "StrategyPattern")

## Facade
A Facade provides a simplified interface to a complex subsystem, acting as a boundary that hides internal complexity from callers. It does not add new functionality or state of its own; instead, it delegates to the underlying components, making the subsystem easier to use and reducing dependencies on its internals. Use a Facade when you want to decouple clients from the details of a subsystem and provide a single entry point. (Source: C2 Wiki "FacadePattern")

## Principle of Least Authority (PoLA)
The Principle of Least Authority states that each component should be given only the minimum authority it needs to perform its function. Authority means the ability to read or modify state, and granting excess authority makes components harder to test, reason about, and maintain. By limiting authority, you reduce unintended coupling and make the system more robust and secure. (Source: C2 Wiki "PrincipleOfLeastAuthority")

## Security Door Anti-Pattern
The Security Door anti-pattern occurs when authorization checks are centralized in one place, but resources are accessed in many places throughout the system. This is like locking the front door but leaving the windows open—security is easily bypassed. Authorization must be co-located with resource access to ensure that every entry point is protected. (Source: C2 Wiki "SecurityDoor")

## Configurable Modularity
Modules should be configured at the point where they are composed—such as in main, a factory, or a dependency injection container—not inside the module itself. If a module hard-codes its collaborators, it cannot be tested or reused in isolation. Configurable modularity enables better testability, flexibility, and separation of concerns. (Source: C2 Wiki "ConfigurableModularity")

## Language-Independent Design
Designs that are tied to the idioms of a specific programming language—such as its syntax, memory model, or standard library—cannot be easily ported or reasoned about at the architectural level. To create robust and adaptable architectures, express design in terms of roles, responsibilities, and interfaces, not language-specific constructs. This makes the design applicable to polyglot systems and easier to communicate. (Source: C2 Wiki "LanguageIndependentDesign")

## No Abstraction Without Two Cases (YAGNI for Generality)
Abstractions should not be created for a single use case. An abstraction is only justified when there are at least two distinct concrete cases that need to be unified. Premature abstraction is often more difficult to remove than premature concreteness, so wait until the need for generality is proven. (Source: C2 Wiki "YouArentGonnaNeedIt")

## Alan Kay on Messaging
Alan Kay's insight into object-oriented design is that the core idea is not objects themselves, but the messages they send and receive. The power of the object model lies in components communicating through well-defined message interfaces, which hide internal state and implementation details. The identity and meaning of a message are more stable over time than the structure of the object that receives it. (Source: C2 Wiki "AlanKayOnMessaging")

## See Also
- `architecture-review/SKILL.md` — layer boundary rules for this project
- `oop-principles/references/OOP_PRINCIPLES.md` — Is-A / Has-A hierarchy design
