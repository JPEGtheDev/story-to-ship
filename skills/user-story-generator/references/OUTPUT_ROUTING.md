# Output Routing -- Where Approved Stories Go

## Context

After Three Amigos Refinement approves a plan, stories must be created in the right location or they will be treated as scratch work and ignored in future sessions.

## Forces

- `plan.md` is a session workspace, not a story tracker -- content in plan.md is overwritten or deleted when a session ends
- GitHub issues are the authoritative record for work items -- they survive across sessions, are visible to collaborators, and carry traceability through to pull requests
- Mixing stories and discovery output in the same artifact makes both harder to use

## Rule

**Approved stories go to GitHub issues, not `plan.md`.** Create one issue per story after Three Amigos Refinement approves the plan. Use `mcp__github__issue_write` with the full user story, Acceptance Criteria, effort estimate, and Definition of Done.

`plan.md` holds the `## Feature Specification` (Discovery output) and `## Implementation Notes` (Developer amigo findings) only. Individual stories in plan.md are a scratch surface -- not a substitute for GitHub issues.
