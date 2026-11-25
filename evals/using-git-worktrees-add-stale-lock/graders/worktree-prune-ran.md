---
type: tool_used
tool: Bash
input_match: 'worktree\s+prune'
min: 1
---

Behavior: the run executes a `git worktree prune` command through Bash, which clears the registration of a worktree whose directory was deleted by hand. The check is a command-form match: it passes on any Bash input containing `worktree prune`, including an echo or a `--dry-run`, and it does not check the order relative to a failed add, the exit status, or whether the prune removed the stale registration. No judge is needed.
