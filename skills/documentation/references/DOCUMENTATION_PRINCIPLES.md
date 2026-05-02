# Documentation Principles

Derived from Ward Cunningham's C2 Wiki synthesis.

## Document Your Intentions

Code shows what is done; it cannot show why. Documentation that restates what the code already shows is redundant and will drift. Documentation that records the intent — the reason for a decision, the alternatives considered, the constraint that drove the design — is irreplaceable. Write intention documentation at the decision point, not the implementation point. Source: C2 Wiki "DocumentYourAssumptions" / "IntentionRevealingNames".

## Document Mode vs Thread Mode

Two distinct modes exist for collaborative knowledge capture. Document mode: a single author produces a coherent, stable artifact that is meant to be read end-to-end. Thread mode: multiple contributors respond to each other incrementally, producing a conversation. Mixing modes produces artifacts that are neither coherent documents nor useful conversations. Choose the mode explicitly before starting. Refactor thread mode into document mode when the conversation has converged. Source: C2 Wiki "DocumentMode" / "ThreadMode".

## UML as Whiteboard-Then-Discard

UML is a thinking tool, not a deliverable. Draw on a whiteboard to explore a design decision; discard when the decision is made. UML diagrams that are committed to a repository will lie: they will not be updated, they will drift from the code, and readers will trust them over the actual source. If a diagram must be committed, auto-generate it from the code so it cannot drift. Source: C2 Wiki "UmlAsProgramming".

## Living Documentation

Living documentation is automatically derived from or co-located with the code it describes. It cannot go stale because it is generated at build time. Examples: API references generated from docstrings, architecture diagrams generated from dependency analysis, test names as the specification. When documentation cannot be made living, co-locate it with the code it describes so that the proximity creates pressure to update it. Source: C2 Wiki "LivingDocumentation".

## Self-Documenting Code

Self-documenting code does not require comments to explain what it does — the names, structure, and decomposition communicate it directly. Names are the primary documentation vehicle: a well-named function communicates its contract; a well-named variable communicates its role. The target: a reader can understand a function's purpose from its name and signature without reading its body. Comments that describe what the code does are a sign the code should be refactored. Source: C2 Wiki "SelfDocumentingCode".

## Literate Programming

Literate programming interleaves prose and code at the decision level: the prose describes the reasoning and the code implements it. Applied selectively, it is appropriate for non-obvious design decisions where the reasoning matters as much as the implementation. Applied globally, it produces verbosity. Limit it to: architectural boundary decisions, non-obvious algorithm choices, and contract definitions. Source: C2 Wiki "LiterateProgramming".

## See Also

- `documentation/references/WIKI_PRINCIPLES.md` — Ward Cunningham's principles for designing a knowledge base
- `documentation/SKILL.md` — project documentation conventions
- `writing-skills/SKILL.md` — skill file authoring (Doc4 Alexandrian Form is defined here)
