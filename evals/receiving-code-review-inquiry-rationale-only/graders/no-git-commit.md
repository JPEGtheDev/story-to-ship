---
type: tool_used
tool: Bash
input_match: 'git\b[^\n]*\bcommit\b'
min: 0
max: 0
---

Never-does check: no Bash command runs `git commit`, because no change is called for by a question about the reason for a choice. The pattern is a command form built from the rule.

Limitation: a commit by another route is not matched, and a zero-count check passes a run that does nothing. The paired graders `read-the-evidence` and `states-rationale-with-evidence` require the work that answers the question.
