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

Repository: anthropics/skills at commit dbd4588f9e1033efb41dad4bef2f7947c8993d44 (2026-10-09), directory skills/skill-creator/. The repository has no tags. Every repository path below was checked to exist at that commit through the public GitHub contents interface on 2026-10-26, and the files read were byte-identical to the copies the line numbers refer to. No third-party write-up is relied on.

| Claim | Primary source | Status |
|---|---|---|
| Test cases are saved in evals/evals.json inside the skill directory | SKILL.md L145; schemas.md L7-9 | verified from primary source |
| Each eval has id, prompt, expected_output, files | schemas.md L14-35 | verified from primary source |
| Eval assertion list field is named "assertions" | SKILL.md L161 | conflict: schemas.md L20 and L35 say "expectations" |
| Graded assertions: grader subagent (or inline) writes grading.json | SKILL.md L225; agents/grader.md L83 | verified from primary source |
| Benchmark: pass_rate, time, tokens; mean and sample stddev; delta | scripts/aggregate_benchmark.py L45-61, L130-145, L214-221; SKILL.md L231 | verified from primary source |
| Blind comparison: comparator agent judges A and B without knowing the skill | agents/comparator.md L3, L7; SKILL.md L325-327 | verified from primary source; optional, needs subagents |
| Trigger testing: run_eval.py, run_loop.py, improve_description.py | scripts/run_eval.py L266; run_loop.py L251-254; improve_description.py L26 | verified from primary source |
| Review viewer: eval-viewer/generate_review.py | SKILL.md L236-249 names it; the file exists at that commit | path verified; contents not read |
| Introduction date (evals, benchmark, comparator "in 2026") | history of skills/skill-creator: b0cbd3df (2026-03-06), b9e19e6f (2026-04-20) | not established; only a third-party write-up claims it |
| The plugin skill-creator loop and claude plugin eval use incompatible formats | code.claude.com skills page, section 'Run evals with skill-creator' and the paragraph before it, 'Two tools automate the baseline comparison' | verified from vendor doc |

Commit read: dbd4588f9e1033efb41dad4bef2f7947c8993d44. Vendor docs: https://code.claude.com/docs/en/skills and https://code.claude.com/docs/en/plugin-evals (read as plain text; line numbers L<n> in the plugin-evals page refer to that plain-text rendering, so use section titles to find a passage). Date read: 2026-10-26.

## Related

- [skill-creator-evals-mechanics.md](skill-creator-evals-mechanics.md) -- how cases are written, graded and run, with cost estimates.
- [claude-plugin-eval.md](claude-plugin-eval.md) -- the first-party command, a different tool with its own case format.
- [../INDEX.md](../INDEX.md) -- documentation index for the docs/ root.
