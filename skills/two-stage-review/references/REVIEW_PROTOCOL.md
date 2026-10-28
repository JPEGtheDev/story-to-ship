# 2-Stage Review Protocol -- Full Details

## Stage 1: Spec Compliance Review

**Question:** Does the implementation do what the spec/requirements asked?

Use the `spec-compliance-reviewer.md` agent. Provide:
- Full requirements / acceptance criteria for the todo
- Full diff or file contents of the implementation

If Stage 1 returns GAPS: implementer fixes gaps. Re-run Stage 1 before proceeding (see "Who Re-Checks a Fix Round" below). This re-run is bounded by the fix-round cap and the unreadable-verdict rule, which live in SKILL.md.

**False positive check for "no other lines should change" requirements:** Stage 1 reviewers reading `git diff base..HEAD` see ALL prior commits as context, and may misattribute pre-existing branch content as implementer changes. When Stage 1 returns GAPS on this class of requirement, verify with `git show <commit> -- <file>` (single commit view). If the single-commit diff shows only the intended change, the coordinator never overrules the verdict itself: it sends that diff back to the same Stage 1 reviewer instance as a re-check and proceeds to Stage 2 only on its PASS. Resume the same instance; if it cannot be resumed, the resume-and-fallback rule of "Who Re-Checks a Fix Round" below applies. Each GAPS verdict gets one such re-check; if the same instance upholds GAPS, the normal fix round starts with no second re-check. The re-check sends no findings to the implementer, so it is not a fix round (SKILL.md defines a fix round as findings going back to the implementer). A missing or off-template re-check reply is not a pass (the unreadable-verdict rule in SKILL.md applies). **Consequences:** Skipping the single-commit view turns a reviewer's context artifact into a fix round: the implementer is dispatched to "fix" lines the todo never touched, and the round costs an implementer dispatch plus a Stage 1 re-run for a change that was never wrong. The check itself costs one `git show` and one re-check dispatch to the same reviewer, which is cheaper than that round.

## Stage 2: Code Quality Review

**Question:** Is the implementation clean, maintainable, and correct?

For skill `.md` files (in `skills/`): use the `skill-reviewer.md` agent.
For all other code and config files: use the `code-quality-reviewer.md` agent.
For each template, one dispatch per group of at most two files that implement one change (a scope with more files gets more dispatches) -- two files share a dispatch only when a changed line in one names the other by path or filename, or a changed line in each names the same skill or file, and files that share only the todo get separate dispatches; the reviewer returns one verdict block per file listed in the dispatch, and a return with fewer blocks than the dispatch listed is re-dispatched.

Provide to the Stage 2 reviewer:
- Full diff or file contents of the implementation
- The implementer's pasted verification output as the {{IMPLEMENTER_EVIDENCE}} value. The reviewer re-runs at least one command from it and reports MATCH or MISMATCH. If the implementer pasted no runnable command, state that explicitly so the reviewer records the spot-check as not possible. In the whole-branch pass the value is the dispatcher's own test run, see the Whole-Branch Pass section.

Adversarial-scenario gate: the Stage 2 dispatch prompt MUST require the reviewer to output a literal line `Adversarial scenario tested: <scenario>` in every verdict block: filled with one unscripted real-world case checked against the clause wording for each file whose diff adds or edits a line matching the case-sensitive trigger `EXCEPTION|carve-out` in agents/ or skills/, and with exactly `trigger not matched` otherwise; a block without that line is an incomplete review -- re-dispatch. The trigger is case-sensitive on purpose: uppercase EXCEPTION is the template convention, lowercase 'No exceptions.' boilerplate does not match, and residual false positives are accepted because the gate favors over-firing. The Stage 2 paragraph of SKILL.md states the gate; on any wording divergence, SKILL.md governs.

If any per-file block returns REQUEST CHANGES, REJECT, or NEEDS WORK: implementer fixes. Re-run Stage 2 before proceeding (see "Who Re-Checks a Fix Round" below). This re-run is bounded by the fix-round cap and the unreadable-verdict rule, which live in SKILL.md.

**Why one dispatch per change, on the Premium tier:** a reviewer that sees only one of a todo's files cannot see a contradiction between two of them, a reference one file leaves dangling in another, or a rule stated in one file and broken in the next; those findings fall between per-file dispatches. Grouping the files that implement one change into one dispatch keeps those findings inside a single review, and the per-file verdict blocks keep the per-file accountability that one-agent-per-file provided. The two-file cap follows the skill-reviewer template, which takes exactly two path slots, and binds the code-quality-reviewer template as well so both templates return the same dispatch shape; above it, the grouping rule, not the cap, is what keeps a contradiction visible. The two Stage 2 templates are pinned to the Premium tier; the tier table, the reason, and the measurement record are in the model-selection reference of the subagent-driven-development skill.

## Whole-Branch Pass

The cadence rule is in `SKILL.md`, section Review Cadence. This section holds the mechanics of one whole-branch Stage 2 cycle.

