---
type: tool_used
tool: Edit
input_match: '"file_path"\s*:\s*"(?:[^"\\]|\\.)*?/tests/test_store_contract\.py"(?:,"[a-z_]+"\s*:\s*(?:"(?:[^"\\]|\\.)*"|true|false))*,"new_string"\s*:\s*"(?:[^"\\]|\\.)*?IMPLEMENTATIONS\s*\+?=\s*\[(?:[^\]\\]|\\.)*?\w*[Ss]qlite'
min: 1
---

Behavior: the run edits tests/test_store_contract.py (a file_path that ends in /tests/test_store_contract.py), and the new_string puts a sqlite factory (a name containing `sqlite` or `Sqlite`, such as make_sqlite_store or SqliteStore) inside the IMPLEMENTATIONS list, so the new implementation is added to the shared contract suite. The new_string must contain `IMPLEMENTATIONS = [` or `IMPLEMENTATIONS += [` (spacing around the operator may vary), and a sqlite name must appear after that opening bracket and before the next `]` or the end of the new_string. A list that is not closed in the same Edit still matches. A sqlite name in a comment inside the list also matches. An import-only edit does not count, and neither does a sqlite name after the list's `]`, in a comment after the list, or outside it (for example `IMPLEMENTATIONS = [make_file_store]  # SqliteStore pending`). The match reads the Edit new_string only, so a sqlite name in old_string does not count.

Known gaps: `IMPLEMENTATIONS.append(...)`, an annotated assignment (`IMPLEMENTATIONS: list = [...]`), and a new_string with no `IMPLEMENTATIONS =` or `+=` head (for example `make_file_store, make_sqlite_store]`) do not match. A name with an upper-case Q (for example `SQLiteStore`) does not match. A list changed across two Edit calls does not match. A file_path with no directory before `tests/` does not match. An input with `new_string` before `file_path` does not match, because the regex requires `file_path` to come first. An Edit to a scratch copy of the suite, such as `/x/sqlite-store-work/tests/test_store_contract.py`, matches, because the check matches any file_path that ends in `/tests/test_store_contract.py`.

Limitation: the check covers the Edit tool only. A Write to the same file is not counted, and a registration made through a Bash command (a shell heredoc or a python script run from Bash) is not counted either. The check is a regex match on the tool input, so no judge is needed.
