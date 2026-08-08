# 2-Stage Review Protocol -- Full Details

## Stage 1: Spec Compliance Review

**Question:** Does the implementation do what the spec/requirements asked?

Use the `spec-compliance-reviewer.md` agent. Provide:
- Full requirements / acceptance criteria for the todo
- Full diff or file contents of the implementation

If Stage 1 returns GAPS: implementer fixes gaps. Re-run Stage 1 before proceeding.

**False positive check for "no other lines should change" requirements:** Stage 1 reviewers reading `git diff base..HEAD` see ALL prior commits as context, and may misattribute pre-existing branch content as implementer changes. When Stage 1 returns GAPS on this class of requirement, verify with `git show <commit> -- <file>` (single commit view). If the single-commit diff shows only the intended change, the GAPS verdict is a false positive -- proceed to Stage 2.

## Stage 2: Code Quality Review

**Question:** Is the implementation clean, maintainable, and correct?

For skill `.md` files (in `skills/`): use the `skill-reviewer.md` agent -- 1 agent per file.
For all other code and config files: use the `code-quality-reviewer.md` agent -- 1 agent per file.

Provide to the Stage 2 reviewer:
- Full diff or file contents of the implementation
- The implementer's pasted verification output as the {{IMPLEMENTER_EVIDENCE}} value. The reviewer re-runs at least one command from it and reports MATCH or MISMATCH. If the implementer pasted no runnable command, state that explicitly so the reviewer records the spot-check as not possible.

Adversarial-scenario gate: if the diff adds or edits a line matching the case-sensitive trigger `EXCEPTION|carve-out` in agents/ or skills/, the Stage 2 dispatch prompt MUST also require the reviewer to output a literal line `Adversarial scenario tested: <scenario>` naming one unscripted real-world case checked against the clause wording; a Stage 2 return without that line, when the trigger matched, is an incomplete review -- re-dispatch. The canonical statement of this gate (including the case-sensitivity rationale and the accepted over-firing) is the Stage 2 paragraph of SKILL.md; on any wording divergence, SKILL.md governs.

If Stage 2 returns REQUEST CHANGES: implementer fixes. Re-run Stage 2 before proceeding.
