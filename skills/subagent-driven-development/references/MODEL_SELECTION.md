# Model Selection

Match model tier to task complexity. Write instructions that the least capable model tier able to run them can follow, regardless of selected tier (the `writing-skills` skill's model-compatibility guidance).

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
| Review: spec compliance (Stage 1 of the `two-stage-review` skill) | Standard |
| Review: quality (Stage 2 of the `two-stage-review` skill; template rows in the assignments table below) | Premium |
| Review: architecture | Standard |
| Architecture design, security, final review (NOT compliance review) | Premium |

## Tier Assignments

Three tiers exist. **Economy** = smallest/cheapest model class, for tasks that clear the content-touching floor below; no row in either table currently uses it. **Standard** = mid class, the default tier for any task no row assigns otherwise. **Premium** = top class, reserved for rows marked Premium.

**Content-touching work floor:** Classification, extraction, distillation, and summarization tasks -- any task that exercises judgment over source content -- run at Standard tier or above, no matter how narrow or mechanical the task otherwise looks. Economy is acceptable only for tasks whose output is mechanically verifiable (for example, a file-listing roll-up), never for judgment over source content. Verbatim copying from large content embedded in a prompt counts as content extraction for the purpose of this floor; verify bytes by hash or pass the content by file path instead of copying it inline.

Tier assignments for named agents and ceremonies, listed here so the full mapping lives in one place. Rows are Standard, the default tier and the floor for content-touching work described above, unless the row says Premium:

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
| skill-reviewer template (Stage 2 quality review of skill files) | Premium | Measured on this repo: a Standard-tier Stage 2 let two defects ship that a Premium-tier reviewer caught on the same diffs (record: the research issue titled "Stage 2 review: evaluate per-todo batching as an alternative to one-reviewer-per-file" on the repo's issue tracker); one dispatch per group of at most two files that implement one change, per-file verdict blocks (the `two-stage-review` skill, Stage 2) |
| code-quality-reviewer template (Stage 2 quality review of code and config files) | Premium | No separate measurement for code and config files; assigned Premium by the same argument and the same dispatch shape as the skill-reviewer row |

This table is the single source of truth for agent and ceremony tiers. Skills and agent templates MUST point here rather than restating model IDs in prose; agent template frontmatter model fields implement these assignments and MUST stay consistent with this table.

**Using Premium for non-architecture tasks:** A template row in the assignments table above that says Premium needs no per-dispatch reasoning. For anything else, state the reasoning before dispatching. Example: "Dispatching Premium for this review because the change touches 3 layer boundaries." Do not dispatch Premium silently for mechanical work.

**Comparing tiers by cost:** When comparing model tiers (for example Economy vs. Standard) for cost, report dollar cost priced from current per-million-token pricing fetched from the platform docs at analysis time -- never compare raw token counts. Tokenizers differ across model families, so token counts from different models are not unit-compatible; a model that consumes more tokens for the same text is not necessarily the more expensive one. The harness's own token-usage figure for a subagent is not a billing-grade metric -- billing-grade truth comes from the per-message usage events recorded in the session and subagent transcript JSONL (JSON Lines) files (input tokens, output tokens, cache creation, cache read); sum those when a dollar comparison matters. A resumed subagent can silently revert to its template's default model instead of the model used for its earlier dispatch -- re-verify the per-call model field before attributing any result to a tier.

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

## Explicit model on every call

Pass `model` on every Agent call, template-backed or not. A template's frontmatter pin is a
fallback for calls that omit the field, and the events log (the events JSON Lines file that the
repo's session-events converter builds from a session transcript) records an omitted field as
`inherit` whether the template pin or your own model ran the call, so the log does not show which
model ran; only the call records the tier decision. Check a finished session with:

```
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Agent" and ((.input.model // "") == "")) | (.input.subagent_type // "general-purpose")' TRANSCRIPT.jsonl | sort | uniq -c
```

Empty output means every dispatch named its tier; each line is an agent type dispatched without
one, with the count (a call that also omits `subagent_type` is listed as `general-purpose`).

**Enforcement is procedural/self-check:** the checkable signal is that listing; no live detector
exists.

## Coordinator tier

This section is a separate axis from the tier table above, which governs dispatched subagents. It
governs the tier of the main agent coordinating a multi-todo plan.

The coordinator runs at the tier the stored model preference names (the same source the priority
list at the top of this file checks first). Moving coordination to a different tier, in either
direction, requires one full multi-todo session at the candidate tier scoring at or under the
threshold on the postmortem-reviewer template's Correction-source audit row: the ratio
externally-caught / (self-caught + externally-caught). The threshold is 0.75, the ratio the Standard
tier scored on its own multi-todo session, unless a stored preference for this threshold sets
another value. The postmortem of each scored session records the session id, the coordinator model,
and the two counts; that record is the evidence for the move.

Scored sessions, one line each, appended as each session is scored (never replaced, so the section is the record of every scored session):
- Standard tier, multi-todo session: 0.75 -- the threshold.
- Premium tier, six-item plan of skill-file edits: 0.47 (7 externally-caught of 15), zero corrections raised by the user, every external catch a dispatch-prompt verification command that could not fire as claimed. At or under the threshold, so the tier is eligible to coordinate; the coordinator still runs at the tier the stored preference names until the user changes that preference.

**Enforcement is procedural/self-check:** the checkable signal is a multi-todo session whose
transcript model field (the per-message model value on assistant messages) is a tier with no
recorded passing session; the Correction-source audit row produces the score after the fact. No
live detector exists.
