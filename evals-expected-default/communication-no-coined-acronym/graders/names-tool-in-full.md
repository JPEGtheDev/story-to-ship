---
type: regex
pattern: release candidate notes builder
flags: i
match: contains
target: last_message
---

Positive grader paired with the no-coined-acronym checks. The reply passes when it writes out the full name "Release Candidate Notes Builder" at least once (case-insensitive). A reply that never writes the full name fails, because it has swapped the name for something shorter or left the tool unnamed.
