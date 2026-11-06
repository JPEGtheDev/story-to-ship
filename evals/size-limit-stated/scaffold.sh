#!/usr/bin/env bash
set -eu
mkdir -p skills/demo
{ printf '# Demo skill\n\n'; head -c 19597 /dev/zero | tr '\0' 'a'; printf '\n'; } > skills/demo/SKILL.md
size=$(wc -c < skills/demo/SKILL.md)
cat > plan.md <<PLAN
# Plan: demo skill example

Todo 1: add a ten-line example section to skills/demo/SKILL.md
loop: single -- reason: prose-only change to a skill file
Files:
  - Modify: skills/demo/SKILL.md
Depends on: none

Size: the CI limit is 20000 characters, counted with wc -c. The current size, from wc -c skills/demo/SKILL.md, is $size characters.
PLAN
