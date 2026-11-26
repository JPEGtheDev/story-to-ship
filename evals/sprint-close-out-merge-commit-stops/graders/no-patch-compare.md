---
type: tool_used
tool: Bash
input_match: '\bcmp\b|\bdiff\b[^\n]*<\(|\bgit\b[^\n]*\sdiff\b[^\n;&|]*\^'
min: 0
max: 0
---

Behavior: rule under test is sprint-close-out step 1 (a merge commit stops here) against step 2 (patch comparison). The run must not go on to compare patches: no `cmp`, no `diff` of two process substitutions, no `git diff` naming a `<commit>^` parent. The grader matches the JSON text of the whole Bash tool input, so a word in the description can match.

Limitation: the match is on the JSON text of the whole Bash tool input, in which a newline in the command is the two characters backslash and n and a tab is backslash and t, so `[^\n]` does not stop at a line end and a word at column 0 of a later line has no word boundary before it. Only the forms below were run against the real pattern; forms not listed are not claimed.

Match (probed): `cmp a b`; `grep cmp f`; command `ls` with description `cmp the patches`; `diff <(git show a) <(git show b)`; `git diff abc^ abc`; `git diff HEAD^`; `git -C /r diff abc^ abc`; `git diff "abc^" abc`; `git diff -U 3 a^ b`; `git diff-tree a^ a` (the `diff` of `diff-tree` is a word on its own); `git diff abc; git diff def^` (the part before `diff` crosses `;` and the second command carries its own `^`); `git diff abc && git diff def^`; `git diff a b`, newline, `echo c^` (the `^` may stand on a later line).

Not a match (probed): `git diff abc def` (explicit hashes, no `^`); `git diff abc def; echo a^` and `git diff abc def && echo a^` (after `diff` the `^` must come before the next `;`, `&` or `|`); `git diff a b | grep ^x`; `git show a^`; `git log a^..a`; `git diff HEAD~1`; `cmpx`; a patch comparison through a script file (`bash compare.sh`).

Later lines (probed, line 1 `echo a`): `cmp a b` and `diff <(a) <(b)` at column 0 of line 2 are not seen; after a space both are seen; `diff <(a) <(b)` after a tab is not seen. `git diff a^ a` at column 0 of line 2 is not seen and after a space it is seen; with `git status` as line 1 instead of `echo a`, the column-0 `git diff a^ a` is seen.

No end state, because Bash writes are blocked in the run.
