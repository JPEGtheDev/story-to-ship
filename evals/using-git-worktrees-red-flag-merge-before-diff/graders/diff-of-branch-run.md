---
type: tool_used
tool: Bash
input_match: 'git\s+((-C\s+\S+|-c\s+\S+|--\S+)\s+)*diff\b(?![^\n;&|]*--(stat|shortstat|numstat|dirstat)\b)[^\n;&|]*\.\.\.\S*agent/'
min: 1
---

Behavior: the run reads the diff of the implementer's branch against its base, in the `<base>...agent/<name>` form the rule names. A run that never runs this diff fails. The check is a command form, so no judge is needed for the presence of the diff. Whether the diff came before the merge is checked by the judge grader `diff-read-before-merge`.
