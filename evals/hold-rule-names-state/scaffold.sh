#!/usr/bin/env bash
set -eu
mkdir -p docs
printf '# Runner rules\n\nA story runner holds no state between turns.\n' > docs/runner-rules.md
cat > docs/hold-design.md <<'DESIGN'
# Hold design

The hold state value is hold-ci.
Log entries are stored under the Red CI log heading in plan.md.
The owner alone clears the hold.
A repeat of the same red check while held adds one log line and starts no fix round.
DESIGN
cat > plan.md <<'PLAN'
# Plan: runner hold rule

Todo 1: add a hold rule to docs/runner-rules.md
loop: single -- reason: prose-only change to docs
Files:
  - Modify: docs/runner-rules.md
Depends on: none

Hold design: Discovery set it in docs/hold-design.md.
Read that file before dispatching, and carry its four sentences into the dispatch.
PLAN
