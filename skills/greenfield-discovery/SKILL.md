---
name: greenfield-discovery
license: MIT
description: Use when the user describes a new project to build from scratch and no ## Domain Model block yet exists in the conversation.
---


## Iron Law

```
YOU MUST COMPLETE THE FULL DOMAIN INTERVIEW AND RECEIVE THE USER'S DOCUMENTATION ANSWER BEFORE PRODUCING THE ## DOMAIN MODEL BLOCK.
NO ARCHITECTURE OR CODE DECISIONS BEFORE ## DOMAIN MODEL IS WRITTEN.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the greenfield-discovery skill to conduct a domain interview for [project description]."

---

## When to Invoke

Load this skill when the user describes a project they want to build from scratch, before any architecture or implementation discussion begins.

If a `## Domain Model` block already exists in the conversation: DO NOT re-run the interview. Read the existing block and proceed to the next step in the greenfield workflow (architecture or implementation planning). Asking the user to re-describe information already in a `## Domain Model` block is a protocol violation.

---

## Phase 1: Domain Interview

**Context:** The user has described a project idea but the domain is not yet modeled. Architecture and code choices made without a domain model fit the code's convenience rather than the problem's structure.

**Forces:** Two minutes of structured interview prevents weeks of rework caused by building against the wrong entities or the wrong success criteria.

**Solution:** Ask one question per response from each category below. Wait for the answer before asking the next. Adapt wording to the user's context -- do not recite questions verbatim.

**Forces (adapt wording):** Verbatim recitation produces an interrogative tone that yields shorter answers and misses domain structure the user would have surfaced through natural dialogue.

### Question Bank

**Problem (ask at least one):**
- "What specific problem does this project solve? Who experiences it, and what happens when it goes unsolved?"
- "What does the user do today without your solution? What breaks or frustrates them?"

**Users (ask at least one):**
- "Who are the primary users? What is their technical background?"
- "Do different user roles have different needs from the system?"

**Core Entities and Operations (ask at least one):**
- "What are the main things this system tracks, creates, or transforms?"
- "What does a user actually DO with those things -- create, run, share, export, configure?"

**Success Criteria (ask at least one):**
- "What does success look like for a user after they've used this system?"
- "What would make a user say 'this solved my problem'?"

### Contradiction Detection

During the interview, compare each answer against prior answers. If an answer contradicts a previous one, flag it immediately before asking the next question:

> "[UNCLEAR: you said [X] but also [Y] -- these appear mutually exclusive because [reason]. Which is correct?]"

DO NOT proceed to the next question while a contradiction is unresolved. Wait for the user to clarify, then continue.

**Forces (resolve contradictions immediately):** Unresolved contradictions compound -- a domain model built on two incompatible premises requires a full re-interview to correct.

---

## Phase 2: Documentation Question (LAST -- MANDATORY GATE)

After all interview question categories are covered, ask this exact question as the final output of the interview phase -- nothing else follows it:

> "Do you have any supporting documentation, whitepapers, or domain references I should read?"

**The `## Domain Model` block MUST NOT appear in any response until the user answers this question.**

- User provides docs -> proceed to Phase 3.
- User says no -> proceed directly to Phase 4.

---

## Phase 3: Read Documentation (if provided)

**Context:** When the user provides documents, files, or URLs, those sources may refine, confirm, or contradict the interview answers. Skipping this phase produces a domain model that ignores authoritative domain knowledge.

1. Read each provided document.
2. Extract domain-specific vocabulary: entity names, operation names, domain constraints, success metrics.
3. Compare extracted concepts against interview answers. Note confirmations, expansions, and contradictions.
4. For any contradiction between docs and interview: flag it -- "[UNCLEAR: interview stated X; document states Y -- which is authoritative?]" -- and resolve before proceeding.

DO NOT skip this phase if documents are provided. The domain model MUST incorporate document content.

**Forces (read provided docs):** Documents provided by the user are authoritative domain sources; ignoring them produces a model that contradicts the user's own reference material, invalidating every downstream architecture decision built on it.

---

## Phase 4: Produce ## Domain Model

