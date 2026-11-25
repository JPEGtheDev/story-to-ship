---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?!(?:[^"\\]|\\.)*?(?:\bmktemp\b|\bcp\s+(?:-\w*[rRa]|--recursive|--archive)))(?:(?:uv\s+run\s+)?pytest\b(?!\s+(?:--version|-V|--help|-h|--collect-only|--co)\b)|(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)\b(?!\s+(?:--version|-V|--help|-h|--collect-only|--co)\b)|(?:[;&|(]|\\n)\s*(?:uv\s+run\s+)?pytest\b(?!\s+(?:--version|-V|--help|-h|--collect-only|--co)\b)|\bpython3?\s+tests/[\w./-]+\.py\b))'
min: 1
---

Behavior: the run issues at least one Bash command that runs the shared contract test runner. A command counts when it runs `-m unittest` or `-m pytest`, runs `pytest` as a command word (optionally after `uv run`), or runs a test file under `tests/` directly (for example `python3 tests/test_store_contract.py`, which the scaffold test files support through their unittest.main() guard). A probe or an install does not count: `pytest --version`, `pytest -h`, `pytest --collect-only`, `pip install pytest`, and `grep -n unittest ...` do not match. A command that copies into a scratch directory with `cp -r`, `cp -R`, `cp -a`, or `cp --recursive`, or that creates one with `mktemp`, does not count when the same command makes that copy or temporary directory, so a run inside a scratch copy is not the suite run.

Limitation: the scorer checks only that a runner command exists. It cannot order calls, so it cannot tell that the run came after the new implementation was added, and it does not check that the new implementation was registered (the outcome grader covers the registration). A baseline run made before the implementation exists is also counted. A runner started in a temporary directory without `cp` or `mktemp` in the same command is also counted. The check does not check that the tests passed. It is a substring match on the Bash `command` value, so no judge is needed.
