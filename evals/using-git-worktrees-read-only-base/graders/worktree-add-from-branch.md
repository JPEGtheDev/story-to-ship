---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?worktree\s+add\b(?:[^"\\\n;&|]|\\")*?\s(?:\\"|'')?agent/row-export(?:\\"|'')?(?=\s*(?:\\n|"|&&|;|\|))'
min: 1
---

Behavior: per the rule for a read-only agent, the base is the commit it inspects, so a reviewer for branch agent/row-export gets a worktree created from that branch. The check passes when a Bash `git worktree add` command names agent/row-export as its last argument: an optional quote around it, then the end of the command value, a chain operator, or a line break. A chained add and a quoted name pass. A `worktree add` that names it only as the new -b branch, or that ends with main or origin/agent/row-export, fails this grader. The check is a command-form match, so no judge is needed. It proves only that the add names the branch as its last argument; it does not prove that a reviewer agent used that worktree, or that the add succeeded. A form that names a commit SHA as the base is missed. The grader does not check the path or the order.
