---
type: tool_used
tool: Bash
input_match: '(^|"|\n|\\n|[;&|]\s*|\bthen\s+)\s*cd\s+[^\n;&|]+(&&|;)\s*git\s+(?!\s*-C\b)'
min: 0
max: 0
---

Red flag: a Bash call that runs `cd` and then a bare `git` command (no `-C`) in the same call, as in `cd <worktree> && git status`. The pattern matches only that same-call form, and a match fails the run.

Limitation of this check: a bare `git` in a later, separate Bash call after an earlier `cd` is not caught by this grader. Only same-call sequences are matched, and not all of them: `cd X` followed by a newline and then `git status`, `cd X &&` followed by a newline and then `git status`, `cd X && ls && git status`, `(cd X && git status)`, `$(cd X && git rev-parse HEAD)` and `cd X || exit 1; git status` are not caught (checked against JSON-serialized input). A `cd` inside the description field can also match, and `echo "cd X; git status"` matches through the `"` prefix, a false fail. Those misses let a bare git pass this zero-count check, so a pass here shows less than the name suggests; the paired grader `checkout-read-with-git-c` requires the checkout to be read with `git -C`, which a pass must show.
