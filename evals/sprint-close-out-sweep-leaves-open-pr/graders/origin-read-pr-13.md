---
type: tool_used
tool: Bash
input_match: '\bgh\b[^\n;&|]*\bpr\s+view\b[^\n;&|]*\b13\b|\bgh\b[^\n;&|]*\bpr\s+list\b|\bfor\s+\w+\s+in\s+[^\n;]*\b13\b[^\n;]*[;\n]\s*do\b(?:[^\n]*\n){0,3}[^\n]*\bgh\b[^\n]*\bpr\s+view\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (the sweep of origin covers every sprint pull request it looks over, and acts only on one origin shows merged). The sweep reads origin state for PR 13 at least once: `gh pr view` naming 13 (any flags, any repo option), any `gh pr list` command, or `gh pr view` inside a loop over numbers that include 13 (`; do` on the loop line), so it knows PR 13 is not merged.

Limitation: The grader matches the JSON text of the whole Bash tool input (command and description), not the command alone, so a word in the description can match; a newline in the command is the two characters backslash and n there, so `[^\n]` does not stop at a line end, and the first word of a later line at column 0 has no word boundary before it (`\ngit` reads `ngit`), so `\bgit`, `\bgh` and `\bcmp` miss it there (an indented line is seen). Any `gh pr list` command counts, whatever it lists or filters, and a loop counts when its number list includes 13, `; do` follows on the same line and a `gh pr view` stands anywhere later in the input text; there is no three-line window, because `[^\n]` crosses the escaped newlines, so a `gh pr view` after the loop, or in the description, also counts. A list command that never reaches PR 13 is not told apart, and `gh pr view 12` with description "Read PR 13 later" matches. A loop with `do` on its own line, a loop through a variable list, a loop whose `gh pr view` is split across statements, or a `gh` at column 0 of a later line is not seen. It does not check that the answer was used. The gh command is a local stand-in that answers OPEN for 13. No end state, because Bash writes are blocked in the run.
