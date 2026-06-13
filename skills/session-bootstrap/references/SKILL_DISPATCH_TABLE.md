# Skill Dispatch Table -- Greenfield Workflow

Context, forces, and row definitions for the three greenfield dispatch rows added to the
session-bootstrap "On Start -- Minimum Skill Loads by Task Type" table.

---

## Context

Applies when: A developer opens a new session to build a new project from scratch -- no existing codebase, no defined architecture.

Does NOT apply when: An existing project is being extended or refactored. Use existing `execution`, `brainstorming`, and `writing-plans` routes for those tasks.

## Forces

Without greenfield-specific routing, new projects jump directly to architecture or implementation before the problem domain is understood. Domain interviews run after architecture is chosen produce models that rationalize the existing design rather than revealing the correct one. The `greenfield-discovery` skill is the gate that ensures domain understanding precedes every downstream decision.

Adding dispatch rows before their referenced skills exist causes broken sessions -- the model invokes a skill file that does not exist. Rows are added only when the referenced skill ships.

## Dispatch Rows (active)

These rows are present in the session-bootstrap "On Start" table:

| Task type | Skill |
|-----------|-------|
| Starting a new project from scratch | `greenfield-discovery` |
| Choosing a language, runtime, or framework for a new project | `greenfield-architecture` |
| Bootstrapping a new project repo after domain model + architecture decision | `greenfield-bootstrap` |

## Dispatch Rows (deferred)

The following row is NOT yet in the session-bootstrap table because the referenced skill
does not exist. Add it when the `exception-philosophy` skill ships (Story 4):

| Writing or reviewing code | add `exception-philosophy` alongside existing `code-quality` |

## Greenfield Invocation Chain

The three active skills form a chain. Each step gates the next:

```
greenfield-discovery  ->  greenfield-architecture  ->  greenfield-bootstrap
(domain model)            (language/framework)          (project repo setup)
```

Each downstream skill reads the output of the prior skill from conversation history.
Neither `greenfield-architecture` nor `greenfield-bootstrap` asks the user to repeat
information already present in a prior skill's output block.

## Consequences

The greenfield-architecture and greenfield-bootstrap rows trigger only for explicit
new-project flows -- they do not modify existing routing for ongoing projects.
Adding them before their skills ship is low-risk: the rows only fire when the user's
session explicitly matches the described task type, and those task types have no
existing dispatch coverage.
