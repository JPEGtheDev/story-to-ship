# SAAC Summarization Method

## What It Is

State/Assign/Action/Complete (SAAC) is a structured summarization method that extracts **actionable intelligence** from a source. Where abstractive and extractive methods report what the source says, SAAC answers what to do with it.

## The Four Components

| Component | Question it answers | Contents |
|-----------|---------------------|----------|
| **State** | What is this about? | Topic, context, problem, or situation the source addresses |
| **Assign** | Who or what is responsible? | Author's intended audience, subject, owner, or agent of action |
| **Action** | What must be done? | Specific steps, decisions, or behaviors the source calls for |
| **Complete** | What does done look like? | Success criteria, outcomes, or signals that the action was effective |

## Rules

1. **Every component is required.** If the source does not address a component (e.g., no explicit success criteria), state: "[Component]: Not specified in source -- infer from context if possible."
2. **Action items must be specific.** "Improve understanding" is not an action. "Re-read a concept until you can explain it without notes" is an action.
3. **Complete must be verifiable.** A Complete statement like "feels better" is not verifiable. "Can explain the concept to someone unfamiliar with it" is.
4. **Do not invent actions.** Actions must be traceable to the source. If the source implies an action without stating it, note it as inferred: "[Action]: (inferred) ..."
5. **SAAC is not a replacement for the other methods.** It operates in parallel and produces structured output that the synthesizer draws from for its "Actions and Lessons" section.

## Length Guidance

Action item count is a soft cap. Add an item beyond the cap only if it is independently verifiable and not implied by another action.

| Source length | Target action count |
|--------------|---------------------|
| Short (< 1,000 words) | 3-5 actions |
| Medium (1,000-3,000 words) | 5-7 actions |
| Long (> 3,000 words) | 6-8 actions |

## Output Format

Return a single Markdown section with this structure:

```markdown
## SAAC Summary

**State:** [1-3 sentences describing the topic, context, and problem the source addresses.]

**Assign:** [1-2 sentences identifying the intended audience or responsible agent.]

**Action:**
- [Specific action 1]
- [Specific action 2]
- [Specific action n]

**Complete:** [1-3 sentences or bullet points describing success criteria or verifiable outcomes.]
```

## Quality Signals

- A good SAAC summary can be handed to someone who has not read the source and they know exactly what to do.
- A bad SAAC summary has vague actions ("learn more", "consider applying") and immeasurable Complete criteria.
- If the Action list has only one item, look harder -- most sources imply multiple actions.
