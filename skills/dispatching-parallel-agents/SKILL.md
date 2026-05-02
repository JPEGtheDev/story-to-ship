---
name: dispatching-parallel-agents
license: MIT
description: Use when multiple independent read-only research tasks can run simultaneously, or when you need to fan out investigation across many files or hypotheses.
---

## Iron Law

```
YOU MUST RESTRICT PARALLEL AGENTS TO READ-ONLY WORK ONLY.
YOU MUST PROVIDE EACH WRITE AGENT WITH ITS OWN ISOLATED WORKTREE — ONE WORKTREE PER AGENT.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the dispatching-parallel-agents skill to [describe what is being parallelized]."

---

## The Team Lead Model

When dispatching parallel agents, the main agent acts as a **team lead**:

| Role | Actor | Responsibilities |
|------|-------|-----------------|
| **Manager** | User / human | Receives validated, aggregated results. Never receives raw agent output directly. |
| **Team lead** | Main agent (you) | Orchestrates agents, tracks work status, validates and cross-checks all results, presents conclusions to the user |
| **Team members** | Subagents | Execute specific, isolated tasks. Return structured results to the team lead only. |

**What the team lead does between dispatch and presentation:**
1. Collect all agent results before acting on any
2. Cross-check conflicts against source files directly
3. Aggregate findings into a coherent summary
4. Remove noise — do not forward raw agent output upstream
5. Present conclusions to the user: "Agents found X. I verified Y at [file:line]. Conclusion: Z."

**What the team lead never does:**
- Forward a finding to the user without verifying it first
- Let two agents report contradictory findings without resolving the conflict
- Report "agents completed" without summarizing what was learned

### Caching Agent Responses for Postmortems

Save the raw structured response from every dispatched agent before aggregating:

```
scratch/<session-id>/agent-<name>-<utc-timestamp>.md
```

Example: `scratch/58b87305/agent-spec-reviewer-20260418T230000Z.md`

These cached responses serve as evidence in postmortems — they show what each agent found, what the team lead accepted, and what was discarded. Without the raw responses, a postmortem cannot determine whether a bad conclusion came from a bad agent or bad aggregation.

`scratch/` is cleaned manually. Do not delete session caches during a session.

---

## Agent Type Selection

Before dispatching any agent, select the correct type. The wrong type wastes context and produces lower-quality output.

| Task type | Correct agent | Wrong choice |
|-----------|--------------|--------------|
| Read-only research across 3+ files — patterns, symbols, hypotheses | `explore` | `general-purpose` |
| Code compliance, style, logic, or spec review | `code-review` | `general-purpose` |
| Multi-step implementation with file modifications | `general-purpose` + worktree | `explore` |
| Build, test, or lint execution — success/failure result only | `task` | `general-purpose` |
| Any read-only + write combination | Separate explore and general-purpose agents | One general-purpose for everything |

**Routing rule:** Use the most constrained agent type that can complete the job. `general-purpose` can do everything — which means it accumulates context, produces serial output, and contaminates findings with session assumptions for work that a constrained agent would complete faster and cleaner.

---

## When to Parallelize

Dispatch agents in parallel when ALL of the following are true:

1. Tasks are **independent** — no agent needs the output of another to start
2. Tasks are **read-only** OR each write agent has its own isolated worktree
3. Each task has a **single clear objective** — multi-part briefs produce noise

**Good candidates for parallelization:**
- Scanning multiple files for a pattern
- Confirming/denying multiple independent hypotheses simultaneously
- Researching 3+ unrelated topics at once
- Running multiple spec-compliance or code-quality reviews simultaneously

**Do NOT parallelize:**
- Tasks where Agent B needs Agent A's output
- Multiple write agents on the same files (race condition)
- Tasks requiring shared state or coordinated decisions

BEFORE DISPATCHING PARALLEL AGENTS, verify:
1. All tasks are truly independent — no agent needs another agent's output to start
2. Return format is explicitly defined for every agent before dispatch
3. No more than 4 agents in flight on Standard accounts (or within your confirmed Enterprise limit)
4. Read-only agents have no shared write targets; write agents each have an isolated worktree

✓ All met → dispatch agents
✗ Any unmet → resolve the dependency, define the return format, or serialize the dispatch before proceeding

---

## BEFORE PROCEEDING

- [ ] All tasks are truly independent — no agent needs another agent's output to start
- [ ] Return format is explicitly defined for every agent before dispatch
- [ ] No more than 4 agents in flight on Standard accounts (or within your confirmed Enterprise limit)
- [ ] Read-only agents have no shared write targets; write agents each have an isolated worktree

✓ All met → dispatch agents
✗ Any unmet → resolve the dependency, define the return format, or serialize the dispatch before proceeding

---

## Concurrency Rules

**Copilot Enterprise:** No practical concurrency limit. Dispatch as many as the task warrants.

**Standard accounts:** Verify your account's agent concurrency limit before dispatching. Default assumption: up to 4 concurrent unless you have confirmed a higher limit.

State your concurrency assumption before dispatching: "Dispatching N agents in parallel — [Enterprise / confirmed N-agent limit / assuming default]."

---

## Isolation Rules

Each parallel agent MUST receive:

1. **Isolated context** — never share your session history. Provide only what that agent needs.
2. **A single objective** — one question, one file set, one hypothesis.
3. **An explicit return format** — tell it exactly what to give back.
4. **No knowledge of other agents** — agents do not know about each other.

**Why isolation matters:** Agents that share context inherit your biases and assumptions. Isolated agents search without your anchoring.

---

## Aggregating Results

When parallel agents return:

1. Read all results before acting on any
2. Treat every finding as a **hypothesis** — not a fact
3. Cross-check conflicting findings against the source files yourself
4. State what each agent found and what you verified:
   ```
   Agent 1 found: [X] — verified by reading [file:line]
   Agent 2 found: [Y] — conflicts with Agent 1 — investigating
   ```
5. Do NOT propagate a finding to the user until you have verified it

---

## Citation Verification

When any agent cites specific file names, page names, or resource paths as evidence, apply this gate **before accepting any cited finding into synthesis:**

1. For each cited resource not directly confirmed by a read or listing tool in the agent's own work: verify the resource yourself by reading or listing it directly.
2. Verification = the resource exists AND its content supports the claim.
3. **If verification fails:** REJECT the finding. Record: `REJECTED: [resource] does not exist — citation unverified.` Do NOT re-dispatch the original agent for the same citation.
4. **If verification passes:** accept the finding. Note: `VERIFIED: read [path] — content confirms [claim].`

**Why:** Agents — especially when working with large archives or documentation sets — frequently cite plausible-but-nonexistent resources. Treating citations as hypotheses and verifying them before synthesis prevents hallucinated evidence from reaching conclusions.

---

## Write Agents — Worktree Requirement

When parallelizing write work (e.g., multiple implementers working on independent subsystems):

1. Create one worktree per agent BEFORE dispatching
2. Verify each worktree is gitignored: `git check-ignore -q .worktrees || echo "NOT IGNORED"`
3. Pass worktree path as the agent's working directory
4. After agents complete: review each diff independently before merging

```bash
# Create isolated worktrees
git worktree add .worktrees/agent-feature-a -b feat/agent-feature-a
git worktree add .worktrees/agent-feature-b -b feat/agent-feature-b

