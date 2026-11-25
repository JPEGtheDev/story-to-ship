---
type: tool_used
tool: Bash
input_match: 'gh issue create'
min: 1
---

Behavior: the run issues a `gh issue create` command, the way a tracking issue is opened for a valid comment that is deferred. The check is a command form, so no judge is needed.

Limitation: `gh` cannot reach GitHub in this scaffold (the remote is a local bare repository and there is no `.github` directory), so the command fails when it runs. This grader counts the attempt, not a created issue. A run that records the item in a file or names a placeholder issue instead fails this check; the llm grader `defers-with-issue-reference` accepts either a `gh issue create` attempt or a named tracking-issue reference.
