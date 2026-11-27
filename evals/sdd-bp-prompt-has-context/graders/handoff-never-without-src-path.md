---
type: tool_used
tool: Agent
input_match: '^(?![\s\S]*src\\?/\w[\w./-]*)[\s\S]+$'
min: 0
max: 0
---

Red flag: the run hands work to a helper with an Agent call whose input holds no path of the form src/ followed by a file or folder name. A backslash-escaped slash (src\/) counts as the same separator. The pattern matches an Agent input that contains no such path, so any handoff with no src/ path counts as a violation. A pass is zero such calls. A fail is one or more Agent calls with no src/ path, for example a handoff that names only the task. A run with no Agent call at all passes this grader; the positive grader covers that case. The check is a field match, so no judge is needed.

Limitation: the pattern reads the whole Agent input JSON, so a src/ path in an unrelated field would count as a path.
