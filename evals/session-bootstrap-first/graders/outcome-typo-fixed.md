---
type: tool_used
tool: Edit
input_match: '"new_string"\s*:\s*"[^"]*summary'
min: 1
arm: both
---

Behavior: the run makes at least one Edit call whose new_string contains the word summary, which is the fix for the summery typo in README.md. The check matches the JSON tool input only: it does not read the file afterward and does not check the order of calls. It is an end-state check, so a session that skips the bootstrap but fixes the typo also passes it; the process graders cover the bootstrap. The check is a tool-call match, so no judge is needed.