- **Wait for CI:** the pass starts only when CI is green on the feature branch head. While CI is red, fix CI first (a CI fix is not a Stage 2 cycle); a CI failure after a cycle's fixes is repaired before the next cycle starts. A CI failure the branch cannot fix (for example a failing check outside the story's scope) is not a cycle either: the runner hands back kind blocked, or an owner question, with the failing check named.
- **Input:** list the files from `git diff --name-only origin/main...HEAD` and group them under the Stage 2 grouping rule in `SKILL.md` (at most two files per dispatch, one verdict block per file); the pass covers every changed file except one whose latest change came from a risky todo that already passed its Stage 2, because that review saw the file as it now stands. The tier is unchanged.
- **Evidence:** `{{IMPLEMENTER_EVIDENCE}}` is the dispatcher's own run of the repository's test command on the branch head, pasted into the dispatch; when the repository has no test command, it is the CI result plus the CI check steps run locally. No single implementer produced the branch, so no implementer output stands in.
- **Charging:** a finding charges the fix-round count of the todo whose `Files:` list names the file. A file that no todo names, or that two or more todos name, is charged to the cycle only.
- **Fix and re-check:** a fresh implementer fixes the findings. The re-check covers the fix round's changed hunks plus the CI result on the updated head, not the whole branch, and CI must be green again before the next cycle. Each cycle's fix rounds charge the todo that owns the named file (see Charging), and the 3-cycle cap and the per-todo fix-round cap both apply; whichever is reached first stops the work.
- **Unreadable verdict:** the unreadable-verdict rule in `SKILL.md` applies to each dispatch of the pass.
- **Edge cases:** a branch diff with one file is one dispatch; a story with no risky todo has no Stage 2 before this pass. The measured case behind this rule: in a 22-todo run the quality review was 39 of 64 review dispatches.
- **Nits:** a nit from the pass is fixed, or declined with the reason recorded in the plan file, before the pass is complete; a size report is recorded there for the owner's decision.

## Who Re-Checks a Fix Round

When a fix round follows a review finding -- Stage 1 GAPS, Stage 2 REQUEST CHANGES, or any other named finding re-check -- the re-check is performed by the same reviewer instance that raised the finding, resumed with its original context. It is not a fresh full-panel re-run and not a different reviewer. A full-panel re-run multiplies cost without adding independence: the reviewer that raised the finding already holds the finding's context and can verify the fix precisely, while swapping reviewers loses that context and risks re-litigating settled ground. If the original instance cannot be resumed -- the resume call fails or the instance is gone -- dispatch a fresh reviewer from the same template with the original requirements file and the fix-round diff, and state in the dispatch that it is a re-check of a named finding, quoting the finding verbatim, so the new instance starts from the finding instead of from a blank review.

**Enforcement is procedural/self-check:** the checkable signal is a fix-round re-check dispatched as a fresh reviewer -- no resume of, or continuity with, the reviewer instance that raised the finding, and no stated resume failure with the finding quoted in the dispatch -- visible in the dispatch transcript. No automated detector exists.

---

## Child Report Size Cap

**Context:** A child's final message enters the dispatcher's context in full and the dispatcher cannot shorten it. In two long sessions, sub-agent hand-backs were 13.0% and 18.4% of the characters added to the main thread (794,337 and 863,233 characters), and pasted diffs and long command output carried most of them (172,009 of 794,337 characters were inside code fences in the first session).
**Forces:** The dispatcher needs the status code, the Worktree line, the Limitations line and the verdict blocks to act; the logs and diffs already live in a commit or a file. Truncating pasted output to its tail and exit status keeps the spot-check possible, because a reviewer re-runs the command and compares the tail and the exit status.
Count: the cap counts the whole final message with `wc -m`; replies are ASCII, so the count equals `wc -c`. A reply with several verdict blocks, a whole-branch pass reply and a re-check reply each count as one message against the cap. This cap is separate from the 3,000-character runner hand-back cap, which governs the story runner's hand-back to its launcher.
Recording an over-cap reply: the dispatcher writes the overrun and the reply's length in the status entry of the todo (in a whole-branch pass, in the cycle's note in the plan file). It does not re-dispatch to shorten the reply, because the re-dispatch would produce a second long reply. A reply that lacks a required line is the exception and follows the existing rules (resubmit, or re-dispatch).
If this section and SKILL.md differ, SKILL.md governs.
**Enforcement is procedural/self-check:** CI pins that the cap sentence is present in the templates and the skill; whether a reply stays under the cap is read from the transcript.

---

## Moved Rationale

These notes moved word for word from SKILL.md to keep the skill under the core-skill size cap; each group is labelled with the rule it belongs to.

**Stage 1 gate (Never skip Stage 1):**
**Context:** An implementer result is in hand and the quality review looks like the faster path.
**Forces:** Stage 2 checks how a change is written, not whether it is the change asked for, so a well-written wrong change passes it; running Stage 1 first spends the quality review only on work known to match the spec.

**Inline-lane todos:**
**Context:** The coordinator made a todo's edit itself instead of dispatching an implementer.
**Forces:** The coordinator's own check inherits the assumptions that wrote the edit, which is what the two stages exist to catch, and a named route in the status entry gives the audit one field to compare with the transcript.

**Unreadable verdict:**
**Enforcement is procedural/self-check:** CI pins the wording only; behavior is read from the transcript.
**Context:** A reviewer reply arrives with a missing, mis-cased, unlisted, or foreign verdict.
**Forces:** A missing verdict reads as a finished review and becomes a silent pass; exact matching makes the check a lookup, and one resumed re-dispatch recovers a reviewer that only mis-formatted its reply.

**Fix-round cap:**
**Enforcement is procedural/self-check:** CI pins the wording only; the transcript shows whether round three stops for a prompt.
**Context:** A todo's review loop keeps returning findings with no end point.
**Forces:** Each round looks cheap, so the loop runs past the point where the todo has consumed the owner's budget; a fixed count makes the stop a lookup, and the prompt hands the owner the open findings when their decision is cheapest.

---

## Canary Rationale

`Canary confirmed: [Worktree: line from implementer output]` is the observable signal that the Worktree line was read before any reviewer dispatch; it is not evidence that items 1 and 3 ran (the numbered items of BEFORE PROCEEDING in SKILL.md). A less powerful model can produce it mechanically: copy the Worktree line, paste it.

**Note:** The canary raises the cost of skipping for compliant agents -- it is not cryptographically bound to execution, and it does not prove the reviewer read the line or that Stage 1 will catch every defect.
