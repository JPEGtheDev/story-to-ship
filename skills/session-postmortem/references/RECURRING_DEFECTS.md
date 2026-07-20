# Recurring Defect Registry

A shared, cross-repo catalog of recurring agent-behavior defects, mined from real user
corrections. Use it in a postmortem: when a defect recurs, look it up here to see whether it
is a known pattern and where its remedy lives.

## Provenance

- Mined 2026-07-19 from 520 real assistant->user pairs across 39 session transcripts
  (harness-injected pseudo-user turns -- task-notifications, system-reminders, skill-load
  bodies -- filtered out).
- 140 of those pairs are user corrections, grouped into 46 canonical failure modes.
- Sources: story-to-ship 92, Particle-Viewer 46, other-project 2 (= 140).
- Every correction is grounded in a real quoted user message. That grounding is the only
  thing claimed as "verified" -- see the maps-to note below.

## Schema

Each entry has:
- `RD-NN` -- stable id, ordered by descending instance count at mining time.
- `signature` -- one line: what went wrong.
- `count` / `domain` -- number of mined instances; `general`, or a domain tag (e.g.
  `graphics`) used for cross-repo routing.
- `maps-to` -- a ROUTING POINTER to the nearest existing remedy (a memory slug or a skill).
  It is NOT a claim the mode is solved or cannot recur. `GAP` means no existing remedy is
  catalogued; those entries carry an inline `remediation` line.
- `instances` -- evidence pointers in `<8-char-session-id>#<turn>` form.

## How to use

1. A defect recurs in a session. Search this file for its signature.
2. If present and `maps-to` names a memory or skill, load that remedy.
3. If `GAP`, apply the inline `remediation`; if it recurs again, promote it to a memory or
   skill rule.

## Scope and limits

- This is a curated point-in-time snapshot (2026-07-19), not an auto-updated view. The mining
  METHOD (scan transcripts -> filter injected turns -> classify corrections -> name mode ->
  map to remedy) is reproducible, but the source transcripts are private and are not
  committed, so there is no one-command regeneration from repo state.
- Singletons (count 1) are candidates, not confirmed patterns -- flagged as such in-line.
- The schema (portable mode names, maps-to slugs, domain tags) is repo-agnostic so other
  repos can adopt or sync entries later; no sync mechanism exists yet.

---

### RD-01: missing-visual-verification
- signature: Claimed render or visual correctness without looking at actual output.
- count: 18 (mined 2026-07-19)   domain: graphics
- maps-to: GAP (inline remediation below)
- remediation: For any visual or render change, inspect the actual rendered screenshot before any correctness claim; automated tests do not substitute for the qualitative visual check.
- instances: 1a422a4c#17, 1a422a4c#19, 1a422a4c#21, 1a422a4c#22, 1a422a4c#23, 1a422a4c#36, 1a422a4c#39, 1a422a4c#42, e5c79d53#1, e5c79d53#4, e5c79d53#6, e5c79d53#7, e5c79d53#8, e5c79d53#9, e5c79d53#16, e5c79d53#20, e5c79d53#21, e5c79d53#23

### RD-02: bootstrap-not-fired
- signature: Did not invoke session-bootstrap first after start, resume, or compaction.
- count: 12 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_bootstrap_first_tool_call
- instances: 1a422a4c#2, e5c79d53#19, 0faf03ea#46, 0faf03ea#49, 1f8a6f73#1, 27ef0dbe#1, 3d1596c9#1, 78c284c0#1, a0e656aa#53, b578f8ff#1, ca61de74#17, ccc3fe08#1

### RD-03: unbacked-causal-diagnosis
- signature: Stated a root cause without a trace or reproduction.
- count: 12 (mined 2026-07-19)   domain: general
- maps-to: skill: systematic-debugging
- instances: 1a422a4c#14, 1a422a4c#18, 1a422a4c#54, e5c79d53#3, e5c79d53#5, 1f8a6f73#2, 1f8a6f73#3, a0e656aa#7, b578f8ff#2, b578f8ff#3, ccc3fe08#2, d98ca0fc#48

### RD-04: scope-overreach
- signature: Did more or other than the task asked; touched out-of-scope surface.
- count: 8 (mined 2026-07-19)   domain: general
- maps-to: skill: execution
- instances: 1a422a4c#45, 1a422a4c#68, 339c9ce6#8, 78c284c0#2, a0e656aa#75, a0e656aa#89, a0e656aa#90, ca61de74#36

