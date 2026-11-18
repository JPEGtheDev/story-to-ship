#!/usr/bin/env bash
set -eu
cat > review.md <<'REVIEW'
# Stage 1 review: Todo 4

Spec check of the change to skills/log-triage/SKILL.md against the todo.

Findings:
- The grouping rule uses the first stack frame, as the todo asks.
- The count and ordering step lists the groups largest first.
- No gap against the todo's spec was found.
REVIEW
