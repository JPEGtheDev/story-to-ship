---
title: "Skill-creator and plugin eval: findings, recommendation and trial story"
description: "Main report: whether the skill-creator loop or claude plugin eval should test skill behaviour; recommendation and one trial story."
domain: research
subdomain: skill-testing
tags: [research, skill-testing, report]
related:
  - "skill-creator-evals-sources.md"
  - "skill-creator-evals-mechanics.md"
  - "claude-plugin-eval.md"
  - "skill-creator-evals-mapping.md"
  - "skill-creator-evals-mapping-loop.md"
  - "skill-creator-evals-dependencies.md"
---

# Skill-creator and plugin eval: findings

## Summary
- The skill-creator toolkit has evals, a benchmark, a blind comparator and a trigger loop. Its trigger loop tests description matching, which the rehearsal and the pins do not check; its benchmark and comparator need subagent runs and an interactive viewer.
- `claude plugin eval` grades with code graders (regex, tool_used, file_exists) or a judge model.
- Its tool_used grader could count Agent calls by input, covering the dispatch rules (inference; Agent tool input fields unverified).
- Adoption needs a model credential, paid runs and a CLI install; no workflow here holds a model credential.
- One run: the model grader failed 3 of 3 votes, the regex grader passed; the judge is unmeasured.

## Recommendation
TRIAL `claude plugin eval` only, run locally by a maintainer, not in CI. Do NOT adopt the skill-creator loop as a kept test: its trigger loop overlaps with neither the rehearsal nor the pins; its benchmark could add a measured GREEN vs RED comparison (inference), but it and the comparator need subagents and the viewer is interactive. Dispatch counts stay with the rehearsal. Keep the two text pins.

## Proposed trial story
Title: "test: trial claude plugin eval on the story-coordinator dispatch rules, local runs only"

Scope:
- One case derived from the rehearsal fixture (REHEARSAL.md, Fixture).
- Graders: tool_used on the Agent tool with input_match for the background flag; regex on the hand-back kind line.
- Bounds: `--runs`, `--max-cost-usd` and `--ablation none`.
- Results compared with one manual rehearsal run.
- No workflow change.

Acceptance criteria sketch:
- The case runs locally and each grader reports a result. Proof: spike
- The background count from tool_used matches the transcript count from one manual run. Proof: spike
- The regex hand-back result agrees with a manual read on each run. Proof: spike
- The run records its cost against `--max-cost-usd` and starts no new run once it is passed. Proof: documentation

The owner files or declines it. Other frameworks were not assessed.

## Related
- [skill-creator-evals-mapping.md](skill-creator-evals-mapping.md) -- plugin eval mapping.
- [skill-creator-evals-mapping-loop.md](skill-creator-evals-mapping-loop.md) -- loop mapping.
- [skill-creator-evals-dependencies.md](skill-creator-evals-dependencies.md) -- new runtimes, secrets.
- [claude-plugin-eval.md](claude-plugin-eval.md) -- the recommended command.
- [skill-creator-evals-mechanics.md](skill-creator-evals-mechanics.md) -- the rejected loop.
- [skill-creator-evals-sources.md](skill-creator-evals-sources.md) -- source per claim.
