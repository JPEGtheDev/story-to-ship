---
type: tool_used
tool: Bash
input_match: '-m\s+(?:unittest|pytest)\b|"command":\s*"(?:(?:[^"\\]|\\.)*(?:&&|;|\|\|)\s*)?(?:timeout\s+\d+\s+)?pytest\b'
min: 1
---

Behavior: the run issues a Bash call that runs the test suite with `-m unittest`, `-m pytest` or a `pytest` command at the start of the command or after `&&`, `;` or `||`, optionally behind `timeout <seconds>`. A quoted path before the `&&` (for example `cd "/a b" && pytest -q`) does not stop the match. The check counts matching Bash calls and needs no judge.

Limitation: a bare `unittest` run without `-m` (for example `unittest discover` through another launcher) is not matched. It reads Bash calls only, so a suite run inside a subagent is not counted. It counts suite runs, not their order, so a run whose only suite run comes before the fix passes it. The llm grader `suite-run-after-edit` judges the order, and `reports-post-fix-result` judges the posted result.
