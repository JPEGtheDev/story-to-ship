---
type: tool_used
tool: Bash
input_match: '"command":\s*"(?:[^"\\]|\\.)*\bgit\b(?:[^"\\]|\\.)*\bcommit\b'
min: 1
---

Behavior: a Bash command runs `git commit`, so the fix is committed and not left in the working tree. The pattern is a command form built from the rule.

Limitation: it shows a commit command was issued, not that it succeeded or that it holds the fix. A commit made before the edit also passes; the order is not checked. The pattern reads only the command field, not the description.
