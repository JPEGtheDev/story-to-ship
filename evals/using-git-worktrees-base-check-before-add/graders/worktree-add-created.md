---
type: tool_used
tool: Bash
input_match: 'worktree\s+add\b'
min: 1
---

Behavior: the run creates a git worktree through a Bash `git worktree add` command. A run that never runs `git worktree add` cannot pass this case, because the case also requires the worktree add. This grader alone does not enforce the order (check before add). The check is a command-form match, so no judge is needed.
