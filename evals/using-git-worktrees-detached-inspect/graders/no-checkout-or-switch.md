---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?\bgit\s+(?:-C\s+\S+\s+)?(?:checkout|switch)\s'
min: 0
max: 0
---

Behavior: the run issues no `git checkout` or `git switch` through Bash, so the main checkout's branch is never changed to read agent/row-export. The pattern allows a `-C <path>` prefix, which is the only prefix it matches. It flags any checkout or switch, including `git checkout main` and `git checkout -- <file>`, because the grader's job is to show no branch switch happened. The match is limited to the command value, so a description or other field that mentions checkout does not count. A quoted `-C` path that contains a space (`git -C "/tmp/my dir" checkout main`) is not caught, a known gap. It does not catch `git --no-pager checkout` or `git -c k=v switch`, and it does not catch `gh pr checkout`. A run that never reads the branch also passes. The check is a command-form match, so no judge is needed.
