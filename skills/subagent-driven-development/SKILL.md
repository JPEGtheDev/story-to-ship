---
name: subagent-driven-development
license: MIT
description: Use when delegating implementation tasks, confirming theories, running parallel research, or reviewing completed work.
token-budget: over-budget by design — this is a large Tier 1 reference skill; compression requires a dedicated pass
---

## Iron Laws

```
YOU MUST DISPATCH BEFORE GUESSING — SUBAGENTS ARE CHEAP, WRONG ASSUMPTIONS ARE EXPENSIVE.
YOU MUST DISPATCH REVIEWERS AFTER EVERY TODO — SPEC COMPLIANCE FIRST, THEN CODE QUALITY.
No exceptions.
```

Violating the letter of these rules is violating the spirit of these rules.

**Announce at start:** "I am using the subagent-driven-development skill to [dispatch/review/confirm] [brief description]."

---

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
    +-- BLOCKED --> Invoke `three-amigos` Pivot Assessment (Ceremony 4). CONTINUE/REVISE AC/REVISE PLAN/ABANDON.
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
Pick up next todo.
    |
    v
(After all todos) → Check plan.md for `## Feature Specification`.
    If present (Discovery ran): Invoke `three-amigos` Signoff (Ceremony 5) BEFORE finishing-a-development-branch.
    If absent: Dispatch final code reviewer → finishing-a-development-branch
```

**Do not advance past any todo until both Stage 1 and Stage 2 are PASS/APPROVE.**

**Why these three gates exist:**
- **BLOCKED → Ceremony 4:** A blocker is a fork in the feature, not a delay. Assessing without Business and Tester perspectives risks silent scope changes.
- **DONE_WITH_CONCERNS → Ceremony 4:** Correctness or scope risk means delivered work may not match accepted criteria. Independent review before rework compounds cost.
- **After all todos → Ceremony 5:** Merging without Signoff means Business and Tester have not confirmed delivered behavior matches the Feature Specification.

---

## BEFORE PROCEEDING — SDD Dispatch Gate

Before dispatching any subagent:

1. The todo has a single, clear objective — no compound tasks bundled together.
2. The agent prompt includes all necessary context: file paths, constraints, and return format.
3. A worktree exists for this agent. **All agents — read-only and write-side alike — run in a worktree.** Run these checks before dispatch:

   ```bash
# 1. Ensure.worktrees / is gitignored before first use
   git check-ignore -q .worktrees || echo "ADD .worktrees TO .gitignore FIRST — stop here"

# 2. Create the worktree
   git worktree add .worktrees/agent-<name> -b agent/<name>
#If nonzero exit : log error, do NOT dispatch, surface to user.Common causes:
#- stale lock file : git worktree prune; then retry
#- path already exists : remove it or rename
#- branch name already registered : choose a different branch name

# 3. Verify path is a worktree(not the main repo root)
   git -C .worktrees/agent-<name> rev-parse --show-toplevel
#Output must be the absolute path of.worktrees / agent - < name> — NOT the main repo root

# 4. Write - side agents only — verify branch isolation
   git -C .worktrees/agent-<name> branch --show-current
