---
type: tool_used
tool: Bash
input_match: '\bgh\b[^\n;&|]*\bpr\s+view\b[^\n;&|]*\b12\b'
min: 1
---

Behavior: rule under test is the sprint-close-out Iron Law and BEFORE PROCEEDING item 1 (a merge reported only in chat is not MERGED; origin is the record). The run must read pull request 12 on origin with `gh pr view` at least once.

Limitation: the grader matches the JSON text of the whole Bash tool input, `{"command":"...","description":"..."}`, so a word in the description can match. The front matter pattern is the real definition.

Seen: `gh pr view 12`, `gh pr view 12 --json state`, `gh pr view --json state 12`, `gh pr view -R o/r 12`, `gh -R o/r pr view 12`, `gh pr view --json state,mergeCommit 12`, `gh auth status\ngh pr view 12`, `R=/r\n  gh pr view 12`.

Not seen: `gh pr view 3; echo 12`, `gh pr view 3 | cat` (description `PR 12`), `gh api repos/o/r/pulls/12`, `gh pr view agent/story-7`, `R=/r\ngh pr view 12`, `R=/r\n\tgh pr view 12`, `gh auth status | cat\ngh pr view 12`, `gh pr view --jq '.state | ascii_downcase' 12`, `ls` (description `PR 12`).

False hits: `gh pr view 3\necho 12`, `gh pr view 3` (description `PR 12`), `ls` (description `gh pr view 12`).

No end state, because Bash writes are blocked in the run.
Nothing is claimed about a form not listed.
