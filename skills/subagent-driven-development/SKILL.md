---
name: subagent-driven-development
license: MIT
description: Use when delegating implementation tasks, confirming theories, running parallel research, or reviewing completed work.
---


## Iron Laws

```
YOU MUST DISPATCH BEFORE GUESSING -- SUBAGENTS ARE CHEAP, WRONG ASSUMPTIONS ARE EXPENSIVE.
YOU MUST DISPATCH REVIEWERS AFTER EVERY TODO -- SPEC COMPLIANCE FIRST, THEN CODE QUALITY.
No exceptions.
```

Violating the letter of these rules is violating the spirit of these rules.

**Announce at start:** "I am using the subagent-driven-development skill to [dispatch/review/confirm] [brief description]."

---

## Workflow

Pick up todo -> Dispatch implementer -> Handle status code -> Stage 1 spec review -> Stage 2 quality review -> Mark done.

**Status code branches:**
- `NEEDS_CONTEXT` -> Provide missing info. Re-dispatch.
- `BLOCKED` -> **Invoke Three Amigos Pivot Assessment (Ceremony 4).** If unavailable: assess, escalate to user.
- `PARTIAL` -> Verify completed portion. Create new todo(s) for remaining. Stage 1 for completed portion only.
- `DONE_WITH_CONCERNS` -> Read concerns. Correctness or scope risk? -> **Ceremony 4.** Otherwise -> canary + Stage 1.
- `DONE` -> Canary confirmation -> Stage 1 -> Stage 2 -> mark done.

**After all todos:** Check plan.md for `## Feature Specification`. Present -> **Invoke Signoff (Ceremony 5)** before `finishing-a-development-branch`. Absent -> dispatch final code reviewer -> `finishing-a-development-branch`.

**Do not advance past any todo until both Stage 1 and Stage 2 are PASS/APPROVE.**

See `references/SDD_LOOP.md` for the full decision tree with complete ASCII flow.

---

## BEFORE PROCEEDING

Before dispatching any subagent:

1. The todo has a single, clear objective -- no compound tasks bundled together.
2. The agent prompt includes all necessary context: file paths, constraints, and return format.
3. A worktree exists for this agent. **All agents -- read-only and write-side alike -- run in a worktree.**
   See `references/WORKTREE_SETUP.md` for setup commands, verification steps, and the `{{WORKTREE_PATH}}` value.
4. If a pre-built template exists in `.claude/agents/` for this task type: use it instead of injecting rules inline. Available templates: `implementer.md`, `skeptic.md`, `spec-compliance-reviewer.md`, `code-quality-reviewer.md`, `researcher.md`, `postmortem-reviewer.md`, `explorer.md`, `architecture-reviewer.md`, `infrastructure-reviewer.md`.
5. Agent type is correct for the task: explore for read-only research, code-review for analysis, general-purpose+worktree for file modifications, task for build/test/lint.

[+] All 5 met -> dispatch the agent
[-] Any unmet -> refine the todo, complete the prompt, create the worktree, or select the correct agent type before dispatching

---

## Canary

When applying this skill, before dispatching any agent, state this line in your response:

> `Worktree: [output of: git -C .worktrees/agent-<name> rev-parse --show-toplevel]`

This is the observable signal that step 3 of BEFORE PROCEEDING was executed, not skipped. A less powerful model can produce it mechanically: run step 3, paste the output.

**Note:** The canary raises the cost of skipping for compliant agents -- it is not cryptographically bound to execution.

---

## Red Flags -- STOP

These thoughts mean stop immediately:

