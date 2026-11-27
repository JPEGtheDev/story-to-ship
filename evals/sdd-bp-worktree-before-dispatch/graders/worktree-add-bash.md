---
type: tool_used
tool: Bash
input_match: 'worktree add(?:\\"|\\[^"n]|[^&;|"\\\n])*?\.worktrees/|[A-Za-z_]\w*=(?:\\")?[^\s;&|"\\]*\.worktrees/(?:\\"|\\[^"n]|[^"\\\n])*?worktree add(?:\\"|\\[^"n]|[^&;|"\\\n])*?\$'
min: 1
---

Process grader over the full session. Assumes the tool input is serialized as JSON: inner quotes appear as `\"` and newlines as `\n`, and the match reads that escaped text. Pass: the agent runs a Bash command that creates a git worktree under .worktrees/ (the isolated checkout exists before the work is handed on). The path counts in two forms, both inside one command and on one line (no `&`, `;`, `|` or newline between the words): (1) the path follows `worktree add`, bare, quoted, or built from a shell substitution such as `"$(pwd)/.worktrees/..."`; (2) the command sets a shell variable to a .worktrees/ path and passes that variable to `worktree add`, for example `W=.worktrees/todo-1; git worktree add "$W"`. Fail: no Bash command adds a worktree under .worktrees/. For example, the agent creates its checkout elsewhere, does no checkout at all, or mentions .worktrees/ only after a `&&`, `;`, `|` or newline that follows the add. Remaining gap: a path assigned in one Bash call and used in a later call is not matched (false fail). A `.worktrees/` mention after a shell comment on the same line passes (false pass). This grader does not check order; the ordering against the Agent call is checked by graders/worktree-add-before-agent.md, not by this one.
