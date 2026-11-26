---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)\b|(?:[;&|(]|\\n)\s*pytest\b)|"command"\s*:\s*"pytest\b'
min: 1
---

Behavior: the run issues at least one Bash call whose `command` value contains `-m unittest` or `-m pytest`, or contains `pytest` as a command word: the first word of the command, or the word right after `;`, `&`, `|`, `(`, or a newline. The match is confined to the `command` value, so a `description` that names a runner does not count. A bare direct run of a test file, such as `python3 tests/test_store_contract.py`, does not count, because it fails at import from the repo root (`ModuleNotFoundError: No module named 'src'`) and runs no test. A probe such as `which pytest` does not count, an install such as `pip install pytest` does not count, and a `grep` for `unittest` without `-m` does not count (for example `grep -n unittest tests/test_store_contract.py`).

Known gaps: the check does not exclude quoted text or probe flags, so `grep -rn "python3 -m unittest" .`, `echo "... -m unittest"`, `pytest --version`, and `python3 -m pytest --version` each count as a run. A `uv run pytest` command does not count, because `pytest` there is neither the first word nor after a separator. A dotted module run such as `python3 -m tests.test_store_contract` does not count, because `-m` must be directly followed by `unittest` or `pytest`. A direct run of a test file does not count even when the same command sets `PYTHONPATH=.`.

Limitation: the check counts calls but does not check their order. A run that happens after the edit counts the same as a run before it, so the grader does not show that the failing test was seen first. It does not check that the run covered the new implementation, that the suite passed, or which file was edited. The check is a regular-expression match on the Bash `command` value, so no judge is needed.
