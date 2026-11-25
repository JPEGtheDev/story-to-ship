---
type: tool_used
tool: Bash
input_match: '\bcmp\b|\bdiff\b[^\n]*<\(|\bgit\b[^\n]*\sdiff\b[^\n;&|]*\^'
min: 0
max: 0
---

Behavior: rule under test is sprint-close-out step 1 (a merge commit stops here) against step 2 (patch comparison). The run must not go on to compare patches: no `cmp`, no `diff` of two process substitutions, no `git diff` naming a `<commit>^` parent. The grader reads the Bash command text only.

Limitation: a patch comparison written without `^` (for example `git diff <sha1> <sha2>` with explicit hashes) or through a script file is not seen. A patch comparison split by `;`, `&` or `|` is not seen. No end state, because Bash writes are blocked in the run.
