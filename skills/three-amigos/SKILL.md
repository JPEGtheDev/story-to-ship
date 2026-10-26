---
name: three-amigos
license: MIT
description: Use when a feature has new or unclear acceptance criteria, a plan has 2+ todos and Discovery ran, or an implementer signals BLOCKED, or DONE_WITH_CONCERNS carrying a correctness or scope risk.
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

| # | Signal | Ceremony | Output |
|---|--------|----------|--------|
| 1 | New or unclear Acceptance Criteria (AC) | Discovery | Feature Specification with example map written to plan.md (a BACK TO OWNER map goes under `## Discovery Open Items`) |
| 2 | Plan 2+ todos AND Discovery ran | Refinement | APPROVE / CONDITIONS / REJECT |
| 3 | Mid-implementation milestone | Progress Check | ON TRACK / AT RISK / PIVOT NEEDED |
| 4 | BLOCKED, or DONE_WITH_CONCERNS carrying a correctness or scope risk (owner prompted first) | Pivot Assessment | CONTINUE / REVISE AC / REVISE PLAN / ABANDON |
| 5 | All todos done, pre-merge | Signoff | ACCEPTED / REVISIONS NEEDED |
| 6 | Feature merged and closed | Retrospective | Process improvement items |

For row 4 (BLOCKED, or DONE_WITH_CONCERNS carrying a correctness or scope risk -- it affects behavior, API surface, or stated requirements), the owner is prompted in this turn, in the same turn the blocker is diagnosed, before this ceremony runs. This ceremony's verdict is not authorization to act before the owner answers. Full requirement: `execution` skill, "Serious blockers and pivots".

Ceremony model tiers are defined once in the `subagent-driven-development` skill (Model Selection, Tier Assignments table). Load that skill for the current tier per ceremony. Do not restate model IDs here.

Simple 1-todo, clear AC -> skip; use Skeptic. 1+2 required for Discovery features. 5 required if Discovery ran. 3+4 trigger-based. 6 required post-merge for multi-session work, optional for single-session work. Full agendas: `references/CEREMONIES.md`.

---

## BEFORE PROCEEDING

1. Which ceremony? (see When to Invoke)
   [+] Ceremony named from the When to Invoke table -> go to item 2
   [-] No ceremony named -> pick one from the table before dispatching
2. Did Discovery run? Check plan.md for `## Feature Specification`.
   If plan.md has `## Discovery Open Items` and no `## Feature Specification`, STOP until the map is updated from the owner's answer and passes the stopping rule; do not plan.
   [+] -> Three Amigos for Ceremonies 2, 5, 6
   [-] -> Skeptic + plan-reviewer pair for Ceremony 2 (see `writing-plans`)
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

1. **Field optionality:** For each field or attribute in the acceptance criteria: is it required, optional, or conditional? Ambiguous optionality MUST be labelled `[UNCLEAR: optional?]` in the example map (Questions line). Never assume required unless the AC explicitly states it.
2. **UI dialog entry paths:** For any UI dialog or panel in the acceptance criteria: enumerate every menu path and keyboard shortcut that opens it. Any path not mentioned in the ACs MUST be flagged as `[UNPLANNED: entry-path]` in the example map (Questions line).

These two questions are part of every Discovery amigo brief's agenda items (the focused-brief rule in Ceremony 1 of `references/CEREMONIES.md`).

A Feature Specification that does not address both questions is incomplete and MUST be revised before Ceremony 2 (Refinement).

A map whose Verdict is `BACK TO OWNER` is written under `## Discovery Open Items`, not `## Feature Specification`, and stops the run at Discovery: do not plan, send the rules with no example and open questions to the owner. The example map fields and stopping rule are defined in `references/CEREMONIES.md`, Ceremony 1.

---

## Discovery Tracking Mechanism

**Context:** Ceremony 2 routing and Signoff only. Not for non-Discovery features.

**Forces:** Without a persisted signal, Refinement vs. Skeptic + plan-reviewer routing is ambiguous across sessions.

**Solution:** `## Feature Specification` in plan.md = "Discovery ran." Written at close. Read by brainstorming, writing-plans, and Signoff.

**Consequences:** `## Feature Specification` is append-only. Deleting it resets routing state.

---

## Worktree Dispatch Protocol

- 3 simultaneous worktrees, branches: `amigo/<ceremony>-<persona>`.
- Source `{{READ_FIRST}}` and `{{AGENDA}}` from `references/CEREMONIES.md`.
- After all verdicts and, in Discovery, after the skeptic check routing (including any amigo return dispatch) has finished: delete worktrees and branches.
- Discovery only: after all three amigo verdicts, a skeptic check runs once, sequentially, read-only, with `model` passed explicitly. Its procedure is in `references/CEREMONIES.md`, Ceremony 1, `### Skeptic check -- PILOT`.
- NEEDS_CONTEXT from any amigo -> re-dispatch that amigo only (a Discovery skeptic return dispatch is the exception: see Ceremony 1, Skeptic check routing).
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
- "The acceptance criteria all describe the happy path" -> STOP. A criteria set with no criterion for invalid input, failure, or deliberate misuse is incomplete -- misuse is a failure case (things going wrong by intent). In Discovery (Ceremony 1), surface the gap under agenda question 4 (failure cases).
- "The AC has zero failure-path coverage at Refinement" -> STOP. That is a CONDITIONS/REJECT ground under Refinement's (Ceremony 2) agenda question 4 (missing edge cases, error handling, or failure modes); such a criteria set cannot receive APPROVE.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "We discussed it, Discovery is redundant" | Discussion != Feature Specification. Run Discovery. |
| "AskUserQuestion answered the same questions" | AskUserQuestion produces informal clarification. Discovery produces a Feature Specification with behavioral ACs, field optionality, and invocation path coverage. They are not equivalent. Run Discovery. |
| "Developer knows the code, skip that amigo" | Amigo reads code first. Findings are evidence. |
| "Two approved -- majority rules" | Any REJECT blocks. Majority is irrelevant. |
| "Signoff is a formality" | Signoff is whole-feature behavioral review. Both required. |
| "Retrospective is optional" | Required for multi-session work; optional only for single-session work. Skipped retrospectives let process debt accumulate. |
| "Not fully blocked, skip Pivot Assessment" | A DONE_WITH_CONCERNS result carrying a correctness or scope risk also triggers the owner prompt, then Pivot Assessment. |
| "The owner answered in chat, so move the map and plan" | The answer can change rules and examples; only a map that passes the stopping rule again is a Feature Specification. Update the map, re-apply the stopping rule, then move it. |

---

## Related Skills

- the `skeptic` agent (`agents/skeptic.md`) -- plan validation without a Three Amigos ceremony when Discovery did not run and a single-todo feature needs review; separately, it runs the Discovery map check (Ceremony 1 in `references/CEREMONIES.md`)
- `brainstorming` -- design exploration; referenced by the Discovery Tracking Mechanism as a reader of the Feature Specification

## References

- `references/CEREMONIES.md` -- per-amigo sources, agenda lists, and output formats for all 6 ceremonies
- `references/FORMULATION.md` -- rules for writing Given/When/Then scenarios
