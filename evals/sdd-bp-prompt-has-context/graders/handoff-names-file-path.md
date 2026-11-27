---
type: tool_used
tool: Agent
input_match: 'src/cli/args\.py'
min: 1
---

Behavior: the text the run hands to its helper names the file to change, src/cli/args.py. The grader reads the Agent tool input JSON, so a handoff that gives the path anywhere in its text passes. A pass is at least one Agent call whose input contains src/cli/args.py. A fail is no Agent call that names that path, for example a handoff that says only "implement Todo 1" with no file path. The check is a field match, so no judge is needed.

Limitation: the pattern does not check that the path is the file the helper actually edits, and it does not check that main.py is named as off limits.
