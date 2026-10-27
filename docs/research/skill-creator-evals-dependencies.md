---
title: "Skill-creator and plugin eval: dependencies adoption would bring"
description: "Lists each runtime, package, service and secret that adopting either eval toolkit would add, and which the CI workflow already uses."
domain: research
subdomain: skill-testing
tags: [research, skill-testing, dependencies]
related:
  - "skill-creator-evals-mechanics.md"
  - "claude-plugin-eval.md"
  - "skill-creator-evals.md"
---

# Dependencies adoption would bring

Checked against `.github/workflows/validate.yml` by grep on 2026-10-26. The workflow has no `claude` command, no `secret` text, and no step that calls a model service.

| Dependency | Needed by | Already used by validate.yml? | Note |
|---|---|---|---|
| Claude Code command-line interface, v2.1.269 or later | plugin eval (claude-plugin-eval.md, Requirements) | No: no `claude` command in any run step | New to CI. |
| Model credential stored as a CI secret | plugin eval and skill-creator loop, which use the user's login (mechanics, Headless) | No: no secret reference | New to CI. Secret handling is a new security surface. |
| Model service account with spend | both; plugin eval estimate per suite (claude-plugin-eval.md, Credentials and cost) | No | New to CI. Each run is paid. |
| Network access to the model service | both | No (inference: no step calls out) | New to CI. |
| git | plugin eval needs 2.31 or later if git is installed (claude-plugin-eval.md, Requirements) | No: no run step calls git; the word appears only inside check arguments (L163, L325, L369) | Preinstalled on the runner (inference). |
| Python 3 | skill-creator scripts (mechanics, Headless) | Yes: `python3 -m unittest discover` in three unit-test steps | Not new. |
| jq | neither tool's source names it | Yes: e.g. L20-27, L65 | Not needed by either (inference). |
| shellcheck | neither tool's source names it | Yes: e.g. L31-50 | Not needed by either (inference). |
| actions/checkout@v4 | both need the repository checked out | Yes: L16 | Not new. |
| skill-creator skill files at a pinned commit | skill-creator loop (sources, Repository) | No | New package. Vendored or fetched at run time (inference on how it would be supplied). |
| claude.ai publishing | plugin eval report, by default when signed in with a subscription (claude-plugin-eval.md, Publishing) | No | Avoidable with `--no-publish`. |
| Browser for the skill-creator viewer | skill-creator review step (sources, SKILL.md L236-249) | No | Interactive, not needed headless; use `--static` (SKILL.md L247). |

## Related
- [skill-creator-evals-mechanics.md](skill-creator-evals-mechanics.md) -- headless needs and the claude command requirement.
- [claude-plugin-eval.md](claude-plugin-eval.md) -- requirements, credentials and publishing for the plugin command.
- [skill-creator-evals.md](skill-creator-evals.md) -- main report that uses this table.
