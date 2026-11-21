---
type: tool_used
tool: Bash
input_match: 'worktree\s+add\b'
min: 1
---

Behavior: the run creates a git worktree through a Bash `git worktree add` command. This grader makes the first grader meaningful: a run that never creates a worktree cannot pass the base-check grader. The check is a command-form match, so no judge is needed.
