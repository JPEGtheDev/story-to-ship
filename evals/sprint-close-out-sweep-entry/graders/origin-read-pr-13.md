---
type: tool_used
tool: Bash
input_match: '\bgh\s+pr\s+view\s+13\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (the sweep of origin covers every sprint pull request it looks over). The sweep reads PR 13 on origin with `gh pr view 13` (any flags) at least once, so it knows PR 13 is not merged.

Limitation: `gh pr list` alone does not count. It does not check that the answer was used. The gh command is a local stand-in that answers OPEN for 13. The grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
