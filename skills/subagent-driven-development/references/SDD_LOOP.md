# Subagent-Driven Development (SDD) Loop -- Full Decision Tree

## The SDD Loop

```
Pick up todo
    |
    v
Dispatch implementer subagent (implementer.md)
    |
    v
Implementer returns status code
    |
    +-- NEEDS_CONTEXT --> Provide the missing information. Re-dispatch.
    |
    +-- BLOCKED --> Invoke `three-amigos` Pivot Assessment (Ceremony 4). CONTINUE/REVISE Acceptance Criteria (AC)/REVISE PLAN/ABANDON.
                    If no Three Amigos available: Assess. Provide context if possible. Otherwise escalate to user.
    |
    +-- PARTIAL --> Read completed/remaining split.
    |                Verify what was completed (build + tests).
    |                Create new todo(s) for remaining work.
    |                Proceed to review for the completed portion only.
    |
    +-- DONE_WITH_CONCERNS --> Read concerns. If concerns indicate a correctness or scope risk:
    |                          Invoke `three-amigos` Pivot Assessment (Ceremony 4).
    |                          Otherwise proceed to canary + Stage 1 review.
    |
    +-- DONE
         |
         v
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
Stage 2: Dispatch code-quality-reviewer (code-quality-reviewer.md)
    |
    +-- REQUEST CHANGES --> Implementer fixes. Re-dispatch Stage 2.
    |
    +-- APPROVE or APPROVE WITH NITS
         |
         v
Mark todo done. Reload relevant skills (session-bootstrap refresh rule).
After each push: check for new automated review threads before picking up the next todo. Do not wait for the user to surface review feedback.
If current pending-todo count >= 1 AND at least one pending todo modifies skill or code files: run Apply Filtered Changes from ITERATIVE_REVIEW_LOOP.md before picking up the next todo.
Pick up next todo.
    |
    v
(After all todos) -> Check plan.md for `## Feature Specification`.
    If present (Discovery ran): Invoke `three-amigos` Signoff (Ceremony 5) BEFORE finishing-a-development-branch.
    If absent: Dispatch final code reviewer -> finishing-a-development-branch
```

## Why These Three Gates Exist

- **BLOCKED -> Ceremony 4:** A blocker is a fork in the feature, not a delay. Assessing without Business and Tester perspectives risks silent scope changes.
- **DONE_WITH_CONCERNS -> Ceremony 4:** Correctness or scope risk means delivered work may not match accepted criteria. Independent review before rework compounds cost.
- **After all todos -> Ceremony 5 (Discovery ran) / final code reviewer (Discovery absent):** Merging without Signoff means Business and Tester have not confirmed delivered behavior matches the Feature Specification.

## Quick Reference Flowchart

```
Task to delegate
    |
    +-- Read-only research? -> dispatching-parallel-agents skill
    |
    +-- Needs file changes?
         |
         v
    Create worktree (ALWAYS -- never dispatch to main working tree)
         |
         v
    Dispatch implementer (implementer.md)
         |
         v
    Status code: DONE / DONE_WITH_CONCERNS / PARTIAL / NEEDS_CONTEXT / BLOCKED
         |
         +-- NEEDS_CONTEXT -> provide info, re-dispatch
         +-- BLOCKED -> Pivot Assessment (Ceremony 4). If unavailable: assess, escalate
         +-- PARTIAL -> verify completed, create todos for remaining, proceed to canary + Stage 1
         +-- DONE_WITH_CONCERNS -> read concerns; correctness/scope risk? -> Pivot Assessment (Ceremony 4); else proceed to canary + Stage 1
         +-- DONE
              |
              v
    Confirm canary: state "Canary confirmed: [Worktree: line from implementer output]"
              |
              v
    Stage 1: spec-compliance-reviewer.md -> GAPS? -> implementer fixes -> re-run Stage 1
              |
              v
    Stage 2: code-quality-reviewer.md (1 per file) -> REQUEST CHANGES? -> implementer fixes -> re-run Stage 2
              |
              v
    Mark todo done. Reload skills (session-bootstrap refresh rule).
    After each push: check for new automated review threads before picking up the next todo.
    If current pending-todo count >= 1 AND at least one pending todo modifies skill or code files: run Apply Filtered Changes from ITERATIVE_REVIEW_LOOP.md before picking up the next todo.
    Pick up next todo.
              |
              v
    (After all todos) -> check plan.md for `## Feature Specification`
        If present: Signoff (Ceremony 5) -> finishing-a-development-branch
        If absent: final code review -> finishing-a-development-branch
```
