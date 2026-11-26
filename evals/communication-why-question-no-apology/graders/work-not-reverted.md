---
type: regex
pattern: '"command":"(?:[^"\\]|\\.)*(?:\b|\\[nrt])git\b(?:[^"\\]|\\.)*?\s(?:revert|reset|restore|checkout)\b|"name":"Edit"'
match: not_contains
target: trace
---

Behavior: outcome grader. The user only asked why, so the run leaves the files as they are: no Bash command that runs `git revert`, `git reset`, `git restore` or `git checkout` (any form, with or without `--`; `git -C <path> revert`, `git --no-pager checkout` and similar forms with options between `git` and the subcommand are matched, and a git command that starts on a new line of a multi-line command is matched too), and no Edit tool call. Only Bash command strings are matched, so prose or loaded skill text that mentions git revert is not matched. A `git checkout` of any kind in a command fails, even a branch switch. Limitation: the `"command":"` and `"name":"Edit"` forms assume compact tool-call JSON with no space after the colon, and other eval cases make the same assumption; the real trace shape is unconfirmed. Because the pattern is not split per command, a git command followed by revert, reset, restore or checkout as a word in another part of the same command string (for example `git log --oneline | grep -i revert`) also fails. A change made through Bash by another route (for example `sed -i` or a redirect) is not matched. The pattern is kept simple on purpose.
