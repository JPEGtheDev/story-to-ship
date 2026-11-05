---
title: "Old-Versus-New Eval Comparison"
description: "Procedure for comparing a shortened or reworded skill against its prior text with claude plugin eval, and for recording the skill's on-invoke token cost before and after."
domain: skills
subdomain: writing-skills
tags: [skills, writing-skills, references, eval, token-cost]
related:
  - "../SKILL.md"
  - "SIZE_AND_COMPRESSION.md"
---

# Old-Versus-New Eval Comparison

Use this procedure before shipping an edit that shortens or rewords a skill. It measures the change; it does not shorten anything.

## a. When It Applies

1. Run this procedure before shipping any edit that shortens or rewords a skill's SKILL.md or references/ text. Step d.1 compares the commit before the edit with the edited tree, so the comparison runs after the edit and before shipping.
2. Ship the changed skill only when no case's score drops. A first-run drop is not a verdict: step d.6 reruns it, and a drop that the step d.6 rerun confirms blocks the change. There is no tolerance for a confirmed drop.

## b. Consent and Cost

1. Every eval run uses model usage. Get the owner's consent for each run before starting it.
2. Pass a ceiling on every run: `--max-cost-usd <ceiling>`.
3. Consent for one run does not cover a rerun or a changed command. Ask again.
4. The comparison has two runs, one per checkout. Each run gets its own ceiling. The total is twice the ceiling.
5. If consent is withheld, no run happens. Do not ship the change on the strength of this procedure.

## c. Cases and Checkouts

1. Cases live in `evals/`: each case folder holds `prompt.md`, `graders/*.md`, `case.yaml` and `scaffold.sh`. `scaffold.sh` builds the small test repository the case runs in. Each case has one rule.
2. Both checkouts must hold identical `evals/` directories. Run `diff -r -x results <old-path>/evals <new-path>/evals`. Continue only when it prints nothing and exits 0.

## d. Steps

1. Make the old checkout: `git worktree add <old-path> <base-commit>`, where `<base-commit>` is the commit before the edit. Keep the edited tree as the new checkout at `<new-path>`.
2. Run the old checkout:
   `claude plugin eval <old-path> --runs 5 --model <model> --judge-model <judge-model> --ablation none --scaffold --allow-tools Edit --no-publish --max-cost-usd <ceiling> --json <old.json>`
3. Run the same command on `<new-path>` with `--json <new.json>`. Keep the same `--runs`, `--model`, `--judge-model`, `--scaffold`, and `--allow-tools Edit` on both.
4. Join and print the per-case scores and the difference. Every case must appear in both files; the join silently skips a case that is missing from new.json:
   `jq -n --slurpfile o <old.json> --slurpfile n <new.json> '[ $o[0].cases[] as $a | ($n[0].cases[] | select(.name==$a.name)) as $b | {case:$a.name, old:$a.aggregates.score, new:$b.aggregates.score, diff:($b.aggregates.score-$a.aggregates.score)} ]'`
5. A negative `diff` is a drop.
6. For a dropped case, rerun that case once on both checkouts: add `--case <case-name>` and a new `--json` file name. The rerun needs the owner's consent and a ceiling.
7. If the rerun still shows a drop, the change is blocked.
8. If the rerun shows no drop, the change may ship. Record the rerun result with the comparison.

## e. Why These Flags

1. `--ablation none`: the default compares the plugin against no plugin and makes `tool_used: Skill` graders display-only. A comparison between two plugin versions needs those graders to count. The flag also halves the spend.
2. `--no-publish`: keeps the HTML report local.
3. `--scaffold --allow-tools Edit`: `--scaffold` runs each case's `scaffold.sh` so the case has its test repository; without it the case runs in an empty folder. `--allow-tools Edit` lets the session-start case edit its README. Both are operator grants and are part of the owner's consent for the run.

## f. Failure Outcomes

1. A run that hits the ceiling exits 2 with partial results and gives no verdict. Either raise the ceiling with the owner's consent and rerun, or do not ship.
2. A case without a grader, a bad grader field, or a bad checkout path fails when the suite loads. No verdict exists.
3. A missing json file means no verdict.
4. Results are written under `evals/results/` in each checkout. That directory is gitignored.

## g. Token Cost

1. Record the skill's on-invoke cost before and after the change, next to the eval comparison.
2. Run `claude --plugin-dir <old-path> plugin details story-to-ship`.
3. Run `claude --plugin-dir <new-path> plugin details story-to-ship`.
4. Confirm the output line `Source: story-to-ship@inline` in each run. It shows the command read the checkout, not the installed copy.
5. Find the skill's row under "Per-component" and read the `on-invoke` column. The readout rounds values; record the value as printed.
6. Use this number, not the chars/4 estimate in `SIZE_AND_COMPRESSION.md`, as the recorded saving.
7. Record one line per change in this format:
   `<skill>: <old on-invoke> -> <new on-invoke>; eval: <n> cases, no drop`

## h. Limits

1. Scores come from model runs. Five runs per case is the floor.
2. A case that scores the same with and without the plugin (the completion-claim case is one) does not prove the skill text matters.
3. A passing comparison shows no measured drop. It does not show the text is unneeded.
4. The join reads cases[].aggregates.score; check that field exists in the first --ablation none output before trusting the table.
