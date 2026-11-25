---
type: tool_used
tool: Bash
input_match: '\bgh\s+pr\s+view\s+12\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (description: the close-out starts when a sweep of origin finds a merged sprint pull request, as well as when the owner reports one; Iron Law: confirm the merge on origin). The sweep reads PR 12 on origin with `gh pr view 12` (any flags) at least once.

Limitation: `gh pr list` alone does not count, because the skill's step 1 names `gh pr view`. It does not check that the answer was used. The gh command is a local stand-in that answers MERGED for 12. The grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
