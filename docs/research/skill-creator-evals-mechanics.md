---
title: "Skill-creator evals: case fields, grading, model calls and headless use"
description: "Explains which skill-creator part writes and grades a case, what one loop costs in model calls, and what a headless run needs."
domain: research
subdomain: skill-testing
tags: [research, skill-testing, mechanics]
related:
  - "skill-creator-evals-sources.md"
  - "claude-plugin-eval.md"
  - "../INDEX.md"
---

# Skill-creator evals: mechanics

## Case fields
- Benchmark case in evals/evals.json: id, prompt, expected_output, files. Assertions are added after the first runs (schemas.md L14-35; SKILL.md L145-161).
- Trigger case: query and should_trigger (run_loop.py L25-30).

## Grading (which part does what)
- Script: checkable assertions are checked by a script the agent writes and runs (SKILL.md L225).
- Model grader: a grader subagent reads agents/grader.md and writes grading.json (SKILL.md L225).
- Blind comparator: a subagent judges outputs labeled A and B; optional (comparator.md L3; SKILL.md L325-327).
- Human: the user reviews outputs in the viewer (SKILL.md L236-282).
- Trigger scoring is code: a run counts as triggered when the streamed output shows a Skill call or a Read naming the skill (run_eval.py L143-168).

## Model calls
Estimates come from source; only the observed line is a run.
- Trigger loop, per iteration: every query (train and test together) runs runs-per-query times, one claude -p call each (run_loop.py L92-100; run_eval.py L199-201). Defaults: 3 runs (run_eval.py L266), 5 iterations (run_loop.py L251), holdout 0.4 (run_loop.py L254).
- Improve call: one claude -p call per iteration except the last, plus a rewrite if over 1024 characters (run_loop.py L183-187; improve_description.py L144, L174).
- Early stop when all train queries pass (run_loop.py L178-181).
- Estimate: 20 queries, 3 runs, 5 iterations = 300 trigger calls plus 4 improve calls.
- Observed 2026-10-26/27 (verification run 2, listed in the pull request body): 2 queries x 1 run = 2 claude -p calls, exit 0.
- Subagent grading and comparison: no count in source. Token counts come from saved task notifications (SKILL.md L209-213).

## Headless and CI
- Needs: a claude command on the path (run_eval.py L71), the same login as normal sessions (environment copied; improve_description.py L33), and the scripts package layout (run_eval.py L19). Run as python -m scripts.run_loop (SKILL.md L382).
- Project root: nearest parent holding a .claude directory (run_eval.py L22-32).
- run_eval.py writes .claude/commands/<name>-skill-<id>.md and deletes it in a finally block (run_eval.py L53-57, L180-181). Observed: directory empty afterwards (verification run 2).
- run_loop.py opens a browser report by default (run_loop.py L257, L279); `--report none` avoids it (from source).
- Interactive: the viewer (SKILL.md L236-249), subagent grading and comparison (SKILL.md L225, L325).

## Related
- [skill-creator-evals-sources.md](skill-creator-evals-sources.md) -- source line for each claim here.
- [claude-plugin-eval.md](claude-plugin-eval.md) -- the first-party command, which has a different case format.
- [../INDEX.md](../INDEX.md) -- documentation index for the docs/ root.
