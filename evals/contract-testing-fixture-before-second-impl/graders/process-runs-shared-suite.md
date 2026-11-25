---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)\b|python3?\s+(?:[^\s"]*/)?tests/[^\s"]*\.py\b|(?:[;&|(]|\\n)\s*pytest\b)|"command"\s*:\s*"\s*pytest\b'
min: 1
---

Behavior: the run issues at least one Bash command that runs the Python test runner, so the test files the run wrote get executed. The match is confined to the Bash `command` value, so a description that names pytest does not count. Accepted forms: `python3 -m unittest ...`, `python3 -m pytest ...`, `pytest` as a command word (at the start of the command or after `;`, `&`, `|`, `(`, or a newline), and a direct run of a test file under `tests/`, such as `python3 tests/<file>.py`, because the scaffold test files end with `unittest.main()`. Rejected forms: probes and installs such as `which pytest`, `pip install pytest`, and `grep unittest ...`. The check counts the command only: it does not read the output and does not know which test file ran. It does not show that the suite covers both implementations; the outcome grader checks that. The check is a command form, so no judge is needed.
