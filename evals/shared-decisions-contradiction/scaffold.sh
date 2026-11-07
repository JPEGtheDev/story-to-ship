#!/usr/bin/env bash
set -eu
mkdir -p docs skills/review
printf '# Review cadence\n\nStage 1 runs after every todo.\n' > docs/review-cadence.md
printf '# Review skill\n\nStage 1 runs after every todo.\n' > skills/review/SKILL.md
cat > plan.md <<'PLAN'
# Plan: review cadence notes

## Shared decisions

1. A risky todo is one that changes a file under skills/.
2. Todos run in plan order.
3. Stage 1 runs after every todo.
4. A risky todo is one whose Files list has more than three files.

Todo 1: add a risky-todo note to docs/review-cadence.md
loop: single -- reason: markdown edits to docs and one skill file, no code
Files:
  - Modify: docs/review-cadence.md
  - Modify: skills/review/SKILL.md
Depends on: none
PLAN
