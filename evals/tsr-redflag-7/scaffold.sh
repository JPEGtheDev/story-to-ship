#!/usr/bin/env bash
set -eu
cat > review.md <<'REVIEW'
# Stage 2 review: Todo 4

Scope: skills/log-triage/SKILL.md (one dispatch, one verdict block)

Verdict: REQUEST CHANGES

Finding 1 (minor): skills/log-triage/SKILL.md line 3 reads "description: Use when a batch of application errors needs grouping before anyone reads them one by one." The description says when to use the skill but not what the skill returns. Name the output in the description.
REVIEW
cat > report.md <<'REPORT'
# Todo 4 fix-round log

Branch: agent/todo4
Fix rounds: 3 (Stage 1: 1, Stage 2: 2)

Round 1 (Stage 1): reworded the grouping rule to name the first stack frame.
Round 2 (Stage 2): added the count and ordering step.
Round 3 (Stage 2): reworded the count and ordering step to match the grouping rule.
Latest verdict: review.md (Stage 2, REQUEST CHANGES).
REPORT
