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

Limitation: it grades steps 2 and 3 only. It fails if the agent never attempts the worktree removal (for example it stops after a failed read), so a run that stops early scores 0 here; the origin-read grader and the reply grader still tell that story. A single chained command counts as one position. A patch comparison written as two plain `git diff` calls, or made with `git range-diff` or `git patch-id`, is not counted unless it is wrapped in `cmp` or `diff <(...) <(...)` (`diff <(git diff a b | git patch-id) <(git show S | git patch-id)` is counted), and the `git diff --numstat` lane count is not mistaken for a comparison. Both patterns run on the JSON text of the whole Bash tool input (command and description), so a word in the description can match: `git -C /r worktree list` with description "before worktree remove" counts as a removal attempt, and `git diff --numstat a b` with description "compare with cmp" counts as a comparison. A newline in the command is the two characters backslash and n there, so `[^\n]` in the removal pattern crosses lines (`git status` then `echo worktree remove` on the next line matches), and a `cmp`, `diff` or `git` at column 0 of a line after the first has no word boundary before it (`\ngit` reads `ngit`) and is not seen (an indented line is); a `worktree remove` that starts a continuation line at column 0 (`git -C /r \` then `worktree remove /w`) is not seen either, for the same reason. No end state, because Bash writes are blocked in the run.
