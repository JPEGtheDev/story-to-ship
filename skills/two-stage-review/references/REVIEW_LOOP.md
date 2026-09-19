# Two-Stage Review Loop

This tree begins where the subagent-driven-development loop hands off an implementer result -- the DONE arrow,
the PARTIAL arrow, or a DONE_WITH_CONCERNS result without a correctness or scope risk -- to canary confirmation (the canary is the `Worktree:` line the implementer prints to prove it read its worktree path) and the two review stages.

```
Confirm canary: state "Canary confirmed: [Worktree: line from implementer output]"
         |
         v
Stage 1: Dispatch spec-compliance-reviewer (spec-compliance-reviewer.md)
    |
    +-- GAPS --> Implementer fixes gaps. Re-dispatch Stage 1.
    |
    +-- PASS
         |
         v
Stage 2: Dispatch `code-quality-reviewer.md` (code/config files) or `skill-reviewer.md` (skill `.md` files) -- one per file
    |
    +-- REQUEST CHANGES --> Implementer fixes. Re-dispatch Stage 2.
    |
    +-- APPROVE or APPROVE WITH NITS
         |
         v
Mark todo done. Reload relevant skills (session-bootstrap refresh rule).
```

## Compact form

```
    Confirm canary: state "Canary confirmed: [Worktree: line from implementer output]"
              |
              v
    Stage 1: spec-compliance-reviewer.md -> GAPS? -> implementer fixes -> re-run Stage 1
              |
              v
    Stage 2: `code-quality-reviewer.md` (code/config) or `skill-reviewer.md` (skill .md files) -- 1 per file -> REQUEST CHANGES? -> implementer fixes -> re-run Stage 2
              |
              v
    Mark todo done. Reload skills (session-bootstrap refresh rule).
```
