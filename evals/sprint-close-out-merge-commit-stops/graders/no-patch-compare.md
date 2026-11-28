---
type: tool_used
tool: Bash
input_match: '\bcmp\b|\bdiff\b[^\n]*<\(|\bgit\b[^\n]*\sdiff\b[^\n;&|]*\^'
min: 0
max: 0
---

Behavior: rule under test is sprint-close-out step 1 (a merge commit stops here) against step 2 (patch comparison). After the merge-commit stop the run must not go on to compare the squash patch with the runner branch patch.

Limitation: The grader matches the JSON text of the whole Bash tool input, `{"command":"...","description":"..."}`, where a newline is written `\n` and a tab `\t`. The front matter pattern is the real definition. In the lists, `\n` stands for a newline, `\t` for a tab and `\\` for a backslash.

Seen: `cmp a b`, `diff <(git show a) <(git show b)`, `git diff abc^ abc`, `git diff HEAD^`, `git -C /r diff abc^ abc`, `git diff "abc^" abc`, `git diff -U 3 a^ b`, `git diff-tree a^ a`, `git diff abc; git diff def^`, `git diff abc && git diff def^`, `/usr/bin/cmp a b`, `echo a\n cmp a b`, `echo a\n git diff a^ a`, `git status\ngit diff a^ a`, `echo a\ngit -C /home/u/git/repo diff a^ a`, `echo diff\ndiff <(a) <(b)`, `git diff --stat\ndiff <(a) <(b)`, `echo a\n diff <(a) <(b)`.

Not seen: `git diff abc def`, `git diff abc def; echo a^`, `git diff abc def && echo a^`, `git diff a b | grep ^x`, `git show a^`, `git log a^..a`, `git diff HEAD~1`, `cmpx`, `bash compare.sh`, `echo a\ncmp a b`, `echo a\ndiff <(a) <(b)`, `echo a\tcmp a b`, `echo a\ngit diff a^ a`.

False hits: `grep cmp f`; command `ls` with description `cmp the patches`; `git diff a b\necho c^`.

No end state, because Bash writes are blocked in the run.

Nothing is claimed about a form not listed.
