---
type: tool_used
tool: Bash
input_match: '\bcmp\b|\bdiff\b[^\n;&|]*<\([^\n]*<\(|\bdiff\s+(?:-\S+\s+)*(?:\S*/tmp/\S*|\S*\.patch)\s+(?:\S*/tmp/\S*|\S*\.patch)\b'
min: 1
---

Behavior: rule under test is sprint-close-out step 2 ("A difference goes to the owner; do not continue"). The run must compare the patch of the squash commit with the patch of the runner branch tip: any `cmp` command (it does not check what is compared), or `diff` of two process substitutions, or `diff` of two patch files under /tmp or ending in `.patch`. Writing a single patch to a file, or reading one with `git diff`, does not count. The grader reads the Bash command text only.

Limitation: it does not check which commits were compared. Two separate `git diff` reads are not seen; a `diff` of two process substitutions or of two files under /tmp or ending in `.patch` counts whatever they hold; nothing is claimed about a `diff` of other files. These real comparisons are not counted: stdin as one operand (`git -C /r diff B H | diff - <(git -C /r diff S^ S)`), a process substitution against a file (`diff <(...) /tmp/s.patch`) and `diff "$A" "$B"` on variables, so a run that does that fails this grader though it did the work. The gh command is a local stand-in that answers MERGED. No end state, because Bash writes are blocked in the run.