| Thought | Required action |
|---------|----------------|
| "I think the issue is..." | Dispatch explore agent -> read the actual code |
| "I dispatched a subagent -- I'll also work on this while waiting" | STOP. The only permissible next call is read_agent. "I'll wait" is a binding constraint, not a statement of intent. |
| "This should work because..." | Run it. Read the output. |
| "I'm confident that..." | State the evidence, or dispatch to get it |
| "It probably passes..." | Run the test suite |
| "I remember that..." | Memory is always unverified -- dispatch |
| "Based on how it usually works..." | Dispatch to confirm the actual behavior |
| "Dispatching a file-modifying agent without creating a worktree first" | STOP. Create the worktree and load `using-git-worktrees` before dispatch. |
| "About to create a worktree without `using-git-worktrees` loaded" | STOP. Load `using-git-worktrees` first -- every time, without exception. The session-bootstrap On Start table maps "Parallel agent work / A/B testing" to this skill. Creating worktrees without it is a retroactive-load violation. |
| "A template exists but I'll build the prompt manually" | STOP. Use the pre-built template from `.claude/agents/`. Do not reinvent it. |
| "These two todos form a 'Phase N' -- I'll dispatch them together" | STOP. Phase is a planning concept, not a dispatch unit. Bundling todos as a phase bypasses the one-clear-objective gate (BEFORE PROCEEDING item 1). Split unconditionally before dispatch. |

---

## Dispatch Decision Table

| Task | Dispatch? | Type |
|------|-----------|------|
| Exploring unfamiliar APIs or libraries | Yes | explore agent |
| Scanning 5+ files for patterns | Yes | explore agent |
| Confirming a theory or assumption | Yes | explore agent |
| Validating a plan before implementation | Yes | Skeptic Agent (see writing-plans skill) |
| Code review (per-file) | Yes | code-review agent, 1 per file |
| Skill review | Yes | `writing-skills` + `skill-reviewer` agent template |
| Multi-file implementation with file isolation | Yes | general-purpose + git worktree |
| Quick grep/glob in 1-2 files | No | do inline (read-only tasks only -- implementation todos require subagent dispatch regardless of estimated size) |
| Reading one known file | No | do inline |
| Single-step trivial command | No | do inline (read-only tasks only, AND if the command reads file content, the file must be under 2 000 tokens -- larger files require explore agent dispatch; implementation todos require subagent dispatch regardless of size) |

**Max 4 concurrent agents.** Beyond that, results compete for context and quality drops.

---

## Implementer Status Codes

Every subagent doing implementation work must report one of these five codes. Require it in every implementer prompt. Do not accept a response that does not include one.

| Code | Meaning | Your response |
|------|---------|---------------|
| `DONE` | Task complete, all verification passed, no concerns | Proceed to Stage 1 review |
| `DONE_WITH_CONCERNS` | Complete but flagged issues for dispatcher review | Read concerns. If concerns indicate a correctness or scope risk: Invoke Three Amigos Pivot Assessment (Ceremony 4). Otherwise proceed to canary + Stage 1. |
| `PARTIAL` | Partially complete -- some items done and verified, rest not done | Verify completed portion. Create new todo(s) for remaining work. Proceed to Stage 1 for completed portion only. |
| `NEEDS_CONTEXT` | Cannot proceed -- specific missing information listed | Provide the missing information. Re-dispatch. |
| `BLOCKED` | Cannot proceed -- external dependency or environment issue described | Invoke Three Amigos Pivot Assessment (Ceremony 4). If unavailable: assess blocker, provide context if possible, otherwise escalate to user. |

---

## 2-Stage Review Protocol

Every completed implementation task requires two reviews in this order. This is mandatory -- not optional -- after every single todo.

```
Stage 1: Spec Compliance Review     <- ALWAYS FIRST (spec-compliance-reviewer.md)
Stage 2: Code Quality Review        <- ONLY after Stage 1 passes (code-quality-reviewer.md)
```

**Canary confirmation (before Stage 1):** Before proceeding to Stage 1 from any implementer result (DONE, DONE_WITH_CONCERNS, or PARTIAL), state: `Canary confirmed: [paste the Worktree: line from implementer output]`. If the canary line is absent from the implementer's output, the implementer did not follow BEFORE PROCEEDING -- require skill reload and resubmit before dispatching Stage 1.

**Never skip Stage 1.** Code that doesn't meet the spec doesn't benefit from quality review.

