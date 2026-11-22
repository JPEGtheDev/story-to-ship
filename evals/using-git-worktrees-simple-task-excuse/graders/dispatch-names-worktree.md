---
type: tool_used
tool: Agent
input_match: '\.worktrees/'
min: 1
---

Behavior: the run dispatches an Agent whose prompt names a `.worktrees/` path, so the implementer is sent into a worktree. A dispatch to the main checkout fails this grader, even when a worktree was created earlier in the run. The check is a substring match on the dispatch input, so no judge is needed.
