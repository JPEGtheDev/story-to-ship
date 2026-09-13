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

YOU MUST categorize and address every review comment. No exceptions.

**Announce at start:** "I am using the receiving-code-review skill to process review feedback on [PR/change]."

Each new round of PR review comments requires a fresh skill invocation. A load from an earlier round does not carry forward. If new comments arrive after the skill was previously loaded, invoke the skill tool again before triaging.

---

## BEFORE PROCEEDING

1. I have read every comment fully before drafting any response
2. Every comment is categorized (must-fix / defer / discuss)
3. No must-fix comment is dismissed without investigation
4. I am not about to defend rather than understand
5. If new comments arrived since the last round, I have invoked this skill again before triaging them

[+] All met -> proceed to address comments
[-] Any unmet -> complete the triage and reload the skill for the current review round before taking action

---

## The Core Problem

Code review feedback is often treated as a bureaucratic step rather than a signal. The two failure modes are:

1. **Performative agreement** -- saying "good point, fixed!" without engaging with the substance
2. **Defensive rejection** -- dismissing feedback without genuinely considering whether it is correct

Both erode trust. The first produces code that hasn't actually improved. The second produces friction that makes reviewers stop giving honest feedback.

---

## Processing Feedback

For every comment, before responding:

1. **Read the comment fully** -- do not draft a response until you understand what the reviewer is pointing at
2. **Reproduce the concern** -- can you see what they see? If not, ask a clarifying question before defending
3. **Categorize it honestly:**

For a comment from the user, the action in every row below is proposed on the thread,
not applied, in that turn (User Review Comments below).

| Category | Action |
|----------|--------|
| Correct -- I missed this | Acknowledge, fix, thank them specifically for the catch |
| Correct but low priority | Acknowledge as valid, explain why it is deferred, open a tracking issue |
| I disagree -- have a counter-argument | State the counter-argument with reasoning. Do not just dismiss. |
| Inquiry -- reviewer asks "why did X change?" | An inquiry wants the rationale, not a change. Answer on the thread with the reasoning and the evidence that drove the decision (cite the source file, rule, or data). Modify code only if writing the answer reveals the rationale was wrong. Distinct from "I don't understand" below: there the REVIEWER's comment is unclear to you; here the reviewer is asking for YOUR rationale. |
| Bug report phrased as a question (e.g. "why is this not null-checked?") | Not an inquiry -- a change request wearing a question mark. The test is what the reviewer wants: rationale (inquiry) or a code change (bug report), not whether the comment contains the word "why". Categorize and fix like any other correctness finding. For the user's comments, see User Review Comments below: the fix is proposed, not applied, in that turn. |
| I don't understand | Ask a specific clarifying question. Not "can you elaborate?" -- name what specifically is unclear. |
| Style preference (not standards) | Note it is a preference, not a defect. Discuss if needed. |

**When the fix is relocating misplaced content:** Identify the out-of-scope content, remove it from this file, and put it in the correct location. Do not expand the file's scope to justify keeping content that does not belong here. If the content genuinely belongs here, first determine whether the file's scope is correctly stated before deciding to relocate.

### User Review Comments: Propose, Then Stop

**Context:** A review comment from the user on the agent's own PR, whether phrased as a question or
as a statement.

**Forces:** The category table above routes a comment that identifies a defect to an immediate
fix. A fix committed in the same turn removes the user's chance to weigh in on the direction,
and it hides any comment the agent disagrees with behind a diff. The communication skill already
treats a why-question as a request for rationale, not a change; the user's declarative comments
deserve the same pause.

Rules:
- Reply on each thread with the check that was run, whether the comment identifies a problem, and
  the concrete change proposed -- or the reason no change is proposed.
- End the turn with those replies. No fix commit and no implementer dispatch (handing the fix to a
  subagent) for the fix in that turn.
- The fix lands after the user answers, and is then addressed per the Definition of "Addressed"
  below.
- Comments from anyone other than the user keep the category table above.

**Consequences:** A confirmed defect stays unfixed until the user replies; the rule trades that
latency for the user's chance to redirect before a diff exists.

**Enforcement is procedural/self-check:** the checkable signal is a fix commit or an implementer
dispatch in the same turn as the reply to a user review comment. No live detector exists.

---

## Responding to Comments

**Required for every non-trivial comment:**
- Acknowledge what the reviewer found (even if you disagree)
- State your decision: fix, defer, disagree, or answer with reasoning
- If fixing: show the fix or link to the commit
- If deferring: link to the tracking issue
- If disagreeing: state the counter-argument directly; invite further discussion if unresolved
- If answering an inquiry: state the rationale and evidence directly on the thread; do not apologize or revert the code unless the reviewer asks for a change

