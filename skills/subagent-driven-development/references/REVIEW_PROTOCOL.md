# 2-Stage Review Protocol -- Full Details

## Stage 1: Spec Compliance Review

**Question:** Does the implementation do what the spec/requirements asked?

Use the `spec-compliance-reviewer.md` agent. Provide:
- Full requirements / acceptance criteria for the todo
- Full diff or file contents of the implementation

If Stage 1 returns GAPS: implementer fixes gaps. Re-run Stage 1 before proceeding.

## Stage 2: Code Quality Review

**Question:** Is the implementation clean, maintainable, and correct?

For skill `.md` files (in `skills/`): use the `skill-reviewer.md` agent -- 1 agent per file.
For all other code and config files: use the `code-quality-reviewer.md` agent -- 1 agent per file.

If Stage 2 returns REQUEST CHANGES: implementer fixes. Re-run Stage 2 before proceeding.
