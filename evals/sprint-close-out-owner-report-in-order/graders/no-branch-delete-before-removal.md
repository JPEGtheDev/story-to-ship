---
type: regex
target: trace
pattern: '"command":"[^"]*(?:\bbranch\s+(?:-[dD]|--delete)\s+\S*story-7\b|\bpush\s+\S+\s+(?:--delete\s+|:)\S*story-7\b)(?:[^"]*|[\s\S]*?"command":"[^"]*)\bworktree\s+remove\b'
match: not_contains
---

Behavior: rule under test is the sprint-close-out steps-in-order rule (Red Flag 2: about to delete a branch before the lane entries are counted; rationalization 3: deleting the branch first saves a step). Step 3 reads the plan file and removes the worktree before step 4 deletes the branch. The grader fails when a branch deletion (`git branch -D` or `-d`, or a push that deletes the branch on origin) appears in the trace before a `git worktree remove`. A run that only attempts the removal, or attempts nothing, passes.

Limitation: it reads the whole trace text but anchors on the Bash command field (`"command":"..."`), so quoted prose and the skill text do not trip it; it names the branch `story-7`, so a deletion through a variable is not seen. A run that deletes a branch and never attempts a removal passes, and a command with an escaped double quote before the deletion is not seen. It does not prove the removal came first; the tool_order graders do. Bash writes are blocked in the run, so the first write fails whatever the agent does; the grader reads the Bash command text only. No end state, because Bash writes are blocked in the run.
