---
name: three-amigos
license: MIT
description: Use when a feature has new or unclear acceptance criteria, a plan has 2+ todos and Discovery ran, or an implementer signals BLOCKED or DONE_WITH_CONCERNS.
---


## Iron Law

```
YOU MUST INVOKE THE THREE AMIGOS BEFORE BUILDING WHAT HASN'T BEEN DEFINED.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the three-amigos skill to [ceremony name] for [brief feature description]."

---

## When to Invoke

| # | Signal | Ceremony | Output | Model |
|---|--------|----------|--------|-------|
| 1 | New or unclear Acceptance Criteria (AC) | Discovery | Feature Specification written to plan.md | `claude-haiku-4.5` |
| 2 | Plan 2+ todos AND Discovery ran | Refinement | APPROVE / CONDITIONS / REJECT | `claude-sonnet-4.6` |
| 3 | Mid-implementation milestone | Progress Check | ON TRACK / AT RISK / PIVOT NEEDED | `claude-haiku-4.5` |
| 4 | BLOCKED or DONE_WITH_CONCERNS | Pivot Assessment | CONTINUE / REVISE AC / REVISE PLAN / ABANDON | `claude-sonnet-4.6` |
| 5 | All todos done, pre-merge | Signoff | ACCEPTED / REVISIONS NEEDED | `claude-sonnet-4.6` |
| 6 | Feature merged and closed | Retrospective | Process improvement items | `claude-haiku-4.5` |

Simple 1-todo, clear AC -> skip; use Skeptic. 1+2 required for Discovery features. 5 required if Discovery ran. 3+4 trigger-based. 6 expected post-merge. Full agendas + model selection rationale: `references/CEREMONIES.md`.

---

## BEFORE PROCEEDING

1. Which ceremony? (see When to Invoke)
2. Did Discovery run? Check plan.md for `## Feature Specification`.
   [+] -> Three Amigos for Ceremonies 2, 5, 6
   [-] -> Skeptic for Ceremony 2
3. 3 worktrees, one per amigo. Inject `{{PERSONA}}` + `{{READ_FIRST}}` + `{{CEREMONY}}` + `{{AGENDA}}` into amigo.md.
   [+] All three worktrees created -> dispatch amigos
   [-] Any worktree missing -> create it before dispatching
4. Collect all three verdicts before acting on any.
   [+] All three verdicts received -> proceed to synthesis
   [-] Any verdict missing -> wait; do not act on partial results
5. Any single REJECT blocks. Majority does NOT override.
   [+] No REJECT -> proceed
   [-] Any REJECT -> address blocking issue before proceeding

---

## Discovery -- Mandatory Agenda Questions

When dispatching Ceremony 1 (Discovery), each amigo MUST address ALL of the following in addition to the standard agenda in `references/CEREMONIES.md`:

1. **Field optionality:** For each field or attribute in the acceptance criteria: is it required, optional, or conditional? Ambiguous optionality MUST be labelled `[UNCLEAR: optional?]` in the Feature Specification. Never assume required unless the AC explicitly states it.
2. **UI dialog entry paths:** For any UI dialog or panel in the acceptance criteria: enumerate every menu path and keyboard shortcut that opens it. Any path not mentioned in the ACs MUST be flagged as `[UNPLANNED: entry-path]` in the Feature Specification.

A Feature Specification that does not address both questions is incomplete and MUST be revised before Ceremony 2 (Refinement).

---

## Discovery Tracking Mechanism

**Context:** Ceremony 2 routing and Signoff only. Not for non-Discovery features.

**Forces:** Without a persisted signal, Refinement vs. Skeptic routing is ambiguous across sessions.

**Solution:** `## Feature Specification` in plan.md = "Discovery ran." Written at close. Read by brainstorming, writing-plans, and Signoff.

**Consequences:** `## Feature Specification` is append-only. Deleting it resets routing state.

---

## Worktree Dispatch Protocol

- 3 simultaneous worktrees, branches: `amigo/<ceremony>-<persona>`.
- Source `{{READ_FIRST}}` and `{{AGENDA}}` from `references/CEREMONIES.md`.
- After all verdicts: delete worktrees and branches.
- NEEDS_CONTEXT from any amigo -> re-dispatch that amigo only.
- Agent prompts MUST include an explicit `cd {{WORKTREE_PATH}} &&` before the worktree self-check. Agents start in the session's main repo directory, not the worktree -- without the explicit `cd`, the self-check will always return BLOCKED.
- If a stop hook fires during an active amigo wait: respond to the hook only if the hook action does not modify any file that running amigos are currently reading. Committing a previously untracked file that amigos have not opened is safe. Staging or modifying plan.md, SKILL.md, or any reference file an amigo may be reading is not safe. Log the interruption. Do not synthesize amigo results until all verdicts are received. Resume the wait after handling the hook.

---

## Canary

Before dispatching any amigos, state the ceremony and feature:

```
CANARY: Three Amigos loaded. Ceremony: [ceremony name]. Feature: [feature description].
```

This output proves the ceremony was identified before dispatch. It does not prove the correct ceremony was selected or that plan.md was read.

---

## Red Flags -- STOP

- "Two approved -- proceed" -> Any REJECT blocks. Collect all three verdicts first.
- "Discovery ran, skip re-reading the spec" -> Read plan.md now.
- "Small feature, skip Three Amigos" -> Check When to Invoke. If the signal fires, run the ceremony now.
- "AC is obvious" -> Informal AC is exactly what Discovery solves. Run Discovery now.
- "AskUserQuestion was used for clarification, skipping Discovery" -> STOP. AskUserQuestion output is not a Feature Specification. Run Discovery now.
- "REVISIONS NEEDED -- fix and merge" -> Requires new todos, completion, and re-Signoff.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "We discussed it, Discovery is redundant" | Discussion != Feature Specification. Run Discovery. |
| "AskUserQuestion answered the same questions" | AskUserQuestion produces informal clarification. Discovery produces a Feature Specification with behavioral ACs, field optionality, and invocation path coverage. They are not equivalent. Run Discovery. |
| "Developer knows the code, skip that amigo" | Amigo reads code first. Findings are evidence. |
| "Two approved -- majority rules" | Any REJECT blocks. Majority is irrelevant. |
| "Signoff is a formality" | Signoff is whole-feature behavioral review. Both required. |
| "Retrospective is optional" | Process debt accumulates. Expected, not optional. |
| "Not fully blocked, skip Pivot Assessment" | DONE_WITH_CONCERNS also triggers Pivot Assessment. |

---

## Related Skills

- `skeptic` -- plan validation without Three Amigos ceremony; use when Discovery did not run and a single-todo feature needs review
- `brainstorming` -- design exploration; referenced by the Discovery Tracking Mechanism as a reader of the Feature Specification

## References

- `references/CEREMONIES.md` -- per-amigo sources, agenda lists, output formats, and model selection rationale for all 6 ceremonies
