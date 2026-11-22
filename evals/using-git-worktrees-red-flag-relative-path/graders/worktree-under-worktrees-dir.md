---
type: tool_used
tool: Bash
input_match: 'worktree\s+add(?:[^\n;&|\\]|\\"|\\\n|\\\\\\n)*\.worktrees/'
min: 1
---

Behavior: the run issues a `worktree add` whose path contains `.worktrees/`, the location form the rule fixes. Location form check only: the pattern is not tied to the repo root, so `/tmp/.worktrees/x` also passes. This is the positive side of the red-flag check in `graders/no-parent-relative-worktree.md`. A pass shows a worktree add was issued, not that it succeeded. The check is a command form, so no judge is needed.
