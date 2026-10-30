# Three Amigos -- Ceremony Reference

Full ceremony definitions for all 6 ceremonies. Orchestrator reads this file to inject `{{AGENDA}}` and `{{READ_FIRST}}` at dispatch time.

**`{{AGENDA}}` data structure:** Copy the `### Agenda -- Questions` block for the relevant ceremony as the `{{AGENDA}}` value.  
**`{{READ_FIRST}}` data structure:** Copy the per-amigo read list for the relevant ceremony as the `{{READ_FIRST}}` value.

---

## Ceremony 1: Discovery

**Trigger:** New feature with new or unclear acceptance criteria.  
**Output:** Feature Specification written into `## Feature Specification` in plan.md; it contains the example map and a verdict; a `BACK TO OWNER` map goes under `## Discovery Open Items` instead (see the stopping rule).  
**Required:** YES for any feature with 2+ todos and unclear Acceptance Criteria (AC).

### Feature Specification grain -- MANDATORY

The Feature Specification is written at **user behavior and outcome** level only.

**Include:**
- What the user can DO (observable actions)
- What the user receives or observes (outcomes)
- Numbered acceptance criteria in behavioral terms (Given/When/Then or plain language; write Given/When/Then per FORMULATION.md in this directory); a criterion proven by documentation evidence or a throwaway spike ends with `Proof: documentation` or `Proof: spike`
- What is explicitly OUT of scope
- Unresolved questions: listed only in the example map's Questions line

**Exclude -- these NEVER appear in the Feature Specification:**
- Class names, struct names, method names, file references
- Implementation steps or architecture decisions
- Todos, task lists, or code-level instructions

**Developer amigo findings in Discovery** (API gaps, missing setters, class constraints) are implementation constraints that inform todo planning -- they do NOT appear in the Feature Specification. The orchestrator records them separately (e.g., in a `## Implementation Notes` section or as initial todos) after the Feature Specification is written.

### Example map -- MANDATORY

The example map lives in the Feature Specification, or under `## Discovery Open Items` when the verdict is `BACK TO OWNER`; each field is its own line, in this order:
- `Story:` one sentence naming the behavior.
- `Rules:` the business rules, one per line, numbered R1, R2.
- `Examples:` at least one concrete example per rule, a named case with real values, numbered R1-E1, R1-E2.
- `Questions:` every unanswered question, one per line, or the single word `none`; an empty or missing line is malformed.
- `Verdict:` `READY FOR PLANNING` or `BACK TO OWNER`.

A rule summarises its examples: state each rule in one sentence and put the detail in its examples. Examples stay at behavior level and obey the grain rule above; a rule with many examples or a map with many rules is a sign to slice the story, and each proposed slice is written as a Question. A rule with no example makes the verdict `BACK TO OWNER` (see the stopping rule). Slicing is optional: record a slice proposal as a Question only when one is made.

### Stopping rule and timebox

Verdict is `BACK TO OWNER` when any rule has no example or Questions is not `none`; the owner then receives the rules without examples and the open questions and answers them before any planning. Otherwise the verdict is `READY FOR PLANNING`. Only a `READY FOR PLANNING` map is written under `## Feature Specification`; a `BACK TO OWNER` map is written under `## Discovery Open Items` instead, so planning routes that look for the Feature Specification heading do not treat it as ready. After the owner answers, update Rules, Examples and Questions from the answer, re-apply this rule, and move the map under `## Feature Specification` only when the verdict is `READY FOR PLANNING`. Each `[UNCLEAR: optional?]` or `[UNPLANNED: entry-path]` label is also listed under Questions.

Timebox: each amigo runs in one dispatch; there is no second dispatch round to answer questions in the same Discovery, except two: the NEEDS_CONTEXT re-dispatch of that amigo only (see `SKILL.md`, Worktree Dispatch Protocol), and one return dispatch per owning amigo after the skeptic check (see `### Skeptic check`), and nothing else. This replaces the roughly 25-minute human session time.

### Synthesis step (orchestrator)

