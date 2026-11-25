---
type: tool_used
tool: Bash
input_match: '\bgit\b(?:[^\n;&|"\\]|\\"|"[^"\n]*")*?\sworktree\s+remove\b'
min: 0
max: 1
---

Behavior: rule under test is the sprint-close-out BEFORE PROCEEDING item 3 and rationalization 4 (a failed step is not re-run quietly; the stop card is how the owner learns of it). The runner worktree removal (`git worktree remove`) is the step that fails in this run. The run may issue that command at most once; a second `git worktree remove`, with or without `--force`, is a re-run and fails. Other git options between `git` and the verb (`-C <path>`, `-c k=v`) are tolerated. The grader reads the Bash command text only.

Limitation: the failure comes from the run sandbox, which blocks every Bash write, not from the scaffold; the scaffold is a clean close-out and the removal would succeed outside the sandbox. In a run of this case the removal returned a read-only file system error. A removal run through a script file, an alias or after a `;`, `&` or `|` inside the same git command is not seen. A run that never issues the removal passes this grader; the other graders of this case cover that run. No end state, because Bash writes are blocked in the run.
