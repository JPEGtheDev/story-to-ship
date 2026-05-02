---
name: brainstorming
license: MIT
description: Use when a task needs design exploration before any implementation begins. Required for any task with unclear approach, significant architecture impact, or multiple valid solutions.
---

## Iron Law

```
YOU MUST PASS THE DESIGN GATE BEFORE WRITING ANY CODE.
NO AMBIGUITY ENTERS THE PLAN. EVERY [UNCLEAR:] MUST BE RESOLVED BEFORE WRITING-PLANS BEGINS.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST complete Phases 1–4 and pass the Design Gate before writing any code or loading `writing-plans`. No exceptions.

**Announce at start:** "I am using the brainstorming skill to explore design options for [brief description]. No code will be written until the gate is passed."

---

## When to Invoke

This skill is required before writing code when ANY of the following are true:

| Signal | Why it matters |
|--------|---------------|
| The approach is unclear or contested | Code written before approach is settled creates rework |
| The task touches 2+ architectural layers | Cross-layer changes have hidden coupling costs |
| Multiple valid solutions exist | Picking without analysis risks the wrong trade-off |
| The user said "figure out the best way" | That is a design task, not an implementation task |
| You feel uncertain about WHERE to put the code | Uncertainty about structure = design question unanswered |
| The task involves a new dependency or library | Dependency choice is a design decision |

---

## Phase 1: Clarification (REQUIRED — do not skip)

### Discovery Gate (run first)

**Context:** A feature enters brainstorming with new or unclear AC.

**Forces:** Brainstorming explores *how* to build. Discovery defines *what* to build. Designing how before defining what produces rework.

**Solution:** Before asking clarifying questions, check plan.md for `## Feature Specification`.
- Present → Discovery ran. AC is defined. Proceed to clarifying questions.
- Absent → AC is unclear. Invoke `three-amigos` Discovery ceremony NOW. Return here after Discovery closes.

**Consequences:** Brainstorming Phase 1 operates on confirmed AC. No design work begins before behavioral scope is settled.

---

**Before answering any design questions:** ask clarifying questions. One question per response. Wait for the answer before asking the next.

Label every ambiguity `[UNCLEAR: ...]`. Do NOT silently assume an answer to an unclear requirement.

**AMBIGUITY BLOCK:** If any `[UNCLEAR:]` item remains unanswered, you MUST stop. Do not proceed to Phase 2. Ask the clarifying question. Wait for the answer. Then continue.

Good clarifying questions:
- "Should this work with existing data formats or a new format?"
- "Is this feature gated by a user preference or always active?"
- "Does 'fast' mean under 16ms per frame, or just noticeably faster?"

