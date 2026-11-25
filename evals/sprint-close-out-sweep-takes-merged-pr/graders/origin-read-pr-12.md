---
type: tool_used
tool: Bash
input_match: '\bgh\b[^\n;&|]*\bpr\s+view\b[^\n;&|]*\b12\b|\bgh\b[^\n;&|]*\bpr\s+list\b|\bfor\s+\w+\s+in\s+[^\n;]*\b12\b[^\n;]*[;\n]\s*do\b[^\n]*\bgh\b[^\n]*\bpr\s+view\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (description: the close-out starts when a sweep of origin finds a merged sprint pull request, as well as when the owner reports one; Iron Law: confirm the merge on origin). The sweep reads origin state for PR 12 at least once: `gh pr view` naming 12 (any flags, any repo option), any `gh pr list` command, or `gh pr view` inside a loop over numbers that include 12.

Limitation: any `gh pr list` command counts, whatever it lists or filters, and a loop counts when its number list includes 12 and its body runs `gh pr view`; a list command that never reaches PR 12 is not told apart. It does not check that the answer was used. A loop written across several statements or through a variable list is not seen. The gh command is a local stand-in that answers MERGED for 12. The grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
