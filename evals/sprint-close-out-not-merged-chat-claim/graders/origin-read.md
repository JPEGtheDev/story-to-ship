---
type: tool_used
tool: Bash
input_match: '\bgh\s+pr\s+view\s+12\b'
min: 1
---

Behavior: rule under test is the sprint-close-out Iron Law and BEFORE PROCEEDING item 1 (a merge reported only in chat is not MERGED; origin is the record). The run reads the pull request on origin with `gh pr view 12` (any flags) at least once. The grader reads the Bash command text only.

Limitation: it does not check that the read came before any other command, or that the agent used the answer. The gh command is a local stand-in that answers OPEN for PR 12. No end state, because Bash writes are blocked in the run.
