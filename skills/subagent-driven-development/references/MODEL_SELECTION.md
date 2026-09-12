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
| rehearsal-subject template (coordinator under test) | Standard | Plays the coordinator in a behavioral rehearsal of skill text; the behavior under test is Standard-tier behavior, and a Premium subject would measure the wrong tier |

This table is the single source of truth for agent and ceremony tiers. Skills and agent templates MUST point here rather than restating model IDs in prose; agent template frontmatter model fields implement these assignments and MUST stay consistent with this table.

**Using Premium for non-architecture tasks:** State the reasoning before dispatching. Example: "Dispatching Premium for this review because the change touches 3 layer boundaries." Do not dispatch Premium silently for mechanical work.

**Comparing tiers by cost:** When comparing model tiers (for example Economy vs. Standard) for cost, report dollar cost priced from current per-million-token pricing fetched from the platform docs at analysis time -- never compare raw token counts. Tokenizers differ across model families, so token counts from different models are not unit-compatible; a model that consumes more tokens for the same text is not necessarily the more expensive one. The harness's own token-usage figure for a subagent is not a billing-grade metric -- billing-grade truth comes from the per-message usage events recorded in the session and subagent transcript JSONL files (input tokens, output tokens, cache creation, cache read); sum those when a dollar comparison matters. A resumed subagent can silently revert to its template's default model instead of the model used for its earlier dispatch -- re-verify the per-call model field before attributing any result to a tier.

**Enforcement is procedural/self-check:** the checkable signal is a tier-cost comparison reported in raw token counts without fetched per-million-token pricing, or a resume dispatch whose report does not restate the per-call model field. No automated detector exists.

**Concurrency:** Verify your account's agent concurrency limit before dispatching parallel agents. See `dispatching-parallel-agents` skill for concurrency rules.

**For parallel read-only research:** Use `dispatching-parallel-agents` skill.

## General-purpose dispatch

The general-purpose agent has no template file and no frontmatter model pin: it inherits the
dispatcher's model, so an unstated tier silently carries the dispatcher's tier onto work
the table above assigns elsewhere. Dispatch it only when no template in `.claude/agents/`
plays the role, and state in the dispatch message, before the call: (1) the closest template
considered and why it does not fit, (2) the tier from the table above with its reasoning. Pass
`model` explicitly on the call. Roles with no template today: an agent that must BE a modified
reviewer prompt (a template A/B run), and independent raters. The coordinator-under-test
role uses `.claude/agents/rehearsal-subject.md`; its dispatch prompt names the inputs only
and never the behavior under test.

**Enforcement is procedural/self-check:** the checkable signal is a general-purpose dispatch with
no template-considered sentence, no tier reasoning, or no explicit `model` in the call. The
postmortem-reviewer template's Dispatch-routing audit row checks this after the fact; no live
detector exists.

## Coordinator tier

This section is a separate axis from the tier table above, which governs dispatched subagents.
The coordinator is named by its specific model rather than by tier class: as of this writing the
candidates are Fable (the top class above Opus), Opus (Premium), and Sonnet (Standard).

The main agent coordinating a multi-todo plan runs at the tier the owner has set. The owner's
stored memory names the current coordinator model; as of 2026-09-11 it is Fable, after the owner
moved coordination from Opus back to Fable on that date. Moving coordination to another tier, in
either direction (Fable -> Opus, Opus -> Sonnet, or back), requires one full multi-todo session at
the candidate tier scoring at or under the owner-set threshold on the postmortem-reviewer
template's Correction-source audit row: the ratio externally-caught / (self-caught +
externally-caught) at or under 0.25 (owner-set 2026-09-12). Each scored session is recorded in the
owner's memory with the session id, the coordinator model, and the two counts.

**Enforcement is procedural/self-check:** the checkable signal is a multi-todo session whose
transcript model field (the per-message model value on assistant messages) is a tier with no
recorded passing session; the Correction-source audit row produces the score after the fact. No
live detector exists.
