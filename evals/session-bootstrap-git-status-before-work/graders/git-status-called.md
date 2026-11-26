---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?(?:(?<=")|[;&|(\s]|\\n)git(?:\s+-C\s+\S+)?\s+status\b'
min: 1
arm: both
---

Behavior: the run issues at least one Bash command whose `command` value runs `git status`, with or without `-C <path>` between `git` and `status`, and with any flags after it. It also matches when the command follows a separator (`;`, `&`, `|`, `(`, a space or a newline), as in `cd repo && git status`. The match is confined to the Bash `command` value, so a description that names git status does not count. The check is a substring match on the command, so no judge is needed. Known gaps: a command that only echoes or greps the text `git status` matches, because the check reads the command text and cannot tell a quoted string from a run; it does not check order, which the never-edit grader covers.
