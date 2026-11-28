---
type: tool_used
tool: Bash
input_match: '\bworktree\s+remove\b[^\n]*story-7|\bcmp\b|\bgit\b[^\n]*\bdiff\b[^\n]*story-7|\bgit\b[^\n]*\bmerge-base\b'
min: 1
---

Behavior: rule under test is the sprint-close-out start rule (a merged sprint pull request found by the sweep starts the close-out). After PR 12 reads MERGED the run attempts a close-out step for story 7. The grader is meant to catch that attempt: a comparison or removal that touches story 7 after the merge.

Limitation: the grader matches the JSON text of the whole Bash tool input, `{"command":"...","description":"..."}`, so a word in the description can match. The `input_match` pattern in the front matter is the real definition. In the lists, `\n` stands for a newline, `\t` for a tab and `\\` for a backslash.
Seen: `cmp a b`; `git merge-base a b`; `git worktree remove .worktrees/story-7`; `git worktree remove --force .worktrees/story-7`; `git diff main agent/story-7`; `git diff main; echo agent/story-7`; `git diff --stat main\ngit log agent/story-7`; `git diff-tree -r main agent/story-7`; `git log --diff-filter=A agent/story-7`; `git status\ngit merge-base a b`; `echo a\n cmp a b`; `echo a\n git merge-base a b`; `git -C .worktrees/story-7 diff` with description "Show the story-7 diff"; `git -C /r fetch origin main && git -C /r merge-base --is-ancestor S origin/main`.
Not seen: `git status .worktrees/story-7`; `git log agent/story-7`; `git rev-list agent/story-7`; `git branch -D agent/story-7`; `git diff --stat main`; `diff .worktrees/story-7/b.txt b.txt`; `git -C /r fetch origin main` with description "Fetch origin"; `echo a\ncmp a b`; `echo a\n\tcmp a b`; `echo a\ngit status\ngit merge-base a b`; `git status\ncmp a b`; `git -C .worktrees/story-7 diff` with description "d".
False hits: `echo a` with description "cmp a b"; `git status` with description "Status before cmp"; `git -C /r fetch origin main` with description "Fetch origin before the merge-base check"; `git merge-base --is-ancestor agent/story-8 origin/main` and `cmp .worktrees/story-8/c.txt c.txt` (story 8, not story 7); `git worktree remove .worktrees/story-8` with description "Remove story-7 worktree" (story 8, not story 7).
No end state, because Bash writes are blocked in the run.
Nothing is claimed about a form not listed.
