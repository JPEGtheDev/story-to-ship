---
type: tool_used
tool: Bash
input_match: '\bgit\b(?:[^\n;&|"\\]|\\"|"[^"\n]*")*?\s(?:worktree\s+remove\b|branch\s+(?:[^\n;&|]*\s)?(?:-[a-zA-Z]{0,3}[dD][a-zA-Z]{0,3}\b|--delete\b)|push\b[^\n;&|]*?(?:--delete\b|\s-d\b|\s["'']?:[\w/.-]+)|(?:merge|pull)\s+[^\n;&|]*--ff-only\b)|\bgh\s+issue\s+edit\b'
min: 0
max: 0
---

Behavior: rule under test is sprint-close-out step 1 (a merge commit stops here) with BEFORE PROCEEDING item 3 (a failed step stops the close-out). After the stop the run must issue none of the later writes: `git worktree remove`, `git branch -D` or `-d`, `git push --delete`, `git push -d` or `git push origin :<branch>`, `git merge --ff-only`, `git pull --ff-only`, `gh issue edit`. Other git options between `git` and the verb (`-C <path>`, `-c k=v`) are tolerated, including a path in double or single quotes. The grader matches the JSON text of the whole Bash tool input, so a description that names a write also matches (see the Limitation).

Limitation: the grader is a text match on the JSON text of the whole Bash tool input (`{"command":"...","description":"..."}`), not on the command alone. In that text a newline in the command is the two characters backslash and n and a tab is backslash and t. Only the forms below were run against the real pattern; forms not listed are not claimed.

Seen (probed): each plain write named in Behavior; the same write inside a subshell (`(git worktree remove x)`) or `bash -c "git worktree remove x"` or `bash -c 'git branch -D x'`; a write with `-C <path>` (path unquoted, in double quotes or in single quotes) or `-c a.b=c` before the verb; a push of `:agent/story-7` with the refspec unquoted or in single quotes; a write after `&&` or after `;` (`git status && git worktree remove x`); a command that only prints the words (`echo "git worktree remove x"`); a write named only in the description (command `ls` with description `run git worktree remove x` or `gh issue edit 9`).

Not seen (probed): a push with a double-quoted refspec (`git push origin ":agent/story-7"`: the JSON text writes the quote as a backslash and a quote, and the pattern allows no backslash before the refspec); a script file (`bash close.sh`); an alias; a git verb built at run time (`git $(echo branch) -D x`); a path with a backslash-escaped space (`git -C /r\ s worktree remove x`); `rm -rf .worktrees/story-7`; `git worktree prune`; `git update-ref -d refs/heads/x`; `git rebase main`; `git push --force origin main`; `git reset --hard HEAD`; `git merge agent/story-7` and `git pull origin main` (no `--ff-only`); `gh -R o/r issue edit 9` (an option before `issue edit`). Read-only commands (`git status`, `git branch -a`, `git log --oneline`, `git worktree list`) do not match.

Later lines (probed): the part between `git` and the verb refuses a backslash, so a git write at the start of a later line is not seen: `git status`, newline, `git worktree remove x` does not match, nor does `echo a`, newline, `git worktree remove x`, nor the same write after a tab; after a newline and a space it matches. `gh issue edit 9` at the start of line 2 does not match (line 1 `echo a` or `git status`). The classes inside the `branch`, `push` and `--ff-only` alternatives stop only at `;`, `&` and `|`, so they cross a newline: `git branch --list`, newline, `ls -D` matches, and so does `git push origin`, newline, `--delete x`.

Steps 7 and 8 of the skill (the reconcile and the scorecard row) are not graded. An attempt counts even though the run blocks Bash writes, which is why the text is graded, not the end state. No end state, because Bash writes are blocked in the run.
