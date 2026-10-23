---
name: reviewing-outside-contributions
license: MIT
description: Use when posting a review comment, requested change, or closing note to a non-owner contributor on a public PR or issue thread.
---


## Iron Law

```
A FINDING ON A PUBLIC THREAD STATES WHAT THE CODE DOES, NEVER WHAT THE AUTHOR MUST NOT KNOW.
YOU MUST write every sentence as an observation, its evidence, or its resolution. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the reviewing-outside-contributions skill to [apply/audit/enforce]."

---

## Reviewing Outside Contributions

**Context:** Text addressed to a non-owner contributor on a public PR or issue thread -- a review comment, a requested change, a closing note.
**Forces:** Evidence-discipline directness (the honesty skill) is calibrated to internal work; left unmodulated for a public audience it degrades into bluntness and attribution about the author instead of the artifact. Correcting for that risk in the other direction degrades into warmth performance, where the finding gets buried under politeness. Public threads are permanent, are read by people outside this conversation, and represent the project -- the register has to survive both failure modes at once.

Rules:

- The review register is informational: every sentence is an observation, its evidence, or its resolution. No emotional decoration in either direction -- not flowery, not harsh.
- No apology framing around findings ("sorry, but...", "unfortunately...", "I hate to say..."). An apology is repair for the reviewer's own error, not packaging for information about the artifact. If the review itself was wrong, correct it plainly -- that is the only apology context on a review thread.
- Banned attribution classes are intent, honesty, and competence/knowledge -- a finding states what the code does, never what the author must not know, understand, or have tested.
- Every negative finding pairs an observation with its evidence and what resolves it.
- No praise openers. No closers that mock or gatekeep. Imperatives target the artifact, not the person.
- A closing condition is permitted when it names the specific artifact change and what resolves it. It is banned when it conditions the reviewer's attention or goodwill on the author, or replaces the named change with a characterization of the author's work.

BAD: "The testing claim (\"all 33 skills discoverable via `opencode run`\") cannot be true of this diff, since no code path registers a skill. Please re-test for real and paste the actual output."
GOOD: "The testing claim states all 33 skills are discoverable via `opencode run`. I looked at the skill-loader module and found no code path that registers a skill with that command. A pasted transcript of the actual run would resolve the discrepancy."

PERMITTED: "Fix the migration function at line 42 before this can merge."
BANNED: "Happy to re-review once the code, README, and PR description agree with each other."
The distinguishing test: PERMITTED names one artifact and the change that resolves it; BANNED names no artifact change and instead makes the reviewer's continued attention conditional on the author's general effort.

## BEFORE PROCEEDING

1. Every sentence is an observation, its evidence, or its resolution
2. No praise opener, no apology framing around a finding, no attribution of intent, honesty, or competence
3. Every negative finding names the evidence and the change that resolves it
4. Any closer names a specific artifact change, or is omitted
5. All output is ASCII

[+] All met -> post the comment
[-] Any unmet -> rewrite the offending sentence before posting

---

## Red Flags -- STOP

- About to post text to a public PR/issue thread containing a praise opener, an author attribution (intent, honesty, or competence), or an apology-framed finding -- **STOP. Apply this skill's rules: state the observation, its evidence, and what resolves it.**
- About to open a public review comment with praise or thanks before the finding ("Great work", "Thanks for the PR") -- **STOP. Start with the observation.**
- About to write a sentence whose subject is the author's knowledge, effort, or testing ("you did not test", "you clearly missed") -- **STOP. Rewrite with the code or the artifact as the subject.**
- About to close with "happy to re-review once..." or any line that makes your attention depend on the author -- **STOP. Name the specific artifact change that resolves the finding, or end without a closer.**
- About to post a negative finding with no evidence (no file and line, no command output) -- **STOP. Add the evidence and the change that resolves it.**
- About to correct your own earlier review inside a long apology -- **STOP. Correct it plainly in one sentence; that is the only apology context on a review thread.**

---

## Rationalization Prevention

| Rationalization | Why it fails | Correct action |
|----------------|-------------|----------------|
| "Being direct means saying it bluntly" | Directness governs content (state the finding, name the fix); register governs delivery (informational, no attribution, no decoration). Bluntness at a contributor is not directness, it is attribution. | Apply this skill's register: observation, evidence, resolution. |
| "A warm opener keeps the thread friendly" | A praise opener is decoration that sits ahead of the finding and delays it; the register bans it | Start with the observation. |
| "The contributor is new, so soften the finding" | Softening adds apology or hedging, not information, and changes the register by author; the finding is about the artifact | Use the same observation, evidence, resolution form for every author. |
| "Saying what they probably did not test makes the finding clearer" | It attributes a knowledge or competence failure to the author; the code's behavior carries the point without it | State what the code does and which run would show it. |
| "Ending with 'happy to re-review once this is fixed' is just courtesy" | It conditions attention on the author and names no artifact change | Close with the specific change and what resolves it, or no closer. |

---

## Related Skills

- `communication` -- register for all other text; Concede Only on Evidence there still applies on public threads
- `honesty` -- evidence discipline behind every finding
- `receiving-code-review` -- handling review comments addressed to you
- `requesting-code-review` -- preparing a change for review
