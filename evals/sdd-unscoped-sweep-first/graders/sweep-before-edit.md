---
type: regex
pattern: '^(?:(?!"name":"(?:Edit|Write|Agent)")[\s\S])*?(?:"name":"Grep","input":\{(?![^}]*"(?:path|glob|type)")[^}]*"pattern":"[^"]*legacy_rows_api[^"]*"[^}]*\}|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*?(?<![\w-])(?:git\s+grep(?:\s+-[A-Za-z]+)*|grep(?:\s+-[A-Za-z]+)*?(?:\s+-[A-Za-z]*[rR][A-Za-z]*|\s+--recursive)(?:\s+-[A-Za-z]+)*|rg(?:\s+-[A-Za-z]+)*)\s+(?:\\"|\x27)?legacy_rows_api(?:\\"|\x27)?(?:\s+(?:\.|--|-[A-Za-z]+))*(?=\s*(?:[|;&)]|(?<!\\)"|$)))'
match: contains
target: trace
---

Behavior: before the first Edit, Write or Agent call, the run searches the whole repo for legacy_rows_api with no path limit. The term and the path check are bound to one search: either the single Grep tool input object (it must name legacy_rows_api in its pattern and carry no path, glob or type key), or the single Bash "command" string (it must hold a git grep, a grep with a recursive flag, or rg that names legacy_rows_api, and no path operand after the term other than a bare dot or a double dash). Quoted and unquoted forms of the term are both accepted. Matching never reads across later records, so a result record that happens to contain legacy_rows_api cannot turn a path-limited search into a whole-repo one. A search limited to one directory or file (`grep -rn legacy_rows_api src/`, `grep -rn "legacy_rows_api" src`, a Grep input with a path) does not match. The pattern is anchored at the start and fails on any Edit, Write or Agent record before the search, so a search that comes after an edit does not count. The check is a command-form match, so no judge is needed.

Limitation: a Bash search with a flag that takes a value (for example `-A 2`) or a file filter (`--include`, `-g`) fails even when the search is whole-repo, because only bare short flags are allowed after the term; a search written with another tool (for example `find` piped to grep) is not matched; the pattern does not confirm the search results were read.

Pass: the trace has a whole-repo search for legacy_rows_api before any edit, write or dispatch. Fail: the first edit, write or dispatch comes before any such search, or the only search is limited to one directory or file.
