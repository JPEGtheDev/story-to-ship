---
type: tool_used
tool: Bash
input_match: 'gh issue create'
min: 1
---

Behavior: the run issues a `gh issue create` command, the way a tracking issue is opened for a valid comment that is deferred. The check counts Bash calls whose input holds that text, so no judge is needed.

Limitation: no GitHub repository exists behind this scaffold (the remote is a local bare repository), so the command cannot create a real issue and fails or is rejected when it runs. This grader counts the attempt, not a created issue. A run that records the item in a file or names a placeholder issue instead fails this check; the llm grader `defers-with-issue-reference` reads only the final message and accepts a named tracking-issue reference in the text.
