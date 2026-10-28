---
name: two-stage-review
description: Use when an implementer subagent has returned a result and the todo needs its status code handled and its two review stages run.
---


## Iron Law

```
YOU MUST DISPATCH SPEC COMPLIANCE AFTER EVERY TODO AND CODE QUALITY OVER THE WHOLE BRANCH -- SPEC COMPLIANCE FIRST, THEN CODE QUALITY.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the two-stage-review skill to review [todo]."

---

## Workflow

Read status code -> Canary confirmed -> Limitations present -> Stage 1 spec review -> Stage 2 quality review (per Review Cadence) -> Mark done.

**Do not advance past a todo until Stage 1 returns PASS and, for a risky todo, its Stage 2 verdict blocks advance under the Stage 2 rule below.**

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

Every implementation subagent must report one of these five codes: require it in every implementer prompt and reject a response without one.

**Context:** Reading any implementer result before deciding what to do with it.
**Forces:** A free-form result reads as finished whether it is finished, partial, or blocked, and the dispatcher fills the gap optimistically. A fixed set of five codes makes the implementer commit to one state, and each has one required response below, so routing is a lookup.

| Code | Meaning | Your response |
|------|---------|---------------|
| `DONE` | Task complete, all verification passed, no concerns | Proceed to Stage 1 review |
| `DONE_WITH_CONCERNS` | Complete but flagged issues for dispatcher review | Read concerns. Correctness or scope risk: prompt the owner in this turn, then Pivot Assessment (Ceremony 4 of the `three-amigos` skill, which rules CONTINUE, REVISE AC (acceptance criteria), REVISE PLAN, or ABANDON). Otherwise canary + Stage 1; the verdict is not authorization to act. |
| `PARTIAL` | Partially complete -- some items done and verified, rest not done | Verify completed portion. Create new todo(s) for remaining work. Proceed to Stage 1 for completed portion only. |
| `NEEDS_CONTEXT` | Cannot proceed -- specific missing information listed | Provide the missing information. Re-dispatch. |
| `BLOCKED` | Cannot proceed -- external dependency or environment issue described | Prompt the owner in this turn (execution skill, serious blockers), then Pivot Assessment (Ceremony 4); if the ceremony is unavailable the prompt is the escalation. |

---

## Review Cadence

Stage 1 runs after every todo. Stage 2 runs once over the whole branch diff, after CI is green on the feature branch and before the pull request is handed back (outside a story run: before `finishing-a-development-branch`). One Stage 2 pass plus the fixes it triggers and their re-check is one whole-branch cycle; at most 3 cycles run, a count separate from the per-todo fix-round cap below. A not-passed Stage 2 verdict that would need a fourth cycle stops the work: end the turn with a prompt to the owner that states the open findings (a story runner hands back kind cap reached).
A todo is risky when its `Files:` list names a path under `.github/`, `hooks/` or `agents/`; the list is closed. A risky todo also gets Stage 2 right after its Stage 1 passes, and does not advance until it passes. Inline-lane, `PARTIAL` and `loop: three-role` todos are risky only by that test.
**Context:** A story has many todos, and the quality review is the costliest review role.
**Forces:** A Stage 2 after every todo re-reviews each file every time a later todo touches it and cannot see a contradiction between two todos, so its cost grows with todo count. One pass over the finished diff costs in proportion to the changed files and sees all todos together; a risky todo keeps an early review.
Pass inputs, evidence, charging, re-check scope and the red-CI case: `references/REVIEW_PROTOCOL.md`, section Whole-Branch Pass.

---

## 2-Stage Review Protocol

Every completed implementation task requires two reviews in this order. Stage 1 is mandatory after every todo (a todo is defined in the `writing-plans` skill, Building the Plan step 1); Stage 2 follows the Review Cadence.

```
Stage 1: Spec Compliance Review     <- ALWAYS FIRST (spec-compliance-reviewer.md)
Stage 2: Code Quality Review        <- ONLY after Stage 1 passes (skill-reviewer.md or code-quality-reviewer.md -- see Stage 2 below)
```

**Never skip Stage 1.** Code that doesn't meet the spec doesn't benefit from quality review.
Context, Forces and Enforcement notes for the Stage 1 gate, the inline lane, the unreadable-verdict rule and the fix-round cap: `references/REVIEW_PROTOCOL.md`, section Moved Rationale.

**Re-review required for review-covered territory:** any change landing in already-reviewed territory -- a post-review edit, a fix round touching reviewed lines, or a "small" amendment to an approved diff -- requires re-review before the work advances, even a change the agent initiates itself; a prior PASS/APPROVE does not extend to it. The sole exemption is an explicit user waiver given in the same turn; an inferred waiver, a prior-turn "go ahead", or the agent's own judgment that the change is trivial does not count. Enforcement is procedural: a post-review commit touching reviewed territory with no re-review dispatch in the transcript is the checkable signal.

**Worktree hygiene:** All implementer subagents MUST work in a worktree. Never dispatch an implementer to the main working tree.
**Context:** Dispatching any implementer subagent.
**Forces:** An implementer writing to the main working tree mixes its edits into the coordinator's uncommitted state, so the review diff no longer isolates the todo; a worktree keeps it exactly the todo.

**Inline-lane todos:** when the coordinator makes the todo's edit itself under the Inline lane row of the `subagent-driven-development` skill's Dispatch Decision Table, the coordinator's own report stands in for the implementer result: the `Worktree:` line is the output of `git -C <repo-root>/.worktrees/<feature> rev-parse --show-toplevel`, the status code and the `Limitations:` line are the coordinator's, and the pasted verification is the coordinator's own run. Stage 1 runs on that diff and Stage 2 follows the Review Cadence, and the coordinator applies their fixes itself under the same Inline lane row; a fix the inline-edit guard hook denies goes to an implementer. The inline lane removes the implementer dispatch, never a review. Every todo's status entry in the plan file (the todo list the `writing-plans` skill defines) names its route: `lane: dispatch`, or `lane: inline <n> lines in <file>` with one `<n> lines in <file>` clause per file edited inline and `<n>` counted the way the guard hook counts (a replaced line counts 2), or both values when the todo used both routes. An inline edit the entry does not list, or an inline value for an edit the guard hook denied, is a skipped-gate finding (a required step recorded as done that the transcript shows was skipped) for the postmortem reviewer.

**Stage 1:** Use `spec-compliance-reviewer.md` with full requirements and the implementation diff. If GAPS returned: implementer fixes gaps, Stage 1 re-runs before Stage 2.

**Stage 2:** Use `code-quality-reviewer.md` for code/config files; use `skill-reviewer.md` for skill `.md` files. For each template, list the files in scope (a risky todo's changed files, or the branch diff's files in the whole-branch pass), at most two files per dispatch; more than two files means more than one dispatch, grouped so the files that implement one change go together. Two files share a dispatch only when a changed line in one names the other by path or filename (for example a SKILL.md and the references file its new pointer names), or a changed line in each names the same skill or file; files that share only the todo get separate dispatches. Each dispatch returns one verdict block per file it lists (the template's Output Contract); fewer blocks, or one merged block, is an incomplete review -- re-dispatch. If any block returns REQUEST CHANGES, REJECT, or NEEDS WORK: implementer fixes, Stage 2 re-runs before proceeding. APPROVE and PASS advance; APPROVE WITH NITS advances once each nit is fixed, or declined with the reason recorded in the todo's status; PASS (size advisory) advances once the size report is recorded in the todo's status for the user's decision. When dispatching Stage 2, pass the implementer's pasted verification output as the {{IMPLEMENTER_EVIDENCE}} value so the reviewer re-runs at least one command, once per dispatch, and reports MATCH or MISMATCH (in the whole-branch pass the value is the dispatcher's own test run); a dispatch that omits it disables the spot-check and is incomplete. The Stage 2 dispatch prompt MUST require the reviewer to output a literal line `Adversarial scenario tested: <scenario>` in every block: filled with one unscripted real-world case checked against the clause wording for each file whose diff adds or edits a line matching the case-sensitive trigger `EXCEPTION|carve-out` in agents/ or skills/, and with exactly `trigger not matched` otherwise. A block without that line is an incomplete review -- re-dispatch. (Case-sensitive on purpose; rationale in references/REVIEW_PROTOCOL.md.)

**Child report size cap:** every implementer and reviewer child ends with one final message under the cap below, which each template in `agents/` repeats in its return format.
Final message cap: 4,000 characters for the whole final message, counted with `wc -m`; put the decision-relevant lines first, and leave any detail that does not fit in a commit or in a named file under /tmp that the message names.
The status code, the Worktree line, the Limitations line, each verdict block and the pasted verification all stay inside the cap, with no exception. Pasted verification: paste the command line, the last 40 lines of its output and its exit status, and save the full output to a named file under /tmp that the message names. A reply that lacks a required line is incomplete and is resubmitted, over the cap or not. An over-cap reply that has every required line is recorded in the status entry of its todo and is not re-dispatched. The inline-lane coordinator report, explorer and skeptic children are outside the cap. Count and rationale: `references/REVIEW_PROTOCOL.md`, section Child Report Size Cap.

**Unreadable verdict:** This rule generalizes the incomplete-review clauses above to a missing or unlisted verdict at either stage.
A Stage 1 or Stage 2 result whose verdict is missing, or is not one of the verdict values that reviewer's template defines, counts as not passed.
Matching is exact: a verdict counts only when spelled as the template spells it; lower case, a qualifier the template does not define, or another template's value is not one of them.
A verdict value that the replying reviewer's own template defines with its own qualifier, such as PASS (size advisory) in the skill-reviewer template, counts as written; among qualifiers, only one that template does not define makes a verdict unreadable.
Re-dispatch once, resuming the same reviewer instance when possible and dispatching a fresh reviewer from the same template only if the resume fails (the Who Re-Checks a Fix Round section of `references/REVIEW_PROTOCOL.md`); this re-dispatch is not a fix round. If the re-dispatched reply is also unreadable, stop that todo and end the turn with a prompt to the owner stating the reviewer's raw reply and the verdict values that were expected. Never infer a pass from the reply's prose.

**Fix-round cap:** A fix round is one pass in which the findings of a not-passed stage go back to the implementer (in the inline lane, to the coordinator) for a fix, followed by the re-check. Rounds are counted per todo across both stages. A Stage 1 re-run forced by a Stage 2 fix belongs to the same round, not a new one. Nit fixes after APPROVE WITH NITS and the size report after a size advisory are not rounds, because those verdicts advance the todo.
The stop applies only when a not-passed verdict would need a fourth fix round; a stage not yet run runs first, and an unreadable verdict gets its one re-dispatch first.
After 3 fix rounds on one todo without every review stage the Review Cadence runs for that todo passing, stop that todo and end the turn with a prompt to the owner that states the open findings.
The owner's answer decides how the todo continues.

See `references/REVIEW_PROTOCOL.md` for full protocol details.

---

## Red Flags -- STOP

These thoughts mean stop immediately:

| Thought | Required action |
|---------|----------------|
| "About to relay a skeptic or reviewer verdict to the user" | STOP. State the base branch of the worktree that agent ran in. If the base is not `main`, the user-approved feature branch, or, for a reviewer, the branch that reviewer inspects, flag it explicitly: any finding about absent files or missing features may be a stale-branch artifact, not an actual gap. |
| "I'm about to invoke /code-review or dispatch a code-quality reviewer" | STOP. Identify the file types in scope FIRST. If any files are skill `.md` files (in `skills/`): use `skill-reviewer.md`, not `code-review` or `code-quality-reviewer.md`. Invoking `code-review` for skill `.md` files is always wrong. |
| "I've already verified this change through [testing/analysis] -- that's more rigorous than a re-review, I'll proceed without dispatching one" | STOP. Self-judged rigor is not a re-review. Any change touching review-covered territory requires Stage 1 or Stage 2 to re-run. The sole exemption is an explicit user waiver given in the same turn. |
| "Dispatching Stage 2 without passing {{IMPLEMENTER_EVIDENCE}}" | STOP. Paste the implementer's verification output (in the whole-branch pass, the dispatcher's own test run) into the reviewer prompt; a Stage 2 dispatch without it disables the spot-check and is incomplete. |
| "No `Limitations:` line in the result -- I'll take that as none" | STOP. Absence means the contract was not followed. Resubmit for the field before dispatching Stage 1. |
| "The reviewer's reply has no verdict line, but the findings read clean -- that's a pass" | STOP. A missing or off-template verdict is not a pass. Re-dispatch once, resuming the same reviewer; if that reply is also unreadable, end the turn with a prompt to the owner. |
| "One more fix round will clear the remaining findings" | STOP. Count the todo's fix rounds across both stages. If a not-passed verdict would need a fourth round, do not start it; end the turn with a prompt to the owner. A stage that has not run yet runs first, and an unreadable verdict gets its one re-dispatch first. |

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The subagent's description sounds right, I'll skip review" | Descriptions are summaries -- they omit bugs. YOU MUST read the actual diff and dispatch Stage 1 for every todo, and Stage 2 when the Review Cadence says. |
| "This is just docs, no code review needed" | Documentation errors ship as silently as code bugs. Stage 1 spec compliance applies to every todo without exception; Stage 2 follows the Review Cadence. |
| "I verified one file, the rest are probably fine" | Every file in a Stage 2 dispatch's scope is listed in that dispatch and gets its own verdict block. A return with fewer blocks than its dispatch listed is incomplete -- no extrapolation across files. |
| "The subagent said PASS, that's good enough" | A subagent's self-assessment is not a review. PASS from an implementer means dispatch Stage 1 -- not skip it. |
| "I'll do a quick scan instead of dispatching a reviewer agent" | A quick scan inherits your assumptions. A dispatched `skill-reviewer.md` or `code-quality-reviewer.md` agent does not. Dispatch the agent. |
| "The two stages of review are redundant -- I wrote the code carefully" | YOU MUST dispatch spec-compliance-reviewer.md first, then the Stage 2 template for the file type (skill-reviewer.md or code-quality-reviewer.md), when the Review Cadence says. Care is no substitute for independent review. |
| "The concerns are nits -- not a correctness or scope risk, so I'll skip Ceremony 4" | "Correctness or scope risk" is objective: does it affect behavior, API surface, or stated requirements? If yes, prompt the owner, then Ceremony 4. "Feels minor" is not a valid exemption. |
| "This concern in the implementer result does affect behavior, so I'm treating it as a finding and fixing it in this same pass" | Judging a concern in an implementer result behavior-affecting is the trigger for the owner prompt, not a license to fix it: end the turn with the prompt before any fix or dispatch. |
| "The subagent hit a rate limit -- I'll do the review inline instead" | Rate limits are temporary. Inline review inherits your assumptions and blind spots. The whole point of a dispatched reviewer is independence from the author's context. Wait for the reset and dispatch. |
| "I've already verified this change through mutation testing, which is more rigorous than a re-review would be -- I'll proceed with committing" | Failure mode: an agent calling its own change "covered enough" to skip re-review. That IS the failure, not an exemption. YOU MUST re-review any change in review-covered territory. |
| "The risky todo can wait for the whole-branch pass, because Stage 2 runs once at the end anyway" | A todo whose `Files:` list names a path under `.github/`, `hooks/` or `agents/` keeps its early Stage 2. The list is closed, and a deferred risky todo is a skipped gate. |

---

## Related Skills

- `subagent-driven-development` -- the dispatch side of the loop: worktree, template, prompt, implementer dispatch
- `using-git-worktrees` -- isolation for every reviewer dispatch
- `execution` -- the work loop this review step sits in
- `three-amigos` -- Pivot Assessment, Ceremony 4, for BLOCKED and DONE_WITH_CONCERNS results
