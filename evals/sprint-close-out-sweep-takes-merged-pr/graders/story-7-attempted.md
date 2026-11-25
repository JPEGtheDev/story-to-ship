---
type: tool_used
tool: Bash
input_match: '\bworktree\s+remove\b[^\n]*story-7|\bcmp\b|\bgit\b[^\n]*\bdiff\b[^\n]*story-7|\bgit\b[^\n]*\bmerge-base\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (a merged sprint pull request found by the sweep starts the close-out). After PR 12 reads MERGED the run attempts a close-out step for story 7: a local check of story 7 (`cmp`, a `git diff` naming story-7, or a `git merge-base`, which is the merge-ancestry close-out check) or a `git worktree remove` naming story-7.

Limitation: the grader cannot tell a comparison of story 7 from one of story 8 when the command names no branch (a bare `cmp` or `git merge-base`); the sweep-leaves-open-pr case covers story-8 writes. A run that checks story 7 with a local read (`git merge-base --is-ancestor`, `cmp`, `git diff` naming story-7) passes; only a run that reads origin through `gh` and reports, with no local git command on story 7, passes nothing here. The first write fails in the run. The grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
