---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?(?:-m\s+(?:unittest|pytest)\b(?!\s+(?:--version|--help|--co(?:llect-only)?)\b)|(?:[;&|(]|\\n)\s*pytest\b(?!\s+(?:--version|--help|--co(?:llect-only)?)\b)|\bpython3?\s+(?:[^"\\\s]*/)?tests/[^"\\\s]*\.py\b)|"command"\s*:\s*"pytest\b(?!\s+(?:--version|--help|--co(?:llect-only)?)\b)'
min: 1
---

Behavior: the run issues at least one Bash command that runs the shared contract suite or a test file, the step that would surface a broken invariant after the cut. The match is confined to the Bash `command` value, so a description that names pytest does not count. The run shapes are `-m unittest`, `-m pytest`, `pytest` as a command word (at the start or after a shell separator), and `python3 tests/<file>.py` (the scaffold test files end with unittest.main(), so a direct file run counts). Probes and installs do not count: `which pytest`, `pip install pytest` and `grep -n unittest tests/test_store_contract.py` have no run shape, and `pytest --version`, `--help` and `--collect-only` are rejected by a lookahead. Known gaps: a direct file run that also passes --help is counted; the check does not see the order of calls, does not check that the run covered the new implementation or that the tests passed, and does not read the output (the outcome grader covers the registration). The check is a substring match on the command, so no judge is needed.
