---
type: tool_used
tool: Bash
input_match: '(^|"command":\s*"|&&|;|\|\|?|\n|\\n)\s*git\s+(-C\s+(?:[^\s\\]|\\")+\s+)?worktree\s+remove\b(?:[^\n;&|\\"]|\\")*csv-export-todo1'
min: 1
---

Behavior: after the Todo 1 branch is merged, the run issues a `git worktree remove` command that names `csv-export-todo1`. The grader reads the command text only. It does not check that the command succeeded or that the worktree is gone afterward. The check is a command form, so no judge is needed.

Limitation: a command that names the path after a `;`, `&` or `|` is not matched, and the order against the Todo 2 dispatch is not checked. The merge and both worktrees are made by the scaffold before the run starts.
