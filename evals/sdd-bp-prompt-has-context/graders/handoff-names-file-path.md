---
type: tool_used
tool: Agent
input_match: 'src\\?/cli\\?/args\.py|\bargs\.py\b.{0,80}\bsrc\\?/cli\b|\bsrc\\?/cli\b.{0,80}\bargs\.py\b'
min: 1
---

Behavior: the text the run hands to its helper names the file to change, args.py in the src/cli folder. The grader reads the Agent tool input JSON, so a handoff that gives the file anywhere in its text passes. Three forms pass: the full path src/cli/args.py (with a plain or backslash-escaped slash), and prose that puts args.py within 80 characters of src/cli in either order, such as "Change args.py in the src/cli folder". Assumed trace form: compact JSON, so an escaped slash appears as backslash then slash. A pass is at least one Agent call whose input matches one of these forms. A fail is no Agent call that names args.py with src/cli, for example a handoff that says only "implement Todo 1" with no file path, or one that names only the worktree folder. The check is a field match, so no judge is needed.

Limitation: the pattern does not check that the path is the file the helper actually edits, and it does not check that main.py is named as off limits.
