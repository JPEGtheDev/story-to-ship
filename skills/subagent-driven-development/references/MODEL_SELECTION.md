# Model Selection

Match model tier to task complexity. Instructions must be written for GPT-4.1 baseline regardless of selected tier.

**Model preference priority -- check in this order before every agent dispatch:**

1. **Stored memory override (highest):** Check stored memories for a user-specified model preference. If found, apply that tier to ALL agents in this batch -- it overrides the table below.
2. **Tier table (default):** If no stored preference, use the task-type table below.
3. **Session default (fallback):** If neither applies, use the current session default.

If the user states a model preference in the current session, store it as a memory fact immediately so it persists.

| Task type | Default tier |
|-----------|-------------|
| Mechanical: grep, rename, format, one-function change | Standard |
| Research: read files, summarize patterns, compare approaches | Standard |
| Implementation: multi-file, design judgment | Standard |
| Review: spec compliance, code quality, architecture | Standard |
| Architecture design, security, final review (NOT compliance review) | Premium |

## Tier Exceptions

Three tiers exist. **Economy** = smallest/cheapest model class (e.g. Haiku) for mechanical, single-focus tasks with no design judgment. **Standard** = mid class (e.g. Sonnet), the default for everything in the table above. **Premium** = top class (e.g. Opus), reserved for the Premium row.

Exceptions to the Standard default:

| Agent or ceremony | Tier | Why |
|-------------------|------|-----|
| explorer template (read-only multi-file lookup) | Economy | Answers narrow factual questions; no judgment calls |
| Three Amigos Ceremony 1 (Discovery) | Economy | Structured interview following a fixed agenda |
| Three Amigos Ceremony 3 (Progress Check) | Economy | Status roll-up against an existing plan |
| Three Amigos Ceremony 6 (Retrospective) | Economy | Pattern collection, no gating decision |
| Three Amigos Ceremony 2 (Refinement) | Standard | Gate decision: APPROVE / CONDITIONS / REJECT |
| Three Amigos Ceremony 4 (Pivot Assessment) | Standard | Gate decision on scope and correctness risk |
| Three Amigos Ceremony 5 (Signoff) | Standard | Pre-merge acceptance decision |

This table is the single source of truth for ceremony tiers. Skills and agent templates MUST point here rather than restating model IDs.

**Using Premium for non-architecture tasks:** State the reasoning before dispatching. Example: "Dispatching Premium for this review because the change touches 3 layer boundaries." Do not dispatch Premium silently for mechanical work.

**Concurrency:** Verify your account's agent concurrency limit before dispatching parallel agents. See `dispatching-parallel-agents` skill for concurrency rules.

**For parallel read-only research:** Use `dispatching-parallel-agents` skill.