**Worktree hygiene:** All implementer subagents MUST work in a worktree. Never dispatch an implementer to the main working tree.

**Stage 1:** Use `spec-compliance-reviewer.md` with full requirements and the implementation diff. If GAPS returned: implementer fixes gaps, Stage 1 re-runs before proceeding to Stage 2.

**Stage 2:** Use `code-quality-reviewer.md` -- one agent per file changed. If REQUEST CHANGES: implementer fixes, Stage 2 re-runs before proceeding.

See `references/REVIEW_PROTOCOL.md` for full protocol details.

---

## Git Worktrees for Parallel Work

See the `using-git-worktrees` skill for full worktree lifecycle, commands, and safety gates.

---

## Model Selection

See `references/MODEL_SELECTION.md` for model tier table and concurrency rules.

---

## Rationale, Evidence, Delegation, Anti-Patterns

See `references/SDD_RATIONALE.md` for: why subagents are mandatory, the empirical evidence mandate, delegation quality rules, and anti-patterns.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The subagent's description sounds right, I'll skip review" | Descriptions are summaries -- they omit bugs. YOU MUST read the actual diff and dispatch the 2-stage review every time. |
| "This is just docs, no code review needed" | Documentation errors ship as silently as code bugs. Stage 1 spec compliance applies to every todo without exception. |
| "I verified one file, the rest are probably fine" | Each file requires its own code-quality reviewer. One agent per file is the rule -- no extrapolation across files. |
| "The subagent said PASS, that's good enough" | A subagent's self-assessment is not a review. PASS from an implementer means dispatch Stage 1 -- not skip it. |
| "I'll do a quick scan instead of dispatching a code-review agent" | A quick scan inherits your assumptions. A dispatched code-review agent does not. Dispatch the agent. |
| "The skill says use worktrees -- I'll follow it when I remember" | The skill is not re-read before every dispatch. The worktree PATH in the prompt is the structural check -- not re-reading the skill. No path in the prompt = no dispatch. Run the 4-step verification above first. |
| "I'll add the worktree after dispatching" | Worktrees MUST exist before dispatch. The agent needs the worktree path in its prompt -- it cannot create its own isolation after the fact. |
| "I'll include the rules in the prompt instead of using a template" | Injected rules drift between sessions. Pre-built templates in `.claude/agents/` are the single source of truth. Use them. |
| "These todos form a natural 'Phase N' -- I'll dispatch them together" | Phase is a planning label, not a dispatch unit. Compound dispatch bypasses the sizing gate -- the outlier agent cost is proportional to the bundled scope. Split unconditionally. One todo = one dispatch, always. |
| "I already know what to do -- the researcher step is overhead" | YOU MUST dispatch the researcher.md template to confirm assumptions before acting. |
| "The two stages of review are redundant -- I wrote the code carefully" | YOU MUST dispatch spec-compliance-reviewer.md first, then code-quality-reviewer.md. Writing carefully is not a substitute for independent review. |
| "I dispatched an audit subagent -- that's a complete audit" | NO. Name every dimension the agent must check in the prompt. An unnamed dimension will not be checked. The audit prompt is the specification -- an incomplete specification produces an incomplete audit. |
| "The concerns are nits -- not a correctness or scope risk, so I'll skip Ceremony 4" | "Correctness or scope risk" is objective: does it affect behavior, API surface, or stated requirements? If yes, dispatch Ceremony 4. "Feels minor" is not a valid exemption. |
| "No `## Feature Specification` in plan.md -- that means Ceremony 5 doesn't apply" | Absence signals Discovery never ran. If Discovery was required for this task (new or unclear Acceptance Criteria (AC)), surface that gap to the user before dispatching the final code reviewer. Do not silently skip Three Amigos routing. |
| "Todo is short -- I'll do it inline" | BANNED. All todos require implementer subagent dispatch regardless of estimated size. Size assessment before execution is speculation -- the outlier case always exists. |
