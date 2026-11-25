---
type: tool_used
tool: Bash
input_match: '\bworktree\s+remove\b[^\n]*story-7|\bcmp\b|\bgit\b[^\n]*\bdiff\b[^\n]*story-7|\bgit\b[^\n]*\bmerge-base\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (a merged sprint pull request found by the sweep starts the close-out). After PR 12 reads MERGED the run attempts a close-out step for story 7: a local check of story 7 (`cmp`, a git command with `diff` in it (`git diff`, `git diff-tree`, `git log --diff-filter=A`) that has story-7 later on the same line, or any `git merge-base` (step 1's ancestry check or step 2's base lookup)) or a `git worktree remove` naming story-7.

Limitation: the grader cannot tell a comparison of story 7 from one of story 8 when the command names no branch (a bare `cmp` or `git merge-base`); the sweep-leaves-open-pr case covers story-8 writes. A run passes only through a `git worktree remove` naming story-7, a `cmp`, a git command with `diff` in it and story-7 later on the same line (`diff-tree` and `--diff-filter` count) or any `git merge-base`. `git -C <story-7 path> diff` (story-7 before `diff`), a `git status`, `git log` or `git rev-list` without `diff` on story 7, a `git branch -D agent/story-7`, and a read of origin through `gh` alone pass nothing here. The grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
