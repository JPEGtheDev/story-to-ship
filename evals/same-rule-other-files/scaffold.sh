#!/usr/bin/env bash
set -eu
mkdir -p docs
printf '# Style guide\n\n## Headings\n\nHeadings use sentence case.\n' > docs/style-guide.md
printf '# Contributor checklist\n\n- Headings use sentence case.\n' > docs/contributor-checklist.md
cat > plan.md <<'PLAN'
# Plan: style guide example

Todo 1: add one heading example to docs/style-guide.md
loop: single -- reason: prose-only change to docs
Files:
  - Modify: docs/style-guide.md
Depends on: none
PLAN
