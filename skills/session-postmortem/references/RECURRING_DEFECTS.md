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
- `count` / `domain` -- number of mined instances; `general`, or a domain tag used for
  cross-repo routing.
- `maps-to` -- a ROUTING POINTER to the nearest existing remedy (a memory slug or a skill).
  It is NOT a claim the mode is solved or cannot recur. `GAP` means no existing remedy is
  catalogued; those entries carry an inline `remediation` line.

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
- Singletons (count 1) are candidates, not confirmed patterns -- flagged as such in-line;
  a few carry an explicit remediation where the corrective is already known.
- The schema (portable mode names, maps-to slugs, domain tags) is repo-agnostic so other
  repos can adopt or sync entries later; no sync mechanism exists yet.

---

### RD-01: missing-visual-verification
- signature: Claimed a UI, rendered, or visual output was correct without inspecting the actual result.
- count: 18 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: For any UI, rendered, or visual output, inspect the actual result (screenshot, rendered page, generated file) before claiming correctness; automated tests do not substitute for the manual visual check.

### RD-02: bootstrap-not-fired
- signature: Did not invoke session-bootstrap first after start, resume, or compaction.
- count: 12 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_bootstrap_first_tool_call

### RD-03: unbacked-causal-diagnosis
- signature: Stated a root cause without a trace or reproduction.
- count: 12 (mined 2026-07-19)   domain: general
- maps-to: skill: systematic-debugging

### RD-04: scope-overreach
- signature: Did more or other than the task asked; touched out-of-scope surface.
- count: 8 (mined 2026-07-19)   domain: general
- maps-to: skill: execution

### RD-05: unverified-claim
- signature: Asserted a fact about code or state without reading or running it.
- count: 7 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_correctness_over_completion

### RD-06: premature-or-wrong-edit
- signature: Edited the wrong thing, or edited before confirming; needed a revert.
- count: 6 (mined 2026-07-19)   domain: general
- maps-to: skill: execution

### RD-07: unbacked-confidence-claim
- signature: Claimed verification happened with no evidence shown.
- count: 6 (mined 2026-07-19)   domain: general
- maps-to: skill: honesty

### RD-08: unchecked-existing-state
- signature: Acted on assumed or stale state without checking current live state.
- count: 6 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: Before creating, opening, or acting, query current live state (open tasks, PRs, skill versions, prior-session outputs); never act from memory of an old session.

### RD-09: banned-language-used
- signature: Used banned honesty vocabulary in output.
- count: 5 (mined 2026-07-19)   domain: general
- maps-to: skill: honesty

### RD-10: weak-imperative-language
- signature: Authored 'should/prefer/consider' where a MUST was required.
- count: 5 (mined 2026-07-19)   domain: general
- maps-to: skill: writing-skills

### RD-11: bare-completion-claim
- signature: Claimed done/complete/CI-pass without inline command output.
- count: 4 (mined 2026-07-19)   domain: general
- maps-to: skill: honesty

### RD-12: skeptic-not-dispatched
- signature: Presented a plan or design without the required Skeptic review.
- count: 4 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_bulletproof_plans

### RD-13: no-branch-created
- signature: Started work on main instead of a new branch off main.
- count: 3 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_branch_selection

### RD-14: unreviewed-direct-edit
- signature: Edited a file inline without the 2-stage subagent review.
- count: 3 (mined 2026-07-19)   domain: general
- maps-to: skill: subagent-driven-development

### RD-15: wrong-artifact-location
- signature: Wrote a session artifact into the repo/docs instead of the session folder.
- count: 3 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: Session artifacts (self-assessment.md, postmortem.md) go in the session directory, never the repo; confirm the skill's stated path before writing.

### RD-16: skill-not-reloaded
- signature: Acted in a skill's domain without invoking or reloading the skill.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_investigation_to_implementation_reload

### RD-17: spend-launch-without-consent
- signature: Launched a paid child (claude -p / workflow) without per-invocation consent.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_spend_launch_consent

### RD-18: sycophancy
- signature: Devolved into uncritical agreement instead of independent analysis.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: When you notice agreement without independent verification, stop and re-bootstrap; the user needs analysis and dissent, not validation.

