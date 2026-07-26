# Skill Dispatch Table -- Greenfield Workflow

Context, forces, and row definitions for the one active greenfield dispatch row added to the
session-bootstrap "On Start -- Minimum Skill Loads by Task Type" table.

---

## Context

Applies when: A developer opens a new session to build a new project from scratch -- no existing codebase, no defined architecture.

Does NOT apply when: An existing project is being extended or refactored. Use existing `execution`, `brainstorming`, and `writing-plans` routes for those tasks.

## Forces

Without greenfield-specific routing, new projects jump directly to architecture or implementation before the problem domain is understood. Domain interviews that run after architecture is chosen produce models that rationalize the existing design rather than revealing the correct one. The `greenfield-discovery` skill is the gate that ensures domain understanding precedes every downstream decision.

Adding dispatch rows before their referenced skills exist causes broken sessions -- the model invokes a skill file that does not exist. Rows are added only when the referenced skill ships.

## Dispatch Rows (active)

These rows are present in the session-bootstrap "On Start" table:

| Task type | Skill | Tier |
|-----------|-------|------|
| Starting a new project from scratch | `greenfield-discovery` | domain |

## Dispatch Rows (deferred)

The following rows are NOT yet in the session-bootstrap table because the referenced skills
do not exist. Add each row only when its skill ships:

| Task type | Skill | Ships with | Tier |
|-----------|-------|------------|------|
| Choosing a language, runtime, or framework for a new project | `greenfield-architecture` | Story 5 | domain |
| Bootstrapping a new project repo after domain model + architecture decision | `greenfield-bootstrap` | Story 7 | domain |
| Writing or reviewing code | add `exception-philosophy` alongside existing `code-quality` | Story 4 | domain |

## Core Skill Tags (per-turn routing block source)

Tag format: a trailing `Tier` column (`core` or `domain`) rather than an HTML comment
marker, because both dispatch-rows tables above already use multi-column pipe tables
(the deferred table has 3 columns) -- a Tier column is a lower-diff, mechanically
greppable extension of the existing structure.

`core` = routes on a structural trigger (every session, every plan, every dispatch)
rather than task domain. These are the skills the compressed per-turn routing block in
`hooks/pre-message-gates.md` must name; `hooks/tests/run-skill-map-drift.sh` asserts
every skill tagged `core` here is present in that file. Domain skills (testing, cpp,
flatpak, build, docs, etc.) are tagged `domain` in the tables above and MUST NOT be
added here or to the per-turn block -- they keep their own dispatch rows.

| Skill | Tier | Routing trigger (session-bootstrap "On Start" table) |
|-------|------|-------------------------------------------------------|
| `session-bootstrap` | core | First tool call this response, every session, sent alone |
| `honesty` | core | Immediately after `session-bootstrap` returns, before any task skill |
| `verification-before-completion` | core | Before any completion claim, commit, or PR |
| `subagent-driven-development` | core | Before dispatching the first subagent for any plan/todo |
| `using-git-worktrees` | core | Alongside `subagent-driven-development` for any subagent dispatch |
| `writing-plans` | core | Any new plan with 2+ todos, or any multi-step task/feature work |

DISCLOSED DEVIATION: `writing-plans` is tagged `core` here because plan T3b explicitly
names it in the injected per-turn block. The plugin-split ruling's core manifest (see
project history) omits `writing-plans` from its core set. This tagging follows the T3b
task instruction as given; the discrepancy with the manifest ruling is not resolved by
this change and is called out for reviewer attention.

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
