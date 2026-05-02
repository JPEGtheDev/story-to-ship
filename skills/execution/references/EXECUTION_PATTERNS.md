# Execution Patterns Reference

Source: Ward Cunningham's C2 wiki audit — patterns for effective implementation execution, optimization discipline, and performance management.

---

## Profile Before Optimizing

Write code for clarity, flexibility, and correctness first. Optimize only after measurement proves it necessary. "I think this is slow" is not a profiling baseline.

The three rules of optimization:
1. Don't do it.
2. (For experts only) Don't do it yet.
3. Profile first, then optimize the measured bottleneck — not the guessed one.

This principle extends to any resource: memory allocation, network round-trips, disk access. The pattern of premature optimization is: implement something slower for clarity, observe hypothetical slowness, optimize without measuring, introduce complexity, discover the bottleneck was elsewhere. Source: C2 Wiki "ProfileBeforeOptimizing", "RulesOfOptimization".

---

## Assign Problems, Not Tasks

When delegating to a subagent or a collaborator, provide the problem and its constraints — not the implementation steps. An executor given steps will follow them even when the steps lead to the wrong outcome. An executor given the problem can recognize when circumstances require a different approach.

The distinction:
- Task assignment: "Add a pointer line to SKILL.md, then append the new section to the reference file, then commit."
- Problem assignment: "The SKILL.md needs a pointer to the new reference file for Six Thinking Hats. The file is over its word limit — use the minimum change that achieves the goal."

The first fails when the file has already been modified. The second adapts. Source: C2 Wiki "AssignProblemsNotTasks".

---

## Technical Debt Visibility

Technical debt is the cost of rework that accumulates when expedient solutions are chosen over correct ones. The debt itself is not always wrong — sometimes a quick solution is correct for the moment. The danger is invisible debt: shortcuts taken without recording that a shortcut was taken.

Rule: every deliberate shortcut must be marked at the decision point. Include: what the shortcut is, what the correct solution would be, and why the shortcut was chosen now. An unmarked shortcut becomes permanent. A marked one can be scheduled.

Do not use technical debt as a rationalization for low-quality work. Use it only to describe explicitly accepted trade-offs with a documented intent to revisit. Source: C2 Wiki "TechnicalDebt", "WardExplainsDebtMetaphor".

---

## Technical Debt Tracking Practices

Marking debt inline (see Technical Debt Visibility above) is necessary but not sufficient. Individual inline markers are invisible to planning until someone reads every file. Close the loop with a tracked list.

Practices:
- Maintain a **Technical Debt List** — a centralized tracked list of known shortcuts, workarounds, and structural problems. Each entry names the debt, its impact, and the effort required to repay it.
- Reference the debt list in planning. Debt that never appears in planning is debt that never gets repaid.

Invisible debt compounds. Inline markers make it discoverable; the debt list makes it plannable.

---

## Relentless Testing as Integration Prerequisite

Integration of any change into the shared codebase requires that all tests pass. This is not optional. A failing test on the integration branch means the branch is broken for everyone until it is fixed.

"Relentless testing" means:
- Tests run before every integration, not just before release
- A failing test stops integration — it is not merged around, deferred, or silenced
- The test suite is fast enough that developers run it habitually

The cost of a broken integration is shared by the whole team. The cost of running the tests belongs to one developer. Keep that asymmetry in mind.

---

## Atomic Refactoring Steps

Each refactoring step must leave the system in a working state. Never accumulate multiple refactoring changes across a session before verifying. After each step:
1. Build succeeds
2. All tests pass
3. Behavior is identical to before the step

Breaking refactoring into atomic steps makes it reversible at any point. If a step breaks the build, revert immediately — do not attempt to fix forward. Small steps with frequent verification are always safer than large restructuring with deferred verification.

---

## Refactoring Friction as Signal

If a refactoring feels expensive, risky, or requires extensive coordination, that friction is information — not a reason to skip the refactoring. High friction signals:
- Tight coupling that should be loosened
- Missing abstractions that make changes ripple
- Inadequate test coverage that makes changes risky
- Unclear ownership that requires coordination

Address the source of friction rather than working around it. A system that is hard to refactor is a system that is accumulating structural debt.

---

## Related Skills

- `execution` — work loop, commit rhythm, mode declaration
- `writing-plans` — SIMPLICITY_PRINCIPLES.md for Assign Problems Not Tasks; YAGNI gate
- `systematic-debugging` — Profile Before Optimizing applies equally to debugging: measure before concluding

---

## Trade-Off Discipline

When two or more valid approaches exist, use this structure:
```
Approach A: [what it gives] / [what it costs]
Approach B: [what it gives] / [what it costs]
Choice: [A or B] because [specific reason]
```

Required when: rejecting a simpler approach, making a correctness/performance/maintainability tradeoff, or when the choice affects testability or coupling.

**Pain as Signal:** Difficult-to-test code signals a design problem. Fix the design, not the test harness.

---

## Keep Commitments — Extended Rationale

When you announce what you will do — in the session-start announcement, in a plan summary, or in a response — those statements are **commitments**, not intentions.

This behavior is the foundation of predictable trust. Consistent commitment-keeping means the user can plan around your output without second-guessing whether announced work was actually done.

---

## Right Wrongs — Extended Rules

**Listen First:** Read the user's feedback fully before drafting any response. A defense written before the criticism is understood is a collision, not a response.

---

## MIWMIRMIF — Extended Rationale

**Relationship to the TDD cycle:**

The TDD Red/Green/Refactor cycle enforces Make It Work → Make It Right at the *micro level* (each individual test). This macro rule enforces the same discipline at the *feature level*: do not optimize code that does not yet pass its tests; do not clean up code that does not yet work.

---

## Continuous Refinement

After any mistake or user correction:

1. Name the failure mode
2. Check existing skills — is it already documented?
3. If new, update the relevant skill now — don't defer
4. Write a concrete prevention rule

---

## Skill Dispatch Table

| Domain | Skill |
|--------|-------|
| Planning a multi-step task | `writing-plans` |
| Subagent dispatch or delegation | `subagent-driven-development` |
| Bug or failure | `systematic-debugging` |
| Completion claim | `verification-before-completion` |
| Writing tests | `testing` |
| Writing/editing C++ | `code-quality` |
| Commits or PRs | `versioning` |
| CI/CD work | `workflow` |
| Flatpak packaging or GL runtime | `flatpak` |
| Build or dependencies | `build` |
| Code review | `code-review agent`, 1 per file |
| Skill review | `general-purpose` + `skill-reviewer` skill |

---

## Communicating Progress — Extended Rules

- **Temporal declaration:** When a plan requires more turns than the user likely expects, state this proactively at plan time: "This will take approximately N responses. Here is what each will deliver: [sequence]." Do not surface this mid-execution — declare it at plan time.
- **Attention cost:** Before sending any response longer than 200 words or creating new work for the user, ask: is this the most respectful use of their attention? Compress or defer non-essential content.
- When all items are complete, give a brief accounting of files touched, tests added, and notable decisions.
