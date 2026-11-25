---
type: tool_order
before:
  tool: Bash
  input_match: '\bgh\s+pr\s+view\s+12\b'
after:
  tool: Bash
  input_match: '\bcmp\b|\bdiff\s+<?\(|\bgit\b[^\n]*\bdiff\b'
---

Behavior: rule under test is the sprint-close-out steps-in-order rule (Iron Law, BEFORE PROCEEDING item 2): step 1 reads origin with `gh pr view 12`, then step 2 compares the patch of the runner branch with the patch of the squash commit (`cmp` or `diff`, or a `git diff` of the two). The first origin read must come before the first patch comparison.

Limitation: it grades steps 1 and 2 only; steps 6 to 8 and the lane_sum count are ignored. It fails if either command is never run, and a single chained command counts as one position, so a read and a comparison in one command do not pass. It does not check the comparison was correct. Bash writes are blocked in the run, so the first write fails whatever the agent does; the grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