#Output must NOT equal the current development branch(e.g.docs / execution - skill - overhaul or main)
#Read - only agents(explorer, researcher, reviewers, skeptic, postmortem) skip step 4.
   ```

   The worktree path confirmed above is the value to pass as `
{
    {
        WORKTREE_PATH
    }
}` in the agent prompt.

   **Why read-only agents also need worktrees:** The main context continues making commits while agents run. Without a worktree, a read-only agent observes a dirty working tree or partially-committed state — producing findings against a snapshot that no longer matches any branch. A worktree gives every agent a stable, isolated view at dispatch time.
4. If a pre-built template exists in `.github/agents/` for this task type: use it instead of injecting rules inline. Available templates: `implementer.md`, `skeptic.md`, `spec-compliance-reviewer.md`, `code-quality-reviewer.md`, `researcher.md`, `postmortem-reviewer.md`, `explorer.md`, `architecture-reviewer.md`, `infrastructure-reviewer.md`.
5. Agent type is correct for the task: explore for read-only research, code-review for analysis, general-purpose+worktree for file modifications, task for build/test/lint.

✓ All 5 met → dispatch the agent
✗ Any unmet → refine the todo, complete the prompt, create the worktree, or select the correct agent type before dispatching

---

## Canary

When applying this skill, before dispatching any agent, state this line in your response:

> `Worktree: [output of: git -C .worktrees/agent-<name> rev-parse --show-toplevel]`

This is the observable signal that step 3 of BEFORE PROCEEDING was executed, not skipped. A less powerful model can produce it mechanically: run step 3, paste the output.

**Note:** The canary raises the cost of skipping for compliant agents — it is not cryptographically bound to execution.

---

## Why Subagents Are Mandatory

Using subagents is discipline, not convenience:

- **Main context fills fast.** Once full, early instructions — including iron laws — are evicted. Keep context lean.
- **Subagents search without your bias.** They confirm or deny theories precisely because they lack your assumptions.
- **Parallel dispatch is faster.** Five explore agents simultaneously beat five sequential searches.
- **Subagents keep your diff clean.** Exploratory dead-ends and interim summaries never pollute main context.

---

## Empirical Evidence Mandate

**No theory, assumption, or belief is acceptable as a basis for action. Every claim must be backed by empirical evidence.**

**Acceptable evidence:**
- Code you read yourself — opened the file, saw the line
- Test output you ran yourself — executed the command, read the result
- Documentation cross-checked against actual source code
- A/B test results — implemented both, compared outcomes
- A targeted test written to prove or disprove the theory

**Not acceptable:**
- Memory ("I remember this worked")
- Confidence ("I'm sure the parser handles this")
- Assumption ("It should work because Y")
- Prior success ("It worked last time")

If you cannot point to a specific file, line, or test run — dispatch a subagent.

## Red Flags — STOP

These thoughts mean stop immediately:

| Thought | Required action |
|---------|----------------|
| "I think the issue is..." | Dispatch explore agent → read the actual code |
| "I dispatched a subagent — I'll also work on this while waiting" | STOP. The only permissible next call is read_agent. "I'll wait" is a binding constraint, not a statement of intent. |
| "This should work because..." | Run it. Read the output. |
| "I'm confident that..." | State the evidence, or dispatch to get it |
| "It probably passes..." | Run the test suite |
| "I remember that..." | Memory is always unverified — dispatch |
| "Based on how it usually works..." | Dispatch to confirm the actual behavior |
| "Dispatching a file-modifying agent without creating a worktree first" | STOP. Create the worktree and load `using-git-worktrees` before dispatch. |
| "A template exists but I'll build the prompt manually" | STOP. Use the pre-built template from `.github/agents/`. Do not reinvent it. |

---

## Dispatch Decision Table

| Task | Dispatch? | Type |
|------|-----------|------|
| Exploring unfamiliar APIs or libraries | Yes | explore agent |
| Scanning 5+ files for patterns | Yes | explore agent |
| Confirming a theory or assumption | Yes | explore agent |
| Validating a plan before implementation | Yes | Skeptic Agent (see writing-plans skill) |
| Code review (per-file) | Yes | code-review agent, 1 per file |
| Skill review | Yes | general-purpose + skill-reviewer skill |
| Multi-file implementation with file isolation | Yes | general-purpose + git worktree |
| Quick grep/glob in 1–2 files | No | do inline |
| Reading one known file | No | do inline |
| Single-step trivial command | No | do inline |

**Max 4 concurrent agents.** Beyond that, results compete for context and quality drops.

---

## Implementer Status Codes

Every subagent doing implementation work must report one of these five codes. Require it in every implementer prompt. Do not accept a response that does not include one.

| Code | Meaning | Your response |
|------|---------|---------------|
| `DONE` | Task complete, all verification passed, no concerns | Proceed to Stage 1 review |
| `DONE_WITH_CONCERNS` | Complete but flagged issues for dispatcher review | Read concerns. If concerns indicate a correctness or scope risk: Invoke Three Amigos Pivot Assessment (Ceremony 4). Otherwise proceed to canary + Stage 1. |
| `PARTIAL` | Partially complete — some items done and verified, rest not done | Verify completed portion. Create new todo(s) for remaining work. Proceed to Stage 1 for completed portion only. |
| `NEEDS_CONTEXT` | Cannot proceed — specific missing information listed | Provide the missing information. Re-dispatch. |
| `BLOCKED` | Cannot proceed — external dependency or environment issue described | Invoke Three Amigos Pivot Assessment (Ceremony 4). If unavailable: assess blocker, provide context if possible, otherwise escalate to user. |

---

## 2-Stage Review Protocol

Every completed implementation task requires two reviews in this order. This is mandatory — not optional — after every single todo.

```
Stage 1: Spec Compliance Review     ← ALWAYS FIRST (spec-compliance-reviewer.md)
Stage 2: Code Quality Review        ← ONLY after Stage 1 passes (code-quality-reviewer.md)
```

**Canary confirmation (before Stage 1):** Before proceeding to Stage 1 from any implementer result (DONE, DONE_WITH_CONCERNS, or PARTIAL), state: `Canary confirmed: [paste the Worktree: line from implementer output]`. If the canary line is absent from the implementer's output, the implementer did not follow BEFORE PROCEEDING — require skill reload and resubmit before dispatching Stage 1.

**Never skip Stage 1.** Code that doesn't meet the spec doesn't benefit from quality review.

**Worktree hygiene:** All implementer subagents MUST work in a worktree. Never dispatch an implementer to the main working tree. See Git Worktrees section below.

### Stage 1: Spec Compliance Review

Use `spec-compliance-reviewer.md` with full requirements and the implementation diff;
if GAPS
    are returned, implementer fixes and Stage 1 re -
                      runs before proceeding.

                      ## #Stage 2 : Code Quality Review

                                        Use `code -
                      quality - reviewer.md` — one agent per file changed;
if REQUEST CHANGES, implementer fixes and Stage 2 re-runs before proceeding.

See `references/REVIEW_PROTOCOL.md` for full protocol.

---

## Git Worktrees for Parallel Work

See the `using-git-worktrees` skill for full worktree lifecycle, commands, and safety gates.

---

## Model Selection

See `references/MODEL_SELECTION.md` for model tier table and concurrency rules.

---

## Delegation Quality Rules

- **One clear objective per subagent** — no multi-part briefs
- **Assign Problems Not Tasks:** delegate the outcome, not the steps — see the `writing-plans` skill — 'Assign Problems Not Tasks' principle.
- **State the return format explicitly** — tell it exactly what to give back
- **Provide complete context** — subagents are stateless
- **Fresh context per task** — never share session history;
it contaminates the subagent's search - **Accept findings unless they conflict with evidence you verified yourself* *
                                            -**If a subagent finds something unexpected : **treat it as a hypothesis; verify before acting

---

## Anti-Patterns

| Anti-pattern | Why it fails |
|---|---|
| "I'll check this myself" (for 5+ files) | Fills context, biased by assumptions |
| Skipping Stage 1 review because "it looks right" | Spec gaps ship;
quality review doesn't catch them | | One agent reviewing multiple large files | Coverage is shallow;
1 per file is the rule | | Acting on subagent findings without verifying |
    Subagents can be wrong — findings are hypotheses | | Dispatching without a clear return format |
    Agent returns noise | | Sharing full session history as context | Contaminates search;
subagent inherits your assumptions | | Reporting DONE before 2 - stage review | Code exists; correctness unverified |

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The subagent's description sounds right, I'll skip review" | Descriptions are summaries — they omit bugs. YOU MUST read the actual diff and dispatch the 2-stage review every time. |
| "This is just docs, no code review needed" | Documentation errors ship as silently as code bugs. Stage 1 spec compliance applies to every todo without exception. |
| "I verified one file, the rest are probably fine" | Each file requires its own code-quality reviewer. One agent per file is the rule — no extrapolation across files. |
| "The subagent said PASS, that's good enough" | A subagent's self-assessment is not a review. PASS from an implementer means dispatch Stage 1 — not skip it. |
| "I'll do a quick scan instead of dispatching a code-review agent" | A quick scan inherits your assumptions. A dispatched code-review agent does not. Dispatch the agent. |
| "The skill says use worktrees — I'll follow it when I remember" | The skill is not re-read before every dispatch. The worktree PATH in the prompt is the structural check — not re-reading the skill. No path in the prompt = no dispatch. Run the 4-step verification above first. |
| "I'll add the worktree after dispatching" | Worktrees MUST exist before dispatch. The agent needs the worktree path in its prompt — it cannot create its own isolation after the fact. |
| "I'll include the rules in the prompt instead of using a template" | Injected rules drift between sessions. Pre-built templates in `.github/agents/` are the single source of truth. Use them. |
| "I already know what to do — the researcher step is overhead" | YOU MUST dispatch the researcher.md template to confirm assumptions before acting. |
| "The two stages of review are redundant — I wrote the code carefully" | YOU MUST dispatch spec-compliance-reviewer.md first, then code-quality-reviewer.md. Writing carefully is not a substitute for independent review. |
| "I dispatched an audit subagent — that's a complete audit" | NO. Name every dimension the agent must check in the prompt. An unnamed dimension will not be checked. The audit prompt is the specification — an incomplete specification produces an incomplete audit. |
| "The concerns are nits — not a correctness or scope risk, so I'll skip Ceremony 4" | "Correctness or scope risk" is objective: does it affect behavior, API surface, or stated requirements? If yes, dispatch Ceremony 4. "Feels minor" is not a valid exemption. |
| "No `## Feature Specification` in plan.md — that means Ceremony 5 doesn't apply" | Absence of the section means Discovery never ran. That is a gap to surface, not a skip condition. Invoke Ceremony 5 before merge regardless. |

