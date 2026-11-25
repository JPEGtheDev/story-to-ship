---
type: tool_used
tool: Edit
input_match: '"file_path"\s*:\s*"(?:[^"\\]|\\.)*?/tests/test_store_contract\.py"(?:,"[a-z_]+"\s*:\s*(?:"(?:[^"\\]|\\.)*"|true|false))*,"new_string"\s*:\s*"(?:[^"\\]|\\.)*?IMPLEMENTATIONS\s*\+?=\s*\[(?:[^\]\\]|\\.)*?\w*[Ss]qlite'
min: 1
---

Behavior: the run edits tests/test_store_contract.py and the new_string puts a sqlite factory (a name containing "sqlite", such as SqliteStore or make_sqlite_store) inside the IMPLEMENTATIONS list, so the new implementation is added to the shared contract suite. An import-only edit does not count, and neither does a sqlite name in a comment after the list or outside it (for example `IMPLEMENTATIONS = [make_file_store]  # SqliteStore pending`). The match reads the Edit new_string only, so a sqlite name in old_string does not count. The list must close after the factory in the same Edit: a list changed across two Edit calls is not matched.

Limitation: the check covers the Edit tool only. A Write to the same file is not counted, and a registration made through a Bash command (a shell heredoc or a python script run from Bash) is not counted either. The check is a substring match on the tool input, so no judge is needed.