After all three Discovery amigos return:
1. Build the example map (see `### Example map -- MANDATORY`) from the **Business and Tester findings only**: rules from Business, examples from both Business scenarios and Tester failure cases. Set the verdict by the stopping rule. Developer findings stay in Implementation Notes.
2. Write the output by verdict. With `READY FOR PLANNING`, write `## Feature Specification` from the **Business and Tester findings only** -- behavioral ACs, Behavior-Driven Development (BDD) scenarios (written per FORMULATION.md in this directory), out-of-scope items; open questions stay in the map's Questions line (`none` when ready). With `BACK TO OWNER`, write the example map and open questions under `## Discovery Open Items` and write no `## Feature Specification` heading. The write happens only after the skeptic check's routing has finished (see the `### Skeptic check` subsection), because that routing can change the verdict. Write each open formulation finding as a note under the scenario it concerns in the Feature Specification; when the verdict is `BACK TO OWNER`, list each note in `## Discovery Open Items` with its amigo, scenario name and quoted step, and carry it under that scenario when the map moves under `## Feature Specification`; a note whose step the owner's answer changed or removed is dropped.
3. Record Developer implementation findings separately under `## Implementation Notes` -- these become inputs to todo planning.
4. Do NOT mix Developer findings into the Feature Specification. Implementation details in the Feature Specification defeat the purpose of the ceremony.

### Skeptic check

This check runs once per Discovery, after all three amigos return and before the map's verdict is final. Its enforcement is procedural: the orchestrator checks its own routing before writing the verdict; no tool enforces it.

**Inputs (read by path, not pasted into the prompt):** the story file, the answers of all three amigos (Business, Developer, Tester), and the example map. The orchestrator saves the three amigo answers and the draft map to scratch files outside the repository (never plan.md, because the Feature Specification heading is append-only) and passes those paths; the draft map is written under its final heading only after routing finishes. The formulation check also reads FORMULATION.md in this directory and `agents/spec-compliance-reviewer.md` by path.

**Report:** findings only. The skeptic reports five classes and nothing else:
- rule with no example: a rule in the map has no example
- example that tests no rule: an example in the map matches no rule
- question left out: an amigo answer raises an open question that is not in the map's Questions line
- statement the source does not support: a map statement the story does not make
- scenario that breaks a formulation rule: a Given/When/Then scenario in a Business or Tester answer or in the draft map breaks a rule of FORMULATION.md in this directory

The skeptic gives no APPROVE or REJECT verdict; the map verdict stays `READY FOR PLANNING` or `BACK TO OWNER`. The report lists one finding per line, naming its class and item, and ends with the line `FINDINGS: <n>`, where `<n>` is the finding count (`FINDINGS: 0` when there are none).

**Formulation class (Discovery only):** the skeptic hosts this check because it is independent of the amigos that wrote the scenarios and runs once before the Feature Specification is written. It reads FORMULATION.md in this directory in full and checks each Given/When/Then scenario against rules 1, 2, 3, 5, 8 and 9, and against rules 4, 6 and 7 only when the answer or draft map holds several scenarios; a criterion in plain language is not checked, and neither is any use of the skeptic outside this Discovery check. Each broken rule is one finding line, one per broken rule per scenario: `formulation: <amigo>/<scenario name> rule <number> (<title>) -- "<quoted offending step>"` (a scenario that appears in both an amigo answer and the draft map is checked once and counted once), with the title taken from the list in the Scenario Formulation Check section of `agents/spec-compliance-reviewer.md`, read by path. When no rule is broken the report carries the line `Formulation: NONE`; when no scenario is in Given/When/Then form, `Formulation: not applicable`; when FORMULATION.md cannot be read, `Formulation: not checked -- reference not found`, which is never read as a pass. The `Formulation:` lines are not findings; each rule line counts once in `FINDINGS: <n>`.

**Prompt overrides:** the plan-review framing of the skeptic template does not apply to this check. Developer answers are inputs; Developer content absent from the map is not a finding.

