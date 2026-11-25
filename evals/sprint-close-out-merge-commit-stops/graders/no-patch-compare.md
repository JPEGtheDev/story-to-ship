---
type: tool_used
tool: Bash
input_match: '\bcmp\b|\bdiff\b[^\n]*<\(|\bgit\b[^\n]*\sdiff\b[^\n;&|]*\^'
min: 0
max: 0
---

Behavior: rule under test is sprint-close-out step 1 (a merge commit stops here) against step 2 (patch comparison). The run must not go on to compare patches: no `cmp`, no `diff` of two process substitutions, no `git diff` naming a `<commit>^` parent. The grader matches the JSON text of the whole Bash tool input, so a word in the description can match.

Limitation: a patch comparison written without `^` (for example `git diff <sha1> <sha2>` with explicit hashes) or through a script file is not seen. After `diff` the `^` must come before the next `;`, `&` or `|`: `git diff abc def; echo a^` and `git diff abc def && echo a^` are not seen, but `git diff abc; git diff def^` is seen, because the part before `diff` crosses `;` and the second command carries its own `^`. The word `cmp` matches anywhere, so `grep cmp f` and a description such as `cmp the patches` fail the run, and any `diff` followed by `<(` matches. A newline in the command is the two characters backslash and n in the matched text, so `[^\n]` does not stop there: `git diff a b`, newline, `echo c^` is seen. No end state, because Bash writes are blocked in the run.
