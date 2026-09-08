# Documentation Principles

Derived from Ward Cunningham's C2 Wiki synthesis.

## Document Your Intentions

Code shows what is done; it cannot show why, and documentation that only restates what the code already shows is redundant and will drift. "Document your intentions" covers two different things that must not be conflated: behavior specification -- what the system does, durable, and owned by the docs tree -- and decision rationale -- why this implementation was chosen over the alternatives, which belongs in the pull request body, not in committed docs (see Documentation Durability Layers below). Write behavior specification into the docs tree; write decision rationale into the pull request body at the decision point. Source: C2 Wiki "DocumentYourAssumptions" / "IntentionRevealingNames".

## Documentation Durability Layers

Documentation splits into three layers with different lifetimes:

1. **Behavior** (durable, lives in the docs tree): the contract the system honors, not how it happens to be implemented today. The completeness bar is the rewrite test: the docs must contain enough for someone to rewrite the application from scratch and reproduce the same behavior. Behavior docs change only when behavior changes; a ground-up reimplementation that preserves behavior leaves them untouched. Restating the implementation is redundant and drifts with the next refactor -- specifying the behavior is the point, and that distinction is what keeps a doc durable across a rewrite.
2. **Decision records** (transient by medium, never the docs tree): a Design Decision Record or an Architecture Decision Record -- the rationale for a choice and the alternatives considered -- rides the pull request body only. The pull request body is inherently dated and tied to the implementation that motivated it, so its transience is knowable from where it lives; committing the same content into the docs tree strips that signal and lets stale rationale get read as current contract.
3. **Verification state** (excluded from docs entirely): see "Verification State Is Not Documentation" below.

Decision rationale explains why the current implementation looks the way it does; a rewrite supersedes it. Source: project convention.

## Verification State Is Not Documentation

Shipped docs never carry a claim about whether something has been verified, in either direction: not the hedge form ("not yet verified by a live run"), not the affirmative form ("verified by a probe"), and not a snapshot count ("currently N suites, M checks"). Both directions rot silently the moment reality moves past the sentence.

Test: if a sentence answers "has this been verified?" or "how many exist right now?", it is state, not documentation -- move it to the issue tracker or delete it. Docs keep design statements, mechanisms, instructions, and generic output shapes with placeholder counts instead of live ones.

A mechanism that is genuinely unverified still needs an honesty marking while it stays unverified. This rule governs what happens after: once a check passes, delete the marking rather than flipping it to "verified." Source: project convention.

## Documentation Does Not Name Tests

A doc under the docs tree or a README does not name a test file, test project, test class, or test method, whether by identifier or by wording that singles out one specific test. Definiteness is the test: a phrase that individuates one particular test ("the layering test asserts ...") names it, while a statement that some unnamed test enforces a rule ("a build-time test enforces this") does not.

A rename, split, or move breaks a named test since nothing checks it, and no build step catches the drift; the runner's output is authoritative, so a restating doc is a weaker, hand-kept copy. A doc may say a test enforces a rule without naming it, or name a configuration location like a coverage-threshold file; code may point at a doc section, but a doc must never point at a test identifier. Source: project convention.

## Document Mode vs Thread Mode

Two distinct modes exist for collaborative knowledge capture. Document mode: a single author produces a coherent, stable artifact that is meant to be read end-to-end. Thread mode: multiple contributors respond to each other incrementally, producing a conversation. Mixing modes produces artifacts that are neither coherent documents nor useful conversations. Choose the mode explicitly before starting. Refactor thread mode into document mode when the conversation has converged. Source: C2 Wiki "DocumentMode" / "ThreadMode".

## UML as Whiteboard-Then-Discard

UML (Unified Modeling Language) is a thinking tool, not a deliverable. Draw on a whiteboard to explore a design decision; discard when the decision is made. UML diagrams that are committed to a repository will lie: they will not be updated, they will drift from the code, and readers will trust them over the actual source. If a diagram must be committed, auto-generate it from the code so it cannot drift. Source: C2 Wiki "UmlAsProgramming".

## Living Documentation

Living documentation is automatically derived from or co-located with the code it describes. It cannot go stale because it is generated at build time. Examples: API references generated from docstrings, architecture diagrams generated from dependency analysis, test names as the specification. When documentation cannot be made living, co-locate it with the code it describes so that the proximity creates pressure to update it. Source: C2 Wiki "LivingDocumentation".

