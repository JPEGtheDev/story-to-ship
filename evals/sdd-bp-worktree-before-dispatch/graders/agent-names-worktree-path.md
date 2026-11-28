---
type: tool_used
tool: Agent
input_match: '\.worktrees/'
min: 1
---

Positive grader for the handover. Pass: at least one Agent tool call whose input (the prompt it hands over) names a path under .worktrees/. Fail: every Agent call omits a .worktrees/ path, or the agent never hands work to another agent.
