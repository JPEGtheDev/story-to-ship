---
type: tool_order
before:
  tool: Bash
  input_match: '\bgh\s+pr\s+view\s+12\b'
after:
  tool: Bash
  input_match: '\bcmp\b|\bdiff\b[^\n;&|]*<\([^\n]*<\('
---

Behavior: rule under test is the sprint-close-out steps-in-order rule (Iron Law, BEFORE PROCEEDING item 2): step 1 reads origin with `gh pr view 12`, then step 2 compares the patch of the runner branch with the patch of the squash commit (`cmp` or `diff` of the two patches). The first origin read must come before the first patch comparison.

Limitation: it grades steps 1 and 2 only; steps 6 to 8 and the lane_sum count are ignored. It fails if either command is never run, and a single chained command counts as one position, so a read and a comparison in one command do not pass. It does not check the comparison was correct. A patch comparison written as two plain `git diff` calls, or made with `git range-diff` or `git patch-id`, is not counted unless it is wrapped in `cmp` or `diff <(...) <(...)` (`diff <(git diff a b | git patch-id) <(git show S | git patch-id)` is counted), and the `git diff --numstat` lane count is not mistaken for a comparison. Both patterns run on the JSON text of the whole Bash tool input (command and description), so a word in the description can match: `echo hi` with description "gh pr view 12" counts as the read, and `git diff --numstat a b` with description "compare with cmp" counts as a comparison (plain `git diff --numstat a b` does not). A newline in the command is the two characters backslash and n there, so `[^\n]` in the `diff <(` pattern crosses lines, and a `gh` or `cmp` or `diff` at column 0 of a line after the first has no word boundary before it (`\ngh` reads `ngh`) and is not seen (an indented line is). No end state, because Bash writes are blocked in the run.
