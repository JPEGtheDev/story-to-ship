---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?worktree\s+add'
min: 1
---

Behavior: the run creates a checkout through a Bash `git worktree add` command, which is the setup the branch query in the other grader runs after. A run with no `git worktree add` command in a Bash command value fails this grader. The match is limited to the command value, so a description or other field that names the phrase does not count, and an earlier command in the same string (`cd <path> && git worktree add ...`) is allowed. The pattern still matches a command that only mentions the phrase (an echo or a `--help`), and a failed add; this grader does not check the path, the branch, or the order. The check is a command-form match, so no judge is needed.
