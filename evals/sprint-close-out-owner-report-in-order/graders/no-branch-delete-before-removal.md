---
type: regex
target: trace
pattern: '"command":"[^"]*(?:\bbranch\s+(?:[^\s";&|\\]+\s+)*?(?:-[a-zA-Z]{0,3}[dD][a-zA-Z]{0,3}|--delete)\b(?:[^";&|\\]|\\")*?story-7\b|\bpush\b[^";&|\\]*?(?:--delete\b|\s-d\b)(?:[^";&|\\]|\\")*?story-7\b|\bpush\s[^";&|\\]*?\s\\?["'']?:\S*story-7\b)(?:[^"]*|(?:(?!"permission_denials")[\s\S])*?"command":"[^"]*)\bworktree\s+remove\b'
match: not_contains
---

Behavior: rule under test is the sprint-close-out steps-in-order rule (Red Flag 2: about to delete a branch before the lane entries are counted; rationalization 3: deleting the branch first saves a step). Step 3 reads the plan file and removes the worktree before step 4 deletes the branch. The grader fails when a branch deletion (`git branch` with `-d`, `-D`, `-Df` or `--delete` in any order with other flags, or `git push` with `--delete`, `-d` or `:<branch>`, quoted or not, that deletes the branch on origin) appears in the trace before a `git worktree remove`. A run that only attempts the removal, or attempts nothing, passes.

Limitation: it reads the trace text up to the result record's `permission_denials` list and anchors on the Bash command field (`"command":"..."`), so quoted prose, the skill text and a denied command repeated in that list do not trip it; it names the branch `story-7`, so a deletion through a variable is not seen. The branch name may be quoted (`git branch -D "agent/story-7"` is seen), and a recon command such as `git branch -a; test -d .worktrees/story-7` is not mistaken for a deletion because the match stops at `;`, `&`, `|` and a newline. A run that deletes a branch and never attempts a removal passes, and a command with an escaped double quote before the deletion is not seen. It does not prove the removal came first; the tool_order graders do. Bash writes are blocked in the run, so the first write fails whatever the agent does; the grader reads the trace text, not an end state. No end state, because Bash writes are blocked in the run.
