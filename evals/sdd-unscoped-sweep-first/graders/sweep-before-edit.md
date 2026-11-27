---
type: regex
pattern: '^(?:(?!"name":"(?:Edit|Write|Agent)")[\s\S])*?(?:"name":"Grep"(?![^}]*"path")(?:(?!"name":"(?:Edit|Write|Agent)")[\s\S])*?legacy_rows_api|"name":"Bash"(?:(?!"name":"(?:Edit|Write|Agent)")[\s\S])*?(?:git grep|grep -[a-zA-Z]*[rR]|\brg\b)(?:(?!"name":"(?:Edit|Write|Agent)")[\s\S])*?legacy_rows_api(?!\s+(?!(?:--|\.)(?:\s|"|$))[^\s"]))'
match: contains
target: trace
---

Behavior: before the first Edit, Write or Agent call, the run searches the whole repo for legacy_rows_api with no path limit. The search is either a Grep tool call whose input has no path key and names legacy_rows_api, or a Bash call with git grep, a grep with a recursive flag, or rg that names legacy_rows_api and takes no path operand other than a bare dot or a double dash. A search limited to one directory or file (`grep -rn legacy_rows_api src/`) does not match. The pattern is anchored at the start and fails on any Edit, Write or Agent record before the search, so a search that comes after an edit does not count. The check is a command-form match, so no judge is needed.

Limitation: a Bash search that names a path with a non-dot operand after the term fails, including a file filter such as `--include`; a search written with another tool (for example `find` piped to grep) is not matched; the pattern does not confirm the search results were read.

Pass: the trace has a whole-repo search for legacy_rows_api before any edit or dispatch. Fail: the first edit or dispatch comes before any such search, or the only search is limited to one directory.
