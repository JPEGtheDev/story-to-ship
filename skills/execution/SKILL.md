---
name: execution
license: MIT
description: Use when executing any non-trivial implementation work.
---


## Iron Law

```
YOU MUST PLAN BEFORE CODE, PROVE BEFORE SHIPPING, AND DELEGATE BEFORE DROWNING.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the execution skill to [implement/fix/refactor] [brief description]."

For planning a multi-step task -> invoke **writing-plans** skill first.
For subagent dispatch or delegation -> invoke **subagent-driven-development** skill.
For debugging -> invoke **systematic-debugging** skill.
For completion claims -> invoke **verification-before-completion** skill.

---

## BEFORE PROCEEDING

Before writing any code or claiming any task done:

1. Requirements restated in own words -- ambiguities labeled `[UNCLEAR:]`
2. For multi-step tasks (3+ steps): tasks for this work exist in the task tool (TaskList)
3. Required skills for this domain are loaded (check session-bootstrap On Start table)
4. No placeholders in any todo -- every item is concrete and executable
5. Verification method is identified -- know what command proves success before starting

[+] All met -> begin execution
[-] Any unmet -> resolve now; do not write a single line of code first

---

## Core Principles

- **Keep It Simple:** Straightforward approach first. Introduce abstraction only when it pays for itself.
- **Senior-Level Standards:** Diagnose root causes. Refuse temporary workarounds.
- **Surgical Precision:** Touch only what the task requires. A smaller diff is always better.
- **Drive to Completion:** Act on what you know. Resolve blockers yourself.

---

## Disciplined Iteration

### Keep Commitments

**Rules:**
- Every announced item must be delivered, OR explicitly acknowledged as undelivered before the response ends
- The format for a missed commitment: `COMMITMENT NOT MET: I committed to [X]. I could not complete it because [specific reason]. Next step: [concrete action]`
- Never let a commitment expire silently -- do not end a response with an announced item quietly dropped
- "I'll get to it next turn" is not a completion -- only "I completed X, verified by [evidence]" is

**Mid-session expectations drift:** If user feedback mid-session reveals your understanding of a requirement was wrong, stop and re-execute Step 0 (Clarify Expectations) before continuing. Do not silently absorb the correction and continue on the old plan.

### The Work Loop

For every planned item, before writing code:

**PPP Gate (Plain Programmer's Purpose):** State what the function or class you are about to write does in one plain sentence: "This function takes [X] and returns [Y] by doing [Z]." If you cannot state it simply, you do not understand the requirement well enough to code it. Stop and re-read the requirements.

```
1. Flag it as in-progress. Reload the relevant skill (session-bootstrap refresh rule).
2. PPP: State the purpose of the code you're about to write (one sentence)
3. Make the change
4. Prove it works (compile, test, inspect diff)
5. Flag it as done
6. DISPATCH REVIEWERS -- Stage 1: spec-compliance-reviewer.md, then Stage 2: code-quality-reviewer.md
   Do NOT pick up the next todo until both stages pass.
