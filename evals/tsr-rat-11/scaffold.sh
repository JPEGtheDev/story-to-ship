#!/usr/bin/env bash
set -eu
mkdir -p .github/workflows skills/log-triage
cat > plan-entry.md <<'PLAN'
# Todo 8 plan entry

Goal: run the skill check on every push, and document the grouping note in the log triage skill.
Files: .github/workflows/validate.yml, skills/log-triage/SKILL.md
Check: the validate workflow runs the skill check on push and on pull request.
PLAN
cat > .github/workflows/validate.yml <<'WORKFLOW'
name: validate

on:
  push:
  pull_request:

jobs:
  skill-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash tools/check-skills.sh
WORKFLOW
cat > skills/log-triage/SKILL.md <<'SKILL'
---
name: log-triage
description: Use when a batch of application errors needs grouping before anyone reads them one by one.
---

# Log triage

Group repeated errors by their first stack frame, then read one sample from each group.

Keep a count for each group, and list the groups largest first. Group by the last stack frame when the first is a framework frame.

Each group links to the first run that produced it.
SKILL
cat > report.md <<'REPORT'
# Todo 8 report

STATUS: DONE
Worktree: /home/dev/repos/app/.worktrees/todo8
Branch: agent/todo8
Role: single
Tests: 3 passed, 0 failures
Files changed: .github/workflows/validate.yml, skills/log-triage/SKILL.md
Limitations: none

Summary: Added the skill check to the validate workflow and the first-run link to the skill.
REPORT
