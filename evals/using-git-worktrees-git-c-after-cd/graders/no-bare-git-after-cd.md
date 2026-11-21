---
type: tool_used
tool: Bash
input_match: '(^|[;&|]\s*|\bthen\s+)\s*cd\s+[^\n;&|]+(&&|;)\s*git\s+(?!\s*-C\b)'
min: 0
max: 0
---

Red flag: a Bash call that runs `cd` and then a bare `git` command (no `-C`) in the same call, as in `cd <worktree> && git status`. The pattern matches only that same-call form, and a match fails the run.

Limitation of this check: a bare `git` in a later, separate Bash call after an earlier `cd` is not caught by this grader. Only same-call sequences are matched. The paired grader `checkout-read-with-git-c` requires the checkout to be read with `git -C`, which a pass must show.
