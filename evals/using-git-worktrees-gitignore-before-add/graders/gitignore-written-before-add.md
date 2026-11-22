---
type: regex
pattern: '^(?:(?!"command":"(?:[^"\\\n]|\\.)*worktree add)[\s\S])*"command":"(?:[^"\\\n]|\\.)*\.worktrees(?:[^"\\\n]|\\.)*\.gitignore(?:[^"\\\n]|\\.)*"[\s\S]*?"command":"(?:[^"\\\n]|\\.)*worktree add'
match: contains
target: trace
---

Behavior: the run writes `.worktrees` into `.gitignore` through a Bash command before its first `git worktree add` command. The pattern matches a write or edit that names both `.worktrees` and `.gitignore` in one command, followed by a worktree add. It does not check the exit status of any check, so a run that checks, ignores the result, and then writes the entry passes. A run that never writes the entry, or adds the worktree first, fails. Limits: an edit made with a tool other than Bash is not matched (the case allows only Bash for this step), and a command that writes the entry to another file is not matched. The check is a command-form match, so no judge is needed.
