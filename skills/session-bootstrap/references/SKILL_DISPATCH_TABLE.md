# Skill Dispatch Table -- Greenfield Workflow

Context, forces, and row definitions for the greenfield dispatch rows added to the
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
| Choosing a language, runtime, or framework for a new project | `greenfield-architecture` | domain |
| Writing starter files for a new project once its domain model and architecture are decided | `greenfield-bootstrap` | domain |

## Dispatch Rows (deferred)

The following row is NOT yet in the session-bootstrap table because the referenced skill
does not exist. Add the row only when its skill ships:

| Task type | Skill | Ships with | Tier |
|-----------|-------|------------|------|
| Writing or reviewing code | add `exception-philosophy` alongside existing `code-quality` | when the skill ships | domain |

## Core Skill Tags (per-turn routing block source)

Tag format: a trailing `Tier` column (`core` or `domain`) rather than an HTML comment
marker, because the dispatch-rows tables above already use multi-column pipe tables
(the active table has 3 columns, the deferred table 4) -- a Tier column is a lower-diff, mechanically
greppable extension of the existing structure.

DISCLOSURE: the "Core Skill Tags" table below is a NEW table added together with
the per-turn core skill-map routing block injected via `hooks/pre-message-gates.md`,
not in-place tagging of the pre-existing "Dispatch Rows" tables above -- every row in
those tables was already domain-tier before this table existed, so those rows carry the
`Tier` column purely for consistency, and the core rows had
to be introduced from scratch. Adding a new table (rather than trying to tag
mixed-skill rows in session-bootstrap SKILL.md's own "On Start" table, e.g. "Creating
a PR or commit" maps to both `versioning` (domain) and `verification-before-completion`
(core) in one row) was a deliberate design decision, not an oversight.

`core` = routes on a structural trigger (every session, every plan, every dispatch)
rather than task domain. These are the skills the compressed per-turn routing block in
`hooks/pre-message-gates.md` must name; `hooks/tests/run-skill-map-drift.sh` asserts
every skill tagged `core` here is present in that file. Domain skills (testing, cpp,
docs, etc.) are tagged `domain` in the tables above and MUST NOT be
added here or to the per-turn block -- they keep their own dispatch rows.

| Skill | Tier | Routing trigger (source) |
|-------|------|---------------------------|
| `session-bootstrap` | core | First tool call this response, every session, sent alone (hooks/pre-message-gates.md, Bootstrap Gate) |
| `honesty` | core | Immediately after `session-bootstrap` returns, before any task skill (session-bootstrap SKILL.md, "On Start" table) |
| `communication` | core | Immediately after `session-bootstrap` returns, alongside `honesty`, before any task skill (session-bootstrap SKILL.md, co-equal peer section) |
| `verification-before-completion` | core | Before any completion claim, commit, or PR (session-bootstrap "On Start" table) |
| `subagent-driven-development` | core | Before dispatching the first subagent for any plan/todo (session-bootstrap "On Start" table) |
| `two-stage-review` | core | When an implementer subagent has returned a result, before reading its status code -- DONE, DONE_WITH_CONCERNS, PARTIAL, NEEDS_CONTEXT, or BLOCKED (session-bootstrap "On Start" table) |
| `using-git-worktrees` | core | Before creating any worktree or dispatching any subagent -- attributed to the `subagent-driven-development` skill's BEFORE PROCEEDING item 3 and its worktree-before-dispatch Red Flag, NOT the "On Start" table (that table lists it only under "Parallel agent work / A/B testing") |
| `writing-plans` | core | Any new plan with 2+ todos, or any multi-step task/feature work (session-bootstrap "On Start" table) |

DISCLOSED DEVIATION: `writing-plans` is tagged `core` here because the per-turn
injection block routes it as core -- `hooks/pre-message-gates.md`'s "Core Skill
Routing" section states "For multi-step planning, load `writing-plans` first."
This conflicts with the plugin-split core manifest, which is not recorded in
this repository, so its contents are enumerated here instead of linked: it
names six skills -- `honesty`, `session-bootstrap`,
`verification-before-completion`, `subagent-driven-development`,
`using-git-worktrees`, and `communication`. The skills tagged `core` above that are
omitted from that manifest are `writing-plans` and `two-stage-review`. This tagging
follows the injection block as it stands.
The discrepancy with the manifest is not resolved by this change and is
called out here for reviewer attention.

## Greenfield Invocation Chain

Three skills form the chain. The recommended order is discovery, then architecture, then
bootstrap. Each step reads the prior step's block from the conversation, so the user is not
asked to repeat information already present in a prior skill's output block:

```
greenfield-discovery  ->  greenfield-architecture  ->  greenfield-bootstrap
(Domain Model block)      (Architecture Decision)      (project starter files)
```

`greenfield-architecture` also works from a bare start without discovery: it asks for the
problem type, output type, and deployment target instead of reading a Domain Model block.
`greenfield-bootstrap` needs a Domain Model block; with none it writes no file and points the
user to `greenfield-discovery`. With no Architecture Decision block it asks one question for the stack.

## Consequences

The `greenfield-architecture` and `greenfield-bootstrap` rows trigger only for explicit
new-project flows. They do not change routing for existing projects.
