---
name: receiving-code-review
license: MIT
description: Use when receiving code review feedback on a PR or code change.
---

## Iron Law

```
EVERY COMMENT GETS A GENUINE RESPONSE. YOU MUST CATEGORIZE AND ADDRESS EVERY COMMENT. "LGTM THANKS" IS NOT A RESPONSE.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the receiving-code-review skill to process review feedback on [PR/change]."

---

## BEFORE PROCEEDING

- [ ] I have read every comment fully before drafting any response
- [ ] Every comment is categorized (must-fix / defer / discuss)
- [ ] No must-fix comment is dismissed without investigation
- [ ] I am not about to defend rather than understand

✓ All met → proceed to address comments
✗ Any unmet → complete the triage before taking action

---

## The Core Problem

Code review feedback is often treated as a bureaucratic step rather than a signal. The two failure modes are:

1. **Performative agreement** — saying "good point, fixed!" without engaging with the substance
2. **Defensive rejection** — dismissing feedback without genuinely considering whether it is correct

Both erode trust. The first produces code that hasn't actually improved. The second produces friction that makes reviewers stop giving honest feedback.

---

## Processing Feedback

For every comment, before responding:

1. **Read the comment fully** — do not draft a response until you understand what the reviewer is pointing at
2. **Reproduce the concern** — can you see what they see? If not, ask a clarifying question before defending
3. **Categorize it honestly:**

| Category | Action |
|----------|--------|
| Correct — I missed this | Acknowledge, fix, thank them specifically for the catch |
| Correct but low priority | Acknowledge as valid, explain why it is deferred, open a tracking issue |
| I disagree — have a counter-argument | State the counter-argument with reasoning. Do not just dismiss. |
| I don't understand | Ask a specific clarifying question. Not "can you elaborate?" — name what specifically is unclear. |
| Style preference (not standards) | Note it is a preference, not a defect. Discuss if needed. |

---

## Responding to Comments

**Required for every non-trivial comment:**
- Acknowledge what the reviewer found (even if you disagree)
- State your decision: fix, defer, or disagree with reasoning
- If fixing: show the fix or link to the commit
- If deferring: link to the tracking issue
- If disagreeing: state the counter-argument directly; invite further discussion if unresolved

**Banned phrases:**
- "Good point, will fix!" (without stating what was wrong or how it was fixed)
- "Thanks for the feedback" (as a standalone response that closes the thread)
- "I'll address this separately" (without creating and linking a tracking issue)
- "I think this is fine as-is" (without explaining why)

---

## Distinguishing Signal from Noise

Not all review comments carry equal weight. Before acting:

| Signal strength | Indicator |
|----------------|-----------|
| High | Comment identifies a bug, a test gap, or a correctness issue |
| High | Reviewer points to a specific line and explains the consequence |
| Medium | Style or naming that violates documented standards |
| Low | Preference that differs from documented standards |
| Noise | Vague comment with no specific claim ("this seems off") |

For **high signal** comments: address them in this PR before merge. No exceptions.
For **medium signal**: follow documented standards. If standards conflict, escalate.
For **low signal / noise**: ask for specifics. If no specifics come, treat as resolved.

---

## The Disagreement Protocol

**Attack ideas, not people.** Disagreement is about the code or the approach — never about the reviewer. Phrase every counter-argument as "this approach has [consequence]", not "you are wrong."

When you genuinely believe a reviewer is wrong:

1. **State your counter-argument directly.** "I disagree because [specific reason]."
2. **Do not soften it into ambiguity.** "I see your point, but..." followed by a counter-argument is not direct. "I disagree because X. Here is my reasoning: Y" is direct.
3. **Ask the reviewer to respond.** A unilateral decision to close a contested comment is not resolution.
4. **Escalate if unresolved.** If two rounds of discussion do not resolve it, flag for a third opinion — do not let it block indefinitely.

---

## Right Wrongs in Review

If a reviewer finds something you missed that you should have caught:

```
1. ACKNOWLEDGE: "This is correct — I missed it."
2. FIX: Make the change.
3. DO NOT MINIMIZE: Do not frame the reviewer's finding as a preference if it is a defect.
```

The Right Wrongs protocol from the `execution` skill applies here directly. A reviewer finding a real bug is the same as discovering a mistake yourself — it must be acknowledged cleanly, not glossed over.

---

## Red Flags — STOP

- Dismissing feedback without investigation
- Responding to feedback with "that's out of scope"
- Closing a comment without addressing it or explicitly deferring it with a tracking issue
- Treating approval as permission to skip the fix list
- Implementing a fix without re-running tests

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The reviewer is just being pedantic" | Pedantic reviewers still find real bugs. Engage with the substance. |
| "I'll fix this in a follow-up" | Follow-up without a tracking issue means never. Create the issue. |
| "They misunderstood what I was doing" | Maybe. But if a reviewer misunderstands, the code is unclear. Clarify the code or the comment. |
| "This is a style preference" | If it violates `code-quality` standards, it is not a preference — it is a defect. |
| "The reviewer doesn't understand the full context" | Context is your job to provide. If the reviewer is confused, add context — do not dismiss the feedback. |
**Review principles (EgolessProgramming, PeerReview ownership, Structured Walkthroughs, Attack Ideas Not People):** `.github/skills/receiving-code-review/references/REVIEW_PRINCIPLES.md`
