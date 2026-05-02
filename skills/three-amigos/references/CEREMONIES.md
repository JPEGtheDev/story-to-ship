# Three Amigos — Ceremony Reference

Full ceremony definitions for all 6 ceremonies. Orchestrator reads this file to inject `{{AGENDA}}` and `{{READ_FIRST}}` at dispatch time.

**`{{AGENDA}}` data structure:** Copy the `### Agenda — Questions` block for the relevant ceremony as the `{{AGENDA}}` value.  
**`{{READ_FIRST}}` data structure:** Copy the per-amigo read list for the relevant ceremony as the `{{READ_FIRST}}` value.

---

## Ceremony 1: Discovery

**Trigger:** New feature with new or unclear acceptance criteria.  
**Output:** Feature Specification written into `## Feature Specification` in plan.md.  
**Required:** YES for any feature with 2+ todos and unclear AC.

### Feature Specification grain — MANDATORY

The Feature Specification is written at **user behavior and outcome** level only.

**Include:**
- What the user can DO (observable actions)
- What the user receives or observes (outcomes)
- Numbered acceptance criteria in behavioral terms (Given/When/Then or plain language)
- What is explicitly OUT of scope
- Unresolved questions for the user

**Exclude — these NEVER appear in the Feature Specification:**
- Class names, struct names, method names, file references
- Implementation steps or architecture decisions
- Todos, task lists, or code-level instructions

**Developer amigo findings in Discovery** (API gaps, missing setters, class constraints) are implementation constraints that inform todo planning — they do NOT appear in the Feature Specification. The orchestrator records them separately (e.g., in a `## Implementation Notes` section or as initial todos) after the Feature Specification is written.

### Synthesis step (orchestrator)

After all three Discovery amigos return:
1. Write `## Feature Specification` from the **Business and Tester findings only** — behavioral ACs, BDD scenarios, out-of-scope items, open questions.
2. Record Developer implementation findings separately under `## Implementation Notes` — these become inputs to todo planning.
3. Do NOT mix the two. Implementation details in the Feature Specification defeat the purpose of the ceremony.

### Read First

- Business Amigo: GitHub issues, README, user stories, existing feature specs.
- Developer Amigo: Architecture docs, relevant existing source files, dependency list.
- Tester Amigo: Existing test files for similar features, testing standards doc.

### Agenda — Questions

1. What does the user want to be able to DO? (observable behavior, not technical steps)
2. What are the boundaries? What is explicitly OUT of scope?
3. What does "done" look like? State 3–5 testable acceptance criteria.
4. What are the failure cases? What must happen when things go wrong?
5. What questions remain unresolved? (Surface to user before proceeding.)

---

## Ceremony 2: Refinement

**Trigger:** Plan written, 2+ todos, Discovery ran (plan.md has `## Feature Specification`).  
**Output:** APPROVE / CONDITIONS / REJECT per amigo. Any REJECT blocks.  
**Required:** YES for any Discovery feature with 2+ todos.

### Read First

- Business Amigo: Feature Specification in plan.md, GitHub issue, README.
- Developer Amigo: Plan todos, relevant source files, existing tests.
- Tester Amigo: AC, plan todos, existing test files.

### Agenda — Questions

1. Does every todo map to at least one acceptance criterion?
2. Are there AC that have no corresponding todo?
3. Is the dependency order correct? Can all todos be completed in stated order?
4. Are there missing edge cases, error handling, or failure modes?
5. Does the plan risk introducing breaking changes to existing behavior?

---

## Ceremony 3: Progress Check

**Trigger:** Mid-implementation milestone (e.g., 50% of todos done, or orchestrator signals milestone).  
**Output:** ON TRACK / AT RISK / PIVOT NEEDED per amigo.  
**Required:** Trigger-based — not required on every feature.

### Read First

- Business Amigo: Feature Specification, completed todo list, any updated GitHub issue.
- Developer Amigo: Completed code changes (git diff), remaining todos, test results.
- Tester Amigo: Tests written so far, remaining AC coverage gaps.

### Agenda — Questions

1. Are completed todos consistent with the Feature Specification?
2. Has any new information emerged that changes the AC?
3. Are remaining todos still correctly scoped?
4. Is there any signal of scope creep or unexpected complexity?
5. Is the feature still on track to meet the original acceptance criteria?

---

## Ceremony 4: Pivot Assessment

**Trigger:** Implementer signals BLOCKED or DONE_WITH_CONCERNS.  
**Output:** CONTINUE / REVISE AC / REVISE PLAN / ABANDON per amigo.  
**Required:** Trigger-based — fires on any BLOCKED or DONE_WITH_CONCERNS signal.

### Read First

- Business Amigo: Original Feature Specification, BLOCKED/CONCERNS description from implementer.
- Developer Amigo: Code at the point of blockage, relevant architecture, error output.
- Tester Amigo: Current AC, tests written so far, failure output.

### Agenda — Questions

1. What exactly caused the BLOCKED or DONE_WITH_CONCERNS signal?
2. Can the original AC still be met, or must they be revised?
3. Can the plan be revised to unblock, or is a fundamental approach change needed?
4. What is the cost of continuing vs. revising vs. abandoning?
5. What new information does this signal provide about the feature's feasibility?

---

## Ceremony 5: Signoff

**Trigger:** All todos complete, pre-merge.  
**Output:** ACCEPTED / REVISIONS NEEDED per amigo. REVISIONS NEEDED from any amigo blocks merge.  
**Required:** YES for any feature that went through Discovery.

### Read First

- Business Amigo: Feature Specification, implemented behavior (demo or code review).
- Developer Amigo: Final code diff, test results, architecture impact.
- Tester Amigo: Test coverage report, AC list, edge case list from Discovery.

### Agenda — Questions

1. Does the implemented behavior match every acceptance criterion?
2. Are there any AC that are not demonstrably covered?
3. Does the feature behave correctly in the documented failure cases?
4. Is there any behavior present that contradicts the Feature Specification?
5. Are there any missing edge cases that must be tested before merge?

---

## Ceremony 6: Retrospective

**Trigger:** Feature merged and closed.  
**Output:** Process improvement items. No verdict — pure learning output.  
**Required:** Expected for all multi-session features. Optional for single-session.

### Read First

- Business Amigo: Full session history, original Feature Specification, ceremony verdict outputs.
- Developer Amigo: Full session history, final code diff, test results summary.
- Tester Amigo: Full session history, AC list, test coverage summary, edge case list.

### Agenda — Questions

1. What went well in the Three Amigos process for this feature?
2. Where did the process slow things down or produce redundant output?
3. Were the ceremony triggers correctly calibrated? Any false positives or missed triggers?
4. Did persona differentiation produce unique findings? If not, what was redundant?
5. What one process change would make the next Three Amigos cycle more effective?
