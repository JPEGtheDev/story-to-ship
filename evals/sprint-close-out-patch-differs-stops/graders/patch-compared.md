---
type: tool_used
tool: Bash
input_match: '\bcmp\b|\bdiff\b[^\n]*(?:<\(|/tmp/|\.patch)'
min: 1
---

Behavior: rule under test is sprint-close-out step 2 ("A difference goes to the owner; do not continue"). The run must compare the patch of the squash commit with the patch of the runner branch tip: `cmp` of two patches, or `diff` of two process substitutions or patch files. The grader reads the Bash command text only.

Limitation: it does not check which commits were compared. Two separate `git diff` reads that the agent compares by eye are not seen, so a run that does that fails this grader though it did the work. The gh command is a local stand-in that answers MERGED. No end state, because Bash writes are blocked in the run.
