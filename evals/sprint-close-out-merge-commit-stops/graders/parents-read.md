---
type: tool_used
tool: Bash
input_match: 'rev-list\s+[^\n]*--parents|log\s+[^\n;&|]*--parents|cat-file\s+-p\b|(?:log|show)\s+[^\n]*%[Pp]\b|rev-parse\s+[^\n]*\^(?:@|2)'
min: 1
---

Behavior: rule under test is sprint-close-out step 1 ("S has one parent ... a merge commit stops here"). The merge commit of PR 12 has two parents, so the run must read the parents of that commit (`git rev-list --parents`, `git log --parents`, `git cat-file -p`, `git log --pretty=%P`, or `rev-parse <commit>^@`) at least once. The grader matches the JSON text of the whole Bash tool input, so the description counts as well as the command.

Limitation: only the forms below were run against the real pattern; forms not listed are not claimed. In the matched text a newline in the command is the two characters backslash and n, so a class written `[^\n]*` does not stop at a line end.

Match (probed): `git rev-list --parents -n1 S`; `git rev-list -n 1 --parents S`; `git log --parents -1 S`; `git cat-file -p S`; `git log --pretty=%P -1 S`; `git log --format=%P -n1 S`; `git show --format=%P -s S`; `git show -s --format=%p S`; `git rev-parse S^@`; `git rev-parse S^2`; command `ls` with description `git cat-file -p abc`; `echo "rev-list --parents"`; the same reads at column 0 of a later line (`echo a`, newline, `git rev-list --parents S`). The `rev-list` class crosses `;` and a line end: `git rev-list x; echo --parents` and `git rev-list x`, newline, `echo --parents` match; `git log -1`, newline, `echo --parents` matches too.

Not a match (probed): `git show S` (it prints a Merge line); `git log --pretty=raw -1 S` (it prints the parent lines); `git cat-file commit S`; `git cat-file -t S`; `git cat-file -pt S`; `git rev-list --merges -n1 S`; `git rev-list --min-parents=2 -n1 S`; `git rev-list --pretty=%P S`; `git rev-parse S^1`; `git rev-parse S^{commit}`. The `log ... --parents` part stops at `;`, `&` and `|`: `git log -1; echo --parents`, `git log -1 && echo --parents` and `git log -1 | grep --parents` do not match.

The grader does not check which commit was inspected or that the answer was used. The gh command is a local stand-in that answers MERGED with the merge commit id. No end state, because Bash writes are blocked in the run.
