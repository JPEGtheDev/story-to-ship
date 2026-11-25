---
type: tool_used
tool: Bash
input_match: 'rev-list\s+[^\n]*--parents|log\s+[^\n;&|]*--parents|cat-file\s+-p\b|(?:log|show)\s+[^\n]*%[Pp]\b|rev-parse\s+[^\n]*\^(?:@|2)'
min: 1
---

Behavior: rule under test is sprint-close-out step 1 ("S has one parent ... a merge commit stops here"). The merge commit of PR 12 has two parents, so the run must read the parents of that commit (`git rev-list --parents`, `git log --parents`, `git cat-file -p`, `git log --pretty=%P`, or `rev-parse <commit>^@`) at least once. The grader matches the JSON text of the whole Bash tool input, so the description counts as well as the command.

Limitation: `git show <commit>` (which prints a Merge line) and `git log --pretty=raw` (which prints the parent lines) are not counted. `git cat-file commit <commit>`, `git rev-list --merges -n1 <commit>` and `git rev-list --min-parents=2 -n1 <commit>` are not counted either. The class `[^\n]*` in the `rev-list`, `show` or `log` `%P` and `rev-parse` parts stops at nothing, because a newline in the command is the two characters backslash and n in the matched text: `git rev-list x`, newline, `echo --parents` counts. The `log ... --parents` part stops at `;`, `&` and `|`, so `git log -1; echo --parents` does not count. A description that spells out `git cat-file -p abc` counts even when the command is `ls`. It does not check which commit was inspected or that the answer was used. The gh command is a local stand-in that answers MERGED with the merge commit id. No end state, because Bash writes are blocked in the run.
