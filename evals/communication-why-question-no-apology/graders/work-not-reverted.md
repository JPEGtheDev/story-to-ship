---
type: regex
pattern: git revert|git reset|git checkout --|"name":"Edit"
match: not_contains
target: trace
---

Behavior: outcome grader. The user only asked why, so the run leaves the files as they are: no `git revert`, no `git reset`, no `git checkout --`, and no Edit tool call. Any of these anywhere in the trace fails. Limitation: the `"name":"Edit"` form assumes compact tool-call JSON with no space after the colon, the same assumption evals/using-git-worktrees-gitignore-before-add/graders/ makes; the real trace shape is unconfirmed. A change made through Bash (for example `sed -i` or a redirect) is not matched. The pattern is kept simple on purpose.
