---
type: regex
pattern: '^(?:(?!"name":"Agent")[\s\S])*"command":"(?:(?:[^"\\\n]|\\.)*?\.worktrees/(?:[^"\\\n]|\\.)*?--show-toplevel|(?:[^"\\\n]|\\.)*?--show-toplevel(?:[^"\\\n]|\\.)*?\.worktrees/)(?:[^"\\\n]|\\.)*"[\s\S]*?"name":"Agent"'
match: contains
target: trace
---
