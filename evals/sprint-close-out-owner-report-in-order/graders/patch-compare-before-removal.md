---
type: tool_order
before:
  tool: Bash
  input_match: '\bcmp\b|\bdiff\b[^\n;&|]*<\([^\n]*<\('
after:
  tool: Bash
  input_match: '\bgit\b[^\n]*\bworktree\s+remove\b'
---

Behavior: rule under test is the sprint-close-out steps-in-order rule (Iron Law, BEFORE PROCEEDING item 2, rationalization 2: the patch comparison is not a formality). Step 2 compares the patches before step 3 removes the runner worktree. The first patch comparison must come before the first `git worktree remove` attempt.

Limitation: it grades steps 2 and 3 only. It fails if the agent never attempts the worktree removal (for example it stops after a failed read), so a run that stops early scores 0 here; the origin-read grader and the reply grader still tell that story. A single chained command counts as one position. A patch comparison written as two plain `git diff` calls, or made with `git range-diff` or `git patch-id`, is not counted, and the `git diff --numstat` lane count is not mistaken for a comparison. Bash writes are blocked in the run, so the first write fails whatever the agent does; the grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