**Banned phrases:**
- "Good point, will fix!" (without stating what was wrong or how it was fixed)
- "Thanks for the feedback" (as a standalone response that closes the thread)
- "I'll address this separately" (without creating and linking a tracking issue)
- "I think this is fine as-is" (without explaining why)

## Definition of "Addressed"

For must-fix comments, "addressed" requires two things:
1. The code change is committed.
2. The PR thread has a reply explaining what was done.

For comments resolved without a code change -- an inquiry answered with rationale, a disagreement stated with reasoning, or a valid-but-deferred item -- "addressed" means the complete PR thread reply, plus the tracking issue link for deferrals. Do not make a code edit just to close a comment; an unnecessary edit dodges the question the reviewer actually asked.

For the user's comments, the deliverable of the reply turn is the per-thread proposal
(User Review Comments above); the commit and the closing reply follow the user's answer.

Declaring a comment "addressed" before the applicable requirements are complete is an Iron Law violation.

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

For **high signal** comments: address them in this PR before merge. No exceptions; a user's
comment is still proposed first (User Review Comments above).
For **medium signal**: follow documented standards. If standards conflict, escalate.
For **low signal / noise**: ask for specifics. If no specifics come, treat as resolved.

---

## The Disagreement Protocol

**Attack ideas, not people.** Disagreement is about the code or the approach -- never about the reviewer. Phrase every counter-argument as "this approach has [consequence]", not "you are wrong."

When you genuinely believe a reviewer is wrong:

1. **State your counter-argument directly.** "I disagree because [specific reason]."
2. **Do not soften it into ambiguity.** "I see your point, but..." followed by a counter-argument is not direct. "I disagree because X. Here is my reasoning: Y" is direct.
3. **Ask the reviewer to respond.** A unilateral decision to close a contested comment is not resolution.
4. **Escalate if unresolved.** If two rounds of discussion do not resolve it, flag for a third opinion -- do not let it block indefinitely.

---

## Right Wrongs in Review

If a reviewer finds something you missed that you were responsible for catching:

```
1. ACKNOWLEDGE: "This is correct -- I missed it."
2. FIX: Make the change.
3. DO NOT MINIMIZE: Do not frame the reviewer's finding as a preference if it is a defect.
```

The Right Wrongs protocol from the `execution` skill applies here directly. A reviewer finding a real bug is the same as discovering a mistake yourself -- it must be acknowledged cleanly, not glossed over.

---

## Red Flags -- STOP

- If you have read any PR comment and have not yet invoked this skill: **STOP. Load the skill NOW. Work done before loading the skill is unverified by the skill's gates.**
- Dismissing feedback without investigation
- Responding to feedback with "that's out of scope"
- Closing a comment without addressing it or explicitly deferring it with a tracking issue
- Treating approval as permission to skip the fix list
- Implementing a fix without re-running tests
- User review comment read, and a fix commit or an implementer dispatch is about to land in this
  same turn -- **STOP. Reply with the check, the assessment, and the proposal; end the turn; fix
  after the user answers.**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The reviewer is just being pedantic" | Pedantic reviewers still find real bugs. Engage with the substance. |
| "I'll fix this in a follow-up" | Follow-up without a tracking issue means never. Create the issue. |
| "They misunderstood what I was doing" | Maybe. But if a reviewer misunderstands, the code is unclear. Clarify the code or the comment. |
| "This is a style preference" | If it violates `code-quality` standards, it is not a preference -- it is a defect. |
| "The reviewer doesn't understand the full context" | Context is your job to provide. If the reviewer is confused, add context -- do not dismiss the feedback. |
| "I'll expand the scope to cover it" | Maybe the scope genuinely needs expanding. But if the content is out of scope, expanding the scope statement to justify keeping it creates ambiguity. Determine whether the content is truly in scope first. If it is not: remove it and relocate it. |
| "The reviewer asked why -- I need to change something" | A why-question is a request for rationale, not a change request. Answering with a defensive edit or revert destroys correct work and dodges the actual question. Reply with the reasoning and evidence; edit only if the rationale fails re-examination. |
| "The comment names a real defect, so fixing it now is the responsive thing" | The user's comment opens a discussion; a same-turn commit closes it before the user has spoken and hides disagreement behind a diff. Reply with the check, the assessment, and the proposal; end the turn; fix after the answer. |
**Review principles (EgolessProgramming, PeerReview ownership, Structured Walkthroughs, Attack Ideas Not People):** `references/REVIEW_PRINCIPLES.md`
