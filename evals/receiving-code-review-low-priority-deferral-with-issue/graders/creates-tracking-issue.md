---
type: tool_used
tool: Bash
input_match: 'gh issue create'
min: 1
---

Behavior: the agent tries to open a tracking issue for the valid comment it defers, so the deferred item is recorded where the team can find it.

Evaluation criteria: the check counts Bash calls whose input holds the text gh issue create and needs at least one. No judge is needed. The match is on the text, so an echo or a commit message that contains gh issue create also counts. A run that records the item in a file, names a placeholder issue, or opens the issue through gh api instead of gh issue create fails this check; the llm grader defers-with-issue-reference reads only the final message and accepts a named tracking-issue reference in the text.

Limitation: no GitHub repository exists behind this scaffold (the remote is a local bare repository), so no issue can be opened for the scaffold's own remote; a command that names another repository (for example `gh issue create -R owner/repo`) can open a real issue when gh is logged in. This grader counts the attempt, not a created issue, and the match is on the text, so an echo or a commit message that contains `gh issue create` also counts. A run that records the item in a file, names a placeholder issue, or opens the issue through `gh api` instead of `gh issue create` fails this check; the llm grader `defers-with-issue-reference` reads only the final message and accepts a named tracking-issue reference in the text.
