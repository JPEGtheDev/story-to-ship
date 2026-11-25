---
type: tool_used
tool: Bash
input_match: '"command":\s*"(?:[^"\\]|\\.)*\bgit\s+(?:(?:-C|-c)\s+\S+\s+|-\S+\s+)*commit\b'
min: 0
max: 0
---

Never-does check: no Bash command runs `git commit`, because the fix is not committed in the turn that answers a user comment. The pattern counts a Bash command field in which `git`, then any global options, then the subcommand `commit` appear in that order, so `git log` with the word commit later in the command does not match.

Limitation: a commit made by another route (a different git front end, an alias) is not matched, and a zero-count check passes a run that does nothing. The paired graders `checked-the-code` and `states-check-assessment-proposal` require the work the proposal rests on. The pattern reads only the command field, not the description.
