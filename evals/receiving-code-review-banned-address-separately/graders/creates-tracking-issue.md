---
type: tool_used
tool: Bash
input_match: 'gh issue create'
min: 1
---

Behavior: the run issues a `gh issue create` command, the way a tracking issue is opened for a valid comment that is deferred. The check counts Bash calls whose input contains that command, so no judge is needed.

Limitation: `gh` cannot reach GitHub in this scaffold (the remote is a local bare repository and there is no `.github` directory), so the command fails when it runs. This grader counts the attempt, not a created issue. A run that names an issue without trying the command fails this check. The llm grader `states-issue-reference` reads the reply only: it accepts a named issue or a reply that reports a failed attempt and names the item, and it does not see the command.
