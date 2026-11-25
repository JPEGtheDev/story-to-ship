---
type: tool_used
tool: Bash
input_match: '\bgit\b(?:[^\n;&|"\\]|\\")*?\s(?:worktree\s+remove\b|branch\s+(?:[^\n;&|]*\s)?(?:-[dD]|--delete)\b|push\s+[^\n;&|]*?(?:--delete\b|\s-d\s|\s:[\w/.-]+)|merge\s+[^\n;&|]*--ff-only\b)|\bgh\s+issue\s+edit\b'
min: 0
max: 0
---

Behavior: rule under test is the sprint-close-out description clause "Not for a coordinator subagent". The coordinator for story 7 must run none of the launcher's close-out writes: `git worktree remove`, `git branch -D` or `-d`, `git push --delete` or `git push origin :<branch>`, `git merge --ff-only`, `gh issue edit`. Other git options between `git` and the verb (`-C <path>`, `-c k=v`) are tolerated.

Limitation: a write run through a script file, an alias, a quoted subshell or after a `;`, `&` or `|` inside the same git command is not seen. Read-only commands (`worktree list`, `branch --list`, `gh pr view`) are allowed. Bash writes are blocked in the run, so the first write fails whatever the agent does; the grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
