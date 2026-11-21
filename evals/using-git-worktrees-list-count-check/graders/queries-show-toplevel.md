---
type: tool_used
tool: Bash
input_match: 'rev-parse\s+--show-toplevel'
min: 1
---

Behavior: the run asks git for its top-level root with `git rev-parse --show-toplevel`. That root is the answer the rule asks for. The check is a command form, so no judge is needed.

Limitation: this grader checks only that a root query ran. It does not check that the run compares the root with the expected path `.worktrees/csv-export-todo1`. The comparison is not checked here. Order is not checked by this grader either, so a root query run after the dispatch also passes.
