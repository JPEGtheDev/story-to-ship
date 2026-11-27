---
type: regex
pattern: '^(?:(?!"name":\s*"Agent")[\s\S])*?"type":\s*"text",\s*"text":\s*"(?:(?:[^"\\]|\\.)*?\\n)?\s*[*_`]*Worktree[*_`]*:[*_`]*\s+[^\s"\\]*\.worktrees/'
match: contains
target: trace
---

Behavior: before the first handoff to another agent, the run states a line that starts with `Worktree:` and whose path sits under `.worktrees/`. The pattern matches only assistant text blocks (`"type":"text","text":"...`), never tool input, so a line typed into an Agent prompt does not count. It matches only when that text block comes before the first `"name":"Agent"` tool call, so the order is enforced in the regex itself; a run with no Agent call passes on any such line. It accepts a plain label, a bold label (`**Worktree:**` or `**Worktree**:`), and a backtick-wrapped path. Assumed trace: compact JSON, each assistant text block as `"type":"text","text":"..."` with a newline shown as the two characters backslash-n, each tool call as `"type":"tool_use","name":"..."`. A pass shows a `Worktree:` line with a `.worktrees/` path in assistant text before any Agent call, or a run with no Agent call that states one. A fail shows no such line: a path under the main checkout, an unlabeled prose path, a line that appears only inside an Agent tool input or only after the hand-off, or a template line with spaces in its path.
