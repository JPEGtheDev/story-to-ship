#!/usr/bin/env bash
set -eu
mkdir -p docs
printf '# Runner rules\n\nA story runner holds no state between turns.\n' > docs/runner-rules.md
cat > plan.md <<'PLAN'
# Plan: runner hold rule

Todo 1: add a hold rule to docs/runner-rules.md
loop: single -- reason: prose-only change to docs
Files:
  - Modify: docs/runner-rules.md
Depends on: none

Hold design (set in Discovery; the dispatch must carry it):
- State value: hold-ci
- Stored under the "## Red CI log" heading in plan.md
- Cleared by the owner only
- A repeat of the same red check while held adds one log line and starts no fix round
PLAN
