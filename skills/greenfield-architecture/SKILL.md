---
name: greenfield-architecture
license: MIT
description: Use when a new project needs its primary language, runtime or framework, or initial architecture chosen.
---

## Iron Law

```
YOU MUST ASK THE USER'S FAMILIARITY WITH THE CANDIDATE STACKS BEFORE RECOMMENDING ANY ONE, AND RUN THE DECISION-DEFERRAL DIAGNOSTIC ON EVERY ARCHITECTURAL DECISION BEFORE EMITTING THE ## Architecture Decision BLOCK.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the greenfield-architecture skill to recommend a language, runtime, and initial architecture for [project description]."

---

## When to Invoke

Load this skill when a developer starts a new project and needs a primary language, a runtime or framework, and an initial architecture. The skill writes no files, generates no stories, and creates no project. It ends with the `## Architecture Decision` block.

A user who has only an idea and wants the full domain interview is pointed to the `greenfield-discovery` skill. The bare path below still works without it.

---

## Input Paths

**Context:** The skill starts from two situations: the conversation holds a `## Domain Model` block, or it holds none.

**Forces:** A user asked to re-describe what the block already says loses trust and time. A bare invocation has no facts, so recommending without three basic facts guesses.

- **Domain-model path.** Use the most recent `## Domain Model` block. Its five fields are Problem, Users, Core Entities, Success Criteria, and Open Questions. NEVER ask the user to re-describe anything those fields contain. Deployment target is not a block field, so ask for it unless the conversation already states it.
- **Bare path.** No block exists. Ask only problem type, output type, and deployment target before recommending.

### Turn Order

| Path | Turn 1 | Turn 2 | Turn 3 |
|------|--------|--------|--------|
| Domain-model | Ask only the context facts the block lacks (facts this skill needs that the block does not hold, such as deployment target), name two or three candidate stacks without recommending one, and ask familiarity | Recommendation and `## Architecture Decision` block | none |
| Bare | Ask only problem type, output type, deployment target | Name two or three candidates without recommending one, ask familiarity | Recommendation and `## Architecture Decision` block |

Name two or three candidates, never more. Candidates come from no fixed list of stacks; name what fits the problem.

---

## Familiarity Check

**Context:** The developer maintains the result. A stack that fits the problem but that the developer cannot maintain fails after the first week.

**Forces:** Naming one stack first anchors the answer and hides a mismatch. Asking about several candidates first surfaces the mismatch before any recommendation exists.

Name the candidates and ask the user to self-report familiarity with each. DO NOT present any single stack as the recommendation before the answer.

When the user reports low familiarity with the candidate you would recommend ("I've never used it", "I want to try it", "I don't know the syntax", or a statement meaning the same), the reply MUST contain the marker `[LOW FAMILIARITY]` followed by the exact question:

Would you like me to suggest an alternative stack?

A reply reporting good familiarity triggers neither the marker nor the question.

After `[LOW FAMILIARITY]`:

- **"no":** keep the stack and record the low familiarity as the language decision's risk.
- **"yes":** offer exactly one alternative and ask familiarity for it. If that one is also low, proceed with the risk recorded. Offer at most one alternative; NEVER loop.

User declines to report familiarity: ask once more at most, then proceed and record "familiarity not reported" as the language decision's risk.

---

## Decision-Deferral Diagnostic

**Context:** The reference below assumes a plan with todos. This skill runs before any plan or todos exist.

**Forces:** Running the questions from memory drifts from the text. Reading them against a plan that does not exist yields no answer.

Load the decision-deferral reference of the `writing-plans` skill. It sits in the references folder of the `writing-plans` skill directory, a sibling of this skill's base directory, and it is the reference that the Decision-Deferral Gate section of the `writing-plans` skill names. Read it before the first decision. If it cannot be found or read, stop and tell the user so; NEVER run the diagnostic from memory.

Apply its three questions (Blocked? Needed? Costly?) to each architectural decision automatically, and record the verdict: `DECIDE NOW` with a named risk, `DEFER -- revisit when [condition]` with a measurable condition (an observable event), or `[UNCLEAR:] -- answer [question]` (a blocking open question). The user never invokes a separate skill for this.

At this stage no plan or todos exist, so read the reference's questions against the domain model's Success Criteria and the requirements the user stated. The `## Architecture Decision` block spells the deferral verdict `DEFERRED -- revisit when [condition]`.

---

## Architecture Decision Block

**Context:** The block is the skill's only output, and the plan that follows reads it.

**Forces:** An omitted field looks like a decision nobody faced. A vague field cannot be checked. A guess at a blocked field hides the open question.

Fields and rules:

- **Language** and **Runtime/framework:** always decided, each with a one-sentence rationale and a `Risk:` clause. Low familiarity and "familiarity not reported" go in the Language line's risk.
- **Persistence** and **API boundary** (application programming interface, the contract between components): decided, `DEFERRED -- revisit when [condition]`, or `[UNCLEAR:] -- answer [question]` when an open question blocks it; the reply then asks that question. A decided "none" with its reason counts as decided. Language and runtime are NEVER unclear in an emitted block.
- **Implementation-level choices** the project has (an object-relational mapper (ORM), specific libraries): each appears as `DEFERRED -- revisit when [condition]` unless the user stated one as a requirement; then it is recorded as decided, with "stated by the user" as its rationale. The plan decides the rest. NEVER omit one.

