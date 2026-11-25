---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)\b|(?:[;&|(]|\\n)\s*pytest\b)|"command"\s*:\s*"\s*pytest\b'
min: 1
---

Behavior: the run issues at least one Bash command whose `command` value runs a Python test runner: `-m unittest` or `-m pytest` anywhere in the command, or `pytest` as a command word after a shell separator (`;`, `&`, `|`, `(`, or a newline) or at the start of the command. A bare direct run of a test file (`python3 tests/<file>.py`) is not counted, because the test files import `src.*` and that run fails at import from the repo root with `ModuleNotFoundError: No module named 'src'` and exit 1. A run of a test file by an absolute path is not counted either. The match is confined to the Bash `command` value, so a description that names pytest or unittest does not count, and probes and installs do not count: `which pytest`, `pip install pytest`, and `grep unittest ...` do not match. The check is a substring match on the command, so no judge is needed. Known gaps: a command that only greps or echoes the quoted text `python3 -m unittest` (for example `grep -rn "python3 -m unittest" README.md`) matches, because the check reads the command text and cannot tell a quoted string from a run; `uv run pytest` and `PYTHONPATH=. pytest` do not match; a direct run that sets PYTHONPATH (`PYTHONPATH=. python3 tests/<file>.py`) does not match, although it runs the file. The check does not check which tests ran, whether they passed, or whether the run covered the suite; the outcome grader covers the suite's content.
