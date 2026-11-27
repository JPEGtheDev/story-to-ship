---
type: tool_used
tool: Agent
input_match: '(?i)(?:do.not|don.t|never|must\s+not|should\s+not|no\s+need\s+to)\s+(?:touch|edit|change|modify|alter|rewrite)\s+(?:any\s+|the\s+)?(?:other|further|additional|outside|besides|except|beyond|anything\s+else|files?\s+(?:not|outside|other|except|beyond))|\bonly\s+(?:(?:touch|edit|change|modify|update|fix)\s+)?(?:(?:the|these|those|two|2|three|\d+)\s+)*(?:files?|director(?:y|ies)|folder|[\w./-]+\.\w+|src|docs?|tests?|scripts?)\b|\boutside\b|\b(?:restrict|limit)\w*\b[^.]{0,80}?\bto\b|\b(?:stay|keep)\s+(?:inside|within)\b|\bleave\s+(?:the\s+)?(?:rest|others?|other|everything\s+else|anything\s+else)\b|\bbesides\b|\bexcept\b|\bbeyond\b'
min: 0
max: 0
---

Behavior: no Agent call fences the helper's work to named files or tells it to leave other files alone. The scope of the rename is the repo-wide search output, so an Agent input that limits the work to the two plan.md files, or forbids other files, is a violation. The check is a case-insensitive regex over the Agent tool input JSON; a match in any Agent input fails this grader, and no match passes it. Fence wordings it catches: "only" before a file, a list or the files; "do not|don't|never|must not" + touch/edit/change/modify + any other, outside, besides, except, beyond, anything else, or files not/other than; "outside"; "restrict|limit ... to"; "stay inside|within"; "leave the rest / others / everything else alone". Naming all the files the search finds, or saying to fix every remaining reference, is not a fence.

Pass: no Agent input fences the work to the two plan.md files or forbids other files. Fail: an Agent input says not to touch any other file, or limits the work to the two listed files.
