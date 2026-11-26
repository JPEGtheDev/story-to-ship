---
type: regex
pattern: '^(?:(?!"command":"(?:[^"\\\n]|\\.)*worktree add)[\s\S])*I am using the using-git-worktrees skill to (?!create a worktree for \[purpose\])'
match: contains
target: trace
---

Behavior: the run states, in its own words, "I am using the using-git-worktrees skill to <purpose>" before it creates the worktree for the Todo 1 implementer. The check is a regex match on the trace, so no judge is needed. The announcement must come before the first Bash command that contains `worktree add`; an announcement after that command fails. The pattern is anchored on the `"command":"` field of a tool call, so the loaded skill text, which also contains `worktree add`, does not count as the add. The pattern skips the template line that a skill file can carry ("... to create a worktree for [purpose]"), so loading the skill text alone does not pass. Assistant text blocks are in the trace.

Limitation: the grader does not prove that the phrase is assistant text rather than tool input, or that the worktree was created. A run that only echoes the phrase in a Bash command also counts when the echo comes before the add. An announcement that words the skill name differently, such as "I am using the git worktree skill", fails (false fail), and so does a reworded lead-in such as "I'm using the using-git-worktrees skill to ...". The grader does not check the purpose text after "to".