**Tier and model:** the skeptic runs at the tier that the Model Selection reference of the `subagent-driven-development` skill (Tier Assignments table) names for the row `Three Amigos Ceremony 1 skeptic check`. Every skeptic call and every amigo return dispatch passes `model` explicitly (an amigo return dispatch uses the amigo's own tier), because a resumed call can fall back to the template pin.

**Routing** (the orchestrator routes each finding; the skeptic never edits the map):
- Zero findings: the map stands.
- Skeptic run failed, BLOCKED, NEEDS_CONTEXT, or its report is unreadable: add a Question and set the verdict to `BACK TO OWNER`.
- A rule with no example goes back to the Tester amigo; an example that tests no rule goes back to the amigo that wrote it. Each owning amigo gets one return dispatch, with all of that amigo's findings batched into the one dispatch.
- A formulation finding goes back to the amigo that wrote the scenario, in that amigo's one batched return dispatch. A formulation finding still open after the return, or whose return dispatch fails, is advisory: it is noted as Synthesis step 2 says, and it never becomes a Question and never sets the verdict to `BACK TO OWNER`. Scenarios changed by a return dispatch or by the owner's answer are not checked again.
- If the return dispatch fails (including a NEEDS_CONTEXT or BLOCKED reply), or the finding is still open after the return, and the finding is not a formulation finding: add a Question and set the verdict to `BACK TO OWNER`.
- A question left out and a statement the source does not support become a Question and the verdict is `BACK TO OWNER`, with no return dispatch. A finding whose owner the source does not show gets the same routing: a Question and `BACK TO OWNER`, never a guessed amigo.
- At most one return dispatch per owning amigo. The skeptic is not re-run after a return.
- Findings never become `none` by omission: the Questions line reads `none` only when there are no unresolved findings and no Questions, and every finding is either resolved by a return or listed as a Question. An open formulation finding is the exception: it is noted as Synthesis step 2 says, not listed as a Question.

### Read First

- Business Amigo: GitHub issues, README, user stories, existing feature specs; FORMULATION.md in this directory (the orchestrator passes its path).
- Developer Amigo: Architecture docs, relevant existing source files, dependency list.
- Tester Amigo: Existing test files for similar features, testing standards doc; FORMULATION.md in this directory (the orchestrator passes its path).

**Focused brief (each Discovery amigo):** a brief names one persona lens, the source file paths to read, and the agenda items that amigo answers: items 1-6 of the agenda below plus the two mandatory extras defined in `SKILL.md` under "Discovery -- Mandatory Agenda Questions" (field optionality, entry paths). On an amigo's first dispatch, a brief contains nothing else; a return dispatch adds only that amigo's batched skeptic findings. Do not paste ceremony prose into the prompt. Discovery amigo calls at the economy tier pass `model` explicitly, which overrides the agent template's pin.

### Agenda -- Questions

1. What does the user want to be able to DO? (observable behavior, not technical steps)
2. What are the boundaries? What is explicitly OUT of scope?
3. What does "done" look like? State 3-5 testable acceptance criteria (Business and Tester: scenario wording per the formulation rules in your read list). Tester: give each criterion's proof kind per the Proof kinds section of the formulation rules in your read list, and flag a criterion whose proof kind does not match that rule.
4. What are the failure cases? What must happen when things go wrong?
5. What questions remain unresolved? (Surface to user before proceeding.)
6. For each rule, give at least one concrete example with real values; list every rule that has none.

### Non-UI Adaptation of the Mandatory Questions

`SKILL.md` mandates two extra Discovery agenda questions on top of the six above: field optionality, and UI dialog entry paths (menu paths and keyboard shortcuts that open a dialog). Both are written assuming a UI feature. For a non-UI or developer-facing feature (skills, tooling, engines, plugins), adapt the two mandatory questions instead of dropping them -- dropping a mandatory question because "there is no UI" silently loses its intent, which generalizes to: enumerate every entry path and flag any not covered.

- Field optionality -> optionality of each field in the feature's data contract (spec or config schema): required, optional, or conditional. Label ambiguous fields `[UNCLEAR: optional?]`.
- UI dialog entry paths -> every invocation or API entry path (namespaced skill invocation, description-match auto-invocation, direct script or command-line launch, allowed-tools surface). Flag any entry path the design does not cover as `[UNPLANNED: entry-path]`.

---

## Ceremony 2: Refinement

**Trigger:** Plan written, 2+ todos, Discovery ran (plan.md has `## Feature Specification`).  
**Output:** APPROVE / CONDITIONS / REJECT per amigo. Any REJECT blocks.  
**Required:** YES for any Discovery feature with 2+ todos.

### Read First

- Business Amigo: Feature Specification in plan.md, GitHub issue, README.
- Developer Amigo: Plan todos, relevant source files, existing tests.
- Tester Amigo: AC, plan todos, existing test files.

### Agenda -- Questions

1. Does every todo map to at least one acceptance criterion?
2. Are there AC that have no corresponding todo?
3. Is the dependency order correct? Can all todos be completed in stated order?
4. Are there missing edge cases, error handling, or failure modes?
5. Does the plan risk introducing breaking changes to existing behavior?
6. Is each todo one behaviour or one reviewable change with one objective that one review can judge? A todo holding two independently verifiable objectives, or one that no single review could judge, must be split before this plan is approved.

---

## Ceremony 3: Progress Check

**Trigger:** Mid-implementation milestone (e.g., 50% of todos done, or orchestrator signals milestone).  
**Output:** ON TRACK / AT RISK / PIVOT NEEDED per amigo.  
**Required:** Trigger-based -- not required on every feature.

### Read First

- Business Amigo: Feature Specification, completed todo list, any updated GitHub issue.
- Developer Amigo: Completed code changes (git diff), remaining todos, test results.
- Tester Amigo: Tests written so far, remaining AC coverage gaps.

### Agenda -- Questions

1. Are completed todos consistent with the Feature Specification?
2. Has any new information emerged that changes the AC?
3. Are remaining todos still correctly scoped?
4. Is there any signal of scope creep or unexpected complexity?
5. Is the feature still on track to meet the original acceptance criteria?

---

## Ceremony 4: Pivot Assessment

**Trigger:** Implementer signals BLOCKED, or DONE_WITH_CONCERNS carrying a correctness or scope risk; the owner is prompted first, in the diagnosing turn, before this ceremony runs -- the ceremony shapes the options, it does not replace the prompt.  
**Output:** CONTINUE / REVISE AC / REVISE PLAN / ABANDON per amigo. This verdict is not authorization to act before the owner answers.  
**Required:** Trigger-based -- fires on any BLOCKED signal, and on a DONE_WITH_CONCERNS signal carrying a correctness or scope risk, after the owner prompt.

### Read First

- Business Amigo: Original Feature Specification, BLOCKED/CONCERNS description from implementer.
- Developer Amigo: Code at the point of blockage, relevant architecture, error output.
- Tester Amigo: Current AC, tests written so far, failure output.

### Agenda -- Questions

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

**Frequency:** One Signoff ceremony per branch is the norm. Repeating the full ceremony is a defect-driven exception -- something went wrong -- not standard practice to budget for; full-ceremony re-runs multiply cost without adding independence. Fix rounds are re-checked by the reviewer that raised the finding (see the `two-stage-review` skill).

**Enforcement is procedural/self-check:** the checkable signal is a second Signoff ceremony dispatched on the same branch with no defect-driven reason stated for repeating it. No automated detector exists.

### Read First

- Business Amigo: Feature Specification, implemented behavior (demo or code review).
- Developer Amigo: Final code diff, test results, architecture impact.
- Tester Amigo: Test coverage report, AC list, edge case list from Discovery.

Read-set completeness gate: before dispatching any amigo whose agenda includes verifying that evidence or an artifact exists or holds -- Signoff always qualifies; Progress Check, Pivot Assessment, and Retrospective qualify whenever their agenda cites specific evidence -- extract every artifact path the PR body, Definition of Done (DoD), or todo evidence cites (scratchpad/, the session's temporary directory, session directories); confirm each appears in that amigo's Read First; paste the path-diff in the dispatch turn. An empty diff is the dispatch precondition. A 'missing X' blocker from a dispatched amigo = first check the dispatch prompt for read-set omission before treating it as a work gap.

### Agenda -- Questions

1. Does the implemented behavior match every acceptance criterion?
2. Are there any AC that are not demonstrably covered?
3. Does the feature behave correctly in the documented failure cases?
4. Is there any behavior present that contradicts the Feature Specification?
5. Are there any missing edge cases that must be tested before merge?

---

## Ceremony 6: Retrospective

**Trigger:** Feature merged and closed.  
**Output:** Process improvement items. No verdict -- pure learning output.  
**Required:** YES for multi-session work. Optional for single-session work.

### Read First

- Business Amigo: Full session history, original Feature Specification, ceremony verdict outputs.
- Developer Amigo: Full session history, final code diff, test results summary.
- Tester Amigo: Full session history, AC list, test coverage summary, edge case list.

Retrospective dispatch prompts supply the evidence record (timeline, artifact paths) and the agenda questions ONLY. A factual timeline entry stating what happened -- including that a defect was found or a review caught it -- is evidence record, not leading. They MUST NOT state the orchestrator's own evaluative conclusion about any agenda question (what a catch means, which process step worked or failed, what the retro surfaces) ahead of the amigo's answer -- a pre-stated conclusion converts the retro into confirmation. The orchestrator's own diagnosis may be shared AFTER all verdicts are collected, for synthesis. Enforcement scope: self-check by the dispatching orchestrator at prompt-authoring time; the postmortem reviewer's Retro-leading audit row (agents/postmortem-reviewer.md, Step 2) surfaces violations after the fact, when a postmortem runs.

### Agenda -- Questions

1. What went well in the Three Amigos process for this feature?
2. Where did the process slow things down or produce redundant output?
3. Were the ceremony triggers correctly calibrated? Any false positives or missed triggers?
4. Did persona differentiation produce unique findings? If not, what was redundant?
5. What one process change would make the next Three Amigos cycle more effective?

---

## Model Selection

Ceremony model tiers and their rationale are defined once in the `subagent-driven-development` skill (Model Selection, Tier Assignments table). Load that skill for the current tier per ceremony; do not restate tier assignments or model IDs in this file.
