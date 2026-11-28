---
type: tool_used
tool: Bash
input_match: '\bgh\b[^\n;&|]*\bpr\s+view\b[^\n;&|]*\b13\b|\bgh\b[^\n;&|]*\bpr\s+list\b|\bfor\s+\w+\s+in\s+[^\n;]*\b13\b[^\n;]*[;\n]\s*do\b(?:[^\n]*\n){0,3}[^\n]*\bgh\b[^\n]*\bpr\s+view\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (a close-out starts when a sweep of origin finds a merged sprint pull request; BEFORE PROCEEDING item 1 checks the pull request with `gh pr view` to show MERGED on origin). The sweep must read origin state for PR 13 at least once.

Limitation: the grader matches the JSON text of the whole Bash tool input, `{"command":"...","description":"..."}`, so a word in the description can match. The front matter pattern is the real definition. In the lists, `\n` stands for a newline, `\t` for a tab and `\\` for a backslash.

Seen: `gh pr view 13`, `gh pr view 13 --json state`, `gh pr view --json state 13`, `gh -R o/r pr view 13`, `gh pr view -R o/r 13`, `gh pr view --json state,mergeCommit 13`, `gh pr list`, `gh pr list --search 99`, `for n in 12 13; do gh pr view $n --json state; done`, `for n in 12 13; do x=1; done\n gh pr view $n`, `for n in 12 13; do echo $n; done; gh pr view 12`, `ls\n  gh pr view 13`, `gh auth status\ngh pr view 13`, `gh pr view 12 --json state\n\tgh pr view 13`, `echo a\n for n in 12 13; do gh pr view $n; done`, `L="12 13"; for n in $L; do gh pr view $n\ndone` (description `Read 13`).

Not seen: `ls\ngh pr view 13`, `ls\n\tgh pr view 13`, `ls\ngh pr list`, `gh api repos/o/r/pulls/13`, `gh auth status; echo\ngh pr view 13`, `gh pr view 12`, `printf '12\n13\n' | while read n; do gh pr view "$n" --json state; done`, `for ((n=12; n<=13; n++)); do gh pr view $n --json state; done`, `for n in 12 13\ndo x=$n; gh pr view $x; done`, `echo a\nfor n in 12 13; do gh pr view $n; done`, `L="12 13"; for n in $L; do gh pr view $n\ndone`, `L="12 13"; for n in $L; do gh pr view $n; done` (description `Read 13`), `for n in 12 13\ndo\n  gh pr view $n\ndone`.

False hits: `echo a` (description `gh pr view 13`), `gh pr view 12` (description `Read PR 13 later`), `for n in 12 13\ndo\n  gh pr view $n\ndone` (description `Read 13`).

No end state, because Bash writes are blocked in the run.
Nothing is claimed about a form not listed.
