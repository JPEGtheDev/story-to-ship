---
type: regex
pattern: '^(?:(?!"name":"Agent")[\s\S])*"command":"(?:[^"\\\n]|\\.)*worktree add(?:[^"\\\n]|\\.)*"[\s\S]*?"name":"Agent"'
match: contains
target: trace
---

Behavior: the run runs a `git worktree add` command in Bash before its first Agent call. The pattern is escape-aware, so a quoted path such as `git -C \"/a/b\" worktree add` is matched. It does not check where the dispatch goes; the paired grader dispatch-names-worktree checks that the dispatch names a `.worktrees/` path. The check is a command-form match, so no judge is needed.
