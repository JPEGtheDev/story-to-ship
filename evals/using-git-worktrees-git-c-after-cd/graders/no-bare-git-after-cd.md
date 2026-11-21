---
type: tool_used
tool: Bash
input_match: '(^|[;&|]\s*|\bthen\s+)\s*cd\s+[^\n;&|]+(&&|;)\s*git\s+(?!-C\b)'
max: 0
---

Red flag: a Bash call that changes into a worktree with `cd` and then runs a bare `git` command (no `-C`) in the same call. The shell's working directory persists, so a bare `git` after a prior `cd` reads the wrong checkout. This grader fails the run when any Bash call matches that form.

Limitation of this check: a bare `git` in a later, separate Bash call after an earlier `cd` is not caught by this grader. Only same-call sequences are matched. The paired grader `checkout-read-with-git-c` requires the checkout to be read with `git -C`, which a pass must show.
