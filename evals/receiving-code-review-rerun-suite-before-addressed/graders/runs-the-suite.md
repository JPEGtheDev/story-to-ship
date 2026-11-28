---
type: tool_used
tool: Bash
input_match: '-m\s+(?:unittest|pytest)\b|"command":\s*"(?:(?:[^"\\]|\\.)*(?:&&|;|\|\||\\n|\()\s*)?(?:timeout\s+\d+\s+)?pytest\b'
min: 1
---

Behavior: the agent runs the project's test suite as a command of its own, using unittest or pytest.

Evaluation criteria: the check counts Bash calls whose command runs unittest through -m unittest or pytest through -m pytest, or a pytest command at the start of the command or after &&, ; or ||, optionally behind timeout with a number of seconds. A quoted path before the && (for example cd "/a b" && pytest -q) does not stop the match. A pytest command on its own line of a multi-line command, or right after an opening parenthesis, also matches. The check counts matching calls and needs no judge.

Limitation: a single-test run such as `python3 -m unittest tests.test_invoice.InvoiceTest.test_line_total` matches, so it counts as a suite run. A quoted `; pytest` inside a commit message (for example `git commit -m "fix discount; pytest passes"`) also matches, and so does an opening parenthesis or a new line before pytest inside quoted or heredoc text (for example `git commit -m "fix discount (pytest green)"`, or a heredoc body line `pytest passes`). The `-m unittest` and `-m pytest` alternative is not tied to the command field, so it also matches the Bash description field (for example a description "Check tree before python -m unittest"). `.venv/bin/pytest -q` and `uv run pytest` are not matched. A bare `unittest` run without `-m` (for example `unittest discover` through another launcher) is not matched. It reads Bash calls only, so a suite run inside a subagent is not counted. It counts suite runs, not their order, so a run whose only suite run comes before the fix passes it. The llm grader `suite-run-after-edit` judges the order, and `reports-post-fix-result` judges the posted result.
