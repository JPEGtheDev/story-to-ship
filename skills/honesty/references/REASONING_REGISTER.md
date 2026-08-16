# Reasoning Register -- Rationale, Example, Measurement

Companion to the "Keep Reasoning Terse" rule in `SKILL.md`. The rule is ADVISORY
until measured (see Promotion below).

## Why this rule exists

Reasoning tokens cost the same as output tokens. Strong models tend to prove
sophistication through register: coined frameworks, grand principles, commentary
on their own analysis. None of it changes the next action; all of it burns
budget. The counter-pressure: some reflective sentences ARE the work -- the
Empirical-Backing Tripwire question, hypothesis statements in debugging, Intent
lines in execution. A register rule that cannot tell the two apart converts a
token saving into a skipped gate. The rule therefore bans the performance class
and explicitly protects every required check.

## Worked example -- the hardest case

A class-closure verdict requires reflective, multi-step reasoning: a sweep wider
than the naming tokens plus an independent review-all pass. In terse register,
checks intact:

    Fixed both em-dashes. Class is non-ASCII, wider than those two tokens.
    Sweep: LC_ALL=C grep -n '[^ -~]' across skills/ -- 0 hits.
    Independent review-all: dispatched, verdict pending.
    Until it returns, the claim is closed-this-round only.
    Tripwire: is the evidence for this verdict pasted in this message? Yes.

Five lines. Every mandated check appears; nothing decorates. If a trace cannot
be written this way, the reasoning is at a genuine fork and earns its paragraph.

## Scope boundaries

- Governs reasoning only. Agents whose DELIVERABLE is prose (summarization,
  synthesis, claim enrichment) write the deliverable in whatever register the
  task demands; this rule never touches deliverable text.
- Never licenses skipping a required check, hypothesis statement, Intent line,
  or tripwire question.
- Re-derivation is banned only while the original evidence is still in context
  (cite it instead). After compaction or resume the evidence is gone and
  re-deriving is the compliant path.

## Enforcement and measurement

- Self-check at generation time (SKILL.md's Red Flags entry) is the enforcement
  mechanism, not a downstream gate -- no automated detector inspects reasoning
  before it is sent. Checkable surfaces: the postmortem reviewer's
  register-sampling audit row (samples reasoning SHAPE -- essay-structure, not
  banned-token grep: the class is broader than any token list) and the
  dispatched-agent token trend.
- Pre-rule baseline, for trend comparison -- 16 harness-reported per-dispatch
  token totals (prompt + completion, NOT billing-grade), recorded during the
  development of the change that introduced this rule; the sample is this list,
  mean ~64,000: 40264, 43706, 49388, 51960, 52499, 58225, 59105, 62458, 63470,
  64911, 66837, 78409, 79192, 81650, 81738, 90244. Compare future samples via
  the same harness counter only.
- The per-template block adds ~110 tokens per dispatch; break-even is under a
  2% reasoning reduction on a typical dispatch.

## Promotion

Advisory -> enforced follows the writing-skills Jargon Rule precedent: measure
the rule's effect on a hand-adjudicated sample (paired dispatches with and
without the block, N >= 10 per arm, token counts from the session record), then
promote explicitly if the effect is real and precision is acceptable.
