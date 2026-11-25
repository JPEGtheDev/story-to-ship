---
type: tool_used
tool: Bash
input_match: 'git\b[^\n]*\bcommit\b'
min: 1
---

Behavior: the run issues a `git commit`, the committed change a fix for a correct comment needs. This is the positive side of the approval check in `graders/not-just-thanks.md`. The check is a command form, so no judge is needed.

Limitation: a pattern match on the command text. A commit that fails, or a commit that holds only one of the two fixes, still passes. The llm grader `answers-both-items` judges the posted text.
