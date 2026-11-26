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

Limitation: it grades steps 1 and 2 only; steps 6 to 8 and the lane_sum count are ignored. It does not check that the comparison was correct. Both patterns run on the JSON text of the whole Bash tool input (command and description), so a word in the description can match: `echo hi` with description "gh pr view 12" counts as the read, and `git diff --numstat a b` with description "compare with cmp" counts as a comparison (plain `git diff --numstat a b` does not). The grader type is `tool_order`; that it fails when either command is never run, and that one chained command holds one position (so a read and a comparison in one command do not pass), are properties of that type and were not probed here. Only the forms below were probed; a form not listed is not claimed.

The read pattern needs `gh pr view 12` as adjacent words: `gh pr view 12`, `gh pr view 12 --json state,mergeCommit` and `gh pr view 12 -R o/r` count, and so does `cd /r && gh pr view 12`; `gh pr view --json state,mergeCommit 12`, `gh pr view -R o/r 12`, `gh -R o/r pr view 12` and `gh api repos/o/r/pulls/12` do not count, so such a read is not counted as the origin read unless the description supplies the words.

The comparison pattern counts `cmp` of any two files, and `diff <(...) <(...)` (`diff <(git diff a b | git patch-id) <(git show S | git patch-id)`). It does not count two plain `git diff` calls, `git range-diff`, `git patch-id`, the `git diff --numstat` lane count, or a plain `diff /tmp/a.patch /tmp/b.patch` of two saved patch files.

A newline in the command is the two characters backslash and n in the JSON text, and a tab is backslash and t, so no word boundary precedes a word at column 0 of a line after the first or right after a tab. A `gh pr view 12`, a `cmp` or a `diff <(a) <(b)` on such a line is not seen on its own (`R=/r` then `gh pr view 12` at column 0 or after a tab does not match, and the same for `cmp a b` and `diff <(a) <(b)`); the same line indented with a space is seen. Each pattern can still be supplied by the description or by another line that holds its own match. For `diff <(a) <(b)`, an earlier line holding `diff` also supplies it, because the `[^\n;&|]*` between `diff` and the first `<(` runs on past the backslash and n: `git diff a b` then `diff <(a) <(b)` matches, and `git diff a b;` then `diff <(a) <(b)` does not. No end state, because Bash writes are blocked in the run.
