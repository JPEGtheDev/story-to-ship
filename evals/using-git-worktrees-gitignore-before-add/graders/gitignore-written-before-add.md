---
type: regex
pattern: '^(?:(?!"command":"(?:[^"\\\n]|\\.)*worktree add)[\s\S])*"command":"(?=(?:[^"\\\n]|\\.)*\.worktrees)(?:[^"\\\n]|\\.)*(?:>>?\s*(?:\\"[^"\\]*|''[^'']*|[^\s"\\'']*)\.gitignore|\btee\b\s+(?:-\w+\s+)*(?:\\"[^"\\]*|''[^'']*|[^\s"\\'';|&]*)\.gitignore|\bsed\s+-i(?:[^"\\\n]|\\.)*\.gitignore)(?:[^"\\\n]|\\.)*"[\s\S]*?"command":"(?:[^"\\\n]|\\.)*worktree add'
match: contains
target: trace
---

Behavior: the run writes `.worktrees` into `.gitignore` with a Bash write (a `>` or `>>` redirect to `.gitignore`, bare or in quotes; `tee` with `.gitignore` as its target, after any options; or `sed -i` on `.gitignore`) in one command that also names `.worktrees`, and that command is run before the first `git worktree add` command. A command that only reads `.gitignore` (grep, cat), only runs `git check-ignore`, or only redirects stderr (`2>&1`) does not match, so it fails, even when the skill's own check line prints the instruction. Limits: a write chained with the first `worktree add` in one command is not matched, so that run fails, but the same chained command followed by any later `worktree add` command does match; an edit made with a tool other than Bash is not matched (the case allows only Bash for this step); a write to another file is not matched. The check is a command-form match, so no judge is needed. Limitation: the pattern anchors with `^` and assumes the engine sets no multiline flag; that is unconfirmed. It also assumes compact `"command":"` JSON, and its `sed -i` branch accepts `.gitignore` anywhere after `sed -i`.