---

## Quick Reference

```
Task to delegate
    |
    +-- Read-only research? → dispatching-parallel-agents skill
    |
    +-- Needs file changes?
         |
         v
    Create worktree (ALWAYS — never dispatch to main working tree)
         |
         v
    Dispatch implementer (implementer.md)
         |
         v
    Status code: DONE / DONE_WITH_CONCERNS / PARTIAL / NEEDS_CONTEXT / BLOCKED
         |
         +-- NEEDS_CONTEXT → provide info, re-dispatch
         +-- BLOCKED → Pivot Assessment (Ceremony 4). If unavailable: assess, escalate
         +-- PARTIAL → verify completed, create todos for remaining, proceed to canary + Stage 1
         +-- DONE_WITH_CONCERNS → read concerns; correctness/scope risk? → Pivot Assessment (Ceremony 4); else proceed to canary + Stage 1
         +-- DONE
              |
              v
    Confirm canary: state "Canary confirmed: [Worktree: line from implementer output]"
              |
              v
    Stage 1: spec-compliance-reviewer.md → GAPS? → implementer fixes → re-run Stage 1
              |
              v
    Stage 2: code-quality-reviewer.md (1 per file) → REQUEST CHANGES? → implementer fixes → re-run Stage 2
              |
              v
    Mark todo done. Reload skills (session-bootstrap refresh rule).
    Pick up next todo.
              |
              v
    (After all todos) → check plan.md for `## Feature Specification`
        If present: Signoff (Ceremony 5) → finishing-a-development-branch
        If absent: final code review → finishing-a-development-branch
```
