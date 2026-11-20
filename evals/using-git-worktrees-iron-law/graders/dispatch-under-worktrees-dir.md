---
type: tool_used
tool: Agent
input_match: '\.worktrees/'
min: 1
---

Behavior: the implementer dispatch names a worktree location under `.worktrees/`. Any dispatch whose prompt names such a path passes; the wording around it does not matter. The regex is a path form, the one the rule fixes for the location, so it is a checkable end state and needs no judge.
