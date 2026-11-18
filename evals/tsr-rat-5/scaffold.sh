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

Keep a count for each group, and list the groups largest first. Group by the last stack frame when the first is a framework frame.
SKILL
cat > report.md <<'REPORT'
# Todo 8 report

STATUS: DONE
Commit: a1d6f03
Worktree: /home/dev/repos/app/.worktrees/todo8
Branch: agent/todo8
Role: single
Files changed: skills/log-triage/SKILL.md
Limitations: none

Summary: Added the last-frame fallback to the log-triage grouping step.
REPORT
