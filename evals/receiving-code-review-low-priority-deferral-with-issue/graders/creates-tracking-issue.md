---
type: tool_used
tool: Bash
input_match: 'gh issue create'
min: 1
---

Behavior: the run issues a `gh issue create` command, the way a tracking issue is opened for a valid comment that is deferred. The check counts Bash calls whose input holds that text, so no judge is needed.

Limitation: no GitHub repository exists behind this scaffold (the remote is a local bare repository), so no issue can be opened for the scaffold's own remote; a command that names another repository (for example `gh issue create -R owner/repo`) can open a real issue when gh is logged in. This grader counts the attempt, not a created issue, and the match is on the text, so an echo or a commit message that contains `gh issue create` also counts. A run that records the item in a file, names a placeholder issue, or opens the issue through `gh api` instead of `gh issue create` fails this check; the llm grader `defers-with-issue-reference` reads only the final message and accepts a named tracking-issue reference in the text.
