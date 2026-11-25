---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)\b|(?:[;&|(]|\\n)\s*pytest\b|\bpython3?\s+(?:[^\s"]*/)?test_[^\s"]*\.py\b)|"command"\s*:\s*"pytest\b'
min: 1
---

Behavior: the run issues at least one Bash call whose `command` value runs the test suite: `python3 -m unittest`, `python3 -m pytest`, `pytest` as a command word, or a direct run of a `test_*.py` file (for example `python3 tests/test_store_contract.py`, because the scaffold test file ends with `unittest.main()`). The match is confined to the `command` value, so a description that names a runner does not count. A probe such as `which pytest` does not count, and an install such as `pip install pytest` does not count. A `grep` that names `unittest` does not count.

Limitation: the check counts calls but does not check their order. A run that happens after the edit counts the same as a run before it, so the grader does not show that the failing test was seen first. It does not check that the run covered the new implementation, that the suite passed, or which file was edited. The check is a substring match on the command, so no judge is needed.
