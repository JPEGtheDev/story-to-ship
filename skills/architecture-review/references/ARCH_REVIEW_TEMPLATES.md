# Architecture Review -- Templates and Dispatch

## Review Report Format

```markdown
## Architecture Review: [file/component]

### Layer Assignment
Component belongs to: Layer [N] ([name])
Expected dependencies: Layers <=[N]
Actual dependencies found: [list includes/calls]

### Violations Found
| File | Line | Violation | Fix |
|------|------|-----------|-----|

### Verdict: CLEAN / VIOLATIONS FOUND
```

A verdict of VIOLATIONS FOUND means the PR is NOT mergeable until every row in the violations table is resolved.

---

## Dispatch Pattern

For PR reviews or major refactors:

1. Dispatch 1 `architecture-reviewer.md` agent per changed file (parallel) -- use `agent_type: "code-review"`
2. Provide: `{{FILE_PATH}}`, `{{INCLUDE_LIST}}`, and `{{DIFF_OR_EMPTY}}`
3. Collect all reports before approving the PR
4. Any VIOLATIONS FOUND verdict = block the PR
