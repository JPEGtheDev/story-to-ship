---
type: tool_used
tool: Bash
input_match: 'git\s+(-C\s+\S+\s+)?(rev-list|merge-base)\b'
min: 1
---

Behavior: the run executes a base check (`git rev-list` or `git merge-base`) through Bash before it creates the worktree, so the new branch is based on a commit the check chose. The check is a command-form match, so no judge is needed. The grader does not check order (check before `worktree add`); that is a Limitations item.
