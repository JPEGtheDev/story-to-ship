---
type: tool_used
tool: Bash
input_match: 'rev-list\s+--left-right|rev-list[^\n;&|]*--count[^\n;&|\\]*origin/main'
min: 1
---

Behavior: per the rule for a base other than the feature branch in the using-git-worktrees skill, that base requires a `rev-list` check against origin/main before `git worktree add`. The run must execute such a check through Bash (`git rev-list --left-right --count origin/main...<base>`, or a `rev-list --count` that names origin/main). The check is a command-form match, so no judge is needed. This grader does not check order: a `rev-list` that runs after `worktree add` also passes, so the case name's "before-add" is not graded. It proves only that a matching rev-list command ran; it does not prove that origin/main was compared or that the chosen base was used. The first alternative's class `[^\n;&|]*` does not exclude a backslash, so a JSON-serialized newline (`\n`) between `rev-list` and `--count` can let it match across a line (probe: `git rev-list HEAD\nwc --count origin/main` matches; the pattern was measured unchanged and is kept as is). A quoted `"origin/main"` in the serialized form is missed. The grader does not check that origin/main was fetched before the rev-list (the rule runs `git fetch origin main` first), and that is a limit of this grader. The prompt names no base, so the run picks its own; the rule's check `rev-list --left-right --count origin/main...<base>` compares that base with origin/main, and a base equal to origin/main prints 0 and 0; the case checks that the check runs, not that a stale base is found.
