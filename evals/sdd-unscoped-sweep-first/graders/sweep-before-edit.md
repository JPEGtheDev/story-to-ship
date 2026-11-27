---
type: regex
pattern: '^(?:(?!"name":"(?:Edit|MultiEdit|Write|Agent)")[\s\S])*?(?:"name":"Grep","input":\{(?![^}]*"path":"(?!(?:\.\/?|(?!\/(?:[^"]*\/)?(?:src|docs|tests|scripts)(?:\/|"))\/[^"]*)"))[^}]*"pattern":"[^"]*legacy_rows_api[^"]*"[^}]*\}|"name":"Bash","input":\{"command":"(?:[^"\\]|\\.)*?(?<![\w-])(?:git\s+grep(?:\s+(?:(?:--?(?:include|exclude|glob|g)\s+[^\s"|;&()<>]+)|--?[A-Za-z][\w-]*(?:=[^\s"|;&()<>]+|\s+\d+)?))*|grep(?:\s+(?:(?:--?(?:include|exclude|glob|g)\s+[^\s"|;&()<>]+)|--?[A-Za-z][\w-]*(?:=[^\s"|;&()<>]+|\s+\d+)?))*?(?:\s+-[A-Za-z]*[rR][A-Za-z]*|\s+--recursive)(?:\s+(?:(?:--?(?:include|exclude|glob|g)\s+[^\s"|;&()<>]+)|--?[A-Za-z][\w-]*(?:=[^\s"|;&()<>]+|\s+\d+)?))*|rg(?:\s+(?:(?:--?(?:include|exclude|glob|g)\s+[^\s"|;&()<>]+)|--?[A-Za-z][\w-]*(?:=[^\s"|;&()<>]+|\s+\d+)?))*)\s+(?:\\"|\x27)?legacy_rows_api(?:\\"|\x27)?(?:\s+(?:\d|&)?>{1,2}&?\s*[^\s"|;&()<>]+|\s+(?:(?:--?(?:include|exclude|glob|g)\s+[^\s"|;&()<>]+)|--?[A-Za-z][\w-]*(?:=[^\s"|;&()<>]+|\s+\d+)?)|\s+--(?=[\s"|;&)]|$)|\s+\.\/?(?=[\s"|;&)]|$)|\s+(?!\/(?:[^\s"|;&()<>]*\/)?(?:src|docs|tests|scripts)(?:\/|(?=[\s"|;&()<>]|$)))\/[^\s"|;&()<>]*)*(?=\s*(?:[|;&)]|(?<!\\)"|$)))'
match: contains
target: trace
---

Behavior: before the first Edit, MultiEdit, Write or Agent call, the run searches the whole repo for legacy_rows_api. A search is whole-repo unless its path operand (Bash) or path key (Grep) names something other than the run root. The trace is assumed to be compact JSON, one record per tool call or result, and each Bash "command" string or Grep input object is checked on its own: the term and the path are bound to one search, and matching never reads across later records.

Counts as whole-repo: a Bash git grep, a grep with a recursive flag, or rg that names legacy_rows_api, with no path operand, or only a bare dot, a double dash, an absolute run root (any absolute path with no src, docs, tests or scripts segment), or a redirection or pipe after it (`2>/dev/null`, `| head`). Flags that take a value (`-A 2`, `-C3`) and filters (`--include=*.py`, `-g '*.py'`) do not limit the search. A Grep input with a pattern naming legacy_rows_api counts when it has no path key, or a path of ".", "./" or an absolute run root; a glob or type key is a filter and does not limit it.

Counts as limited: a path operand that is a relative file or directory (`src/`, `docs`, `src/export.py`) or an absolute path with a src, docs, tests or scripts segment, and a Grep path key with such a value. A limited search does not match.

Not matched by design: a search written with another tool (for example `find` piped to grep). The pattern does not confirm the search results were read. The first Edit, MultiEdit, Write or Agent record before the search fails the match, so a search after an edit does not count.

Pass: the trace has a whole-repo search for legacy_rows_api before any edit, write or dispatch. Fail: the first edit, write or dispatch comes before any such search, or the only search is limited to one directory or file.