```
## Architecture Decision

Language: [name] -- [one-sentence rationale]. Risk: [named risk]
Runtime/framework: [name] -- [one-sentence rationale]. Risk: [named risk]
Persistence: [one form: decided choice, or "none" with reason -- rationale. Risk: named risk / DEFERRED -- revisit when measurable condition / [UNCLEAR:] -- answer question]
API boundary: [one form: decided choice, or "none" with reason -- rationale. Risk: named risk / DEFERRED -- revisit when measurable condition / [UNCLEAR:] -- answer question]
Implementation-level choices:
- [ORM or library]: DEFERRED -- revisit when [measurable condition]
```

Each field takes exactly one value: delete the bracketed alternatives it does not use.

A measurable condition names an observable event, such as "when the first integration test touches the database layer". "Later", "when needed", "eventually", and "when the time is right" fail.

---

## Failure Behavior

**Context:** Each rule covers a case where the skill would emit a block it cannot stand behind, or would loop.

**Forces:** Stopping too early wastes the user's turn. Emitting anyway hides the gap.

- **Contradictory requirements that block the language or runtime choice:** ask the one question that resolves it. DO NOT emit the block until it is answered.
- **An `[UNCLEAR:]` open question in the domain model:** it blocks only the decisions it bears on. Surface it; NEVER guess those decisions. Decide the rest.
- **User asks to defer the language or runtime:** refuse with a one-line reason: every later step needs them.
- **User proposes a vague re-entry condition:** rewrite it as a measurable one.
- **Deferral reference missing or unreadable:** stop and say so.

---

## BEFORE PROCEEDING

Before emitting the recommendation and the `## Architecture Decision` block, verify all of the following:

1. Input path settled: the most recent `## Domain Model` block was read, or the three bare-path facts (problem type, output type, deployment target) were asked and answered
2. Two or three candidates named (never more) and familiarity answered (or declined twice and recorded as "familiarity not reported")
3. `[LOW FAMILIARITY]` handled if low familiarity was reported: the question was asked and the answer applied
4. The decision-deferral reference was read and its diagnostic ran on every architectural decision
5. No blocking contradiction or blocking `[UNCLEAR:]` remains on the language or runtime; a blocking `[UNCLEAR:]` on persistence or API boundary sits in its field and its question was asked
6. Every deferred item carries a measurable condition

[+] All 6 met -> emit the recommendation and the block
[-] Any unmet -> complete the unmet step; DO NOT emit the block until all 6 are met

---

## Red Flags -- STOP

- Presenting a single stack as the recommendation before the user answered the familiarity question -> STOP. Name the candidates and ask first.
- Asking the user to re-describe the problem, users, entities, or success criteria when a `## Domain Model` block exists -> STOP. Read the block.
- Reply to low familiarity lacks `[LOW FAMILIARITY]` or the exact question -> STOP. Add both.
- Offering a second alternative stack, or asking about alternatives in a loop -> STOP. One alternative at most, then proceed with the risk recorded.
- Deferring the language or runtime -> STOP. Decide both; refuse the deferral in one line.
- A deferred item with a condition like "later", "when needed", or "eventually" -> STOP. Rewrite it as an observable event.
- Omitting the ORM or specific libraries from the block because "the project has none yet" -> STOP. List them as deferred with a measurable condition.
- Running the diagnostic from memory because the reference could not be read -> STOP. Say so and stop.
- Writing files, generating stories, or scaffolding the project -> STOP. The skill ends with the block.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "One stack is obviously right, so asking familiarity wastes a turn" | The best stack the developer cannot maintain is the wrong stack. The question costs one turn; a mismatch costs the project. |
| "The domain model is vague, so I will ask the user to restate it" | Read the block. Surface its `[UNCLEAR:]` items and ask only about those and the missing context facts. |
| "The user said they want to try the stack, so low familiarity is a plus" | Wanting to try it is low familiarity. Emit `[LOW FAMILIARITY]` and the question; the user decides. |
| "The ORM is obvious, so I will decide it now" | Implementation-level choices are DEFERRED in the block unless the user stated one as a requirement. The plan decides the rest; record the observable condition. |
| "A deferred item can say 'revisit later'; everyone knows what it means" | Nobody else can check "later". Name an event someone else can observe. |
| "The user asked to defer the language, so I will comply" | Every later step needs the language and runtime. Refuse in one line and decide them. |
| "I remember the diagnostic well enough to skip reading the reference" | A memory of the diagnostic drifts from the text. Read the reference, or stop and say it cannot be read. |
| "The user said no to an alternative, but a second alternative might land" | One alternative at most. Keep the stack, record the risk, and proceed. |

---

## Related Skills

- `greenfield-discovery` -- produces the `## Domain Model` block this skill reads
- `writing-plans` -- owns the decision-deferral reference and its Decision-Deferral Gate
