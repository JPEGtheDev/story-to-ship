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

Limitation: it grades steps 2 and 3 only. The removal pattern reads the command text, not its result, so a removal attempt counts as written. Both patterns run on the JSON text of the whole Bash tool input (command and description), so a word in the description can match: `git -C /r worktree list` with description "before worktree remove" counts as a removal attempt, and `git diff --numstat a b` with description "compare with cmp" counts as a comparison. The grader type is `tool_order`; that a run that never attempts the removal scores 0 here (for example when it stops after a failed read), and that one chained command holds one position, are properties of that type and were not probed here. Only the forms below were probed; a form not listed is not claimed.

The comparison pattern counts `cmp` of any two files and `diff <(...) <(...)` (`diff <(git diff a b | git patch-id) <(git show S | git patch-id)`). It does not count two plain `git diff` calls, `git range-diff`, `git patch-id`, the `git diff --numstat` lane count, or a plain `diff /tmp/a.patch /tmp/b.patch`.

The removal pattern needs a `git` and, later in the same command text, a `worktree remove` with a boundary before `worktree`. It counts `git worktree remove /w`, `git -C /r worktree remove --force /w`, `git -C "/r" worktree remove /w` and `cd /r; git worktree remove /w`. It does not count `echo worktree remove x` with no `git` before it, `git -C /r worktree prune` or `rm -rf /r/.worktrees/story-7`. Because `[^\n]` crosses the backslash and n of a newline, an earlier `git` supplies the match for a later line: `git status` then `echo worktree remove x` matches, and so does `git status;` then `git worktree remove x`.

A newline in the command is the two characters backslash and n in the JSON text, and a tab is backslash and t, so no word boundary precedes a word at column 0 of a line after the first or right after a tab. A `cmp a b` or `diff <(a) <(b)` on such a line is not seen on its own (the same line indented with a space is seen). A `git` on such a line is not seen on its own (`echo a` then `git worktree remove x` at column 0, or after a tab, does not match; after a space it does). A `worktree remove` that starts a continuation line at column 0 or after a tab is not seen even after an earlier `git` (`git -C /r \` then `worktree remove /w`, and `git status;` then `worktree remove /w`), and one after a space is seen. For the comparison, an earlier line holding `diff` supplies a later `diff <(a) <(b)`, as in the origin-read grader: `git diff a b` then `diff <(a) <(b)` matches, and `git diff a b;` then `diff <(a) <(b)` does not. No end state, because Bash writes are blocked in the run.
