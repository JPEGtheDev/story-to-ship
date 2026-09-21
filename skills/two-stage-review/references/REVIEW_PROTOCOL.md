# 2-Stage Review Protocol -- Full Details

## Stage 1: Spec Compliance Review

**Question:** Does the implementation do what the spec/requirements asked?

Use the `spec-compliance-reviewer.md` agent. Provide:
- Full requirements / acceptance criteria for the todo
- Full diff or file contents of the implementation

If Stage 1 returns GAPS: implementer fixes gaps. Re-run Stage 1 before proceeding (see "Who re-checks a fix round" below).

**False positive check for "no other lines should change" requirements:** Stage 1 reviewers reading `git diff base..HEAD` see ALL prior commits as context, and may misattribute pre-existing branch content as implementer changes. When Stage 1 returns GAPS on this class of requirement, verify with `git show <commit> -- <file>` (single commit view). If the single-commit diff shows only the intended change, the GAPS verdict is a false positive -- proceed to Stage 2. **Consequences:** Skipping the single-commit view turns a reviewer's context artifact into a fix round: the implementer is dispatched to "fix" lines the todo never touched, and the round costs an implementer dispatch plus a Stage 1 re-run for a change that was never wrong. The check itself costs one `git show`.

## Stage 2: Code Quality Review

**Question:** Is the implementation clean, maintainable, and correct?

For skill `.md` files (in `skills/`): use the `skill-reviewer.md` agent.
For all other code and config files: use the `code-quality-reviewer.md` agent.
For each template, one dispatch per group of at most two files that implement one change (a todo with more files gets more dispatches) -- two files share a dispatch only when a changed line in one names the other by path or filename, or a changed line in each names the same skill or file, and files that share only the todo get separate dispatches; the reviewer returns one verdict block per file listed in the dispatch, and a return with fewer blocks than the dispatch listed is re-dispatched.

Provide to the Stage 2 reviewer:
- Full diff or file contents of the implementation
- The implementer's pasted verification output as the {{IMPLEMENTER_EVIDENCE}} value. The reviewer re-runs at least one command from it and reports MATCH or MISMATCH. If the implementer pasted no runnable command, state that explicitly so the reviewer records the spot-check as not possible.

Adversarial-scenario gate: the Stage 2 dispatch prompt MUST require the reviewer to output a literal line `Adversarial scenario tested: <scenario>` in every verdict block: filled with one unscripted real-world case checked against the clause wording for each file whose diff adds or edits a line matching the case-sensitive trigger `EXCEPTION|carve-out` in agents/ or skills/, and with exactly `trigger not matched` otherwise; a block without that line is an incomplete review -- re-dispatch. The canonical statement of this gate (including the case-sensitivity rationale and the accepted over-firing) is the Stage 2 paragraph of SKILL.md; on any wording divergence, SKILL.md governs.

If any per-file block returns REQUEST CHANGES, REJECT, or NEEDS WORK: implementer fixes. Re-run Stage 2 before proceeding (see "Who re-checks a fix round" below).

**Why one dispatch per change, on the Premium tier:** a reviewer that sees only one of a todo's files cannot see a contradiction between two of them, a reference one file leaves dangling in another, or a rule stated in one file and broken in the next; those findings fall between per-file dispatches. Grouping the files that implement one change into one dispatch keeps those findings inside a single review, and the per-file verdict blocks keep the per-file accountability that one-agent-per-file provided. The two-file cap follows the skill-reviewer template, which takes exactly two path slots, and binds the code-quality-reviewer template as well so both templates return the same dispatch shape; above it, the grouping rule, not the cap, is what keeps a contradiction visible. The two Stage 2 templates are pinned to the Premium tier; the tier table, the reason, and the measurement record are in the model-selection reference of the subagent-driven-development skill.

## Who Re-Checks a Fix Round

When a fix round follows a review finding -- Stage 1 GAPS, Stage 2 REQUEST CHANGES, or any other named finding re-check -- the re-check is performed by the same reviewer instance that raised the finding, resumed with its original context. It is not a fresh full-panel re-run and not a different reviewer. A full-panel re-run multiplies cost without adding independence: the reviewer that raised the finding already holds the finding's context and can verify the fix precisely, while swapping reviewers loses that context and risks re-litigating settled ground. If the original instance cannot be resumed -- the resume call fails or the instance is gone -- dispatch a fresh reviewer from the same template with the original requirements file and the fix-round diff, and state in the dispatch that it is a re-check of a named finding, quoting the finding verbatim, so the new instance starts from the finding instead of from a blank review.

**Enforcement is procedural/self-check:** the checkable signal is a fix-round re-check dispatched as a fresh reviewer -- no resume of, or continuity with, the reviewer instance that raised the finding, and no stated resume failure with the finding quoted in the dispatch -- visible in the dispatch transcript. No automated detector exists.

---

## Canary Rationale

`Canary confirmed: [Worktree: line from implementer output]` is the observable signal that BEFORE PROCEEDING items 1-3 of SKILL.md were executed before any reviewer dispatch, not skipped: the status code was read, the worktree line was found in the implementer's result, and the Limitations field was present. A less powerful model can produce it mechanically: copy the Worktree line, paste it.

**Note:** The canary raises the cost of skipping for compliant agents -- it is not cryptographically bound to execution, and it does not prove the reviewer read the line or that Stage 1 will catch every defect.
