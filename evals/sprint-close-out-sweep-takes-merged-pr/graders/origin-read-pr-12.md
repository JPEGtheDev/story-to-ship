---
type: tool_used
tool: Bash
input_match: '\bgh\b[^\n;&|]*\bpr\s+view\b[^\n;&|]*\b12\b|\bgh\b[^\n;&|]*\bpr\s+list\b|\bfor\s+\w+\s+in\s+[^\n;]*\b12\b[^\n;]*[;\n]\s*do\b[^\n]*\bgh\b[^\n]*\bpr\s+view\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (description: the close-out starts when a sweep of origin finds a merged sprint pull request, as well as when the owner reports one; Iron Law: confirm the merge on origin). The sweep must read origin state for PR 12 at least once. The grader is meant to catch a sweep that does not read PR 12.

Limitation: the grader matches the JSON text of the whole Bash tool input, `{"command":"...","description":"..."}`, so a word in the description can match. The `input_match` pattern in the front matter is the real definition. In the lists, `\n` stands for a newline, `\t` for a tab and `\\` for a backslash.
Seen: `gh pr view 12`; `gh pr view --json state 12`; `gh -R o/r pr view 12`; `gh pr view 12 --json state,mergeCommit`; `gh pr list`; `for n in 12 13; do gh pr view $n; done`; `gh pr view 13 --json state\ngh pr view 12`; `echo a\n gh pr view 12`; `gh auth status\n\tgh pr view 12`; `echo a\n for n in 12 13; do gh pr view $n; done`; `for n in 12 13; do x=1; done; gh pr view $n`; `echo a` with description "gh pr view 12".
Not seen: `gh pr view 13`; `gh api repos/o/r/pulls/12`; `PR=12; gh pr view "$PR" --json state`; `echo 12 13 | xargs -n1 gh pr view`; `for ((n=12; n<=13; n++)); do gh pr view $n --json state; done`; `for n in 13 14; do gh pr view $n; done`; `gh pr view --json state --jq '.state | ascii_downcase' 12`; `echo a\ngh pr view 12`; `echo a\n\tgh pr view 12`; `gh auth status; echo\ngh pr view 12`; `for n in 12 13; do x=1; done\ngh pr view $n`; `echo a\nfor n in 12 13; do gh pr view $n; done`; `for n in 12 13\ndo\n  gh pr view $n;\ndone` with description "Read PRs 12 and 13".
False hits: `gh pr view 13\necho 12` (reads PR 13 only); `gh pr list --state merged --search 99` (a pr list that does not reach PR 12); `gh pr view 13` with description "Check PR 13 after PR 12".
No end state, because Bash writes are blocked in the run.
Nothing is claimed about a form not listed.
