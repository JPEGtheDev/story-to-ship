---
type: regex
pattern: 'I am using the using-git-worktrees skill to (?!create a worktree for \[purpose\])'
match: contains
target: trace
---

Behavior: the run states, in its own words, "I am using the using-git-worktrees skill to <purpose>" before it creates the worktree for the Todo 1 implementer. The check is a regex match on the trace, so no judge is needed. It proves that an announcement naming the skill and a purpose appears somewhere in the trace. The pattern skips the template line that a skill file can carry ("... to create a worktree for [purpose]"), so loading the skill text alone does not pass. It does not prove that the phrase comes before the `git worktree add` call, that it is assistant text rather than tool input, or that the worktree was created. Assistant text blocks are in the trace. A run that only echoes the phrase in a Bash command also passes.

Limitation: the pattern has no order check against `git worktree add`, so an announcement given after the worktree is created also passes (false pass). An announcement that words the skill name differently, such as "I am using the git worktree skill", fails (false fail). The grader does not check the purpose text after "to".
