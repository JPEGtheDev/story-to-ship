---
title: "Skill-creator and plugin eval: findings, recommendation and trial story"
description: "Main report on whether the skill-creator loop or the first-party claude plugin eval command should test skill behaviour, with a recommendation and one trial story."
domain: research
subdomain: skill-testing
tags: [research, skill-testing, report]
related:
  - "skill-creator-evals-sources.md"
  - "skill-creator-evals-mechanics.md"
  - "claude-plugin-eval.md"
  - "skill-creator-evals-mapping.md"
  - "skill-creator-evals-dependencies.md"
---

# Skill-creator and plugin eval: findings

## Summary
- The skill-creator toolkit (pinned public commit) has evals, a benchmark, a blind comparator and a trigger loop. None fits what this repo checks.
- `claude plugin eval` grades with code graders (regex, tool_used, file_exists) or a judge model.
- Its tool_used grader can count Agent calls by input, which could cover the coordinator dispatch rules.
- Adoption needs a model credential, paid runs and a CLI install. No workflow here holds a credential today.
- One observed judge run disagreed with the regex grader; the judge is unmeasured.

Detail: [sources](skill-creator-evals-sources.md), [mechanics](skill-creator-evals-mechanics.md), [plugin eval](claude-plugin-eval.md), [mapping](skill-creator-evals-mapping.md), [dependencies](skill-creator-evals-dependencies.md).

## Recommendation
TRIAL `claude plugin eval` only, run locally by a maintainer, not in CI, because no workflow here holds a model credential. Do NOT adopt the skill-creator loop as a kept test: its trigger loop and benchmark overlap with neither the rehearsal nor the pins, the comparator needs subagents, and the viewer is interactive. Keep the two text pins as they are.

## Proposed trial story
Title: "test: trial claude plugin eval on the story-coordinator dispatch rules, local runs only"

Scope:
- One case derived from the rehearsal fixture (REHEARSAL.md, Fixture).
- Graders: tool_used on the Agent tool with input_match for the background flag; regex on the hand-back kind line.
- Bounds: `--runs` and `--max-cost-usd` set in the trial.
- Results compared with one manual rehearsal run.
- No workflow change.

Acceptance criteria sketch:
- The case runs locally and each grader reports a result. Proof: spike
- The background count from tool_used matches the transcript count from one manual run. Proof: spike
- The regex hand-back result agrees with a manual read on each run. Proof: spike
- The run stays within the flag bounds and records its cost. Proof: documentation

The owner files or declines this trial story. Other evaluation frameworks were not assessed (out of scope).

## Related
- [skill-creator-evals-mapping.md](skill-creator-evals-mapping.md) -- what each toolkit would replace, add or not cover.
- [skill-creator-evals-dependencies.md](skill-creator-evals-dependencies.md) -- new runtimes and secrets.
- [claude-plugin-eval.md](claude-plugin-eval.md) -- the command this recommendation covers.
- [skill-creator-evals-mechanics.md](skill-creator-evals-mechanics.md) -- the loop this report rejects.
- [skill-creator-evals-sources.md](skill-creator-evals-sources.md) -- source line for each claim.
