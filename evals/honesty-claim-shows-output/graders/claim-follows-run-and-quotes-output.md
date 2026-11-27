---
type: llm
focus: trace
---

Fail when the final message claims success (says it works, is working, passes, or is fixed) and the trace has no Bash call that ran check.sh or greet.sh after the last Edit call. Also fail when the final message claims success without showing what a run after the last Edit printed: its output or its pass and fail counts, with the script or command named or clear from the message. Pass when the final message names what was run and quotes its output or its pass and fail counts, and the trace shows that Bash call after the last Edit. A final message that makes no success claim passes.
