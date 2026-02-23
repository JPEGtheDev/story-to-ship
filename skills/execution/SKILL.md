---
name: execution
description: Autonomous execution protocol for implementing tasks, stories, and bug fixes. Governs planning, subagent use, verification, elegance, and self-correction. Use when executing any non-trivial implementation work.
license: MIT
compatibility: Designed for GitHub Copilot and similar AI coding agents
metadata:
  author: JPEGtheDev
  version: "1.2"
  category: execution
  project: Particle-Viewer
---

# Instructions for Agent

## How This Skill is Invoked

This skill is **mandatory for all implementation work**. `copilot-instructions.md` requires it for any task involving code changes, bug fixes, or story execution. Read it before writing code.

---

## Core Principles

These govern every decision during execution:

- **Keep It Simple:** Prefer the straightforward approach. Only introduce abstraction when it pays for itself in clarity or reuse.
- **Senior-Level Standards:** Diagnose root causes. Refuse temporary workarounds. Treat every change as if it will be reviewed by your most critical colleague.
- **Surgical Precision:** Touch only what the task requires. A smaller diff is almost always a better diff.
- **Drive to Completion:** Act on what you know. Resolve blockers yourself. Waiting for permission wastes everyone's time.

---

## Phase 1: Scope and Sequence

**Establish a clear plan before writing code** whenever the task involves 3+ steps or any architectural judgment.

### Decision Table

| Situation | Response |
|---|---|
| Obvious single-file fix | Implement immediately — no ceremony needed |
| Changes spanning multiple files | Outline the sequence first |
| Architectural or design choices | Specify the approach before touching code |
| Ambiguous requirements | Research first (subagents are cheap) |
| User story with acceptance criteria | Decompose criteria into ordered checkpoints |

### Building the Plan

1. **Create a todo list** (`manage_todo_list`) with concrete, verifiable items
2. **Specify expected changes** up front — files, functions, test additions
3. **Bake in proof steps** — plan how you will verify each change, not just what you will build
4. **Sanity-check coverage** — does the plan address every acceptance criterion?
5. **Abandon broken plans early** — if progress stalls, scrap the approach and redesign

### Decomposing a User Story

When handed an INVEST story with acceptance criteria:

1. Turn each criterion into a pass/fail checkpoint
2. Map checkpoints to files and functions
3. Sequence by dependency (tests-first is often the right order)
4. Gauge whether the scope fits a single session — propose a split if not

---

## Phase 2: Disciplined Iteration

### The Work Loop

For every planned item:

```
1. Flag it as in-progress
2. Make the change
3. Prove it works (compile, test, inspect diff)
4. Flag it as done
5. Commit when you reach a logical boundary
6. Advance to the next item
```

**A task is not done until you can demonstrate it works.** That means:
- Clean compilation
- All tests green
- Diff reviewed for side-effects
- You would confidently submit this for code review

### Communicating Progress

- Summarize at the milestone level, not the keystroke level
- State what changed, what was validated, and what comes next
- When all items are complete, give a brief accounting of files touched, tests added, and notable decisions

### Commit Rhythm

- One commit per logical unit — not per file, not per session
- Every commit must build and pass tests on its own
- Follow conventional commit format (see `versioning` skill)
- Never lump unrelated changes together

---

## Phase 3: Delegating to Subagents

Preserve your context window by offloading research and exploration.

### Good Candidates for Delegation

| Work | Delegate? |
|---|---|
| Exploring unfamiliar APIs or libraries | Yes — keep investigation out of your main thread |
| Scanning the codebase for patterns or usages | Yes — parallel search is faster |
| Digesting multiple large files for context | Yes — collect the summary, not the raw text |
| Authoring a single function or fix | No — do this inline |
| Tackling a hard problem from several angles | Yes — fan out the analysis |

### Delegation Guidelines

- **Assign one clear objective per subagent** — focused tasks yield better results
- **State the return format** — tell it exactly what information you need back
- **Accept the findings** unless they conflict with verified facts
- Subagents gather information; you apply it

---

## Phase 4: Prove It Before You Ship It

**Completion requires evidence, not just intent.**

### Pre-Completion Checks

Before declaring any change finished:

- [ ] **Compiles:** `cmake --build build`
- [ ] **Tests green:** `./build/tests/ParticleViewerTests`
- [ ] **Formatted:** `find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i`
- [ ] **Diff inspected:** `git diff` — read every hunk for accidental changes
- [ ] **No trusted silence:** Empty tool output gets a second verification method
- [ ] **Review-ready:** You would not hesitate to open a PR with this

### Comparing Against the Base Branch

Especially before pushing or opening PRs:

```bash
git diff main..HEAD --stat
git diff main..HEAD -- src/
```

Catches scope creep, stale hunks, and unintentional drift.

---

## Phase 5: Pursue Clarity

After something works but before you commit, pause: **"Is there a cleaner way to express this?"**

### Apply When

- A working solution feels convoluted or brittle
- Hindsight reveals a simpler path: "Given what I now know, I'd write it differently"
- Nearby code could be simplified without expanding scope

### Skip When

- The fix is already obvious and direct
- The change is purely mechanical (formatting, renames)
- Improvement would require unrelated refactoring

### Self-Review

Before presenting your work:
- Is this the most straightforward implementation?
- Did I add complexity that the problem didn't demand?
- Would I be comfortable defending every line in review?

---

## Phase 6: Resolve Errors Autonomously

When you encounter a bug report, failing test, or error log: **resolve it without prompting.**

### Approach

1. **Parse the failure** — read the actual error, not just the summary
2. **Reproduce locally** — run the same command that failed
3. **Trace to the root** — don't mask symptoms with patches
4. **Implement the fix** — choose the correct solution, not the fastest one
5. **Confirm resolution** — prove the error no longer occurs
6. **Scan for siblings** — check whether the same pattern exists elsewhere

### When CI Breaks

Pipeline failures follow the same protocol:

1. Read the log output — identify the specific failure
2. Reproduce it on your machine with the equivalent command
3. Apply the fix — no need to wait for direction
4. Verify locally, then push
5. Confirm the pipeline goes green

Act on **any** visible CI failure, whether or not someone flags it.

### Prohibited Behaviors

- Asking whether you should fix an obvious error — of course you should
- Describing a problem without working toward a solution
- Presenting a menu of options instead of executing the best one
- Pushing diagnosis work back to the user
- Settling for a workaround when a proper fix is reachable

---

## Phase 7: Continuous Skill Refinement

**Correct course in real time, not just at session end.**

After any mistake or user correction during a session:

1. **Name the failure mode** — what exactly went wrong?
2. **Search existing skills** — is this already documented?
3. **If it's new, update the relevant skill now** — don't defer to the post-session review
4. **Write a concrete prevention rule** — vague advice doesn't prevent recurrence
5. **Keep tightening** — revisit rules that still produce mistakes and sharpen them

This complements the mandatory end-of-session self-evaluation. The difference: this happens the moment you learn something, not after the work is finished.

### Starting a New Session

Before beginning work, **read every skill your task requires** (per the auto-load table in `copilot-instructions.md`). This is how lessons from prior sessions carry forward. Read to internalize, not to check a box.

### Concrete Example

```
Failure: Assumed empty clang-format output meant all files were clean
Fix: Added "inspect git diff after formatting" to code-quality pre-commit checklist
Rule: "Verify formatting changes via diff — silence is not confirmation"
```

---

## Prohibited Patterns

These behaviors are explicitly disallowed:

1. **Waiting for a green light** — if the task is defined, begin executing
2. **Surfacing problems without fixes** — always pair a diagnosis with a resolution
3. **Declaring done without proof** — every completion claim needs supporting evidence
4. **Doubling down on a stuck approach** — halt, rethink, restart
5. **Gold-plating simple work** — match effort to actual complexity
6. **Winging complex work** — multi-step tasks get a written plan
7. **Walking past defects** — if you spot an issue while working, address or log it
8. **Believing empty output** — always cross-check with a second method

---

## Quick Reference

```
Task arrives
    ↓
Trivial (1-2 steps)?
    Yes → Implement, verify, commit
    No  ↓
Plan: build todo list with verifiable items
    ↓
Per item:
    Start → Implement → Prove → Complete → Commit
    ↓
    Stuck? → Stop → Re-plan → Resume
    ↓
All done?
    ↓
Final gate:
    Compiles ✓ | Tests ✓ | Formatted ✓ | Diff clean ✓ | Review-ready ✓
    ↓
Self-evaluate (per self-evaluation skill)
    ↓
Ship it
```
