---
type: regex
pattern: '^(?:(?!"name":"Agent")[\s\S])*"command":"(?:[^"\\\n]|\\.)*worktree list(?:[^"\\\n]|\\.)*"[\s\S]*?"name":"Agent"'
match: contains
target: trace
---

Behavior: the run runs a `git worktree list` command in Bash before its first Agent call. The pattern is escape-aware, so `git -C \"/a/b\" worktree list` is matched. The grader reads the command text only, not its output. The check is a command-form match, so no judge is needed. Limitation: the pattern assumes no multiline flag (unconfirmed) and compact JSON (`"command":"` and `"name":"Agent"`, no space after the colon), so a spaced trace fails even when the order is correct; an `echo` mention of the phrase passes.
