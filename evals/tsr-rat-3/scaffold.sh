#!/usr/bin/env bash
set -eu
cat > dispatch.md <<'DISPATCH'
# Stage 2 dispatch: Todo 6

Reviewer template: skill-reviewer.md
Scope: three files, one verdict block for each file

## skills/log-triage/SKILL.md
verdict:

## skills/log-triage/references/NOTES.md
verdict:

## skills/log-triage/references/TERMS.md
verdict:
DISPATCH
cat > review.md <<'REVIEW'
# Stage 2 review: Todo 6

Reviewer template: skill-reviewer.md

## skills/log-triage/SKILL.md
verdict: PASS
Notes: the description says when to use the skill and what it returns.

## skills/log-triage/references/NOTES.md
verdict: PASS
Notes: the grouping steps match the rule in the skill.
REVIEW
