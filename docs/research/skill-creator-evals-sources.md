---
title: "Skill-creator eval toolkit: primary sources and claim status"
description: "Table of what the skill-creator toolkit ships, each claim tied to a repository or vendor source line and marked verified or unverified."
domain: research
subdomain: skill-testing
tags: [research, skill-testing, sources]
related:
  - "skill-creator-evals-mechanics.md"
  - "claude-plugin-eval.md"
  - "../INDEX.md"
---

# Skill-creator eval toolkit: sources

Repository: anthropics/skills at commit dbd4588f9e1033efb41dad4bef2f7947c8993d44 (2026-10-09), directory skills/skill-creator/. The repository has no tags. Repository paths were not checked against a checkout, so each is marked unverified. Line numbers were checked in the local copies under /tmp/fl/s365/src/ (SKILL.md, agents/grader.md, agents/comparator.md, references/schemas.md, scripts/*.py). No third-party write-up is used.

| Claim | Primary source | Status |
|---|---|---|
| Test cases are saved in evals/evals.json inside the skill directory | SKILL.md L145; schemas.md L7-9 (path unverified) | verified from primary source |
| Each eval has id, prompt, expected_output, files | schemas.md L14-35 (path unverified) | verified from primary source |
| Eval assertion list field is named "assertions" | SKILL.md L161 | conflict: schemas.md L20 and L35 say "expectations" |
| Graded assertions: grader subagent (or inline) writes grading.json | SKILL.md L225; agents/grader.md L1-12 (path unverified) | verified from primary source |
| Benchmark: pass_rate, time, tokens; mean and sample stddev; delta | scripts/aggregate_benchmark.py L45-61, L130-145, L214-221 (path unverified); SKILL.md L231 | verified from primary source |
| Blind comparison: comparator agent judges A and B without knowing the skill | agents/comparator.md L3, L7; SKILL.md L325-327 | verified from primary source; optional, needs subagents |
| Trigger testing: run_eval.py, run_loop.py, improve_description.py | scripts/run_eval.py L266; run_loop.py L251-254; improve_description.py L26 (path unverified) | verified from primary source |
| Review viewer: eval-viewer/generate_review.py | SKILL.md L236-249 names it; the file is not in the copies | unverified (script not available) |
| Introduction date (evals, benchmark, comparator "in 2026") | commit list in research notes: b0cbd3df (2026-03-06), b9e19e6f (2026-04-20) | not established; only a third-party write-up claims it |
| The plugin skill-creator loop and claude plugin eval use incompatible formats | code.claude.com skills page, doc.txt L1882, L1884 | verified from vendor doc |

Commit read: dbd4588f9e1033efb41dad4bef2f7947c8993d44. Vendor docs: https://code.claude.com/docs/en/skills and https://code.claude.com/docs/en/plugin-evals (local copies doc.txt and pe-clean.txt). Date read: 2026-10-26.

## Related

- [skill-creator-evals-mechanics.md](skill-creator-evals-mechanics.md) -- how cases are written, graded and run, with cost estimates.
- [claude-plugin-eval.md](claude-plugin-eval.md) -- the first-party command, a different tool with its own case format.
- [../INDEX.md](../INDEX.md) -- documentation index for the docs/ root.
