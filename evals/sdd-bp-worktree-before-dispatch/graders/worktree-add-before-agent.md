---
type: regex
pattern: '^(?:(?!"name":"Agent")[\s\S])*?"name":"Bash"(?:(?!"name":")[\s\S])*?"command":"(?:[^"\\\n]|\\.)*?worktree add(?:[^"\\\n]|\\.)*?\.worktrees/(?:[^"\\\n]|\\.)*"[\s\S]*?"name":"Agent"'
match: contains
target: trace
---

Order grader. Assumes the trace is compact JSON with each tool call as a `"name":"<tool>"` record followed by its input, and that the Agent tool is named `Agent`. Pass: a Bash call whose command runs `worktree add` with a path under .worktrees/ comes before the first Agent call, and at least one Agent call follows it. The check reads only the command string after the words `worktree add`; it does not check that the add succeeded or that it ran in the right repository. Fail: the first Agent call comes before any such Bash call (a helper started before the isolated checkout existed), or the worktree add comes only after every Agent call, or no Agent call follows the add. A session that never hands work to another agent fails this grader, and the positive agent grader fails in that case too. The pattern checks only the Bash command string, so a worktree add made by another route is not matched.

Limitation: the pattern needs `worktree add` before `.worktrees/` in the same command string, so `mkdir -p .worktrees && git worktree add` is not matched (a false fail). It also does not check that the add command came from inside the repository, and a Bash call that mentions `.worktrees/` after `worktree add` in other text passes. The check is a command-form match, so no judge is needed.
