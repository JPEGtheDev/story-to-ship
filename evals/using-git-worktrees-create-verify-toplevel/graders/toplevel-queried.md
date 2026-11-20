---
type: tool_used
tool: Bash
input_match: '--show-toplevel'
min: 1
---

Behavior: the run asks git for the root of the checkout it is about to use (the verification in Create step 3). `--show-toplevel` is the git option that returns that root, so any form of the query that reads the root matches. A run that never queries the root fails. The check is a command form, and a judge is not needed to read it.