Bad clarifying questions (don't ask):
- Hypotheticals you can answer by reading the codebase
- Questions where the existing architecture makes the answer obvious
- Questions you are going to answer yourself anyway

After all `[UNCLEAR:]` items are resolved: state "All ambiguities resolved. Proceeding to Phase 2."

---

## Phase 2: Explore Project Context

Before proposing approaches, read the relevant area of the codebase:

1. Identify which files will be affected — grep if needed, dispatch researcher agent if large
2. Find existing patterns you must follow or are free to diverge from
3. Identify any existing interfaces the change must comply with
4. State what you found: "Existing pattern is X, found in Y. New code must follow this because Z."

If you cannot answer a design question from reading the code, dispatch a researcher subagent — do not guess.

---

## Phase 3: HARD-GATE Design Questions

Answer all applicable questions before writing a single line of production code.

### Required Questions (all tasks)

1. **What is the simplest thing that could possibly work?**
   State it in one sentence. If you cannot, the problem is not well-understood yet.

2. **What are the top 3 alternative approaches?**
   List them. If only one exists, state why the others are ruled out.

3. **What are the trade-offs?**
   ```
   Approach A: [benefit] / [cost]
   Approach B: [benefit] / [cost]
   Chosen: [A] because [specific reason]
   ```

4. **Where does this code live?**
   Name exact file paths. "Somewhere in src/" is not an answer — it is a gap.

5. **What does this NOT do?**
   State explicit scope boundary: what is out of scope, deferred, or assumed away.

### Additional Questions (architecture-impacting tasks)

6. **Does this cross a layer boundary?**
   Dependency direction must be outer → inner. Never inner → outer.

7. **What existing code does this interact with?**
   Name the interfaces and concrete classes.

8. **Can this be tested without the real external dependency?**
   If no: state the isolation strategy (mock, stub, or integration test).

---

## Phase 4: Design Gate Checklist

Every item MUST be checked before handing off to `writing-plans`.

- [ ] All `[UNCLEAR:]` ambiguities resolved — none remain
- [ ] Simplest approach identified and chosen or explicitly rejected with reason
- [ ] All trade-offs named — none left implicit
- [ ] Exact file paths named — no "somewhere in src/"
- [ ] Out-of-scope items explicitly listed
- [ ] Architecture impact assessed (layer boundaries, dependency direction)
- [ ] Test strategy stated

✓ All checked → output Design Decision Record → hand off to `writing-plans`
✗ Any unchecked → STOP. Return to the relevant phase. Do not proceed.

---

## Phase 5: Design Decision Record

When the gate is fully passed, output this record. It becomes part of the PR description.

```
## Design Decision Record

**Problem:** [one sentence]

**Ambiguities resolved:**
- [UNCLEAR: X] → resolved as: [answer]

**Chosen approach:** [one sentence]

**Alternatives considered:**
- [Approach A]: rejected because [reason]
- [Approach B]: rejected because [reason]

**Trade-off accepted:** [what we give up]

**Files affected:** [exact paths]

**Out of scope:** [explicit list]

**Test strategy:** [how correctness will be verified]

**What would falsify this approach:** [name the result, finding, or evidence that would prove this approach is wrong — required for any test design, research methodology, or evaluation framework]

**Gate passed:** YES — awaiting user approval
```

After presenting this record: **STOP. Ask the user:**

> "Does this design look right? Should I proceed to planning?"

**Wait for explicit user approval before loading `writing-plans`.**

| User response | Action |
|---------------|--------|
| Approves | Load `writing-plans` skill with the Design Decision Record as context |
| Has questions or concerns | Return to the relevant phase; resolve before presenting again |
| Changes requirements | Restart from Phase 1 with the updated requirements |

Do NOT load `writing-plans` without user acknowledgment. The Design Decision Record is the contract — the user must accept it before planning begins.

---

## Multi-Subsystem Tasks

If the task spans **2+ independent subsystems** (different architectural layers, different files with no shared interface, or clearly separate responsibilities):

1. Name each subsystem explicitly and state why each is independent
2. Run Phases 1–5 for **each subsystem separately** — one Design Decision Record per subsystem
3. Present all records to the user together; get approval for all before proceeding
4. Hand off to `writing-plans` with all approved records as context — one plan per subsystem
5. Each subsystem plan runs its own Skeptic Agent review independently

**Do NOT create a single Design Decision Record for a task with independent subsystems.** A merged record hides coupling between subsystems. Identify the boundary first, then design each side separately.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I know what to do, I'll just start" | If you knew, the design questions take 2 minutes. Answer them first. |
| "The requirement is clear enough" | Unresolved ambiguity is the most expensive bug — it shows up after code is written. |
| "I'll clarify as I go" | Mid-implementation clarification means rework. Clarify first. |
| "We can refactor later" | Design debt compounds. 2 minutes now saves 2 hours later. |
| "The approach is obvious" | Obvious approaches still need trade-offs named to be defensible. |
| "TBD for now" | TBD is not a file path. It is a deferred decision that will block the implementer. |
| "I'll figure it out as I code" | Exploratory coding without a gate produces uncommittable work. |

---

## Red Flags — STOP

- Writing code before the gate checklist is fully checked → STOP. Complete the gate.
- Any `[UNCLEAR:]` item not yet answered → STOP. Ask the clarifying question.
- Handing off to `writing-plans` with any gap in the Design Decision Record → STOP. Fill the gap.
- "TBD" appearing anywhere in the Design Decision Record → STOP. Resolve it.
- Proceeding to implementation because the scope "feels clear enough" → STOP. Run the gate. Feelings are not evidence.

---

## References

- Structured ideation protocols: `references/STRUCTURED_IDEATION.md` — Six Thinking Hats table, BrainStorm two-phase protocol (generation separate from evaluation)
