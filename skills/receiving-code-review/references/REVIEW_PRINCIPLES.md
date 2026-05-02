# Review Principles Reference

Source: Ward Cunningham's C2 wiki audit — principles for giving and receiving code review as a professional practice.

---

## Egoless Programming

Code review works when authors treat their code as an independent object — not an extension of themselves. When identity is fused with code, criticism of the code registers as criticism of the person, and defensiveness blocks signal.

The problem is self-orientation, not ego. Ego (pride in craft, motivation, standards) is valuable. Self-orientation (treating a code review comment as a personal attack) destroys collaboration and trust.

The HyperSensitiveCodeMachine anti-pattern: the author produces large volumes of code, avoids review, tests minimally, and responds to criticism defensively. The result is a high-output, low-quality loop that is invisible until it fails.

Practical rule: state opinions as opinions, not facts. State facts as facts, not opinions. "I think this approach will make testing harder" is not the same as "this approach is wrong." Source: C2 Wiki "EgolessProgramming".

---

## Divided Responsibility Is the Fatal Flaw

If the reviewer is responsible for finding all errors, the author stops ensuring correctness. If both are "responsible," each relies on the other — and neither catches anything.

Ownership of correctness cannot be handed off to reviewers. The author is responsible for producing correct code. The reviewer is responsible for an independent perspective that the author's familiarity cannot provide. These are complementary roles, not transferable ones.

Applied to agent-assisted review: the human owns the result. The agent is a tool. "The agent reviewed it" is not a correctness guarantee. Source: C2 Wiki "PeerReview".

---

## Structured Walkthroughs (Code Inspection Protocol)

A structured walkthrough is a formal review with defined roles and a defined sequence. The essential structure:

1. **Author presents:** walks through the code or design at a pace that allows others to follow
2. **Reviewers note, not decide:** reviewers record issues for later discussion — they do not debate or fix during the walkthrough
3. **Discussion phase:** address the noted issues; categorize as defects, suggestions, or questions
4. **No management present:** management attendance suppresses honest feedback (participants self-censor)
5. **Output is a defect list, not a verdict:** the goal is finding defects, not evaluating the author

The walkthrough is a tool for finding defects early, not for assigning blame. Adapt: for agent-assisted review, the "structured walkthrough" maps to a spec-compliance check followed by a code-quality check — two separate passes, not one. Source: C2 Wiki "CodeReview", "StructuredWalkthrough".

---

## Attack Ideas, Not People

Code review feedback must target the code, not the author. The distinction:
- "This design makes it impossible to test the render path in isolation" — targets the code
- "You didn't think about testability" — targets the author

When receiving review: separate "this design has a problem" from "I have a problem." When giving review: state the technical issue and the reason. Never characterize the author's ability, intent, or knowledge.

The test: could this comment appear in a review of anonymous code? If not, rewrite it. Source: C2 Wiki "AttackIdeasNotPeople".

---

## Related Skills

- `receiving-code-review` — processing review feedback without performative agreement
- `requesting-code-review` — targeted review requests, SHA-based dispatch, agent pre-review
- `self-evaluation` — structural objectivity mechanisms to bypass the self-evaluation block
- `execution` — commit rhythm and work loop; review is a gate before committing
