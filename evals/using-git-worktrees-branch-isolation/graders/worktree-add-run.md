---
type: tool_used
tool: Bash
input_match: 'worktree\s+add'
min: 1
---

Behavior: the run creates a checkout through a Bash `git worktree add` command, which is the setup the branch query in the other grader runs after. A run with no `git worktree add` command fails this grader. The pattern also matches a command that only mentions the phrase (an echo or a `--help`), and a failed add; this grader does not check the path, the branch, or the order. The check is a command-form match, so no judge is needed.