Using the completed interview answers and any documentation, produce the `## Domain Model` block.

Schema reference: `references/DOMAIN_MODEL_SCHEMA.md` -- required fields, BAD/GOOD examples, and completeness gate.

```
## Domain Model

**Problem:** [one paragraph -- project-specific, no placeholders]

**Users:** [named roles with context -- no "end users" or "people"]

**Core Entities:** [domain-specific names and operations -- no generic names]

**Success Criteria:** [observable user outcomes -- not implementation milestones]

**Open Questions:** [any [UNCLEAR:] items from interview/docs, or "None"]
```

Every field MUST contain project-specific vocabulary. Run the completeness gate in `references/DOMAIN_MODEL_SCHEMA.md` before producing the block.

### Downstream Contract

The `## Domain Model` block is the authoritative domain source for `greenfield-architecture` and `greenfield-bootstrap`. When multiple `## Domain Model` blocks exist in conversation history, the most recent is authoritative.

`greenfield-architecture` and `greenfield-bootstrap` MUST read the existing `## Domain Model` block before asking the user any questions about their project. They MUST NOT ask the user to re-describe or re-paste domain information that is already present in the block.

---

## BEFORE PROCEEDING

Before producing the `## Domain Model` block, verify all of the following:

1. All interview question categories covered: problem, users, core entities/operations, success criteria
2. No unresolved contradictions -- every `[UNCLEAR:]` flag has been answered and cleared
3. Documentation question asked: "Do you have any supporting documentation, whitepapers, or domain references I should read?"
4. User has answered the documentation question
5. If docs provided: docs read, domain concepts extracted, contradictions resolved
6. Completeness gate from `references/DOMAIN_MODEL_SCHEMA.md` passed: all Required fields contain project-specific vocabulary

[+] All 6 met -> produce the `## Domain Model` block
[-] Any unmet -> complete the unmet phase; do not produce the block until all 6 conditions are met

---

## Red Flags -- STOP

- Producing `## Domain Model` before asking the documentation question -> STOP. Ask the question. Wait for the answer. Then produce the block.
- Producing `## Domain Model` with placeholder text ("your domain", "the system", "entities", "Model", "Item") -> STOP. Replace every placeholder with project-specific vocabulary before showing the block.
- Architecture or code recommendations appearing before `## Domain Model` is written -> STOP. Finish the domain interview first. No architecture without a domain model.
- Re-running the interview when a `## Domain Model` block already exists in the conversation -> STOP. Read the existing block. Do not ask the user to repeat information.
- Continuing past a contradictory answer without flagging it -> STOP. Write the `[UNCLEAR:]` label at the point of detection. Resolve it before asking the next question.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The user's initial description is detailed enough -- I can skip the interview" | A detailed description is not a domain model. The interview extracts structure the user does not know they have not stated. Missing structure becomes wrong architecture. |
| "The documentation question is unnecessary -- they already mentioned they have no docs" | The documentation question MUST be the last line of the interview phase regardless. Confirm explicitly before producing the model. |
| "The ## Domain Model has some placeholders but I will fill them in during architecture" | A model with placeholders is not a model. Architecture decisions made against placeholders produce the wrong architecture. Fill every field now. |
| "I see a contradiction but it is minor -- I will note it later" | Minor contradictions compound. Flag `[UNCLEAR:]` at the moment of detection and resolve before asking the next question. "Later" does not exist. |
| "greenfield-architecture already knows the domain -- I will skip reading the ## Domain Model" | Read the existing `## Domain Model` block. The most recent block is authoritative. Architecture built from a stale or assumed domain produces a misaligned design. |
| "The user is in a hurry -- I will ask fewer questions" | The interview requires at least one question per category: problem, users, core entities, success criteria. Speed is not grounds for skipping categories. A rushed domain model produces the wrong architecture. |

---

## References

- `references/DOMAIN_MODEL_SCHEMA.md` -- required field definitions, BAD/GOOD examples, completeness gate
- `references/EXAMPLE_RUN.md` -- sample session: "I want to build a mathematical model simulator"
