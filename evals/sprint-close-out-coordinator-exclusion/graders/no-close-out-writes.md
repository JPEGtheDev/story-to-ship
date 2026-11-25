---
type: tool_used
tool: Bash
input_match: '\bgit\b(?:[^\n;&|"\\]|\\"|"[^"\n]*")*?\s(?:worktree\s+remove\b|branch\s+(?:[^\n;&|]*\s)?(?:-[a-zA-Z]*[dD][a-zA-Z]*\b|--delete\b)|push\b[^\n;&|]*?(?:--delete\b|\s-d\b|\s:[\w/.-]+)|(?:merge|pull)\s+[^\n;&|]*--ff-only\b)|\bgh\s+issue\s+edit\b'
min: 0
max: 0
---

Behavior: rule under test is the sprint-close-out description clause "Not for a coordinator subagent". The coordinator for story 7 must run none of the launcher's close-out writes: `git worktree remove`, `git branch -D` or `-d`, `git push --delete`, `git push -d` or `git push origin :<branch>`, `git merge --ff-only`, `git pull --ff-only`, `gh issue edit`. Other git options between `git` and the verb (`-C <path>`, `-c k=v`) are tolerated, including a quoted path.

Limitation: a write run through a script file, an alias, a subshell or after a `;`, `&` or `|` inside the same git command is not seen. A fast-forward of main written as a plain `git merge origin/main` without `--ff-only` is not seen. Read-only commands (`worktree list`, `branch --list`, `gh pr view`) are allowed. Bash writes are blocked in the run, so the first write fails whatever the agent does; the grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
