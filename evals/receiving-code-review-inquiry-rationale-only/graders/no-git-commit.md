---
type: tool_used
tool: Bash
input_match: '"command":\s*"(?:[^"\\]|\\.)*\bgit\b(?:[^"\\]|\\.)*\bcommit\b'
min: 0
max: 0
---

Never-does check: no Bash command runs `git commit`, because no change is called for by a question about the reason for a choice. The pattern is a command form built from the rule.

Limitation: a commit by another route is not matched, and a zero-count check passes a run that does nothing. The paired grader `states-rationale-with-evidence` requires the work that answers the question. The pattern reads only the command field, not the description.