# Review diffs after completion
git -C .worktrees/agent-feature-a diff main
git -C .worktrees/agent-feature-b diff main
```

See `using-git-worktrees` skill for full worktree lifecycle.

---

## Red Flags — STOP

| Pattern | Action |
|---------|--------|
| Two or more agents assigned to the same file or overlapping file sets | STOP. Reassign to non-overlapping sets or serialize the dispatch. |
| Dispatching agents without a defined return format | STOP. Define the exact return format for every agent before dispatching. |
| Acting on one agent's result before all agents have returned | STOP. Collect ALL results first, then aggregate and verify. |
| More than 4 concurrent agents on a Standard account without confirming the limit | STOP. Verify your account's concurrency limit before dispatching. |
| Forwarding agent output to the user without verifying it against source files | STOP. Cross-check every finding against source files before presenting conclusions. |

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "These tasks are mostly independent" | Mostly = risk. Confirm independence before dispatching. |
| "I'll just have them both edit the file" | Race condition. One agent's changes will be overwritten. Use worktrees. |
| "I'll share my session context — it's helpful" | It contaminates their search. They'll confirm your assumptions instead of testing them. |
| "One agent can do all this" | Sequential agents fill your context. Parallel agents preserve it. |
| "I don't need to verify — the agent found it" | Findings are hypotheses. You verify before you propagate. |
| "I'll use general-purpose — it can do everything" | general-purpose for read-only research wastes context and produces serial output. Use explore for research across many files. |
| "I'll run them sequentially — parallel is harder to coordinate" | YOU MUST run independent tasks in parallel. Sequential dispatch wastes turns. |
| "The agents can share the same branch — I'll merge their changes manually" | YOU MUST use worktrees for parallel agents with side effects. Shared branches produce conflicts. |

---

## Related Skills

- [`subagent-driven-development`](.github/skills/subagent-driven-development/) — orchestration framework; parallel dispatch is a specialized case of subagent dispatch
- [`using-git-worktrees`](.github/skills/using-git-worktrees/) — required for any parallel write agents; isolation guarantee
- [`execution`](.github/skills/execution/) — work loop and commit rhythm that parallel dispatch operates within
