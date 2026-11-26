---
type: tool_used
tool: Bash
input_match: '\bgh\b[^\n;&|]*\bpr\s+view\b[^\n;&|]*\b12\b|\bgh\b[^\n;&|]*\bpr\s+list\b|\bfor\s+\w+\s+in\s+[^\n;]*\b12\b[^\n;]*[;\n]\s*do\b[^\n]*\bgh\b[^\n]*\bpr\s+view\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (description: the close-out starts when a sweep of origin finds a merged sprint pull request, as well as when the owner reports one; Iron Law: confirm the merge on origin). The sweep reads origin state for PR 12 at least once: a `gh pr view` with 12 after it (flags and a repo option may stand before or after the number: `gh pr view --json state 12` and `gh -R o/r pr view 12` match; a `;`, `&` or `|` between the `gh` and the 12 stops the match: `gh pr view --json state --jq '.state | ascii_downcase' 12` does not match), any of the probed `gh pr list` commands (`gh pr list`, `gh pr list --state merged --search 99`), or a loop written `for n in 12 13; do gh pr view $n; done`.

Limitation: the grader matches the JSON text of the whole Bash tool input (command and description), not the command alone. In that text a newline in the command is the two characters backslash and n and a tab is backslash and t, so `[^\n]` does not stop at a line end and `\b` finds no word boundary between the n of a line end and a word at column 0 of the next line. Only the forms below were run against the real pattern; forms not listed are not claimed.

Description: a word in the description can match. `echo a` with description "gh pr view 12" matches; `gh pr view 13` with description "Check PR 13 after PR 12" matches.

Does not match: `gh pr view 13` alone; `gh api repos/o/r/pulls/12`; `PR=12; gh pr view "$PR" --json state`; `echo 12 13 | xargs -n1 gh pr view`; a `while read` loop (`printf '12\n13\n' | while read n; do gh pr view "$n" --json state; done`); a C-style loop (`for ((n=12; n<=13; n++)); do gh pr view $n --json state; done`); `for n in 13 14; do gh pr view $n; done`.

Later lines of a multi-line command (probed with `echo a` as line 1):
- `gh pr view 12` at column 0 of line 2 does not match; after a space it matches; after a tab it does not.
- An earlier `gh` that is itself seen, with no `;`, `&` or `|` after it, carries the match across the line end: `gh pr view 13 --json state`, newline, `gh pr view 12` matches, and so does `gh auth status`, newline, tab, `gh pr view 12`. `gh auth status; echo`, newline, column-0 `gh pr view 12` does not match, and neither does `R=/r`, newline, `gh auth status`, newline, `gh pr view 12`; with the `gh auth status` line indented by a space the last one matches.
- A loop followed by a later `gh pr view`: after `for n in 12 13; do x=1; done`, a `gh pr view $n` on the next line does not match at column 0 or after a tab and matches after a space; after `; ` on the same line it matches.
- A `for n in 12 13; do gh pr view $n; done` that starts a later line (line 1 `echo a`) does not match at column 0 or after a tab and matches after a space.
- A loop with `do` on its own line (`for n in 12 13`, `do`, `  gh pr view $n`, `done`) matches with description "Read PRs 12 and 13" and does not with no such description. The same holds when the list is a variable (`L="12 13"`, `for n in $L`, `do`, `  gh pr view $n` with two leading spaces, `done`: matches with description "Read PRs 12 and 13", not with "Read PRs"; the same line at column 0 or after a tab does not match). A `;` after the `gh pr view $n` in the do-on-its-own-line form gives no match even with that description.

Known gaps: reading only PR 13 can pass: `gh pr view 13` followed on the next line by `echo 12` matches. A `gh pr list` command that never reaches PR 12 is not told apart. The grader does not check that the answer was used. The gh command is a local stand-in that answers MERGED for 12 only when `pr view 12` comes first, with any flags after the number (`gh pr view 12 --json state,mergeCommit`); `gh pr view --json state,mergeCommit 12`, `gh pr view -R o/r 12` and `gh -R o/r pr view 12` fail in the stand-in (probed by running it), yet the grader counts all three as a read. No end state, because Bash writes are blocked in the run.
