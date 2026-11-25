---
type: tool_used
tool: Bash
input_match: 'worktree\s+add\b'
min: 1
---

Behavior: the run issues a Bash `git worktree add` command for the Todo 1 checkout. A run with no `git worktree add` command fails this grader. The pattern also matches a command that only mentions the phrase (an echo or a `--help`), and an add that failed because the path existed; this grader does not check the path, the base, whether the add succeeded, or the order relative to the removal or rename.
