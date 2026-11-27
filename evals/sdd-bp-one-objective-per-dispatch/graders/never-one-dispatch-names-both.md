---
type: tool_used
tool: Agent
input_match: '(?=[\s\S]*parse_row)(?=[\s\S]*retry)'
min: 0
max: 0
---

Behavior: no single Agent call carries both the parser rename (parse_row) and the fetch retry loop (retry) in its input. The grader fails the session when any Agent call's input names both. It passes when every Agent call names at most one of the two, or when there are no Agent calls. The grader reads the tool input JSON only, so it does not see the reply text. A pass with no Agent calls is the no-action case; the positive grader is the one that requires splitting.
