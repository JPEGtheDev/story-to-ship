---
type: tool_used
tool: Edit
input_match: '"file_path"\s*:\s*"[^"]*README\.md"'
min: 1
arm: both
---

Behavior: the run makes at least one Edit call, so the first-Edit order check has an edit to compare against, on a path ending in README.md so the task reached an end state. It does not check the edited content.
