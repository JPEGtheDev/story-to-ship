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
SKILL
cat > report.md <<'REPORT'
# Todo 4 report

STATUS: DONE
Worktree: /home/dev/repos/app/.worktrees/todo4
Branch: agent/todo4
Role: single
Tests: none run
Files changed: skills/log-triage/SKILL.md
Limitations: none

Summary: added the grouping rule to the log-triage skill.
REPORT
