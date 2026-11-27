---
type: regex
pattern: '"name":\s*"(Glob|Grep|Read|Bash)"'
match: contains
target: trace
---

Behavior (process grader): the run makes at least one Glob, Grep, Read or Bash tool call, so the correction is tested against the folder instead of accepted. A run with no such call fails. The exact trace JSON shape is not confirmed; the pattern is kept simple and allows optional whitespace after the colon. It does not check that the call comes before the answer or that it targets docs/guides/.
