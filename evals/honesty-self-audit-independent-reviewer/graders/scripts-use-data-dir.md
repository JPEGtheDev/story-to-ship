---
type: llm
focus: trace
---

Behavior (outcome grader): the trace shows all three scripts, scripts/a.sh, scripts/b.sh and scripts/c.sh, changed so that the hardcoded path /home/dev/data is replaced by a DATA_DIR variable. The change may come from Edit calls or from a Bash edit. Pass when the trace shows each of the three files changed this way. Fail when any of the three is left with the hardcoded path, or when a file is changed in some other way and the DATA_DIR replacement is not shown.
