---
type: tool_used
tool: Bash
input_match: "grep.*issue"
min: 1
---

Pass: the session holds at least one Bash call whose command runs grep and names the word issue, which is the search for spelled-out tracker references in the written instructions file. Fail: no Bash call runs grep over a file with the word issue in it, for example when the run never searches its instructions at all. The match is on the tool input, so it does not show that the search ran after the Write; the process grader covers the order.
