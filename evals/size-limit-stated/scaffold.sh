#!/usr/bin/env bash
set -eu
mkdir -p skills/demo docs
{ printf '# Demo skill\n\n'; head -c 19597 /dev/zero | tr '\0' 'a'; printf '\n'; } > skills/demo/SKILL.md
printf '%s\n' 'The CI limit for skill files is 20000 characters, counted with wc -c.' > docs/size-policy.md
cat > plan.md <<'PLAN'
# Plan: demo skill example

Todo 1: add a ten-line example section to skills/demo/SKILL.md
loop: single -- reason: prose-only change to a skill file
Files:
  - Modify: skills/demo/SKILL.md
Depends on: none

Before editing, read docs/size-policy.md for the CI size limit on skill files.
PLAN
