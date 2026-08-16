---
name: writing-plans
license: MIT
description: Use when starting any multi-step task, story, or feature work.
---


## Iron Law

```
CLARIFY FIRST. PLAN BEFORE CODE. NO PLACEHOLDERS.
YOU MUST follow this law on every task. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the writing-plans skill to plan [brief description]."

---

## Step 0: Clarify Expectations

**Before building a plan** -- restate requirements in your own words. Earliest-possible catch for "solved the wrong problem."

```
"Here is what I understand you're asking for:
1. [requirement 1]
2. [requirement 2]
[UNCLEAR: anything ambiguous, marked explicitly]

My optimization target: [user's stated outcome], not [convenient proxy]."
```

- Label every ambiguity `[UNCLEAR: ...]` -- never silently assume
- For each acceptance criterion that references a field with possible optionality (required, optional, conditional, nullable): state the optionality explicitly. If the issue text does not resolve it, label `[UNCLEAR: optional?]`. Assuming a field is required when the AC intended optional ships as a defect.
- If requirements have gaps: name the gap and state your assumption
- Map each acceptance criterion to a verifiable test
- "This seems obvious" is the warning sign you need this step most

---

## Situation Gate

| Situation | Response |
|---|---|
| Obvious single-file fix | Implement immediately -- no plan needed |
| 2+ files touched | Outline sequence before coding |
| Architectural decision | Specify approach before touching code |
| Ambiguous requirements | Clarify first -- do not plan around unknowns |
| User story with acceptance criteria | Map each criterion to a checkpoint |
| "Can you test X?" or "evaluate X?" without stated methodology | `[UNCLEAR: what does success look like? what is the baseline? does methodology matter?]` -- ask before designing anything |

---

## Building the Plan

1. Create a todo list (`TodoWrite` tool) with concrete, verifiable items
2. Specify expected file changes up front -- files, functions, test additions
3. Bake in proof steps -- plan how to verify each change
4. Sanity-check: does the plan address every acceptance criterion?
5. Name known downsides proactively -- trade-offs, risks, limitations the user did not ask about
6. Disclose decision rationale -- name alternatives considered and why the chosen approach was selected
7. **Token budget gate:** If todo count >= 8, load `user-story-estimation` and compute the token budget before presenting the plan for approval. A 14-todo epic with a full 3-agent review pipeline consumes ~500K tokens x 42+ dispatches minimum. Compute this upfront -- not after 3 rate-limit hits.

### No-Placeholder Rule

Every todo must contain what an engineer needs to execute it. These are **plan failures** -- never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" (without specifying what)
- "Write tests for the above" (without naming what to test)
- "Similar to Task N" (repeat the specifics -- tasks may be read out of order)
- Steps that describe what to do without showing how

### Task Granularity (TDD: Test-Driven Development Steps)

Each task MUST be one concrete action (2-5 minutes), touch <=2 files, and is estimated at <=25 tool calls. Any todo exceeding either limit MUST be split before the plan is presented.

For implementation tasks, follow TDD structure:

```
Task N: [Feature or component name]
Files:
  - Create: exact/path/to/NewFile.<ext>
  - Modify: exact/path/to/ExistingFile.<ext>
  - Test:   tests/path/to/TestFile.<ext>

RED   todo: Write the failing test for [behavior]
RED   todo: Run test -- verify it fails for the right reason
GREEN todo: Write minimal implementation to pass the test
GREEN todo: Run full suite -- verify all tests pass
REFACTOR todo: Clean up -- rename, extract, remove duplication; tests must stay green
COMMIT todo: git add / git commit -m "feat[scope]: description"
```

Each step must be its own todo with a distinct status.

---

## BEFORE PROCEEDING

Before building or presenting any plan:

1. Requirements restated in own words -- ambiguities labeled `[UNCLEAR:]`
2. Every acceptance criterion is mapped to a verifiable checkpoint
3. Todo list has no placeholders -- every item is concrete and executable
4. Plan has been reviewed by BOTH a Skeptic Agent AND the plan-reviewer agent, dispatched in parallel (or Three Amigos Refinement if Discovery ran)
5. No todo touches 3+ files or exceeds 25 tool calls without being split

[+] All met -> present the plan and wait for explicit user approval
[-] Any unmet -> resolve the unmet item; do not start implementation

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

[+] All 5 questions answered with no gaps -> proceed to review gate or implementation
[-] Any unanswered question or revealed gap -> stop, revise the plan, then re-run the gate

**For features with background threads or async state:** answer a 6th question before finalizing: "How will a developer diagnose this at runtime?" If no debug output path exists, add an observability todo before presenting the plan. A feature with invisible async state has no failure-diagnosis path.

For any plan with 2+ todos or an architectural decision, dispatch a review agent before implementation. The routing depends on whether Discovery ran:

**If plan.md contains `## Feature Specification` (Discovery ran):**
Invoke the `three-amigos` skill for a Refinement review. Three amigos review replaces the Skeptic for Discovery features. Discovery's three-amigos Refinement runs three independent personas under a unanimous-non-REJECT gate -- coverage that already exceeds the Skeptic + plan-reviewer pairing, so no additional reviewer is dispatched on the Discovery path.

**Otherwise (no Discovery):**
Dispatch BOTH agents in parallel: a **Skeptic Agent** and the **plan-reviewer agent**. Read both verdicts before presenting the plan as final.

Skeptic Agent prompt:

```
You are a Skeptic Agent. Find what this plan is missing.
Do not validate what looks correct -- find what is wrong.

Requirements: [FULL TEXT]
Plan: [FULL PLAN WITH TODOS]

Answer only these five questions:
1. What is the plan NOT addressing that the requirements ask for?
2. What assumptions must be true for this plan to work? (name assumption + what must hold)
3. Strongest argument against this approach?
4. Most likely way this fails in practice?
5. Does any claim that two competing constraints are both satisfied come with a worked example carried end-to-end? If not, name the missing example.

If you genuinely find no gaps after thorough analysis, state that explicitly.
```

Also dispatch the **plan-reviewer agent** using the `agents/plan-reviewer.md` template, passing it the plan path and a worktree. Its role is complementary to the Skeptic's: the Skeptic finds what is MISSING from the plan; the plan-reviewer judges whether what IS in the plan is sound, correctly sequenced, and enforceable. Both verdicts are mandatory reads before the plan is presented as final -- neither agent substitutes for the other.

### Review-Round Cap

Adversarial plan review is capped at round 3. Past round 3, OR as soon as plan length exceeds the length of the file(s) it edits, switch the review surface from plan prose to the actual diff: implement, then review the diff. Do not add more plan-review rounds.

**Self-feeding detector:** a blocking finding located in text written in answer to the previous round -- not in the original plan -- is a manufactured defect. Treat it as the stop signal, not as something to fix with more prose. "Rounds keep finding real defects" and "the review must stop" can both be true at once; the fix is switching surfaces, not adding rounds.

**Permissive-clause closure:** when a review finds an ambiguous or permissive clause, close it by deleting the clause, not rewording it -- rewording can make the bypass easier (e.g. "the user asks" -> "the user directs the change" turned a stretch into a bright-line match). If you must reword, test the new wording against the concrete evasion sentence that exploited the old wording.

**Enforcement is procedural/self-check:** round count > 3 and plan-lines > target-file-lines are both countable from the transcript/plan file. No automated detector exists.

### Untriggered-Branch Cap

If a DoD-specified behavioral branch has had N>=2 fixture attempts that all resolved without triggering it: the next attempt must be a structural redesign (>=5 changed lines vs the prior fixture, measured by diff and pasted), OR the plan escalates to an explicit user ruling quoted in the PR body. Cosmetic retries (<5 changed lines) do not increment the attempt count. Disclosure prose alone cannot close the branch. The comparison baseline is the last attempt that incremented the count (the first fixture, when none has) -- cosmetic retries do not move the baseline.

**Enforcement is procedural/self-check:** successive-fixture diffs and their changed-line counts are pasted artifacts a reviewer can recount; the user ruling, when taken, is quoted in the PR body. No automated detector exists.

---

## Heuristics: You Ain't Gonna Need It (YAGNI) - Simplest Thing - Plain Programmer's Purpose (PPP)

**YAGNI (You Ain't Gonna Need It):** If a todo cannot be traced to a specific acceptance criterion, cut it.
> Forbidden: "We'll probably need it later."

**Simplest Thing That Could Possibly Work:** After the Smart Trust gate, verify a simpler implementation satisfies all criteria. Fewer files, fewer abstractions, fewer dependencies.

**PPP -- Plain Programmer's Purpose:** Per todo: "This [function/class] takes [X] and does [Y]." Can't state it simply? Decompose.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll start coding, plan as I go" | Unplanned work creates cascading mistakes |
| "It's obvious what needs to be done" | Obvious tasks still have sequencing risks |
| "The todo list wastes time" | The list is the audit trail -- skipped items accumulate silently |
| "I'll update todos later" | Later never comes -- update before starting, after finishing |
| "I understand the requirements" | Misunderstood requirements are the most expensive bug |
| "We'll probably need this later" | YAGNI -- not in criteria means not in this plan |
| "This todo touches multiple files but they're closely related" | Related does not mean atomic. 3+ files = compounding scope. Split on file boundaries before the plan is presented. |
| "The plan looks good -- I'll just start" | A plan presented is not a plan approved. Wait for explicit instruction. |
| "The user implied I should proceed" | Implied is not explicit. "Looks good", "go ahead", or "start" are approval. Silence is not. |
| "The user said 'autopilot' / 'just go' -- that overrides plan-first" | When a message says both "autopilot/just go" and "show me first / I want to know your flow," the show-first instruction wins. Explicit plan presentation is the PLAN BEFORE CODE law. "Autopilot" is not an explicit override unless the user also says "skip the plan." |
| "I listed all the main files -- the audit scope is complete" | Listing top-level files from memory or a shallow glob misses references/ subdirectories, recently-added files, and nested content. For any audit task, run a file listing command (e.g. `find .claude/skills -type f -name '*.md'`) before planning. Do not enumerate scope from memory. |
| "I found the bug -- fixing it now" | A request to debug or research is not a request to fix. Present findings first. Wait for instruction. |
| "Plan states a numerical estimate (word count, file size, line count) without measuring" | Measure before writing. Run `wc -w` or `wc -l`. Unverified numerical claims in plans cause failed acceptance criteria. |
| "It's just a quick test, I don't need todos" | Any multi-step task without todos has no review gate. The Skeptic and Three Amigos dispatch rules cannot fire if todos were never created. Create todos first, then execute. |
| "Implementation revealed a dependency on a second file -- I'll modify it" | Scope expansion requires user authorization. STOP. State the dependency and ask before touching any file not in the original plan. |
| "Skeptic or Refinement approved with conditions, I addressed them -- I can proceed" | NO. Review findings change the plan -- user approval of the original does not carry forward. Re-present the revised post-review plan to the user. Wait for explicit re-approval before creating branches or dispatching implementers. |
| "The Skeptic is enough -- the plan-reviewer is redundant" | The two jobs do not overlap: the Skeptic finds what is MISSING; the plan-reviewer judges whether what IS present is sound, sequenced, and enforceable. Both fire by default on every non-Discovery plan with 2+ todos -- dispatch them together, not one or the other. |
| "Round 4 found a real defect, so the review is still productive" | Past round 3 the defects are manufactured by the review itself -- the round-3 cap and the plan-longer-than-file tripwire are the stop signals. Switch review surface to the diff instead of adding rounds. |
| "The fixture almost triggered it -- one more small variation will do it" | Cosmetic retries (<5 changed lines) do not increment the attempt count and cannot close the branch. After two untriggered attempts: structural redesign with pasted diff, or user ruling. |
| "The user replied 'I guess' / 'sure, whatever' -- that's approval" | Hedged assent is not approval -- it signals the plan was too opaque to evaluate. Simplify, define the terms, re-present. Only plain approval ("go ahead", "approved", "looks good") starts implementation; a reply mixing an uncertainty qualifier (such as "I guess", "I think", "somewhat", "whatever") with an approval token ("I guess, go ahead") stays hedged -- re-present, while a casual affirmative with no qualifier ("sure, go ahead") is plain approval. |

---

## Scope and Commitment Sizing

- If a plan covers multiple independent subsystems, split into one plan per subsystem
- Each plan MUST produce working, testable software on its own
- Realism check: can this be completed and verified in this session? If not, commit to the verifiable portion only. State the remainder as a separate commitment explicitly.
- An over-committed partial delivery is worse than a smaller honest delivery.

---

## Red Flags -- STOP

- Code or file edits before Step 0 (restate requirements) is complete -- **STOP. Do Step 0 now.**
- **HARD-GATE:** Plan has 2+ todos, review not dispatched -- **STOP. Check plan.md for `## Feature Specification`. If present: invoke three-amigos Refinement. If absent: dispatch Skeptic + plan-reviewer (both, in parallel). No first edit until review result is read.**
- **HARD-GATE:** About to send a message presenting a design or plan as final -- review not yet dispatched? **STOP. Check plan.md for `## Feature Specification`. If present: invoke three-amigos Refinement. If absent: dispatch Skeptic + plan-reviewer (both, in parallel). The review must be in-flight or complete before the plan is presented as finished.**
- Any todo lacks a concrete description -- **STOP. Fill every description before starting.**
- A single todo touches 3+ files or is estimated at 30+ tool calls -- **STOP. Split the todo before presenting the plan. A todo that wide is a phase, not a task.**
- Plan states a numerical estimate without a `wc` measurement -- **STOP. Measure first. Run `wc -w` or `wc -l`.**
- Next todo started without prior todo's 2-stage review passing -- **STOP. Both stages required before advancing.**
- Implementation started before user gives explicit plan approval -- **STOP. Wait for "go ahead."**
- About to dispatch audit or research agents without listing every dimension the agent must check -- **STOP. Enumerate every file, section, rule, and reference in the prompt before dispatching. Label any dimension you cannot enumerate [UNCLEAR:] and resolve it first.**
- Adversarial plan review is in round 4+, or plan length now exceeds the target file's length -- **STOP. Switch the review surface to the diff (implement, then review the diff). A finding located in text written answering the previous round is a manufactured defect, not evidence to keep reviewing.**
- A plan claims two competing constraints are both satisfied, and no worked example carries one concrete case end-to-end -- **STOP. Demand one worked example carried end-to-end before any further abstract argument. The example either exposes the hidden cost or proves the design absorbs it; abstract debate does neither.**
- A DoD behavioral branch has resolved untriggered across two fixture attempts and the next fixture is another small tweak -- **STOP. The next attempt must be a structural redesign (>=5 changed lines vs the baseline fixture, diff pasted), or the plan escalates to an explicit user ruling quoted in the PR body.**
- Plan presented, user replied with hedged assent ("I guess", "sure, I think") -- even if an approval token appears in the same reply -- and you are about to start implementation -- **STOP. Hedged assent is a comprehension signal, not approval. Re-present the plan in plainer terms and wait for plain approval.**

---

## References

- Simplicity principles, dimensions of simplicity table, quick reference flowchart, assign problems not tasks: `references/SIMPLICITY_PRINCIPLES.md`
