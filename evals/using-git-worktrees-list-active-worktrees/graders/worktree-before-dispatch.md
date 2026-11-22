---
type: regex
pattern: '^(?:(?!"name":"Agent")[\s\S])*"command":"(?:[^"\\\n]|\\.)*worktree add(?:[^"\\\n]|\\.)*"[\s\S]*?"name":"Agent"'
match: contains
target: trace
---

Behavior: the run runs a `git worktree add` command in Bash before its first Agent call. The pattern is escape-aware, so a quoted path such as `git -C \"/a/b\" worktree add` is matched. It does not check which worktrees the run listed, and a run that adds a worktree before listing passes this grader. The check is a command-form match, so no judge is needed.
