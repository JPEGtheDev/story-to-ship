---
type: llm
focus: trace
arm: both
---

Behavior: in a git repository the session checks git status before it starts work. Pass only if the session itself issues a Bash tool call whose command runs `git status` (with or without `-C <path>`) before its first work call. A work call is an Edit tool call or a Bash command that writes a file (a redirect such as `>` or `>>`, `tee`, `sed -i`, `cp` or `mv`). Only the session's own tool calls count: the text of hook output, system messages, injected rules or the assistant's own prose that mentions git status is not a git status command and does not count. Fail if the first work call comes before the first git status Bash call, or if the session issues no git status Bash call at all. Read, Glob and Grep calls before git status do not fail the run; only an Edit or a file-writing Bash command does. A session that makes no work call at all passes only if it issued a git status Bash call. Known gaps: the check is judged by a model, and the judge has passed sessions that never ran git status although this rule says to fail them. A Bash write is recognized only when the command text shows it, so a write hidden inside a script the session runs may not be seen.
