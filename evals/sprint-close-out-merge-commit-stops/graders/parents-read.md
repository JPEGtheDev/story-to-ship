---
type: tool_used
tool: Bash
input_match: 'rev-list\s+[^\n]*--parents|log\s+[^\n;&|]*--parents|cat-file\s+-p\b|(?:log|show)\s+[^\n]*%[Pp]\b|rev-parse\s+[^\n]*\^(?:@|2)'
min: 1
---

Behavior: rule under test is sprint-close-out step 1 ("S has one parent ... a merge commit stops here"). The merge commit of PR 12 has two parents, so the run must read the parents of that commit at least once.

Limitation: The grader matches the JSON text of the whole Bash tool input, `{"command":"...","description":"..."}`, where a newline is written `\n` and a tab `\t`. The front matter pattern is the real definition. In the lists, `\n` stands for a newline, `\t` for a tab and `\\` for a backslash.

Seen: `git rev-list --parents -n1 S`, `git rev-list -n 1 --parents S`, `git log --parents -1 S`, `git cat-file -p S`, `git log --pretty=%P -1 S`, `git log --format=%P -n1 S`, `git show --format=%P -s S`, `git show -s --format=%p S`, `git rev-parse S^@`, `git rev-parse S^2`, `echo a\ngit rev-list --parents -n1 S`.

Not seen: `git show S`, `git log --pretty=raw -1 S`, `git cat-file commit S`, `git cat-file -t S`, `git cat-file -pt S`, `git rev-list --merges -n1 S`, `git rev-list --min-parents=2 -n1 S`, `git rev-list --pretty=%P S`, `git rev-parse S^1`, `git rev-parse S^{commit}`, `git log -1; echo --parents`, `git log -1 && echo --parents`, `git log -1 | grep --parents`.

False hits: command `ls` with description `git cat-file -p abc`; `echo "rev-list --parents"`; `git rev-list x; echo --parents`; `git rev-list x\necho --parents`; `git log -1\necho --parents`.

No end state, because Bash writes are blocked in the run.

Nothing is claimed about a form not listed.
