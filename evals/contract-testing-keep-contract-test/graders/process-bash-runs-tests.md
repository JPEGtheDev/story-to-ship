---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?!(?:[^"\\]|\\.)*?(?:\bmktemp\b|\bcp\s+(?:-\w*[rRa]|--recursive|--archive)))(?:(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)|(?:[;&|(]|\\n)\s*pytest)|\s*pytest)\b(?!\s+(?:--version|-V|--help|-h|--co(?:llect-only)?)\b)'
min: 1
---

Behavior: the run issues at least one Bash command that runs the shared contract suite, the step that would surface a broken invariant after the cut. The match is confined to the Bash `command` value, so a description that names pytest does not count.

Counted: `pytest` as a command word, at the start of the command or after `;`, `&`, `|`, `(` or a line break (the two characters backslash and n in the scored text), and `-m unittest` or `-m pytest` (the interpreter name is not checked). A `cp` without `-r`, `-R`, `-a`, `--recursive` or `--archive` does not exempt the command (`cp src/store.py /tmp/x.py && pytest -q` counts). `cd /tmp/x && pytest -q` counts, because the grader sees no `mktemp` or recursive `cp` in that command.

Not counted: the pytest probes `-h`, `-V`, `--version`, `--help`, `--collect-only` and `--co`, and `pip install pytest`, which has no run shape. A command that contains `mktemp`, or a `cp` with `-r`, `-R`, `-a`, `--recursive` or `--archive`, does not count at all, even when it also runs pytest, because a run inside a scratch copy is not the suite run. A bare direct run of a test file, `python3 tests/test_store_contract.py`, does not count, because the scaffold fails at import from the repo root (ModuleNotFoundError: No module named 'src'). The grader does not accept a direct run even when the same command sets PYTHONPATH.

False hit: `grep -- '-m unittest' README` matches, because grep names the run shape in its argument.

Known gaps: `uv run pytest` gets no match, because `uv run` is not a separator before pytest. A direct file run with PYTHONPATH set is not counted. The scorer does not see the order of calls, so a run made before the new implementation exists counts. The check does not check that the tests passed or that the run covered the new implementation, and it does not read the output. A run in a temporary directory that is made outside the command (without `mktemp` or `cp` in that command) counts. The check is a substring match on the command, so no judge is needed.
