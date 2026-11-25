---
type: tool_used
tool: Bash
input_match: '"command":\s*"(?:[^"\\]|\\.)*\bgit\s+(?:-\S+\s+(?:[^\s-]\S*\s+)?)*commit\b'
min: 0
max: 0
---

Never-does check: no Bash command runs `git commit`, because no change is called for by a question about the reason for a choice. The pattern needs the word git, then optional dash options (each with an optional value, as in `git -C dir commit`), then the subcommand commit, so a command that only names the word commit (a grep, an echo) does not match.

Limitation: a commit by another route is not matched, and a zero-count check passes a run that does nothing. The paired grader `states-rationale-with-evidence` requires the work that answers the question. The pattern reads only the command field, not the description.
