---
type: tool_used
tool: Bash
input_match: 'gh issue create'
min: 1
---

Behavior: the agent tries to open a tracking issue for the valid comment it defers, rather than deferring it with no issue.

Evaluation criteria: the check matches a Bash call whose input contains the gh issue create command, the way a tracking issue is opened for a valid comment that is deferred, and needs at least one such call, so no judge is needed.

Limitation: no GitHub repository exists behind this scaffold (the remote is a local bare repository and there is no `.github` directory), so no issue can be opened for the scaffold's own remote; a command that names another repository (for example `gh issue create -R owner/repo`) can open a real issue when gh is logged in. This grader counts the attempt, not a created issue, and the match is on the text, so an echo or a commit message that contains `gh issue create` also counts. A run that records the item in a file, names a placeholder issue, or opens the issue through `gh api` instead of `gh issue create` fails this check, and a run that names an issue without trying the command fails it too. The llm grader `states-issue-reference` reads the reply only: it accepts a named issue or a reply that reports a failed attempt and names the item, and it does not see the command.
