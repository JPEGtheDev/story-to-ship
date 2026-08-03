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

### Verdict: APPROVE / REQUEST CHANGES
```

A verdict of REQUEST CHANGES means the PR is NOT mergeable until every finding in the table is resolved (findings classified `judgment call` -- a classification tracked in the dispatched agent's own findings table, not this local one -- do not block approval on their own).

---

## Dispatch Pattern

For PR reviews or major refactors:

1. Dispatch 1 architecture-review agent per changed file (parallel) -- use `agent_type: "architecture-reviewer"`
2. Provide: `{{FILE_PATH}}`, `{{INCLUDE_LIST}}`, and `{{DIFF_OR_EMPTY}}`
3. Collect all reports before approving the PR
4. Any REQUEST CHANGES verdict = block the PR
