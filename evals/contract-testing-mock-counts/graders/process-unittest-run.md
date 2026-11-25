---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)\b|(?:[;&|(]|\\n)\s*(?:pytest|python3?\s+tests/[\w./-]+\.py)\b)|"command"\s*:\s*"\s*(?:pytest|python3?\s+tests/[\w./-]+\.py)\b'
min: 1
---

Behavior: the run issues at least one Bash command whose `command` value runs a Python test runner: `-m unittest` or `-m pytest`; `pytest` as a command word after a shell separator (`;`, `&`, `|`, `(`, or a newline) or at the start of the command; or a direct run of a test file under `tests/` (`python3 tests/<file>.py`, which the scaffold's test files support through `unittest.main()`), again after a separator or at the start. The match is confined to the Bash `command` value, so a description that names pytest or unittest does not count, and probes and installs do not count: `which pytest`, `pip install pytest`, and `grep unittest ...` do not match. A direct run of a file outside `tests/` does not match. The check is a substring match on the command, so no judge is needed. It does not check which tests ran, whether they passed, or whether the run covered the suite; the outcome grader covers the suite's content.
