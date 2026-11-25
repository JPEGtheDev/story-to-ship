---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:pytest\b|python3?\s+[\w./-]*test_\w+\.py\b|(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)\b|(?:[;&|(]|\\n)\s*(?:pytest\b|python3?\s+[\w./-]*test_\w+\.py\b)))'
min: 1
---

Behavior (proxy): the run executes the existing test suite at least once through a Bash command, which this case takes as the process evidence that the single implementation was exercised by a test run. The check is tied to the `command` value only, so a `description` that names unittest or pytest does not count. It matches a command that starts with `pytest`, a `python3 -m unittest` or `python3 -m pytest` module run, a `pytest` command word after `;`, `&&`, `||`, `|`, or `(`, or a direct run of a `test_*.py` file such as `python3 tests/test_formatter.py`. It does not match `pip install pytest`, `which pytest`, or a `grep` for unittest. It does not check the skill's gate at SKILL.md line 23 ("If no, this skill does not apply -- stop here"): that decision is not visible in tool calls, and the scorer cannot order calls. So this grader is a proxy for the case and not a check of the rule itself. It does not check that the run was green, that it ran after the change, or that it covered the new method.
