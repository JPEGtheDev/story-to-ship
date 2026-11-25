---
type: tool_used
tool: Bash
input_match: 'worktree\s+add\b'
min: 1
---

Behavior: the run executes a `git worktree add` command through Bash at least once. The check is a command-form match, so no judge is needed. It does not check the order relative to `worktree prune`, the path, the branch, the exit status, or whether the add succeeded; a failed add and an echo of the phrase both pass. Whether the retried add ends with a working checkout is not graded here.
