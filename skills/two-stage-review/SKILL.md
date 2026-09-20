---
name: two-stage-review
description: Use when an implementer subagent has returned a result and the todo needs its status code handled and its two review stages run.
---


## Iron Law

```
YOU MUST DISPATCH REVIEWERS AFTER EVERY TODO -- SPEC COMPLIANCE FIRST, THEN CODE QUALITY.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the two-stage-review skill to review [todo]."

---

## Workflow

Read status code -> Canary confirmed -> Limitations present -> Stage 1 spec review -> Stage 2 quality review -> Mark done.

**Do not advance past any todo until Stage 1 returns PASS and every Stage 2 verdict block advances under the Stage 2 rule below.**

See `references/REVIEW_LOOP.md` for the full decision tree with complete ASCII flow.

---

## BEFORE PROCEEDING

Before dispatching Stage 1 for any implementer result:

1. The status code is read and its row's action taken (table below). `NEEDS_CONTEXT` and `BLOCKED` return to the dispatcher and never reach a review stage.
2. `Canary confirmed: [Worktree: line from implementer output]` is stated in your response.
3. The implementer result contains a `Limitations:` line. Absent -> resubmit for it; never infer "none".
4. File type identified: skill `.md` files (in `skills/`) -> `skill-reviewer.md`; code/config files -> `code-quality-reviewer.md`. Never invoke `/code-review` (the slash command) for skill `.md` files.
   **Context:** Choosing the Stage 2 reviewer for a changed file.
   **Forces:** The slash command is the shortest path to "a review happened", but it applies code-review criteria to a skill file and never runs the writing-skills checklist (Iron Law, gate, tables, size), so a skill defect comes back approved. Routing by file type costs one look at the path.

[+] All 4 met -> dispatch Stage 1
[-] Any unmet -> resolve it before any reviewer dispatch

---

## Canary

When applying this skill, before dispatching Stage 1 from any implementer result, state this line in your response:

> `Canary confirmed: [paste the Worktree: line from implementer output]`

If the canary line is absent from the implementer's output, the implementer did not follow its own BEFORE PROCEEDING -- require skill reload and resubmit before dispatching Stage 1.

It signals that the worktree line was read before any reviewer dispatch; it does not prove the reviewer read it or that Stage 1 will catch every defect.

Canary rationale: references/REVIEW_PROTOCOL.md.

---

## Implementer Status Codes

Every subagent doing implementation work must report one of these five codes. Require it in every implementer prompt. Do not accept a response that does not include one.

**Context:** Reading any implementer result before deciding what to do with it.
**Forces:** A free-form result reads as finished whether the work is finished, partial, or blocked, and the dispatcher fills the gap with the optimistic reading. A fixed set of five codes makes the implementer commit to one state, and each state has one required response in the table below, so the routing is a lookup instead of a judgment call.

| Code | Meaning | Your response |
|------|---------|---------------|
| `DONE` | Task complete, all verification passed, no concerns | Proceed to Stage 1 review |
| `DONE_WITH_CONCERNS` | Complete but flagged issues for dispatcher review | Read concerns. Correctness or scope risk: prompt the owner in this turn, then Pivot Assessment (Ceremony 4 of the `three-amigos` skill, which rules CONTINUE, REVISE AC (acceptance criteria), REVISE PLAN, or ABANDON). Otherwise canary + Stage 1; the verdict is not authorization to act. |
| `PARTIAL` | Partially complete -- some items done and verified, rest not done | Verify completed portion. Create new todo(s) for remaining work. Proceed to Stage 1 for completed portion only. |
| `NEEDS_CONTEXT` | Cannot proceed -- specific missing information listed | Provide the missing information. Re-dispatch. |
| `BLOCKED` | Cannot proceed -- external dependency or environment issue described | Prompt the owner in this turn (execution skill, serious blockers), then Pivot Assessment (Ceremony 4); if the ceremony is unavailable the prompt is the escalation. |

---

## 2-Stage Review Protocol

Every completed implementation task requires two reviews in this order. This is mandatory -- not optional -- after every single todo (a todo is defined in the `writing-plans` skill, Building the Plan step 1).

```
Stage 1: Spec Compliance Review     <- ALWAYS FIRST (spec-compliance-reviewer.md)
Stage 2: Code Quality Review        <- ONLY after Stage 1 passes (skill-reviewer.md or code-quality-reviewer.md -- see Stage 2 below)
```

**Never skip Stage 1.** Code that doesn't meet the spec doesn't benefit from quality review.
**Context:** An implementer result is in hand and the quality review looks like the faster path.
**Forces:** Stage 2 checks how the change is written, not whether it is the change that was asked for, so a well-written wrong change passes it. Stage 1 checks the diff against the requirements; running it first means Stage 2 spends its review only on work already known to match the spec.

**Re-review required for review-covered territory:** The GAPS/REQUEST CHANGES re-run rules below are one instance of a general rule: any change landing in already-reviewed territory -- a post-review edit, a fix round touching reviewed lines, or a "small" amendment to an approved diff -- requires re-review before the work advances. A prior PASS/APPROVE does not extend to the new change, even one the agent itself initiates. The sole exemption is an explicit user waiver given in the same turn -- not an inferred waiver, a prior-turn "go ahead", or the agent's own judgment that the change is trivial or already covered. Enforcement is procedural: a post-review commit touching reviewed territory with no re-review dispatch visible in the transcript is the checkable signal; no automated detector exists.

**Worktree hygiene:** All implementer subagents MUST work in a worktree. Never dispatch an implementer to the main working tree.
**Context:** Dispatching any implementer subagent.
**Forces:** The main working tree is where the coordinator commits and reviews; an implementer writing there mixes its edits into the coordinator's uncommitted state, so the diff under review no longer isolates the todo. A worktree gives the implementer its own branch and directory, so the review diff is exactly the todo.

**Stage 1:** Use `spec-compliance-reviewer.md` with full requirements and the implementation diff. If GAPS returned: implementer fixes gaps, Stage 1 re-runs before proceeding to Stage 2.

**Stage 2:** Use `code-quality-reviewer.md` for code/config files; use `skill-reviewer.md` for skill `.md` files. For each template, list the files the todo changed, at most two files per dispatch; more than two files means more than one dispatch, grouped so the files that implement one change go together. The test is a named dependency: two files share a dispatch only when a changed line in one names the other by path or filename (for example a SKILL.md and the references file its new pointer names), or a changed line in each names the same skill or file (two restatements of one rule); files that share only the todo are unrelated and get separate dispatches. Each dispatch returns one verdict block per file listed in that dispatch (the Output Contract section of the template); fewer blocks than that dispatch listed, or one merged block, is an incomplete review -- re-dispatch. If any block returns REQUEST CHANGES, REJECT, or NEEDS WORK: implementer fixes, Stage 2 re-runs before proceeding. APPROVE and PASS advance; APPROVE WITH NITS advances once each nit is fixed, or declined with the reason recorded in the todo's status; PASS (size advisory) advances once the size report is recorded in the todo's status for the user's decision. When dispatching Stage 2, pass the implementer's pasted verification output to the reviewer as the {{IMPLEMENTER_EVIDENCE}} value so the reviewer re-runs at least one command, once per dispatch, and reports MATCH or MISMATCH. A Stage 2 dispatch that omits {{IMPLEMENTER_EVIDENCE}} disables the spot-check and is incomplete. The Stage 2 dispatch prompt MUST require the reviewer to output a literal line `Adversarial scenario tested: <scenario>` in every block: filled with one unscripted real-world case checked against the clause wording for each file whose diff adds or edits a line matching the case-sensitive trigger `EXCEPTION|carve-out` in agents/ or skills/, and with exactly `trigger not matched` otherwise. A block without that line is an incomplete review -- re-dispatch. (Trigger is deliberately case-sensitive: uppercase EXCEPTION is the template convention; lowercase 'No exceptions.' boilerplate does not match. Residual false positives are accepted -- the gate favors over-firing.)

See `references/REVIEW_PROTOCOL.md` for full protocol details.

---

## Red Flags -- STOP

These thoughts mean stop immediately:

| Thought | Required action |
|---------|----------------|
| "About to relay a skeptic or reviewer verdict to the user" | STOP. State the base branch of the worktree that agent ran in. If the base is not `main` (or the user-approved feature branch), flag it explicitly: any finding about absent files or missing features may be a stale-branch artifact, not an actual gap. |
| "I'm about to invoke /code-review or dispatch a code-quality reviewer" | STOP. Identify the file types in scope FIRST. If any files are skill `.md` files (in `skills/`): use `skill-reviewer.md`, not `code-review` or `code-quality-reviewer.md`. Invoking `code-review` for skill `.md` files is always wrong. |
| "I've already verified this change through [testing/analysis] -- that's more rigorous than a re-review, I'll proceed without dispatching one" | STOP. Self-judged rigor is not a re-review. Any change touching review-covered territory requires Stage 1 or Stage 2 to re-run. The sole exemption is an explicit user waiver given in the same turn. |
| "Dispatching Stage 2 without passing {{IMPLEMENTER_EVIDENCE}}" | STOP. Paste the implementer's verification output into the reviewer prompt; a Stage 2 dispatch without it disables the spot-check and is incomplete. |
| "No `Limitations:` line in the result -- I'll take that as none" | STOP. Absence means the contract was not followed. Resubmit for the field before dispatching Stage 1. |

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The subagent's description sounds right, I'll skip review" | Descriptions are summaries -- they omit bugs. YOU MUST read the actual diff and dispatch the 2-stage review every time. |
| "This is just docs, no code review needed" | Documentation errors ship as silently as code bugs. Stage 1 spec compliance applies to every todo without exception. |
| "I verified one file, the rest are probably fine" | Every file the todo changed is listed in a Stage 2 dispatch and gets its own verdict block. A return with fewer blocks than its dispatch listed is incomplete -- no extrapolation across files. |
| "The subagent said PASS, that's good enough" | A subagent's self-assessment is not a review. PASS from an implementer means dispatch Stage 1 -- not skip it. |
| "I'll do a quick scan instead of dispatching a reviewer agent" | A quick scan inherits your assumptions. A dispatched `skill-reviewer.md` or `code-quality-reviewer.md` agent does not. Dispatch the agent. |
| "The two stages of review are redundant -- I wrote the code carefully" | YOU MUST dispatch spec-compliance-reviewer.md first, then code-quality-reviewer.md. Writing carefully is not a substitute for independent review. |
| "The concerns are nits -- not a correctness or scope risk, so I'll skip Ceremony 4" | "Correctness or scope risk" is objective: does it affect behavior, API surface, or stated requirements? If yes, prompt the owner, then Ceremony 4. "Feels minor" is not a valid exemption. |
| "The subagent hit a rate limit -- I'll do the review inline instead" | Rate limits are temporary. Inline review inherits your assumptions and blind spots. The whole point of a dispatched reviewer is independence from the author's context. Wait for the reset and dispatch. |
| "I've already verified this change through mutation testing, which is more rigorous than a re-review would be -- I'll proceed with committing" | Documented failure mode (source postmortem): the agent adjudicating whether its own change is "covered enough" to skip re-review IS the failure -- not a valid exemption. YOU MUST re-review any change in review-covered territory. |

---

## Related Skills

- `subagent-driven-development` -- the dispatch side of the loop: worktree, template, prompt, implementer dispatch
- `using-git-worktrees` -- isolation for every reviewer dispatch
- `execution` -- the work loop this review step sits in
- `three-amigos` -- Pivot Assessment, Ceremony 4, for BLOCKED and DONE_WITH_CONCERNS results
