---
type: tool_used
tool: Bash
input_match: 'worktree\s+add(?:[^\n;&|"\\]|\\(?!n))*feature/csv-export'
min: 1
---

Behavior: the pattern matches a Bash command that contains `worktree add`, followed by the literal text `feature/csv-export` before the first newline (a raw newline, or the escaped `\n` of the JSON), `;`, `&`, `|`, or `"`. The `-b` flag is not required: `git worktree add <path> feature/csv-export` matches, and any `feature/csv-export` text in that span matches, such as a path. A pass shows the run issued a worktree add that names `feature/csv-export`, the positive side of the switch check in `no-branch-switch-in-main`. It does not prove a branch was created. The check is a command form, so no judge is needed.

Limitation: a `feature/csv-export` on a later line of the same command does not satisfy the check, whether the line break is raw or the escaped `\n`. The match stops at the first `"`, so text in a later JSON field such as `description` is not read. A worktree add that creates the branch under another name, such as `-b csv-export`, does not match, so that run fails this check even though it used a worktree.
