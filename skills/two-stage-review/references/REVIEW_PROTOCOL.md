# 2-Stage Review Protocol -- Full Details

## Stage 1: Spec Compliance Review

**Question:** Does the implementation do what the spec/requirements asked?

Use the `spec-compliance-reviewer.md` agent. Provide:
- Full requirements / acceptance criteria for the todo
- Full diff or file contents of the implementation

If Stage 1 returns GAPS: implementer fixes gaps. Re-run Stage 1 before proceeding (see "Who re-checks a fix round" below).

**False positive check for "no other lines should change" requirements:** Stage 1 reviewers reading `git diff base..HEAD` see ALL prior commits as context, and may misattribute pre-existing branch content as implementer changes. When Stage 1 returns GAPS on this class of requirement, verify with `git show <commit> -- <file>` (single commit view). If the single-commit diff shows only the intended change, the GAPS verdict is a false positive -- proceed to Stage 2.

## Stage 2: Code Quality Review

**Question:** Is the implementation clean, maintainable, and correct?

For skill `.md` files (in `skills/`): use the `skill-reviewer.md` agent -- 1 agent per file.
For all other code and config files: use the `code-quality-reviewer.md` agent -- 1 agent per file.

Provide to the Stage 2 reviewer:
- Full diff or file contents of the implementation
- The implementer's pasted verification output as the {{IMPLEMENTER_EVIDENCE}} value. The reviewer re-runs at least one command from it and reports MATCH or MISMATCH. If the implementer pasted no runnable command, state that explicitly so the reviewer records the spot-check as not possible.

Adversarial-scenario gate: if the diff adds or edits a line matching the case-sensitive trigger `EXCEPTION|carve-out` in agents/ or skills/, the Stage 2 dispatch prompt MUST also require the reviewer to output a literal line `Adversarial scenario tested: <scenario>` naming one unscripted real-world case checked against the clause wording; a Stage 2 return without that line, when the trigger matched, is an incomplete review -- re-dispatch. The canonical statement of this gate (including the case-sensitivity rationale and the accepted over-firing) is the Stage 2 paragraph of SKILL.md; on any wording divergence, SKILL.md governs.

If Stage 2 returns REQUEST CHANGES: implementer fixes. Re-run Stage 2 before proceeding (see "Who re-checks a fix round" below).

## Who Re-Checks a Fix Round

When a fix round follows a review finding -- Stage 1 GAPS, Stage 2 REQUEST CHANGES, or any other named finding re-check -- the re-check is performed by the same reviewer instance that raised the finding, resumed with its original context. It is not a fresh full-panel re-run and not a different reviewer. A full-panel re-run multiplies cost without adding independence: the reviewer that raised the finding already holds the finding's context and can verify the fix precisely, while swapping reviewers loses that context and risks re-litigating settled ground.

**Enforcement is procedural/self-check:** the checkable signal is a fix-round re-check dispatched as a fresh reviewer -- no resume of, or continuity with, the reviewer instance that raised the finding -- visible in the dispatch transcript. No automated detector exists.

---

## Canary Rationale

`Canary confirmed: [Worktree: line from implementer output]` is the observable signal that BEFORE PROCEEDING items 1-3 of SKILL.md were executed before any reviewer dispatch, not skipped: the status code was read, the worktree line was found in the implementer's result, and the Limitations field was present. A less powerful model can produce it mechanically: copy the Worktree line, paste it.

**Note:** The canary raises the cost of skipping for compliant agents -- it is not cryptographically bound to execution, and it does not prove the reviewer read the line or that Stage 1 will catch every defect.
