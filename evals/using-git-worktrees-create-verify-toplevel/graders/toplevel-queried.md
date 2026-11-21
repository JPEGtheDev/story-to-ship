---
type: tool_used
tool: Bash
input_match: '--show-toplevel'
min: 1
---

Behavior: the run asks git for its top-level root (the verification in Create step 3). `--show-toplevel` is the git option that returns that root, so any form of the query that reads the root matches. A run that never queries the root fails. This grader checks only that a root query ran; a bare query in the main checkout also matches. Whether the query targets the checkout the run is about to dispatch is checked by the judge grader toplevel-compared-before-dispatch, not here. The check is a command form, and a judge is not needed to read it.