### RD-19: verification-independence-compromised
- signature: Reported findings on own work before dispatching an independent reviewer.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_confirmation_asymmetry_verification

### RD-20: wrong-branch-base
- signature: Based a new branch off an arbitrary branch instead of main.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_branch_selection

### RD-21: wrong-reviewer-type-dispatched
- signature: Used code-review for skill .md files instead of skill-reviewer.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: skill: subagent-driven-development

### RD-22: wrong-worktree-dispatch
- signature: Dispatched an agent with main-context paths instead of the worktree path.
- count: 2 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_agent_worktree_context

### RD-23: bundled-chunks-not-per-concept
- signature: Wrote a bundled chunks file instead of one file per concept.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_chunk_per_concept_files

### RD-24: context-thrashing-not-addressed
- signature: Kept re-reading oversized chunks after being told to diagnose the thrash.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).

### RD-25: cost-compared-in-tokens-not-dollars
- signature: Compared spend in tokens instead of dollars via per-MTok pricing.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_compare_dollars_not_tokens

### RD-26: forgot-required-process-step
- signature: Omitted a required process step (e.g. Three Amigos) from a plan.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: skill: session-bootstrap

### RD-27: generalization-increased-scoped-content
- signature: Generalizing by inline relocation increased the scoped footprint.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_relocation_preserves_floor

### RD-28: incomplete-fix-partial-scope
- signature: Closed a defect class after fixing only the token-narrow subset.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_leak_class_broader_than_tokens

### RD-29: incorrect-rule-application
- signature: Misapplied the acronym-expansion rule to file-format tokens (YAML/ASCII).
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: skill: writing-skills

### RD-30: insufficient-mechanical-analysis
- signature: Asked what to analyze instead of engaging the established violation.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).

### RD-31: literal-interpretation-of-analogy
- signature: Took a user analogy literally instead of as illustration.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).

### RD-32: memory-fix-instead-of-skill-fix
- signature: Applied a recurring-issue fix to a memory or a temp/plugin-cache copy instead of the tracked source skill.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: When a recurring issue needs a durable rule, fix the tracked source skill, not a private memory or a plugin-cache/temp copy; edits to a plugins/cache snapshot are outside git and are silently overwritten on the next plugin update. For a repo-specific or plugin skill, edit the source repo's skill file and ship it through review.

### RD-33: memory-scope-misunderstood
- signature: Treated private memory as a shared or authoritative record.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).

### RD-34: metric-chasing-without-justification
- signature: Optimized to hit a size/token metric without justifying the cut.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_sdd_enforcement_preserve

### RD-35: missing-index-and-frontmatter
- signature: Shipped documentation with no index entry and no frontmatter linking it to related files.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_chunk_per_concept_files

### RD-36: no-model-tiering-applied
- signature: Dispatched agents on inherited top-tier model with no haiku/sonnet tiering.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_subagent_model_tiers

### RD-37: no-validation-checkpoint-before-continued-iteration
- signature: Kept iterating on tuning with no step-back validation checkpoint.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).

### RD-38: premature-merge-proposal
- signature: Proposed or pushed to merge; merge is the user's hard gate.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: memory: feedback_pr_merge_signoff_user_gate

### RD-39: review-missed-invest-criterion
- signature: A ceremony passed a story that was not INVESTable.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: skill: three-amigos

### RD-40: scope-too-narrow
- signature: Forced content into existing categories instead of surfacing gaps.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).

### RD-41: self-evaluation-skipped
- signature: Closed a session without running self-evaluation.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: skill: self-evaluation

### RD-42: shallow-synthesis-failure
- signature: Synthesis was shallow and missed depth the source supported.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).

### RD-43: stale-documentation-not-updated
- signature: Left docs implying a removed feature still worked.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).

### RD-44: thin-todo-tracking-causes-compaction-loss
- signature: Shallow todo tracking caused repeated context loss across compaction.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).

### RD-45: uncommitted-changes-left-at-stop
- signature: Stopped with uncommitted changes left in the working tree.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).

### RD-46: unexplained-delay
- signature: Produced an unexplained delay the user flagged.
- count: 1 (mined 2026-07-19)   domain: general
- maps-to: GAP (inline remediation below)
- remediation: candidate (1 instance -- not yet a confirmed pattern).
