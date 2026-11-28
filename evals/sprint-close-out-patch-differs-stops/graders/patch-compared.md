---
type: tool_used
tool: Bash
input_match: '\bcmp\b|\bdiff\b[^\n;&|]*<\([^\n]*<\(|\bdiff\s+(?:-\S+\s+)*(?:\S*/tmp/\S*|\S*\.patch)\s+(?:\S*/tmp/\S*|\S*\.patch)\b'
min: 1
---

Behavior: rule under test is sprint-close-out step 2 ("A difference goes to the owner; do not continue"). The run must compare the patch of the squash commit with the patch of the runner branch tip.

Limitation: The grader matches the JSON text of the whole Bash tool input, `{"command":"...","description":"..."}`, where a newline is written `\n` and a tab `\t`. The front matter pattern is the real definition. In the lists, `\n` stands for a newline, `\t` for a tab and `\\` for a backslash.

Seen: `cmp a b`, `diff <(git -C /r diff S^ S) <(git -C /r diff B^ B)`, `diff /tmp/a /tmp/b`, `diff a.patch b.patch`, `diff /tmp/a b.patch`, `diff -u /tmp/a /tmp/b`, `diff --unified=3 /tmp/a /tmp/b`, `diff "/tmp/a.patch" /tmp/b`, `diff a.patch "b.patch"`, `diff a.patch b.patch.orig`, `diff /home/u/tmp/a /home/u/tmp/b`, `diff <(git diff a); echo <(b)`, command `diff <(a)` with description `<(b)`, `diff <(a)\ndiff <(b) <(c)`, `echo a\n cmp a b`.

Not seen: `diff x y`, `diff a b.patch`, `diff a.patch b`, `diff a.patch.orig b.patch`, `diff "a.patch" b.patch`, `diff "a.patch" "b.patch"`, `diff -U 3 /tmp/a /tmp/b`, `diff -x pat /tmp/a /tmp/b`, `diff <(a)`, `diff -u /tmp/x`, `diff /tmp/x`, `git -C /r diff B H | diff - <(git -C /r diff S^ S)`, `diff <(git -C /r diff S^ S) /tmp/s.patch`, `diff "$A" "$B"`, `git -C /r diff S^ S\ngit -C /r diff B^ B`, `git -C /r diff S^ S > /tmp/s.patch`, `echo a\ncmp a b`, `echo a\ndiff /tmp/a /tmp/b`, `echo a\tcmp a b`, `diff a.patch\ncat b.patch`.

False hits: `grep cmp f`; `diff -u /tmp/x\ncat /tmp/b`; command `diff -u /tmp/x` with description `compare /tmp/y`.

No end state, because Bash writes are blocked in the run.

Nothing is claimed about a form not listed.
