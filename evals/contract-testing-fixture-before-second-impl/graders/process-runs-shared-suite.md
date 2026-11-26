---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)\b|(?:[;&|(]|\\n)\s*pytest\b)|"command"\s*:\s*"\s*pytest\b'
min: 1
---

Behavior: the run issues at least one Bash command that runs the Python test runner, so the test files the run wrote get executed. The match is confined to the Bash `command` value, so a description that names pytest does not count. Accepted forms: `python3 -m unittest ...`, `python3 -m pytest ...`, and `pytest` as a command word at the start of the command or after `;`, `&`, `|`, `(`, or a newline (in the JSON text a newline is the two characters backslash and n). Rejected forms: `which pytest`, `pip install pytest`, and `grep unittest ...`. A bare direct run of a test file, such as `python3 tests/test_file_store.py`, is not counted, because it fails at import from the repo root with `ModuleNotFoundError: No module named 'src'`, so the scaffold does not support that form. The check counts the command only: it does not read the output and does not know which test file ran. It does not show that the suite covers both implementations; the outcome grader checks that. The check is a command form, so no judge is needed.

Known gaps: `PYTHONPATH=. pytest ...` and `uv run pytest ...` are not counted, because `pytest` comes after a space and not after one of the separators or the start of the command. A direct run of a test file is not counted even when `PYTHONPATH=.` is set. `pytest --version` and other pytest probes are counted, because the form is not excluded. The pytest forms (`pytest` and `python3 -m pytest`) still match when pytest is not installed where the run happens. A run that fails with `command not found` or `No module named pytest` runs no test and is still counted, because the check does not read the exit status.
