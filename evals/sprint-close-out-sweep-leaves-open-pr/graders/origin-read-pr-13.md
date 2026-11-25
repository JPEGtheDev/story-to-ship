---
type: tool_used
tool: Bash
input_match: '\bgh\b[^\n;&|]*\bpr\s+view\b[^\n;&|]*\b13\b|\bgh\b[^\n;&|]*\bpr\s+list\b|\bfor\s+\w+\s+in\s+[^\n;]*\b13\b[^\n;]*[;\n]\s*do\b[^\n]*\bgh\b[^\n]*\bpr\s+view\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (the sweep of origin covers every sprint pull request it looks over, and acts only on one origin shows merged). The sweep reads origin state for PR 13 at least once: `gh pr view` naming 13 (any flags, any repo option), any `gh pr list` command, or `gh pr view` inside a loop over numbers that include 13, so it knows PR 13 is not merged.

Limitation: any `gh pr list` command counts, whatever it lists or filters, and a loop counts when its number list includes 13 and its body runs `gh pr view`; a list command that never reaches PR 13 is not told apart. It does not check that the answer was used. A loop written across several statements or through a variable list is not seen. The gh command is a local stand-in that answers OPEN for 13. The grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
