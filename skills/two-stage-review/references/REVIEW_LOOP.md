# Two-Stage Review Loop

This tree begins where the subagent-driven-development loop hands off an implementer result -- the DONE arrow,
the PARTIAL arrow, or a DONE_WITH_CONCERNS result without a correctness or scope risk -- to canary confirmation (the canary is the `Worktree:` line the implementer prints to prove it read its worktree path) and the two review stages.

The fix-round cap and the unreadable-verdict rule are defined in `SKILL.md` (Fix-round cap, Unreadable verdict); the branches below apply them and do not restate them in full.

```
Confirm canary: state "Canary confirmed: [Worktree: line from implementer output]"
         |
         v
Check the implementer result for a `Limitations:` line
    |
    +-- Absent --> Resubmit to the implementer for it; never infer "none".
    |
    +-- Present
         |
         v
Stage 1: Dispatch spec-compliance-reviewer (spec-compliance-reviewer.md)
    |
    +-- Verdict missing or not spelled as the replying reviewer's own template spells it (unreadable, off-template) --> counts as not passed. Re-dispatch once, resuming the same reviewer when possible; this is not a fix round. If the reply is unreadable again --> stop and prompt the owner with the raw reply and the verdict values that reviewer's template defines.
    |
    +-- GAPS --> Implementer fixes gaps (one fix round; at most 3 fix rounds per todo, counted across both stages). Re-dispatch Stage 1. A GAPS that would need a fourth fix round --> stop and prompt the owner with the open findings.
    |
    +-- PASS
         |
         +-- Todo not risky (no Files entry under .github/, hooks/ or agents/, and no file also named by another todo's Files list) --> no Stage 2 for this todo; go to Mark todo done
         |
         +-- Todo risky (a Files entry under .github/, hooks/ or agents/, or a file another todo's Files list also names) --> Stage 2 right after Stage 1, below
         |
         v
Stage 2 (risky todo only; the whole-branch pass after the last todo is below): Dispatch `code-quality-reviewer.md` (code/config files) or `skill-reviewer.md` (skill `.md` files) -- one dispatch per group of at most two files that implement one change; one verdict block per file listed
    |
    +-- Verdict missing or not spelled as the replying reviewer's own template spells it (unreadable, off-template) in any block --> counts as not passed. Re-dispatch once, resuming the same reviewer when possible; this is not a fix round. If the reply is unreadable again --> stop and prompt the owner with the raw reply and the verdict values that reviewer's template defines.
    |
    +-- Any block REQUEST CHANGES, REJECT, or NEEDS WORK --> Implementer fixes (one fix round, counted per todo across both stages; a Stage 1 re-run forced by this fix belongs to the same round). Re-dispatch Stage 2. A not-passed verdict that would need a fourth fix round --> stop and prompt the owner with the open findings.
    |
    +-- Every block APPROVE, APPROVE WITH NITS, PASS, or PASS (size advisory)
         |
         v
Mark todo done once each nit from an APPROVE WITH NITS block is fixed, or declined with the reason recorded in the todo's status, and the size report from any PASS (size advisory) block is recorded there for the user's decision. Reload relevant skills (session-bootstrap refresh rule).
         |
         v
After the last todo (the whole-branch pass; it is not run per todo):
CI on the feature branch head: red --> fix CI first (a CI fix is not a Stage 2 cycle) --> green
         |
         v
Stage 2 over the branch diff (`git diff --name-only origin/main...HEAD`, minus any file whose latest change came from a risky todo that already passed its Stage 2, grouped as in the Stage 2 rule above: at most two files per dispatch, one block per file; same verdict-block rules, including the unreadable-verdict re-dispatch)
    |
    +-- Every block APPROVE, APPROVE WITH NITS, PASS, or PASS (size advisory) --> whole-branch pass complete once each nit is fixed or declined with a recorded reason, and any size report is recorded for the owner's decision
    |
    +-- Any block REQUEST CHANGES, REJECT, or NEEDS WORK --> one whole-branch cycle (at most 3 cycles, a count separate from the per-todo fix-round cap): fresh implementer fixes -> re-check by the same reviewer instance covering the fix round's changed hunks plus CI green on the updated head -> next cycle. A cycle that would be the fourth --> stop and prompt the owner with the open findings.
```

## Compact form

```
    Confirm canary: state "Canary confirmed: [Worktree: line from implementer output]"
              |
              v
    Limitations: the implementer result must carry a `Limitations:` line -> absent? -> resubmit for it, never infer "none"
              |
              v
    Verdict check at both stages below: a verdict that is missing or not spelled as the replying reviewer's own template spells it (unreadable, off-template) counts as not passed -> re-dispatch once, resuming the same reviewer when possible, not a fix round -> unreadable again -> stop and prompt the owner with the raw reply and the verdict values that reviewer's template defines
              |
              v
    Stage 1: spec-compliance-reviewer.md -> GAPS? -> implementer fixes -> re-run Stage 1 (fix round, at most 3 fix rounds per todo across both stages; a GAPS needing a fourth fix round -> stop and prompt the owner with the open findings)
              |
              v
    Stage 2 (risky todo only, right after Stage 1 PASS; other todos go straight to mark-done): `code-quality-reviewer.md` or `skill-reviewer.md` by file type -- at most two files that implement one change per dispatch, one block per file -> any block REQUEST CHANGES / REJECT / NEEDS WORK? -> implementer fixes -> re-run Stage 2 (same fix round count per todo; a Stage 1 re-run forced by this fix belongs to the same round; a not-passed verdict needing a fourth fix round -> stop and prompt the owner with the open findings)
              |
              v
    Mark todo done once each nit is fixed or declined with a recorded reason, and any size report is recorded for the user's decision. Reload skills (session-bootstrap refresh rule).
              |
              v
    After the last todo (whole-branch pass): CI red -> fix CI first -> CI green -> Stage 2 over `git diff --name-only origin/main...HEAD` minus files last changed by a risky todo that passed its Stage 2 (same verdict rules) -> any block REQUEST CHANGES / REJECT / NEEDS WORK? -> fresh implementer fixes (a finding charges the fix rounds of the todo whose Files list names the file) -> re-check changed hunks + CI green -> next cycle (at most 3 whole-branch cycles, separate from the per-todo fix-round cap; a fourth cycle -> stop and prompt the owner with the open findings)
```
