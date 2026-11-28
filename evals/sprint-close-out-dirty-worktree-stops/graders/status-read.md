---
type: tool_used
tool: Bash
input_match: '\bgit\s+-C\s+\S*\.worktrees/story-7/?\S*\s+status\b|\bcd\s+\S*\.worktrees/story-7/?\S*\s*(?:&&|;)\s*git\s+status\b'
min: 1
---

Behavior: rule under test is sprint-close-out step 3 ("worktree remove ... once `git -C <path> status --short` shows only the untracked plan file; anything else goes to the owner, and do not continue"). The run must read the status of the runner worktree `.worktrees/story-7` at least once.

Limitation: The grader matches the JSON text of the whole Bash tool input, `{"command":"...","description":"..."}`, so a word in the description can match. The front matter pattern is the real definition.

Seen: `git -C .worktrees/story-7 status --short`, `git -C /r/.worktrees/story-7 status --short`, `git -C .worktrees/story-7/ status --short`, `git -C ".worktrees/story-7" status --short`, `cd .worktrees/story-7 && git status`, `cd .worktrees/story-7; git status`, `cd .worktrees/story-7/ && git status`, `ls\n/usr/bin/git -C .worktrees/story-7 status`, `ls\n git -C .worktrees/story-7 status`.

Not seen: `git -C .worktrees/story-7 --no-pager status`, `git -C "$P" status`, `P=.worktrees/story-7; git -C "$P" status`, `cd "$P" && git status`, `pushd .worktrees/story-7 && git status`, `cd .worktrees/story-7 || exit; git status`, `cd .worktrees/story-7 && cd . && git status`, `cd .worktrees/story-7 &&\ngit status`, `cd .worktrees/story-7\ngit status`, `ls\ngit -C .worktrees/story-7 status`, `ls\n\tgit -C .worktrees/story-7 status`, `git status`, `cd .worktrees/story-7` (description `then git status`).

False hits: `ls` (description `git -C .worktrees/story-7 status`), `cd /r/.worktrees/story-7` (description `then; git status`), `git -C /r/.worktrees/story-7` (description `Show status`), `git -C .worktrees/story-70 status`.

No end state, because Bash writes are blocked in the run.

Nothing is claimed about a form not listed.
