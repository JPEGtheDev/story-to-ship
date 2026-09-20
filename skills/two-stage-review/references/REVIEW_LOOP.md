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
Stage 2: Dispatch `code-quality-reviewer.md` (code/config files) or `skill-reviewer.md` (skill `.md` files) -- one dispatch per group of at most two files that implement one change; one verdict block per file listed
    |
    +-- Any block REQUEST CHANGES, REJECT, or NEEDS WORK --> Implementer fixes. Re-dispatch Stage 2.
    |
    +-- Every block APPROVE, APPROVE WITH NITS, PASS, or PASS (size advisory)
         |
         v
Mark todo done once each nit from an APPROVE WITH NITS block is fixed, or declined with the reason recorded in the todo's status, and the size report from any PASS (size advisory) block is recorded there for the user's decision. Reload relevant skills (session-bootstrap refresh rule).
```

## Compact form

```
    Confirm canary: state "Canary confirmed: [Worktree: line from implementer output]"
              |
              v
    Stage 1: spec-compliance-reviewer.md -> GAPS? -> implementer fixes -> re-run Stage 1
              |
              v
    Stage 2: `code-quality-reviewer.md` or `skill-reviewer.md` by file type -- at most two files that implement one change per dispatch, one block per file -> any block REQUEST CHANGES / REJECT / NEEDS WORK? -> implementer fixes -> re-run Stage 2
              |
              v
    Mark todo done once each nit is fixed or declined with a recorded reason, and any size report is recorded for the user's decision. Reload skills (session-bootstrap refresh rule).
```
