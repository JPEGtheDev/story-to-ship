---
type: tool_used
tool: Agent
input_match: '\.worktrees/'
min: 1
---

Behavior: the run dispatches an Agent whose prompt names a `.worktrees/` path, so the implementer is sent into a worktree. Any dispatch whose prompt names such a path passes; the wording around it does not matter. The check is a substring match on the dispatch input, so no judge is needed.
