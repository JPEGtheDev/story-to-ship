---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?worktree\s+prune'
min: 1
---

Behavior: the run executes a `git worktree prune` command through Bash, which clears the registration of a worktree whose directory was deleted by hand. The check is a command-form match: it passes on any Bash command containing `worktree prune`, including an echo or a `--dry-run`, and it does not check the order relative to a failed add, the exit status, or whether the prune removed the stale registration. The pattern starts at the `command` value, so a description alone does not pass. No judge is needed.
