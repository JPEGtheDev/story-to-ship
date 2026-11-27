---
type: regex
pattern: '^(?:(?!"name":"Agent")[\s\S])*?"name":"Bash"(?:(?!"name":")[\s\S])*?"command":"(?:[^"\\\n]|\\.)*?(?:worktree add(?:\\"|\\[^"n]|[^&;|"\\\n])*?\.worktrees/|[A-Za-z_]\w*=(?:\\")?[^\s;&|"\\]*\.worktrees/(?:\\"|\\[^"n]|[^"\\\n])*?worktree add(?:\\"|\\[^"n]|[^&;|"\\\n])*?\$)[\s\S]*?"name":"Agent"'
match: contains
target: trace
---

Order grader. Assumes the trace is compact JSON with each tool call as a `"name":"<tool>"` record followed by its input, that the Agent tool is named `Agent`, and that a Bash command string appears JSON-escaped (inner quotes `\"`, newlines `\n`). Pass: a Bash call whose command runs `worktree add` with a path under .worktrees/ comes before the first Agent call, and at least one Agent call follows it. The add forms match those of graders/worktree-add-bash.md: the path follows `worktree add` on the same line (bare, quoted, or from a shell substitution), or the command assigns a .worktrees/ path to a shell variable and passes that variable to `worktree add`. Fail: the first Agent call comes before any such Bash call (a helper started before the isolated checkout existed), or the worktree add comes only after every Agent call, or no Agent call follows the add. A session that never hands work to another agent fails this grader, and the positive agent grader fails in that case too. The check reads only the command string, so it does not check that the add succeeded or that it ran in the right repository.

Limitation: the add must sit on one line with no `&`, `;`, `|` or newline between `worktree add` and its path (or between the variable assignment and the add). So `git worktree add ../t1 && ls .worktrees/` is not a pass. A path assigned in an earlier Bash call and used in a later one is not matched (false fail). A worktree add made by another route (for example a script file) is not matched (false fail). A `.worktrees/` mention after a shell comment on the same line passes (false pass).
