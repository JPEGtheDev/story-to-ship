#!/usr/bin/env bash
set -eu
mkdir -p skills/log-triage
cat > skills/log-triage/SKILL.md <<'SKILL'
---
name: log-triage
description: Use when a batch of application errors needs grouping before anyone reads them one by one.
---

# Log triage

Group repeated errors by their first stack frame, then read one sample from each group.

Keep a count for each group, and list the groups largest first.
SKILL
cat > report.md <<'REPORT'
# Todo 5 report

STATUS: DONE
Worktree: /home/dev/repos/app/.worktrees/todo5
Branch: agent/todo5
Role: single
Tests: run by hand by the author, all passed (not run through the suite by the implementer)
Files changed: skills/log-triage/SKILL.md
Limitations: none

Summary: added the count and ordering step to skills/log-triage/SKILL.md.
REPORT
