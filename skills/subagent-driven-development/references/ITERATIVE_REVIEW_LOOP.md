# Iterative Review Loop -- Full Decision Tree

## When This Applies

Activate the outer loop when BOTH conditions are true:

1. The task has 2 or more todos (evaluate at PLAN TIME; re-evaluate at every todo transition — todo proliferation from PARTIAL returns can push a task over the threshold mid-execution)
2. At least one pending todo modifies: skill files (`*.md` inside `skills/`), code files (`.ts`, `.py`, `.rs`, or similar), or configuration that affects runtime behavior

Re-evaluate after each todo completes. If new todos are created (e.g., from a PARTIAL return or APPROVE WITH CONDITIONS), recount and re-check condition 2 before picking up the next todo.

## When It Does NOT Apply

- Single-todo tasks (inner SDD loop from SDD_LOOP.md is sufficient)
- Read-only research tasks (no file modifications)
- Plan-only changes (modifying plan.md only, no skill or code files touched)
- Tasks with 2+ todos where no todo modifies skill, code, or config files (the inner SDD loop per todo is sufficient; the outer loop's condition 2 is not met)
- Edits to ITERATIVE_REVIEW_LOOP.md itself (see Document-Edit Exemption section)

## Apply Filtered Changes

Run this procedure AFTER Stage 1 (spec-compliance-reviewer) AND Stage 2 (code-quality-reviewer for code and config files; skill-reviewer for skill `.md` files) both return their findings for a todo:

```
Step 1: Compile the full findings list
    Collect every finding from Stage 1 and Stage 2 into a single ordered list.
    |
    v
Step 2: Dispatch filtering agent
    Dispatch filtering-agent with this custom prompt:
    "You are a finding-categorization agent. You receive a numbered list of findings from
    Stage 1 (spec-compliance) and Stage 2 (code-quality) reviewers. For each finding,
    categorize it as:
      MANDATORY — correctness violation, spec gap, Iron Law breach, or factual error that
                  makes the output incorrect or unexecutable
      DEFERRED  — size alert below ideal max, style preference, low-priority improvement,
                  or preference without Iron Law backing
    Return: numbered list matching input order. Each item: [MANDATORY] or [DEFERRED] +
    one-sentence rationale."
    |
    v
Step 3: Apply ONLY the MANDATORY findings
    |
    v
Step 4: Log DEFERRED items
    Record each DEFERRED item with its rationale in self-assessment.md or plan.md.
    |
    v
Step 5: Dispatch confirm Skeptic
    Dispatch confirm-Skeptic with this custom prompt:
    "You are a confirm-Skeptic. You receive: (1) the MANDATORY findings list, (2) the
    actual changes made. For each MANDATORY finding, verify whether it was applied
    correctly. Return one of:
      APPROVE — all MANDATORY findings correctly applied
      APPROVE WITH CONDITIONS — findings partially applied; list each unresolved condition
      REJECT — one or more MANDATORY findings not applied; list which and why"
    |
    +-- APPROVE
    |       Proceed to next todo.
    |
    +-- APPROVE WITH CONDITIONS
    |       Address each listed condition.
    |       Re-dispatch confirm-Skeptic.
    |       Do not proceed until APPROVE is returned.
    |
    +-- REJECT
            Re-apply missing MANDATORY findings.
            Re-dispatch confirm-Skeptic.
            Do not proceed until APPROVE is returned.
```

## The Outer Loop

```
Phase 0: Plan
    |
    Load writing-plans skill.
    Draft todos: each must be single-objective (one clear deliverable per todo).
    Identify all files that will be modified.
    |
    v
Phase 1: Pre-implementation Skeptic
    |
    Dispatch Skeptic (skeptic.md) with full plan.
    |
    +-- REJECT
    |       Revise plan to address rejection reasons.
    |       Re-dispatch Skeptic.
    |       Do not proceed until APPROVE is returned.
    |
    +-- APPROVE WITH CONDITIONS
    |       Address each CONDITION in the plan.
    |       Re-dispatch Skeptic.
    |       Do not proceed until APPROVE is returned.
    |
    +-- APPROVE
            Proceed to Phase 2.
    |
    v
Phase 2: Per-todo execution (repeat for each todo)
    |
    Pick up next todo.
    |
    v
    Run inner SDD loop (SDD_LOOP.md) for this todo.
    |
    v
    After Stage 2 APPROVE:
    Run Apply Filtered Changes (see section above).
    |
    v
    No todos remain? --> Proceed to Phase 3.
    Todos remain?   --> Return to top of Phase 2 with next todo.
    |
    v
Phase 3: Post-loop termination
    |
    All todos done.
    Dispatch post-loop Skeptic (skeptic.md).
    |
    +-- APPROVE
    |       Termination condition met.
    |       Check plan.md for `## Feature Specification`:
    |         - Present (Discovery ran): Invoke `three-amigos` Signoff (Ceremony 5)
    |           BEFORE `finishing-a-development-branch`
    |         - Absent: Dispatch final code reviewer → `finishing-a-development-branch`
    |
    +-- APPROVE WITH CONDITIONS
    |       Create new todos for each CONDITION.
    |       Re-dispatch post-loop Skeptic after addressing all new todos.
    |       Loop does not terminate until APPROVE is returned.
    |
    +-- REJECT
            Evaluate rejection scope:
            |
            +-- Spec or scope issues (work does not match what was required)
            |       Revise plan.
            |       Re-enter at Phase 1 (new pre-implementation Skeptic).
            |
            +-- Implementation gaps only (MANDATORY findings not applied, items missed)
                    Create new todos for each gap.
                    Re-enter at Phase 2 directly.
```

## Termination Condition

The loop terminates when ALL of the following are true:

1. All todos are marked done.
2. Post-loop Skeptic returns **APPROVE** — not APPROVE WITH CONDITIONS, not REJECT.

After post-loop Skeptic APPROVE, the `## Feature Specification` check in plan.md governs the final step: if the section is present, Ceremony 5 (`three-amigos` Signoff) runs before `finishing-a-development-branch`; if absent, dispatch a final code reviewer and proceed directly to `finishing-a-development-branch`.

## Breakout Gate -- False Reviewer Claims

Before dispatching any fix agent in response to a "No other changes" GAPS finding or "extra changes found" claim from a spec-compliance reviewer:

1. Run `git diff <base-branch>..<worktree-branch> -- <file>` directly in the main context.
2. Compare the actual base diff against the reviewer's claimed extra changes.
3. If the claimed changes do NOT appear in the base diff: the reviewer used the wrong baseline (e.g., compared per-commit diffs within the worktree instead of base-to-HEAD). Do not dispatch a fix agent. Treat the "no other changes" check as PASS.

A reviewer finding extra changes that are absent from the base diff is a baseline confusion error. Dispatching a fix agent in response to a false claim creates a correction loop with no exit. Verify the diff directly before acting.

**Max iteration gate:** If the same file has received 2+ GAPS verdicts about "unrequested changes" with no confirming evidence in `git diff base..branch`, stop the loop. Verify the diff directly. Do not dispatch further fix agents until the base diff confirms the claimed changes exist.

## Document-Edit Exemption

Edits to ITERATIVE_REVIEW_LOOP.md itself follow the normal 2-stage SDD review:
- Stage 1: spec-compliance-reviewer
- Stage 2: code-quality-reviewer

Do NOT apply the outer loop to edits of this file. This prevents self-referential recursion.

The trade-off: structural errors in this document receive 2-stage review only, not Skeptic review. The post-loop Skeptic on the task that created or edited this file provides Skeptic coverage for those edits.
