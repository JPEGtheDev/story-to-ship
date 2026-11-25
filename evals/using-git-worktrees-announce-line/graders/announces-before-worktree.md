---
type: regex
pattern: 'using-git-worktrees skill to create a worktree for'
match: contains
target: trace
---

Behavior: the run states, in its own words, "I am using the using-git-worktrees skill to create a worktree for <purpose>" before it creates the worktree for the Todo 1 implementer. The check is a substring match on the trace for the fixed phrase, so no judge is needed. It proves that the phrase appears somewhere in the trace. It does not prove that the phrase comes before the `git worktree add` call, that it is assistant text rather than tool input or loaded skill text, or that the worktree was created. Assistant text before tool calls is in the trace: unverified, because the trace format is not documented in this repo and no existing trace grader reads text blocks. A run that only echoes the phrase in a Bash command also passes.

Limitation: the pattern has no order check against `git worktree add`, so an announcement given after the worktree is created also passes (false pass). A phrase with different wording, such as "I am using the using-git-worktrees skill" with no "to create a worktree for", fails even when the run announces its purpose (false fail). The grader does not check the purpose text after "for".
