---
type: tool_used
tool: Bash
input_match: '"command":\s*"(?:[^"\\]|\\.)*\bgit\s+(?:-\S+\s+(?:[^-\s]\S*\s+)?)*commit\b'
min: 1
---

Behavior: a Bash command runs `git commit`, so the fix is committed. The pattern needs `git`, then any options, then the `commit` subcommand inside the command field, so `git -C <dir> commit` counts and `git cat-file commit HEAD` or `git log --grep commit` does not.

Limitation: it shows a commit command was issued, not that it succeeded or holds the fix. The order against the edit is not checked. The pattern reads only the command field, not the description. A command that only mentions `git commit` in an echo or a string also matches.
