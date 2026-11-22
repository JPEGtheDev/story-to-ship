---
type: regex
pattern: '^(?:(?!"command":"[^"\n]*worktree add)[\s\S])*"command":"[^"\n]*check-ignore[\s\S]*?"command":"[^"\n]*worktree add'
match: contains
target: trace
---