### RD-05: unverified-claim
- signature: Asserted a fact about code or state without reading or running it.
- count: 7 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_correctness_over_completion
- instances: 1a422a4c#62, 8e942b47#17, e5c79d53#26, 339c9ce6#17, a0e656aa#62, b578f8ff#4, d98ca0fc#38

### RD-06: premature-or-wrong-edit
- signature: Edited the wrong thing, or edited before confirming; needed a revert.
- count: 6 (mined 2026-07-19)   domain: general
- maps-to: skill: execution
- instances: cdc887b7#4, 1f8a6f73#18, 1f8a6f73#21, ca61de74#12, ca61de74#18, d98ca0fc#49

### RD-07: unbacked-confidence-claim
- signature: Claimed verification happened with no evidence shown.
- count: 6 (mined 2026-07-19)   domain: general
- maps-to: skill: honesty
- instances: e5c79d53#10, e5c79d53#11, e5c79d53#17, e5c79d53#30, 1f8a6f73#4, ccc3fe08#3

### RD-08: unchecked-existing-state
- signature: Acted on assumed or stale state without checking current live state.
- count: 6 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: Before creating, opening, or acting, query current live state (open tasks, PRs, skill versions, prior-session outputs); never act from memory of an old session.
- instances: 1ae6b75f#1, a0e656aa#2, d98ca0fc#18, d98ca0fc#19, d98ca0fc#20, d98ca0fc#46

### RD-09: banned-language-used
- signature: Used banned honesty vocabulary in output.
- count: 5 (mined 2026-07-19)   domain: general
- maps-to: skill: honesty
- instances: e5c79d53#42, 0faf03ea#61, a0e656aa#61, a0e656aa#68, a0e656aa#76

### RD-10: weak-imperative-language
- signature: Authored 'should/prefer/consider' where a MUST was required.
- count: 5 (mined 2026-07-19)   domain: general
- maps-to: skill: writing-skills
- instances: 8e942b47#7, e5c79d53#34, 3d1596c9#2, 6c9dfb3b#6, d98ca0fc#35

### RD-11: bare-completion-claim
- signature: Claimed done/complete/CI-pass without inline command output.
- count: 4 (mined 2026-07-19)   domain: general
- maps-to: skill: honesty
- instances: 1a422a4c#12, 8e942b47#22, 1ae6b75f#5, d98ca0fc#26

### RD-12: skeptic-not-dispatched
- signature: Presented a plan or design without the required Skeptic review.
- count: 4 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_bulletproof_plans
- instances: e5c79d53#14, 1ae6b75f#2, d98ca0fc#32, d98ca0fc#50

### RD-13: no-branch-created
- signature: Started work on main instead of a new branch off main.
- count: 3 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_branch_selection
- instances: d98ca0fc#6, d98ca0fc#9, d98ca0fc#10

### RD-14: unreviewed-direct-edit
- signature: Edited a file inline without the 2-stage subagent review.
- count: 3 (mined 2026-07-19)   domain: general
- maps-to: skill: subagent-driven-development
- instances: 6c9dfb3b#1, 6c9dfb3b#2, ca61de74#30

### RD-15: wrong-artifact-location
- signature: Wrote a session artifact into the repo/docs instead of the session folder.
- count: 3 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: Session artifacts (self-assessment.md, postmortem.md) go in the session directory, never the repo; confirm the skill's stated path before writing.
- instances: ca61de74#19, ca61de74#27, ca61de74#28

### RD-16: skill-not-reloaded
- signature: Acted in a skill's domain without invoking or reloading the skill.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_investigation_to_implementation_reload
- instances: 8e942b47#20, d98ca0fc#14

### RD-17: spend-launch-without-consent
- signature: Launched a paid child (claude -p / workflow) without per-invocation consent.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_spend_launch_consent
- instances: 339c9ce6#19, 339c9ce6#20

### RD-18: sycophancy
- signature: Devolved into uncritical agreement instead of independent analysis.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: When you notice agreement without independent verification, stop and re-bootstrap; the user needs analysis and dissent, not validation.
- instances: 0faf03ea#48, a0e656aa#8

### RD-19: verification-independence-compromised
- signature: Reported findings on own work before dispatching an independent reviewer.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_confirmation_asymmetry_verification
- instances: a0e656aa#67, a0e656aa#70

