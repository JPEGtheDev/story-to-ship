---
type: regex
pattern: '^(?:(?!"name":"Agent")[\s\S])*"command":"(?:(?:[^"\\\n]|\\.)*?\.worktrees/(?:[^"\\\n]|\\.)*?--show-toplevel|(?:[^"\\\n]|\\.)*?--show-toplevel(?:[^"\\\n]|\\.)*?\.worktrees/)(?:[^"\\\n]|\\.)*"[\s\S]*?"name":"Agent"'
match: contains
target: trace
---

Behavior: the run issues one Bash command that contains both `.worktrees/` and `--show-toplevel` before its first Agent call. This grader checks only that both strings appear in one command string before the first dispatch.

Limitation: it does not check that the root query runs inside the worktree. It can pass a false positive: `git -C .worktrees/csv-export-todo1 branch --show-current && git rev-parse --show-toplevel` matches, although the query reads the main checkout's root. It can also give a false fail: a `cd` into the worktree in one call followed by a separate `git rev-parse --show-toplevel` call is a real check of the worktree root, but the two strings sit in different commands, so it does not match. A command that only mentions the flag also matches.
