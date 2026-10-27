---
title: "claude plugin eval: first-party plugin test command"
description: "Describes the first-party claude plugin eval command: layout, grader types, exit codes, cost flags and publishing."
domain: research
subdomain: skill-testing
tags: [research, skill-testing, plugin-eval]
related:
  - "skill-creator-evals-sources.md"
  - "skill-creator-evals-mechanics.md"
  - "../INDEX.md"
---

# claude plugin eval

Source: https://code.claude.com/docs/en/plugin-evals (local copy pe-clean.txt), read 2026-10-26.

## Requirements
Claude Code v2.1.269 or later. Git 2.31 or later, if git is installed (pe-clean.txt L164, L169).

## Layout
- evals/<case>/prompt.md plus graders/<name>.md. A case may use case.yaml instead, or both (L362-368).

## Grader types
Six types (grader types table, L1654-1725): regex, tool_used, tool_order and file_exists are computed from the transcript and files at no cost; llm and baseline call a judge model (L534-536). "agent" is not a grader type; `type: agent` configures an agent mock (L816-819).

## Scoring and exit codes
- A run's score is the weighted fraction of graders passed. A case's score is the mean across runs. Default runs: 3. A case passes at or above the threshold, default 1.0 (L209-212).
- Exit 0: every case met the threshold. Exit 1: a case below threshold, a load failure or an application programming interface (API) error. Exit 2: cost ceiling hit or credential rejected; partial results written (L1143-1168).

## Cost-bounding flags
- --runs <n>: default is each case's runs, else 3.
- --max-cost-usd: list-price ceiling checked before each run; started runs finish, so spend can pass it (L1060-1062).
- --ablation none: one arm only, which halves cost (L592-593).
- --judge-model: default is the model Claude Code uses for background tasks (L547-552; L1041-1047).

## Publishing and CI
- --no-publish keeps the report local. By default the report is published as a private artifact only when signed in with a claude.ai subscription and artifacts are available; API-key authentication stays local (L1238-1246).
- --trust-plugin skips the first-run trust prompt; pass it in CI (L1071-1073).

## Credentials and cost
Runs and judge calls use the user's credentials and count against plan usage or the API bill; reported cost is a list-price estimate (L182-186). Per suite: about cases x runs agent runs, the same again for the baseline, plus three judge calls per llm or baseline grader per run (L214-217).

## Observed (runs.md, Run 1, 2026-10-26/27)
Command: claude plugin eval . --runs 1 --ablation none --no-publish --trust-plugin --max-cost-usd 0.5 --model <alias> --json <path> (model name elided). Claude Code 2.1.296. Regex grader passed; llm grader failed 3 of 3 votes; case score 0.5; exit 1. costUsd 0.00258339 plus judgeCostUsd 0.0000585. The result, in JavaScript Object Notation (JSON), has no token fields. One run; no judge-reliability conclusion.

## Related
- [skill-creator-evals-sources.md](skill-creator-evals-sources.md) -- the other toolkit's sources.
- [skill-creator-evals-mechanics.md](skill-creator-evals-mechanics.md) -- that toolkit's call counts.
- [../INDEX.md](../INDEX.md) -- docs/ index.
