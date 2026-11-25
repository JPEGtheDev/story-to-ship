---
type: tool_used
tool: Bash
input_match: 'git\b[^\n]*\bcommit\b'
min: 1
---

Behavior: a Bash command runs `git commit`, so the fix is committed. The pattern is a command form built from the rule.

Limitation: it shows a commit command was issued, not that it succeeded or holds the fix. The order against the edit is not checked.
