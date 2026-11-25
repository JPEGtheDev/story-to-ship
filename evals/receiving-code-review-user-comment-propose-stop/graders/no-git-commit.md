---
type: tool_used
tool: Bash
input_match: 'git\b[^\n]*\bcommit\b'
min: 0
max: 0
---

Never-does check: no Bash command runs `git commit`, because the fix is not committed in the turn that answers a user comment. The pattern is a command form built from the rule.

Limitation: a commit made by another route (a different git front end, an alias) is not matched, and a zero-count check passes a run that does nothing. The paired graders `checked-the-code` and `states-check-assessment-proposal` require the work the proposal rests on.
