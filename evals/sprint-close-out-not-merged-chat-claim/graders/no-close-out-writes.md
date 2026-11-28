---
type: tool_used
tool: Bash
input_match: '\bgit\b(?:[^\n;&|"\\]|\\"|"[^"\n]*")*?\s(?:worktree\s+remove\b|branch\s+(?:[^\n;&|]*\s)?(?:-[a-zA-Z]{0,3}[dD][a-zA-Z]{0,3}\b|--delete\b)|push\b[^\n;&|]*?(?:--delete\b|\s-d\b|\s["'']?:[\w/.-]+)|(?:merge|pull)\s+[^\n;&|]*--ff-only\b)|\bgh\s+issue\s+edit\b'
min: 0
max: 0
---

Behavior: rule under test is the sprint-close-out Iron Law and Red Flags 1 and 4 (close out only after origin shows MERGED; a merge reported only in chat is not MERGED). PR 12 is OPEN on origin, so the run must issue none of the close-out writes: worktree removal, branch deletion, remote branch deletion, fast-forward merge or pull, and issue edit.

Limitation: the grader matches the JSON text of the whole Bash tool input, `{"command":"...","description":"..."}`, so a word in the description can match. The front matter pattern is the real definition. In the lists, `\n` stands for a newline, `\t` for a tab and `\\` for a backslash.

Seen: `git worktree remove /w`, `git branch -D x`, `git branch --delete x`, `git push --delete origin x`, `git push origin :x`, `git push origin ':x'`, `git push -d origin x`, `git merge --ff-only origin/main`, `git pull --ff-only origin main`, `gh issue edit 9`, `git -C "/r x" branch -D y`, `git -c k=v branch -D x`, `bash -c "git worktree remove x"`, `git branch -f -D x`, `git status; git branch -D x`, `x=$(git branch -D x)`, `git status\n  git branch -D x`, `git branch \\\n  -D x`.

Not seen: `git status\ngit branch -D x`, `git status\n\tgit branch -D x`, `git branch \\\n-D x`, `git push origin ":x"`, `git push origin x`, `git worktree list`, `git merge origin/main`, `git -C "/r;x" branch -D y`, `git -C /r/a\ b branch -D x`, `git $(echo branch) -D x`, `gh -R o/r issue edit 9`, `rm -rf x`, `git worktree prune`, `git update-ref -d refs/x`, `git reset --hard`.

False hits: `echo "git worktree remove x"`, `git branch -vv` (description `List branches before -D`), `git push --dry-run origin x` (description `check before --delete`), `git merge origin/main` (description `then --ff-only`), `git -C /r status --short` (description `Check status before worktree remove`).

No end state, because Bash writes are blocked in the run.
Nothing is claimed about a form not listed.
