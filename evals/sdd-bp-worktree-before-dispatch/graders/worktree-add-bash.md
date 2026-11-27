---
type: tool_used
tool: Bash
input_match: 'worktree add(?:[^"\\\n]|\\.)*?\.worktrees/'
min: 1
---

Process grader over the full session. Assumes the tool input is serialized as JSON, so a quoted path appears with each inner quote escaped (`\"`); the match reads that escaped form. Pass: the agent runs a Bash command that creates a git worktree whose path is under .worktrees/, whether the path is bare, quoted, or built from a shell substitution such as `"$(pwd)/.worktrees/..."` (the isolated checkout exists before the work is handed on). Fail: no Bash command adds a worktree under .worktrees/, for example the agent creates its checkout elsewhere or does no checkout at all. This grader does not check order; the ordering against the Agent call is checked by graders/worktree-add-before-agent.md, not by this one.
