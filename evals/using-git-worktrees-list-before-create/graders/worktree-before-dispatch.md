---
type: regex
pattern: '^(?:(?!"name":"Agent")[\s\S])*"command":"[^"\n]*worktree add[\s\S]*?"name":"Agent"'
match: contains
target: trace
---
