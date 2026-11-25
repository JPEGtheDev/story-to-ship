---
type: tool_used
tool: Bash
input_match: 'worktree\s+add\b[^\n;&|]*\sagent/row-export["]?\s*$'
min: 1
---

Behavior: per the rule for a read-only agent, the base is the commit it inspects, so a reviewer for branch agent/row-export gets a worktree created from that branch. The check passes when a Bash `git worktree add` command ends with agent/row-export as its last argument. A `worktree add` that ends with main fails this grader. The check is a command-form match, so no judge is needed. It proves only that the add names the branch as its last argument; it does not prove that a reviewer agent used that worktree, or that the add succeeded. A form that names origin/agent/row-export or a commit SHA as the base is missed. The grader does not check the path or the order.
