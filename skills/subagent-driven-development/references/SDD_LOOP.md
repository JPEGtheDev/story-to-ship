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
    +-- BLOCKED --> Prompt the owner in this turn (execution skill, serious blockers), then invoke `three-amigos` Pivot Assessment (Ceremony 4) to shape the options: CONTINUE/REVISE Acceptance Criteria (AC)/REVISE PLAN/ABANDON.
    |               The verdict shapes the options; it is not authorization to act before the owner answers.
    |               If no Three Amigos available: the prompt is the escalation.
    |
    +-- PARTIAL --> Read completed/remaining split.
    |                Verify what was completed (build + tests).
    |                Create new todo(s) for remaining work.
    |                Load two-stage-review (canary + Stage 1) for the completed portion only.
    |
    +-- DONE_WITH_CONCERNS --> Read concerns. Correctness or scope risk: prompt the owner in this turn,
    |                          then invoke `three-amigos` Pivot Assessment (Ceremony 4).
    |                          The verdict shapes the options; it is not authorization to act before the owner answers.
    |                          Otherwise load two-stage-review (canary + Stage 1).
    |
    +-- DONE
         |
         v
Load two-stage-review -> handle status code, canary, Stage 1, Stage 2 -> Mark todo done
After each push: check for new automated review threads before picking up the next todo. Do not wait for the user to surface review feedback.
Pick up next todo.
    |
    v
(After all todos) -> Check plan.md for `## Feature Specification`.
    If present (Discovery ran): Invoke `three-amigos` Signoff (Ceremony 5) BEFORE finishing-a-development-branch.
    If absent: Dispatch final code reviewer -> finishing-a-development-branch
```

## Why These Three Gates Exist

- **BLOCKED -> owner prompt -> Ceremony 4:** A blocker is a fork in the feature, not a delay. The owner hears about the fork in their own feature before the agent spends further budget on it; Ceremony 4 then checks for silent scope changes with Business and Tester perspectives.
- **DONE_WITH_CONCERNS -> owner prompt -> Ceremony 4:** Correctness or scope risk means delivered work may not match accepted criteria. The owner hears about the risk before rework or Ceremony 4 compounds the cost of being wrong. The verdict shapes the options; it is not authorization to act before the owner answers.
- **After all todos -> Ceremony 5 (Discovery ran) / final code reviewer (Discovery absent):** Merging without Signoff means Business and Tester have not confirmed delivered behavior matches the Feature Specification.
- **Enforcement is procedural/self-check:** the checkable signal is a transcript showing a BLOCKED or risk-carrying DONE_WITH_CONCERNS result followed by a ceremony dispatch or continued work with no owner prompt in that same turn. The postmortem-reviewer template's Blocker-disclosure audit row checks this after the fact; no live detector exists.

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
         +-- BLOCKED -> prompt the owner in this turn, then Pivot Assessment (Ceremony 4); if unavailable, the prompt is the escalation
         +-- PARTIAL -> verify completed, create todos for remaining, load two-stage-review (canary + Stage 1)
         +-- DONE_WITH_CONCERNS -> read concerns; correctness/scope risk? -> prompt the owner, then Pivot Assessment (Ceremony 4; not authorization to act); else load two-stage-review (canary + Stage 1)
         +-- DONE
              |
              v
    Load two-stage-review -> handle status code, canary, Stage 1, Stage 2 -> Mark todo done
    After each push: check for new automated review threads before picking up the next todo.
    Pick up next todo.
              |
              v
    (After all todos) -> check plan.md for `## Feature Specification`
        If present: Signoff (Ceremony 5) -> finishing-a-development-branch
        If absent: final code review -> finishing-a-development-branch
```
