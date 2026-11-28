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

Limitation: The grader matches the JSON text of each Bash tool input, its command and description, in call order; the front matter patterns are the real definition. Seen: comparison `cmp a b`, `diff <(a) <(b)`, `git diff --numstat a b` with the description `compare with cmp`, `git diff a b\ndiff <(a) <(b)`, and `R=/r\n cmp a b`; removal `git worktree remove /w`, `git -C /r worktree remove --force /w`, `git -C "/r" worktree remove /w`, `cd /r; git worktree remove /w`, and `git status\necho worktree remove x`; order `cmp a b` then (a later call) `git worktree remove /w`. Not seen: comparison `diff /tmp/a.patch /tmp/b.patch`, `git diff a b`, `R=/r\ncmp a b`, `R=/r\n\tcmp a b`, and `git diff a b;\ndiff <(a) <(b)`; removal `echo worktree remove x`, `git -C /r worktree prune`, `rm -rf /r/.worktrees/story-7`, and `echo a\ngit worktree remove x`; order `git worktree remove /w` then (a later call) `cmp a b`, and `cmp a b && git worktree remove /w` in one call. No end state, because Bash writes are blocked in the run. Nothing is claimed about a form not listed.
