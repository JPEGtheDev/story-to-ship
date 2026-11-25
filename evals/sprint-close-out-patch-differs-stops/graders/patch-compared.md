---
type: tool_used
tool: Bash
input_match: '\bcmp\b|\bdiff\b[^\n;&|]*<\([^\n]*<\(|\bdiff\s+(?:-\S+\s+)*(?:\S*/tmp/\S*|\S*\.patch)\s+(?:\S*/tmp/\S*|\S*\.patch)\b'
min: 1
---

Behavior: rule under test is sprint-close-out step 2 ("A difference goes to the owner; do not continue"). The run must compare the patch of the squash commit with the patch of the runner branch tip: any command text holding the word `cmp` (it does not check what is compared or that `cmp` is the command: `grep cmp file` and `echo cmp` pass, and so does a description holding `cmp`), or `diff` of two process substitutions, or `diff` of two patch files under /tmp or ending in `.patch`. Writing a single patch to a file, or reading one with `git diff`, does not count. The grader matches the JSON text of the whole Bash tool input (command and description), so a word in the description can match.

Limitation: it does not check which commits were compared. After the first `<(` of a `diff`, the second `<(` may come after a `;`, `&` or `|`, on a later line (a newline is backslash and n in the JSON text) or in the description: `diff <(git diff a); echo <(b)` matches. Two separate `git diff` reads are not seen; a `diff` of two process substitutions or of two files under /tmp or ending in `.patch` counts whatever they hold; nothing is claimed about a `diff` of other files. These real comparisons are not counted: stdin as one operand (`git -C /r diff B H | diff - <(git -C /r diff S^ S)`), a process substitution against a file (`diff <(...) /tmp/s.patch`) and `diff "$A" "$B"` on variables, so a run that does that fails this grader though it did the work. The gh command is a local stand-in that answers MERGED. No end state, because Bash writes are blocked in the run.