### RD-20: wrong-branch-base
- signature: Based a new branch off an arbitrary branch instead of main.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_branch_selection
- instances: ca61de74#15, ca61de74#16

### RD-21: wrong-reviewer-type-dispatched
- signature: Used code-review for skill .md files instead of skill-reviewer.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: skill: subagent-driven-development
- instances: 0faf03ea#60, d98ca0fc#13

### RD-22: wrong-worktree-dispatch
- signature: Dispatched an agent with main-context paths instead of the worktree path.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_agent_worktree_context
- instances: ca61de74#13, d98ca0fc#37

### RD-23: bundled-chunks-not-per-concept
- signature: Wrote a bundled chunks file instead of one file per concept.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_chunk_per_concept_files
- instances: a0e656aa#58

### RD-24: context-thrashing-not-addressed
- signature: Kept re-reading oversized chunks after being told to diagnose the thrash.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: 8e942b47#10

### RD-25: cost-compared-in-tokens-not-dollars
- signature: Compared spend in tokens instead of dollars via per-MTok pricing.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_compare_dollars_not_tokens
- instances: 339c9ce6#10

### RD-26: forgot-required-process-step
- signature: Omitted a required process step (e.g. Three Amigos) from a plan.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: skill: session-bootstrap
- instances: a0e656aa#60

### RD-27: generalization-increased-scoped-content
- signature: Generalizing by inline relocation increased the scoped footprint.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_relocation_preserves_floor
- instances: a0e656aa#55

### RD-28: incomplete-fix-partial-scope
- signature: Closed a defect class after fixing only the token-narrow subset.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_leak_class_broader_than_tokens
- instances: 6c9dfb3b#5

### RD-29: incorrect-rule-application
- signature: Misapplied the acronym-expansion rule to file-format tokens (YAML/ASCII).
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: skill: writing-skills
- instances: d98ca0fc#42

### RD-30: insufficient-mechanical-analysis
- signature: Asked what to analyze instead of engaging the established violation.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: 8e942b47#19

### RD-31: literal-interpretation-of-analogy
- signature: Took a user analogy literally instead of as illustration.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: 339c9ce6#15

### RD-32: memory-fix-instead-of-skill-fix
- signature: Fixed a recurring issue in memory when a skill change was needed.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: 6c9dfb3b#3

### RD-33: memory-scope-misunderstood
- signature: Treated private memory as a shared or authoritative record.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: 0faf03ea#45

### RD-34: metric-chasing-without-justification
- signature: Optimized to hit a size/token metric without justifying the cut.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_sdd_enforcement_preserve
- instances: d98ca0fc#23

### RD-35: missing-index-and-frontmatter
- signature: Shipped ragable chunks with no INDEX and no frontmatter linking.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_chunk_per_concept_files
- instances: 339c9ce6#9

### RD-36: no-model-tiering-applied
- signature: Dispatched agents on inherited top-tier model with no haiku/sonnet tiering.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_subagent_model_tiers
- instances: 3d1596c9#4

### RD-37: no-validation-checkpoint-before-continued-iteration
- signature: Kept iterating on tuning with no step-back validation checkpoint.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: e5c79d53#12

### RD-38: premature-merge-proposal
- signature: Proposed or pushed to merge; merge is the user's hard gate.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_pr_merge_signoff_user_gate
- instances: a0e656aa#79

### RD-39: review-missed-invest-criterion
- signature: A ceremony passed a story that was not INVESTable.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: skill: three-amigos
- instances: a0e656aa#40

### RD-40: scope-too-narrow
- signature: Forced content into existing categories instead of surfacing gaps.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: 339c9ce6#4

### RD-41: self-evaluation-skipped
- signature: Closed a session without running self-evaluation.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: skill: self-evaluation
- instances: 0faf03ea#40

### RD-42: shallow-synthesis-failure
- signature: Synthesis was shallow and missed depth the source supported.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: ca61de74#24

### RD-43: stale-documentation-not-updated
- signature: Left docs implying a removed feature still worked.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: e5c79d53#39

### RD-44: thin-todo-tracking-causes-compaction-loss
- signature: Shallow todo tracking caused repeated context loss across compaction.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: 8e942b47#3

### RD-45: uncommitted-changes-left-at-stop
- signature: Stopped with uncommitted changes left in the working tree.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: 90997f2d#1

### RD-46: unexplained-delay
- signature: Produced an unexplained delay the user flagged.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
- instances: cdc887b7#2
