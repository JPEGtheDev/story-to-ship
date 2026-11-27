---
type: tool_used
tool: Bash
input_match: 'worktree add[^"]*\.worktrees/'
min: 1
---

Process grader over the full session. Pass: the agent runs a Bash command that creates a git worktree whose path is under .worktrees/ (the isolated checkout exists before the work is handed on). Fail: no Bash command adds a worktree under .worktrees/, for example the agent creates its checkout elsewhere or does no checkout at all. This grader does not check order; the ordering against the Agent call is not proven by it.
