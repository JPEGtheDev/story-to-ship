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

Limitation: The grader matches the JSON text of each Bash tool input, its command and description, in call order; the front matter patterns are the real definition. Seen: read `gh pr view 12`, `gh pr view 12 --json state,mergeCommit`, `gh pr view 12 -R o/r`, `cd /r && gh pr view 12`, `R=/r\n gh pr view 12`, and `echo hi` with the description `gh pr view 12`; comparison `cmp /tmp/a.patch /tmp/b.patch`, `diff <(git diff a b | git patch-id) <(git show S | git patch-id)`, `git diff --numstat a b` with the description `compare with cmp`, `git diff a b\ndiff <(a) <(b)`, `git diff a b; diff <(a) <(b)`, and `R=/r\n cmp a b`; order `gh pr view 12` then (a later call) `cmp a b`. Not seen: read `gh pr view --json state,mergeCommit 12`, `gh pr view -R o/r 12`, `gh -R o/r pr view 12`, `gh api repos/o/r/pulls/12`, `R=/r\ngh pr view 12`, and `R=/r\n\tgh pr view 12`; comparison `diff /tmp/a.patch /tmp/b.patch`, `git diff a b`, `git range-diff a b`, `git patch-id`, `git diff a b;\ndiff <(a) <(b)`, and `R=/r\ncmp a b`; order `cmp a b` then (a later call) `gh pr view 12`, and `gh pr view 12 && cmp a b` in one call. No end state, because Bash writes are blocked in the run. Nothing is claimed about a form not listed.
