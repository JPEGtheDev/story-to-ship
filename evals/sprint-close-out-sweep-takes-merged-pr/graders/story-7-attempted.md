---
type: tool_used
tool: Bash
input_match: '\bworktree\s+remove\b[^\n]*story-7|\bcmp\b|\bgit\b[^\n]*\bdiff\b[^\n]*story-7|\bgit\b[^\n]*\bmerge-base\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (a merged sprint pull request found by the sweep starts the close-out). After PR 12 reads MERGED the run attempts a close-out step for story 7. The pattern has four parts: `worktree remove` followed later in the input text by story-7, any `cmp`, `git` followed later in the input text by `diff` followed later by story-7 (`git diff main agent/story-7`, `git diff-tree -r main agent/story-7`, `git log --diff-filter=A agent/story-7`), and any `git` followed later by `merge-base`.

Limitation: the grader matches the JSON text of the whole Bash tool input (command and description), not the command alone. In that text a newline in the command is the two characters backslash and n and a tab is backslash and t, so `[^\n]` does not stop at a line end, and a word at column 0 of a later line has no word boundary before it (`\ncmp` reads `ncmp`). Only the forms below were run against the real pattern; forms not listed are not claimed.

Match (probed):
- `cmp a b`; `git merge-base a b`; `git merge-base --is-ancestor agent/story-8 origin/main`; `cmp .worktrees/story-8/c.txt c.txt`; `git worktree remove .worktrees/story-7` and the same with `--force`.
- A `git diff`-type command with story-7 after it: `git diff main agent/story-7`, `git diff main; echo agent/story-7`, `git diff --stat main` then on the next line `git log agent/story-7`.
- Line 2 of a command whose line 1 is `echo a`: ` cmp a b` and ` git merge-base a b` (after a space) match; the same after a tab or at column 0 do not.
- An earlier line that starts with a seen `git` carries the match across the line end: `git status`, newline, `git merge-base a b` matches at column 0 and after a tab; `git status; echo x` or `git status && echo x` before it works the same. `echo a`, `git status`, `git merge-base a b`, each at column 0, does not match, and with ` git status` indented by a space it does. `git status`, newline, `git diff main agent/story-7` matches; a `cmp` at column 0 of a later line does not match even after an earlier `git status` line.

Description: a word in the description can match. `echo a` with description "cmp a b" or "git merge-base" matches; a bare "merge-base" in the description does not match with command `echo a` and matches with command `git status`. `git -C .worktrees/story-7 diff` matches with description "Show the story-7 diff" and with "Diff before merge-base" and does not match with description "d". `gh pr view 12` with description "Read PR 12 state before cmp" matches and a plain `gh pr view 12` does not. `git branch -D agent/story-7` and `git log agent/story-7` with description "Check the merge-base" match; `git status` with description "Status before cmp" matches.

Does not match (probed): `git status .worktrees/story-7`, `git log agent/story-7`, `git rev-list agent/story-7` and `git branch -D agent/story-7` with a generic description; `git diff --stat main` alone; `diff .worktrees/story-7/b.txt b.txt` with no `git` anywhere in the input (with a generic description or "Compare story 7"); a lone `git -C /r fetch origin main` with description "Fetch origin" (a run that stops at a failed step-1 fetch fails min 1 although the close-out started).

Fetch forms that match: `git -C /r fetch origin main && git -C /r merge-base --is-ancestor S origin/main`, and a lone `git -C /r fetch origin main` with description "Fetch origin before the merge-base check".

Known gaps: the grader cannot tell a comparison of story 7 from one of story 8: a bare `cmp`, a bare `git merge-base`, `git merge-base --is-ancestor agent/story-8 origin/main` and `cmp .worktrees/story-8/c.txt c.txt` match, and `git worktree remove .worktrees/story-8` with story-7 in the description or on a later line (`echo story-7`) matches too; the sweep-leaves-open-pr case covers story-8 writes. It does not check order or that any PR 12 read happened: a bare `cmp a b` with no `gh` call passes it, and origin-read-pr-12 is the grader that covers the read. No end state, because Bash writes are blocked in the run.
