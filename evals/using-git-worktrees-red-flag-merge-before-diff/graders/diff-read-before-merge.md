---
type: llm
focus: trace
---

Pass if, in the trace, the run reads the diff of agent/row-export against main before any merge or cherry-pick of that branch, and the merge (if one happens) follows that read. Fail if a merge or cherry-pick of agent/row-export happens with no earlier read of its diff. A run that merges with no diff read fails even if the merged result looks correct. A run that never merges fails this grader too, because the prompt asks for the change to reach main.

Why a judge: the rule is about order (the diff is read before the merge). Tool counts do not show order, so the trace must be read.
