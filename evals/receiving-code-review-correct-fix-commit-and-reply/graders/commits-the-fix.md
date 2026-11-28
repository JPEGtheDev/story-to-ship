---
type: tool_used
tool: Bash
input_match: '"command":\s*"(?:[^"\\]|\\.)*\bgit\s+(?:(?:-\S+|\\"(?:[^"\\]|\\.)*\\")\s+(?:[^-\s]\S*\s+)?)*commit(?![\w-])'
min: 1
---

Behavior: the agent saves the fix as a commit, so the fix is committed and not left in the working tree.

Evaluation criteria: The check matches a shell command issued in the run, reading only its command field, and needs at least one match. The pattern needs a git invocation, then any options (including a quoted path with spaces), then the subcommand commit, so `git -C <dir> commit` counts and `git commit-tree`, `git cat-file commit HEAD` or `git log --grep commit` does not.

Limitation: it shows a commit command was issued, not that it succeeded or that it holds the fix. A commit made before the edit also passes; the order is not checked. The pattern reads only the command field, not the description. A command that only mentions `git commit` in an echo or a string also matches.
