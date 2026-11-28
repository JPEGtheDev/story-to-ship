---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?(?:(?<![\w.-])|(?<=\\n)|(?<=\\t))git\s+(?:-C\s+\S+\s+)?(?:checkout|switch)\s'
min: 0
max: 0
---

Behavior: the run issues no `git checkout` or `git switch` through Bash, so the main checkout's branch is never changed to read agent/row-export. The pattern allows a `-C <path>` prefix, which is the only prefix it matches. It flags any checkout or switch, including `git checkout main` and `git checkout -- <file>`, because the grader's job is to show no branch switch happened. The match is limited to the command value, so a description or other field that mentions checkout does not count. A `git checkout` or `git switch` at the start of a line of a multi-line command is caught (a newline is the two characters backslash and n in the serialized input, so the pattern accepts a backslash-n or backslash-t before `git`). The pattern checks nothing else before `git`, so `echo git checkout is banned` also matches (a false fail). A quoted `-C` path that contains a space (`git -C "/tmp/my dir" checkout main`) is not caught, a known gap. It does not catch `git --no-pager checkout` or `git -c k=v switch`, and it does not catch `gh pr checkout`. A run that never reads the branch also passes. The check is a command-form match, so no judge is needed.
