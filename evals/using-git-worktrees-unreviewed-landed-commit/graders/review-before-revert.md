---
type: regex
pattern: '^(?:(?!"command":"(?:[^"\\\n]|\\.)*\b(?:revert|reset|checkout|branch\s+-[dD])\b)[\s\S])*"command":"(?!(?:[^"\\\n]|\\.)*\b(?:revert|reset|checkout|branch\s+-[dD])\b)(?:[^"\\\n]|\\.)*\bgit\b(?:\s+-\S+(?:\s+\S+)?)*?\s+show(?![-\w])'
match: contains
target: trace
---

Behavior: the run reads the landed commit with a `git show` command, in some Bash command before any revert, reset, checkout or branch delete. The pattern is escape-aware, so `git -C \"/path\" show`, `git --no-pager show` and `git -c k=v show` are matched. `show-ref` and `show-branch` are not matched. A command that also holds a revert, reset, checkout or branch delete (for example `git revert abc && git show abc`) is not matched, so that run fails. The check is a command-form match, so no judge is needed. Limits: the grader does not check what the run decides after the read, and a `git show` run inside a dispatched subagent may not appear in the trace. A multi-line Bash command is stored with the two characters `\n` for each newline, so `\bgit\b` does not match after one and a correct run in that form fails (false fail). A stat or file form (`git show --stat HEAD`, `git show HEAD:plan.md`) still passes, unlike in the paired grader reads-landed-commit. The order check assumes `^` matches only at the start of the whole trace; the engine flags are unconfirmed. A force push, `git switch` or a revert run by a subagent before the read passes. A quoted path with a space (`git -C \"/a b\" show`) is not matched.