7. Commit when you reach a logical boundary
8. Advance to the next item
```


### Communicating Progress

- Summarize at the milestone level, not the keystroke level
- State what changed, what was validated, and what comes next

For temporal declaration and attention cost rules, see `references/EXECUTION_PATTERNS.md`.

### Commit Rhythm

- One commit per logical unit -- not per file, not per session
- Every commit must build and pass tests on its own
- Follow conventional commit format (see `versioning` skill)
- Never lump unrelated changes together

### Red Flags -- STOP

If you catch yourself thinking any of these:
- "I'll mark it done after I clean up a few things"
- "The tests will probably still pass"
- "I'll commit everything at the end"
- "Just one more small change before I verify"
- "This is done enough to move on"
- "Evidence contradicts the plan but I'll finish this step first" -- **Stop. Confront reality immediately.** State what the plan assumed, what evidence shows, and what that means for remaining todos. Revise the plan before proceeding, even if it voids completed work. Continuing on a plan you know is wrong is not progress.
- "I just inserted an item into a numbered list" -- **Stop. Re-read the full list from top to bottom to verify sequential numbering. Duplicate or out-of-sequence numbers must be fixed before the next edit call or commit.**
- "I see a Don't Repeat Yourself (DRY) violation in code I am currently modifying" -- **STOP. Fix it in this commit or open a tracking issue now. Walking past it makes you the author.**

**All of these mean: Stop. Run the full verification gate before advancing. See `verification-before-completion` skill.**

---

## Prove It Before You Ship It

**REQUIRED: Load and invoke the `verification-before-completion` skill** -- this means calling the `skill` tool, not referencing the skill name in text. A completion claim made without a `skill.invoked` event for `verification-before-completion` is a protocol violation. Runtime user-visible bugs found after a "fully implemented" claim are the direct cost of skipping this load.

Before claiming any task done:
- Diff: `git --no-pager diff --staged` -- read every hunk for accidental changes. **Applies to ALL file types including documentation. Documentation commits are not exempt.**

For project-specific build, test, and format commands, see `references/PROJECT_COMMANDS.md`.

---

## Pursue Clarity

After something works but before you commit: **"Is there a cleaner way to express this?"**

### Behavior Preservation Gate (Refactoring)

1. Green baseline before any refactoring changes
2. Structural changes only (rename, extract, move) -- no new behavior
3. Green after each discrete change
4. If a test turns red: you changed behavior. Revert and re-examine.

[+] All steps green -> proceed to commit
[-] Baseline fails -> fix tests before refactoring; do not start structural changes
[-] Any step turns red -> you changed behavior; revert before proceeding

**If you discover a bug while refactoring: stop, record it, finish the refactor, then fix the bug as a separate commit.**

### Trade-Off Discipline

For trade-off discipline structure and the Approach A/B/Choice template, see `references/EXECUTION_PATTERNS.md`.

---

## Make It Work, Make It Right, Make It Fast

1. **Make it work** -- pass the tests; behavior is correct
2. **Make it right** -- refactor: clean design, no duplication, clear names
3. **Make it fast** -- optimize: only after correctness and cleanliness are established

**Gates:**

| Phase | Gate question | If not met |
|-------|---------------|-----------|
| Make It Right | Do all tests pass? | Return to Make It Work |
| Make It Fast | Is the design clean and duplication removed? | Return to Make It Right |

**Red Flags:**
- Optimizing code that does not yet pass its tests
- Refactoring while tests are red (behavior is unknown)
- Profiling before a clean design exists (profiling a mess optimizes the wrong thing)

For the relationship between Make It Work, Make It Right, Make It Fast (MIWMIRMIF) and the TDD cycle, see `references/EXECUTION_PATTERNS.md`.

---

### Mode Declaration

When a response combines two or more phases:
```
MODE: [Research / Planning / Implementation / Verification / Review]
```

---

## Right Wrongs

When a mistake is discovered:

```
1. ACKNOWLEDGE: "I was wrong about [X]." No minimizing.
2. STATE WHAT WAS WRONG: "I stated [Y]. The correct answer is [Z]."
3. STATE THE IMPACT: "This affected [what work / what understanding]."
4. FIX IT: [correction with evidence]
```

**Forbidden:** "To be fair...", "There was some ambiguity...", "Technically...", moving on without acknowledging.

**Symmetric Right Wrongs:** If a user instruction will produce a defective result, say so before acting: "I'll proceed if you confirm, but this will cause [specific consequence]."

---

## Continuous Refinement

After a mistake, apply the Continuous Refinement protocol -- see `references/EXECUTION_PATTERNS.md`.

---

## Skill Dispatch Table

For the domain-to-skill dispatch lookup, see `references/EXECUTION_PATTERNS.md`.

---

## Prohibited Patterns

1. **Waiting for a green light** -- if the task is defined, execute
2. **Declaring done without proof** -- every completion claim needs evidence
3. **Doubling down on a stuck approach** -- halt, rethink, restart
4. **Gold-plating simple work** -- match effort to complexity
5. **Walking past defects** -- address or log what you find
6. **Believing empty output** -- cross-check with a second method

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I already know what to do, the plan step is obvious" | Obvious steps fail in unexpected ways. YOU MUST execute the full PPP gate for every todo -- no shortcuts. |
| "The todo is small, no review needed" | Small todos introduce the same bugs as large ones. YOU MUST dispatch both reviewer stages after every todo without exception. |
| "I'll review the spec compliance myself, no need to dispatch" | You wrote the code -- you will rationalize away the gaps. Dispatch spec-compliance-reviewer.md every time. |
| "The previous todo had no issues, this one is probably fine too" | Each todo is independent. Prior clean reviews do not carry over. Dispatch reviewers after this todo. |
| "I'm close to the end, I'll skip the Skeptic for this todo" | End-of-plan todos are the most likely to drift from the original scope. The Skeptic Agent is mandatory regardless of position in the plan. |
| "Inline nit fix is trivial, no review needed" | Inline fixes are unverified by default. If the fix is a structural change (heading level, path format, sentence replacement), dispatch a re-review or apply only to content you can verify in the same view call. |
| "After a rate limit, I can resume dispatching immediately -- my last checkpoint shows what was in flight" | A rate limit severs the agent's awareness of what agents completed, errored, or were interrupted. Dispatch a validation-only batch first and wait for the result before dispatching any continuation agents. |
| "User correction deferred 'for the self-review later' -- I'll remember it" | Memory does not survive rate limits, context compactions, or session summaries. File deferred corrections immediately as a task via TaskCreate or as a session note. "I'll remember" is not a commitment mechanism. |
| "This is just a position/ordering/default value change - not real behavior" | If the change is observable (rendering differs, field value differs, control flow path changes), it requires a failing test first. Observable = testable. No exceptions. |
| "User asked 'can we X' -- that's an instruction to implement X" | A question phrased as 'can we X' is a design probe, not an implementation approval. Present options and wait for explicit confirmation ("yes, do it") before touching any files. |

---

## Quick Reference

See `references/EXECUTION_PATTERNS.md` for: quick-reference flowchart, Profile Before Optimizing, Assign Problems Not Tasks, Technical Debt Visibility, Trade-Off Discipline template, and Continuous Refinement protocol.
