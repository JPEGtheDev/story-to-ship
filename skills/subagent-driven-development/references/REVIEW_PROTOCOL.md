# 2-Stage Review Protocol — Full Details

## Stage 1: Spec Compliance Review

**Question:** Does the implementation do what the spec/requirements asked?

Use `.github/agents/spec-compliance-reviewer.md`. Provide:
- Full requirements / acceptance criteria for the todo
- Full diff or file contents of the implementation

If Stage 1 returns GAPS: implementer fixes gaps. Re-run Stage 1 before proceeding.

## Stage 2: Code Quality Review

**Question:** Is the implementation clean, maintainable, and correct?

Use `.github/agents/code-quality-reviewer.md` — 1 agent per file changed.

If Stage 2 returns REQUEST CHANGES: implementer fixes. Re-run Stage 2 before proceeding.