## Self-Documenting Code

Self-documenting code does not require comments to explain what it does -- the names, structure, and decomposition communicate it directly. Names are the primary documentation vehicle: a well-named function communicates its contract; a well-named variable communicates its role. The target: a reader can understand a function's purpose from its name and signature without reading its body. Comments that describe what the code does are a signal to refactor the code, not add a comment. Source: C2 Wiki "SelfDocumentingCode".

## Literate Programming

Literate programming interleaves prose and code at the decision level: the prose describes the reasoning and the code implements it. Applied selectively, it is appropriate for non-obvious design decisions where the reasoning matters as much as the implementation. Applied globally, it produces verbosity. Limit it to: architectural boundary decisions, non-obvious algorithm choices, and contract definitions. Source: C2 Wiki "LiterateProgramming".

## Bounded Contexts as Taxonomy Organizer

Each `docs/<domain>/` directory is a Bounded Context in the Domain-Driven Design (DDD) sense: one team concern owns it, uses a consistent vocabulary within it, and documents that vocabulary there. Do not let terms cross context boundaries without translation. If a concept from one domain appears in another domain's docs, write a brief mapping note rather than importing raw terminology from a different context. Source: C2 Wiki "BoundedContexts" / "DomainDrivenDesign".

## Repo Scope and Documentation Ownership

A repo's documentation scope maps directly to its DDD scope:

| Repo type | Docs it owns | References externally |
|-----------|-------------|----------------------|
| Single domain | All docs for that domain | Shared kernel, enterprise standards |
| Multi-domain | All `docs/<domain>/` directories | External shared docs, if any |
| Subdomain microservice | `docs/<subdomain>/` only | Parent domain docs, shared kernel |

Cross-repo concerns -- shared kernel definitions, context maps, enterprise-level standards -- live in an external repo or wiki. The local repo references them by link. Duplication is acceptable only when the external dependency would break agent context loading, or when the content is foundational enough that developers need it without navigating away. When duplicating: note the authoritative source.

A parent API or platform repo may own upper-level domain documentation. A microservice that implements a subdomain links upward to the parent domain docs rather than duplicating them. Source: DDD "Context Map" / "Shared Kernel".

## Documentation Index

Every `docs/` directory at each level MUST maintain an `INDEX.md` for what it owns:
- `docs/INDEX.md` -- cross-cutting standards and links to domain-level indexes
- `docs/<domain>/INDEX.md` -- domain-wide docs and links to subdomain indexes
- `docs/<domain>/<subdomain>/INDEX.md` -- subdomain-specific docs

Each index uses this format:

```
| File | Domain | Subdomain | Description |
|------|--------|-----------|-------------|
| invoicing/disputes.md | payments | invoicing | Dispute resolution patterns |
| https://example.com/paper.pdf | payments | -- | Research: invoice fraud patterns |
```

Universal token maximum: 800 tokens per article (all types). External references linked in the index have no local limit -- the limit applies only to files stored in the repo.

Include in each index: owned doc files at that level, architecture diagrams, relevant research papers, articles, and any external sources that informed decisions in that domain. Do not duplicate entries already in a child index -- link to the child index instead.

The index is the fast-path for discovering what documentation exists. Without it, agents scan the filesystem; with it, agents read one file. For external sources, the index entry links out rather than storing content. Source: DDD "Context Map" pattern.

## DocumentationPatterns: Write Once, Link Everywhere

Document each concept exactly once. When a second location needs the same content, link to the authoritative source instead of duplicating it. Duplicate documentation diverges. Core principles from C2 Wiki's DocumentationPatterns:

- Single Source of Truth: one file per concept; all other locations link back to it
- Document inheritance: a subdomain guide implicitly inherits the rules of its domain guide; state deviations explicitly, not the full rule set again
- For documenting intent vs. implementation (WHY not WHAT), see "Document Your Intentions" above
Source: C2 Wiki "DocumentationPatterns" / "LightweightDocumentation".

## See Also

- `WIKI_PRINCIPLES.md` in this skill's `references/` directory -- Ward Cunningham's principles for designing a knowledge base
- `writing-skills` skill -- skill file authoring (Alexandrian Form is defined there)
