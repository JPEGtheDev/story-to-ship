---
name: writing-plans
license: MIT
description: Use when starting any multi-step task, story, or feature work.
---

## Iron Law

```
CLARIFY FIRST. PLAN BEFORE CODE. NO PLACEHOLDERS.
```

YOU MUST follow this law on every task. No exceptions.

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the writing-plans skill to plan [brief description]."

---

## Step 0: Clarify Expectations

**Before building a plan** — restate requirements in your own words. Earliest-possible catch for "solved the wrong problem."

```
"Here is what I understand you're asking for:
1. [requirement 1]
2. [requirement 2]
[UNCLEAR: anything ambiguous, marked explicitly]

My optimization target: [user's stated outcome], not [convenient proxy]."
```

- Label every ambiguity `[UNCLEAR: ...]` — never silently assume
- If requirements have gaps: name the gap and state your assumption
- Map each acceptance criterion to a verifiable test
- "This seems obvious" is the warning sign you need this step most

---

## Situation Gate

| Situation | Response |
|---|---|
| Obvious single-file fix | Implement immediately — no plan needed |
| 2+ files touched | Outline sequence before coding |
| Architectural decision | Specify approach before touching code |
| Ambiguous requirements | Clarify first — do not plan around unknowns |
| User story with acceptance criteria | Map each criterion to a checkpoint |
| "Can you test X?" or "evaluate X?" without stated methodology | `[UNCLEAR: what does success look like? what is the baseline? does methodology matter?]` — ask before designing anything |

---

## Building the Plan

1. Create a todo list (`sql` tool) with concrete, verifiable items
2. Specify expected file changes up front — files, functions, test additions
3. Bake in proof steps — plan how to verify each change
4. Sanity-check: does the plan address every acceptance criterion?
5. Name known downsides proactively — trade-offs, risks, limitations the user did not ask about
6. Disclose decision rationale — name alternatives considered and why chosen approach was preferred

### No-Placeholder Rule

Every todo must contain what an engineer needs to execute it. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" (without specifying what)
- "Write tests for the above" (without naming what to test)
- "Similar to Task N" (repeat the specifics — tasks may be read out of order)
- Steps that describe what to do without showing how

### Task Granularity (TDD Steps)

Each task MUST be one concrete action (2–5 minutes). For implementation tasks, follow TDD structure:

```
Task N: [Feature or component name]
Files:
  - Create: exact/path/to/NewFile.<ext>
  - Modify: exact/path/to/ExistingFile.<ext>
  - Test:   tests/path/to/TestFile.<ext>

RED   todo: Write the failing test for [behavior]
RED   todo: Run test — verify it fails for the right reason
GREEN todo: Write minimal implementation to pass the test
GREEN todo: Run full suite — verify all tests pass
REFACTOR todo: Clean up — rename, extract, remove duplication; tests must stay green
COMMIT todo: git add / git commit -m "feat[scope]: description"
```

Each step must be its own todo with a distinct status.

---

## Smart Trust Gate (5 Questions)

Answer before finalizing any plan. Dispatch a research subagent if you cannot answer from existing knowledge.

| # | Question | What it confronts |
|---|----------|-------------------|
| 1 | **What does success look like concretely?** Outcome + verification method, not activity | Vague plans |
| 2 | **What is this plan NOT addressing?** Name every omission, deferred item, assumed-away requirement | Hidden scope |
| 3 | **Top 3 failure modes?** For each: signal that indicates it's occurring + response | Unexamined risk |
| 4 | **Do I have the capability?** Any libraries or patterns requiring research before coding? | Wrong assumptions |
| 5 | **What would a skeptic say?** Strongest argument against this approach | Comfort choices |

✓ All 5 questions answered with no gaps → proceed to review gate or implementation
✗ Any unanswered question or revealed gap → stop, revise the plan, then re-run the gate

For any plan with 2+ todos or an architectural decision, dispatch a review agent before implementation. The routing depends on whether Discovery ran:

**If plan.md contains `## Feature Specification` (Discovery ran):**
Invoke the `three-amigos` skill for a Refinement review. Three amigos review replaces the Skeptic for Discovery features.

**Otherwise (no Discovery):**
Dispatch a **Skeptic Agent**:

```
You are a Skeptic Agent. Find what this plan is missing.
Do not validate what looks correct — find what is wrong.

Requirements: [FULL TEXT]
Plan: [FULL PLAN WITH TODOS]

Answer only these four questions:
1. What is the plan NOT addressing that the requirements ask for?
2. What assumptions must be true for this plan to work? (name assumption + what must hold)
3. Strongest argument against this approach?
4. Most likely way this fails in practice?

If you genuinely find no gaps after thorough analysis, state that explicitly.
```

---

## Heuristics: YAGNI · Simplest Thing · PPP

**YAGNI:** If a todo cannot be traced to a specific acceptance criterion, cut it.
> Forbidden: "We'll probably need it later."

