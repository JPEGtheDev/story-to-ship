---
type: tool_used
tool: Bash
input_match: '\bgit\b(?:[^\n;&|"\\]|\\"|"[^"\n]*")*?\s(?:worktree\s+remove\b|branch\s+(?:[^\n;&|]*\s)?(?:-[a-zA-Z]{0,3}[dD][a-zA-Z]{0,3}\b|--delete\b)|push\b[^\n;&|]*?(?:--delete\b|\s-d\b|\s["'']?:[\w/.-]+)|(?:merge|pull)\s+[^\n;&|]*--ff-only\b)|\bgh\s+issue\s+edit\b'
min: 0
max: 0
---

Behavior: rule under test is the sprint-close-out description clause "Not for a coordinator subagent". The coordinator for story 7 must run none of the launcher's close-out writes: `git worktree remove`, `git branch -D` or `-d`, `git push --delete`, `git push -d`, `git push origin :<branch>`, `git merge --ff-only`, `git pull --ff-only`, or `gh issue edit`. The grader is meant to catch those writes.

Limitation: The grader matches the JSON text of the whole Bash tool input, `{"command":"...","description":"..."}`, so a word in the description can match. The front matter pattern is the real definition. In the lists, `\n` stands for a newline, `\t` for a tab and `\\` for a backslash.

Seen: `git worktree remove /w`, `git branch -D x`, `git branch -d x`, `git push --delete o x`, `git push origin :x`, `git push origin ':x'`, `git merge --ff-only origin/main`, `git pull --ff-only origin main`, `gh issue edit 9`, `(git branch -D x)`, `git -C /r branch -D x`, `git -c k=v branch -D x`, `git -C "/r" branch -D x`, `git branch \\\n  -D x`, `git branch --list\ngit branch -D x`, `gh issue edit 3\ngh issue edit 9`.

Not seen: `git -C "/r;x" branch -D y`, `git push origin ":x"`, `git $(echo branch) -D x`, `git worktree prune`, `git merge origin/main`, `git pull origin main`, `git worktree list`, `git branch --list`, `gh pr view 12`, `gh issue view 9`, `git status\ngit branch -D x`, `git status;\tgit branch -D x`, `git status\n\tgit branch -D x`, `cat /tmp/b\ngh issue edit 9`, `gh -R o/r issue edit 9`, `rm -rf /w`, `ls` (description `branch -D x`).

False hits: `echo "git worktree remove x"`, `ls` (description `git worktree remove x`), `ls` (description `gh issue edit 3`), `git branch -vv` (description `List branches before -D`), `git branch --list\nls -D`, `git merge origin/main\necho --ff-only`, `git -C /r status` (description `see what branch -D would hit`).

No end state, because Bash writes are blocked in the run.

Nothing is claimed about a form not listed.
