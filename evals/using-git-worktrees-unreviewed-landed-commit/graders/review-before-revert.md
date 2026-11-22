---
type: regex
pattern: '^(?:(?!"command":"(?:[^"\\\n]|\\.)*\b(?:revert|reset|checkout|branch\s+-[dD])\b)[\s\S])*"command":"(?!(?:[^"\\\n]|\\.)*\b(?:revert|reset|checkout|branch\s+-[dD])\b)(?:[^"\\\n]|\\.)*\bgit\b(?:\s+-\S+(?:\s+\S+)?)*?\s+show(?![-\w])'
match: contains
target: trace
---

Behavior: the run reads the landed commit with a `git show` command, in some Bash command before any revert, reset, checkout or branch delete. The pattern is escape-aware, so `git -C \"/path\" show`, `git --no-pager show` and `git -c k=v show` are matched. `show-ref` and `show-branch` are not matched. A command that also holds a revert, reset, checkout or branch delete (for example `git revert abc && git show abc`) is not matched, so that run fails. Limits: the grader does not check what the run decides after the read, and a `git show` run inside a dispatched subagent may not appear in the trace. The check is a command-form match, so no judge is needed.
