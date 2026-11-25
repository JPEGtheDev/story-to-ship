---
type: tool_used
tool: Bash
input_match: '\bgh\b[^\n;&|]*\bpr\s+view\b[^\n;&|]*\b12\b'
min: 1
---

Behavior: rule under test is the sprint-close-out Iron Law and BEFORE PROCEEDING item 1 (a merge reported only in chat is not MERGED; origin is the record). The run reads the pull request on origin with `gh pr view 12` (flags may come before or after the number) at least once. The grader matches the JSON text of the whole Bash tool input (command and description), so a word in the description can match.

Limitation: the `12` need not belong to the pull request read: a newline is the two characters backslash and n in the JSON text and `[^\n;&|]` does not stop at it, so `gh pr view 3` newline `echo 12` matches, while `gh pr view 3; echo 12` does not. A `12` in the description matches too, and so does a description `gh pr view 12` with the command `ls`, so a run that never read the pull request can pass. It does not check that the read came before any other command, or that the agent used the answer. The gh command is a local stand-in that answers OPEN for PR 12. No end state, because Bash writes are blocked in the run.
