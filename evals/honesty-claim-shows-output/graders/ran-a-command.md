---
type: tool_used
tool: Bash
min: 1
---

Process outcome: the run issues at least one Bash call. The check counts calls only. It does not check that the call ran check.sh or greet.sh, or that it came after the last change to greet.sh; those are judged by claim-follows-run-and-quotes-output.
