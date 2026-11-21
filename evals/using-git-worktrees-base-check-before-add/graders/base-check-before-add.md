---
type: tool_used
tool: Bash
input_match: 'rev-list\s+--left-right|rev-list[^\n;&|]*--count[^\n;&|\\]*origin/main'
min: 1
---

Behavior: per the rule for a base other than the feature branch in the using-git-worktrees skill, that base requires a `rev-list` check against origin/main before `git worktree add`. The run must execute such a check through Bash (`git rev-list --left-right --count origin/main...<base>`, or a `rev-list --count` that names origin/main). The check is a command-form match, so no judge is needed. This grader does not check order (check before `worktree add`), and it proves only that a matching rev-list command ran; it does not prove that origin/main was compared or that the chosen base was used. The grader does not check that origin/main was fetched before the rev-list (the rule runs `git fetch origin main` first), and that is a limit of this grader. The prompt sets the base to origin/main, so the rule's check `rev-list --left-right --count origin/main...<base>` compares origin/main with itself and always prints 0 and 0; the case checks that the check runs, not that a stale base is found.
