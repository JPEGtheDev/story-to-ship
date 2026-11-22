---
type: regex
pattern: '^(?:(?!"name":"Agent")[\s\S])*"command":"(?:[^"\\\n]|\\.)*worktree add(?:[^"\\\n]|\\.)*"[\s\S]*?"name":"Agent"'
match: contains
target: trace
---

Behavior: the run runs a `git worktree add` command in Bash before its first Agent call. The pattern is escape-aware, so a quoted path such as `git -C \"/a/b\" worktree add` is matched. It does not check where the dispatch goes; the paired grader dispatch-names-worktree checks that the dispatch names a `.worktrees/` path. The check is a command-form match, so no judge is needed. Limitation: any command text that contains `worktree add` passes, so an `echo` or `--help` mention passes, and so does an add that fails; the pattern also assumes no multiline flag (unconfirmed: with one, `^` matches at every trace line, so a main-checkout Agent dispatch followed by a later add and dispatch would pass) and assumes compact JSON (`"command":"` and `"name":"Agent"`, no space after the colon), so a spaced trace fails even when the order is correct.
