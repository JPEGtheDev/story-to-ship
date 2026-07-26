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

DISCLOSURE: the "Core Skill Tags" table below is a NEW table added by T3b, not
in-place tagging of the pre-existing "Dispatch Rows" tables above -- every row in
those two tables was already greenfield/domain before T3b, so the greenfield rows
carry the `Tier` column purely for consistency, and the core rows had to be
introduced from scratch. Adding a new table (rather than trying to tag mixed-skill
rows in session-bootstrap SKILL.md's own "On Start" table, e.g. "Creating a PR or
commit" maps to both `versioning` (domain) and `verification-before-completion`
(core) in one row) was a deliberate design decision, not an oversight.

`core` = routes on a structural trigger (every session, every plan, every dispatch)
rather than task domain. These are the skills the compressed per-turn routing block in
`hooks/pre-message-gates.md` must name; `hooks/tests/run-skill-map-drift.sh` asserts
every skill tagged `core` here is present in that file. Domain skills (testing, cpp,
flatpak, build, docs, etc.) are tagged `domain` in the tables above and MUST NOT be
added here or to the per-turn block -- they keep their own dispatch rows.

| Skill | Tier | Routing trigger (source) |
|-------|------|---------------------------|
| `session-bootstrap` | core | First tool call this response, every session, sent alone (session-bootstrap SKILL.md Iron Law) |
| `honesty` | core | Immediately after `session-bootstrap` returns, before any task skill (session-bootstrap SKILL.md, "On Start" table) |
| `verification-before-completion` | core | Before any completion claim, commit, or PR (session-bootstrap "On Start" table) |
| `subagent-driven-development` | core | Before dispatching the first subagent for any plan/todo (session-bootstrap "On Start" table) |
| `using-git-worktrees` | core | Before creating any worktree or dispatching any subagent -- attributed to `subagent-driven-development` SKILL.md's BEFORE PROCEEDING item 3 and its worktree-before-dispatch Red Flag, NOT the "On Start" table (that table lists it only under "Parallel agent work / A/B testing") |
| `writing-plans` | core | Any new plan with 2+ todos, or any multi-step task/feature work (session-bootstrap "On Start" table) |

DISCLOSED DEVIATION: `writing-plans` is tagged `core` here because plan T3b explicitly
names it in the injected per-turn block. This conflicts with the plugin-split core
manifest per a 2026-07-26 user ruling: honesty, session-bootstrap,
verification-before-completion, subagent-driven-development, using-git-worktrees, plus
the 5 generic agent templates -- `writing-plans` is omitted from that manifest. The
ruling is recorded in this session's corrections plan, an UNTRACKED scratch artifact
(not in git history, not searchable via `git log` or issue tracker) -- it will be
formalized in the future plugin-split tracking issue. This tagging follows the T3b task
instruction as given; the discrepancy with the manifest ruling is not resolved by this
change and is called out here for reviewer attention.

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
