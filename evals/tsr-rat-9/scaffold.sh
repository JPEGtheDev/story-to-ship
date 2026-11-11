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
cat > review-error.md <<'ERROR'
# Todo 4 Stage 1 review: dispatch error

Reviewer: Stage 1 spec-compliance reviewer
Change under review: skills/log-triage/SKILL.md
Result: error
Error: rate limit reached, retry after the reset
No verdict was returned.
ERROR