**Simplest Thing That Could Possibly Work:** After the Smart Trust gate, verify a simpler implementation satisfies all criteria. Fewer files, fewer abstractions, fewer dependencies.

**PPP — Plain Programmer's Purpose:** Per todo: "This [function/class] takes [X] and does [Y]." Can't state it simply? Decompose.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll start coding, plan as I go" | Unplanned work creates cascading mistakes |
| "It's obvious what needs to be done" | Obvious tasks still have sequencing risks |
| "The todo list wastes time" | The list is the audit trail — skipped items accumulate silently |
| "I'll update todos later" | Later never comes — update before starting, after finishing |
| "I understand the requirements" | Misunderstood requirements are the most expensive bug |
| "We'll probably need this later" | YAGNI — not in criteria means not in this plan |
| "The plan looks good — I'll just start" | A plan presented is not a plan approved. Wait for explicit instruction. |
| "The user implied I should proceed" | Implied is not explicit. "Looks good", "go ahead", or "start" are approval. Silence is not. |
| "The user said 'autopilot' / 'just go' — that overrides plan-first" | When a message says both "autopilot/just go" and "show me first / I want to know your flow," the show-first instruction wins. Explicit plan presentation is the PLAN BEFORE CODE law. "Autopilot" is not an explicit override unless the user also says "skip the plan." |
| "I listed all the main files — the audit scope is complete" | Listing top-level files from memory or a shallow glob misses references/ subdirectories, recently-added files, and nested content. For any audit task, run a file listing command (e.g. `find .github/skills -type f -name '*.md'`) before planning. Do not enumerate scope from memory. |
| "I found the bug — fixing it now" | A request to debug or research is not a request to fix. Present findings first. Wait for instruction. |
| "Plan states a numerical estimate (word count, file size, line count) without measuring" | Measure before writing. Run `wc -w` or `wc -l`. Unverified numerical claims in plans cause failed acceptance criteria. |
| "It's just a quick test, I don't need todos" | Any multi-step task without SQL todos has no review gate. The Skeptic and Three Amigos dispatch rules cannot fire if todos were never created. Create todos first, then execute. |
| "Implementation revealed a dependency on a second file — I'll modify it" | Scope expansion requires user authorization. STOP. State the dependency and ask before touching any file not in the original plan. |
| "Skeptic or Refinement approved with conditions, I addressed them — I can proceed" | NO. Review findings change the plan — user approval of the original does not carry forward. Re-present the revised post-review plan to the user. Wait for explicit re-approval before creating branches or dispatching implementers. |

---

## Scope and Commitment Sizing

- If a plan covers multiple independent subsystems, split into one plan per subsystem
- Each plan MUST produce working, testable software on its own
- Realism check: can this be completed and verified in this session? If not, commit to the verifiable portion only. State the remainder as a separate commitment explicitly.
- An over-committed partial delivery is worse than a smaller honest delivery.

---

## Red Flags — STOP

- Code or file edits before Step 0 (restate requirements) is complete — **STOP. Do Step 0 now.**
- **HARD-GATE:** Plan has 2+ todos, review not dispatched — **STOP. Check plan.md for `## Feature Specification`. If present: invoke three-amigos Refinement. If absent: dispatch Skeptic. No first edit until review result is read.**
- **HARD-GATE:** About to send a message presenting a design or plan as final — review not yet dispatched? **STOP. Check plan.md for `## Feature Specification`. If present: invoke three-amigos Refinement. If absent: dispatch Skeptic. The review must be in-flight or complete before the plan is presented as finished.**
- Any todo lacks a concrete description — **STOP. Fill every description before starting.**
- Plan states a numerical estimate without a `wc` measurement — **STOP. Measure first. Run `wc -w` or `wc -l`.**
- Next todo started without prior todo's 2-stage review passing — **STOP. Both stages required before advancing.**
- Implementation started before user gives explicit plan approval — **STOP. Wait for "go ahead."**
- About to dispatch audit or research agents without listing every dimension the agent must check — **STOP. Enumerate every file, section, rule, and reference in the prompt before dispatching. Label any dimension you cannot enumerate [UNCLEAR:] and resolve it first.**

---

## Quick Reference

```
Task arrives
    ↓
Trivial (1 file, 1 step)? → Implement directly
    ↓ (multi-step)
Step 0: Clarify Expectations — restate requirements, label [UNCLEAR:]
    ↓
Smart Trust Gate — answer 5 questions; if 2+ todos: check for `## Feature Specification` → three-amigos Refinement OR Skeptic
    ↓
Build todo list: YAGNI + PPP per item + No Placeholders
    ↓
TDD task structure: RED / GREEN / REFACTOR / COMMIT as separate todos
    ↓
Plan review: covers all criteria? downsides named?
    ↓
Present plan to user — WAIT for explicit approval
    ↓
Begin execution (invoke execution skill)
```

---

## References

- Simplicity principles and dimensions: `references/SIMPLICITY_PRINCIPLES.md` — Simplest Thing gate, dimensions of simplicity table, assign problems not tasks
