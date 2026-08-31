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

## Tier Assignments

Three tiers exist. **Economy** = smallest/cheapest model class (e.g. Haiku), for tasks that clear the content-touching floor below; no row in the table currently uses it. **Standard** = mid class (e.g. Sonnet), the default tier for any task no row assigns otherwise. **Premium** = top class (e.g. Opus), reserved for the Premium row.

**Content-touching work floor:** Classification, extraction, distillation, and summarization tasks -- any task that exercises judgment over source content -- run at Standard tier or above, no matter how narrow or mechanical the task otherwise looks. Economy is acceptable only for tasks whose output is mechanically verifiable (for example, a file-listing roll-up), never for judgment over source content. Verbatim copying from large content embedded in a prompt counts as content extraction for the purpose of this floor; verify bytes by hash or pass the content by file path instead of copying it inline.

Tier assignments for named agents and ceremonies, listed here so the full mapping lives in one place. Every current row is Standard, the default tier and the floor for content-touching work described above:

| Agent or ceremony | Tier | Why |
|-------------------|------|-----|
| Three Amigos Ceremony 1 (Discovery) | Standard | Each amigo reads source documents (issues, specs, architecture docs, tests) and synthesizes them into acceptance criteria and a Feature Specification -- content-touching under the floor above |
| explorer template (read-only multi-file lookup) | Standard | Reads and summarizes source content across files -- content-touching under the floor above |
| Three Amigos Ceremony 3 (Progress Check) | Standard | Status roll-up against an existing plan is summarization of source content -- content-touching under the floor above |
| Three Amigos Ceremony 6 (Retrospective) | Standard | Pattern collection distills prior session content -- content-touching under the floor above |
| Three Amigos Ceremony 2 (Refinement) | Standard | Gate decision: APPROVE / CONDITIONS / REJECT |
| Three Amigos Ceremony 4 (Pivot Assessment) | Standard | Gate decision on scope and correctness risk |
| Three Amigos Ceremony 5 (Signoff) | Standard | Pre-merge acceptance decision |

This table is the single source of truth for agent and ceremony tiers. Skills and agent templates MUST point here rather than restating model IDs in prose; agent template frontmatter model fields implement these assignments and MUST stay consistent with this table.

**Using Premium for non-architecture tasks:** State the reasoning before dispatching. Example: "Dispatching Premium for this review because the change touches 3 layer boundaries." Do not dispatch Premium silently for mechanical work.

**Comparing tiers by cost:** When comparing model tiers (for example Economy vs. Standard) for cost, report dollar cost priced from current per-million-token pricing fetched from the platform docs at analysis time -- never compare raw token counts. Tokenizers differ across model families, so token counts from different models are not unit-compatible; a model that consumes more tokens for the same text is not necessarily the more expensive one. The harness's own token-usage figure for a subagent is not a billing-grade metric -- billing-grade truth comes from the per-message usage events recorded in the session and subagent transcript JSONL files (input tokens, output tokens, cache creation, cache read); sum those when a dollar comparison matters. A resumed subagent can silently revert to its template's default model instead of the model used for its earlier dispatch -- re-verify the per-call model field before attributing any result to a tier.

**Enforcement is procedural/self-check:** the checkable signal is a tier-cost comparison reported in raw token counts without fetched per-million-token pricing, or a resume dispatch whose report does not restate the per-call model field. No automated detector exists.

**Concurrency:** Verify your account's agent concurrency limit before dispatching parallel agents. See `dispatching-parallel-agents` skill for concurrency rules.

**For parallel read-only research:** Use `dispatching-parallel-agents` skill.
