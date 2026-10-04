# Decision Deferral Reference

Run the deferral diagnostic on every significant architectural or infrastructure component a plan would add, before any todo is written. The diagnostic asks three yes/no questions and records one verdict per component: decide it now, defer it until a named condition, or mark it unclear. The writing-plans gate runs the diagnostic; this file holds everything needed to apply it.

---

## Significant Component

A component is significant when the choice is hard to reverse, adds an external dependency (software the project does not own and must track), or fixes a boundary that other work builds on. Examples: a persistence layer, messaging, an external service, a language or framework. Default for borderline cases: when borderline, run the diagnostic.

A component that already exists in the repo and is not added by the plan is not diagnosed, because the plan did not choose it.

---

## The Three Questions

Answer each question yes or no for the component.

1. **Blocked?** Do two or more requirements contradict each other, or is a fact missing that stops you from answering the other questions? What the task or issue text asserts or presupposes counts as stated; for example, a request that compares two client libraries for a message bus states that the bus is in use.
2. **Needed?** Does a todo, test, or requirement in the plan need the answer? The simplest valid option is the simplest option that satisfies every stated requirement and adds no new component or dependency (direct calls instead of a broker, no cache, standard-library access instead of a library); not adding the component counts as an option. Needed is yes when no simplest valid option exists (a language, a first data store), and no when one exists and lets every todo proceed.
3. **Costly?** Once other work builds on the choice, is reversing it expensive (rework across more than one todo, a data migration, or a changed interface)?

## Verdict Rule

Apply the rows in order. The first row that matches decides the verdict.

| Answers | Verdict |
|---------|---------|
| Blocked = yes | `[UNCLEAR:] -- answer [question]` -- name the specific contradiction or the specific missing-fact question |
| Needed = no | `DEFER -- revisit when [condition]` -- the condition must pass the rubric below |
| Needed = yes, Costly = yes | `DECIDE NOW` -- carry a named risk: what goes wrong if the choice is left open |
| Needed = yes, Costly = no | `DECIDE NOW` -- pick the simplest valid option; the named risk is the todo or requirement that cannot proceed without it |

---

## Why DEFER: You Ain't Gonna Need It (YAGNI)

YAGNI says to build only what the plan needs now. A choice that nothing forces yet, because the simplest valid option lets every todo proceed, is a guess about the future, and a wrong guess costs rework. Deferring trades a possible later migration for not guessing now: the simplest valid option carries every todo meanwhile, the facts that settle the choice arrive with the work that needs it, and the measurable condition bounds when the migration is weighed.

## Why DECIDE NOW: Named Risk

A costly choice that no todo can proceed without cannot wait: each todo written on top of an open choice adds rework if the choice lands differently. Naming the risk proves the decision is forced. If you cannot say what goes wrong when the choice stays open, nothing forces it, and the verdict is DEFER.

---

## Measurability Rubric for a DEFER Condition

A measurable condition names an observable event or threshold that someone else can check without asking you what you meant.

- Passing: `when the first integration test touches the database layer`
- Failing: `when the time is right`

These vague words fail on their own: "later", "when needed", "eventually", "when the time is right". The list is illustrative: any condition that names no observable event or threshold fails.

---

## Failure-Path Rules

- A DEFER whose condition is only vague language, or mixes vague clauses with no measurable clause, is rejected and rewritten as a measurable condition. If no measurable condition can be named, the verdict becomes `[UNCLEAR:] -- answer [question]` where the question asks what would force the decision.
- A DECIDE NOW that depends on a fact the plan does not state becomes `[UNCLEAR:] -- answer [that fact]` only when it decides, by itself, whether an option satisfies a stated requirement or contradicts one. A fact that only ranks the valid options (every option still works whichever way the fact goes) does not block: pick the simplest valid option and record the unstated fact it assumes as the named risk. An unstated requirement is a missing fact, which the Blocked question catches.
- A DECIDE NOW with no nameable risk is malformed and is not emitted; the verdict falls to DEFER because nothing forces the decision.
- An `[UNCLEAR:]` with no named question or contradiction is malformed.
- A todo that depends on a DEFER component uses that component's simplest valid option and adopts no other option; a todo that needs an option beyond the simplest valid option is rewritten or removed. An `[UNCLEAR:]` component gets no todo until it is resolved.
- The diagnostic runs after the Situation Gate of writing-plans. For the component it covers, a DEFER verdict wins over that gate's row "Architectural decision".
- An `[UNCLEAR:]` verdict falls under the writing-plans "Red Flag" on `[UNCLEAR:]` markers: resolve it (ask the owner, the person who assigned the work, or run Discovery, the clarifying step of the three-amigos skill) before the plan is presented, then re-run the three questions for that component.

---

## Recording Verdicts

Write one line per component in the plan file, before the todos. Each line names the component and its verdict in the exact spelling above.

A plan with no significant component records the exact line:

```
Deferral gate: no significant components
```
