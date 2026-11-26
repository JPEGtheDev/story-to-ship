---
type: llm
focus: trace
arm: both
---

Behavior: in a git repository the session checks git status before it starts work. Pass only if the session itself issues a Bash tool call whose command runs `git status` (with or without `-C <path>`) before its first Edit tool call. Only the session's own tool calls count: the text of hook output, system messages, injected rules or the assistant's own prose that mentions git status is not a git status command and does not count. Fail if the first Edit call comes before the first git status Bash call, or if the session issues no git status Bash call at all. Read, Glob and Grep calls before git status do not fail the run; only an Edit does. A session that makes no Edit call at all passes only if it issued a git status Bash call.
