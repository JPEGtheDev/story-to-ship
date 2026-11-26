---
type: regex
pattern: might be worth considering|could potentially|may need to be addressed|one option would be|i'?m not sure but maybe|it seems like
flags: i
match: not_contains
target: last_message
---

The final message states its recommendation without the hedge phrases the communication skill replaces with "do X because Y". A reply containing any of these phrases fails.
