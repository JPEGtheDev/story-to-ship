#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src
printf 'print("export")\n' > src/export.py
cat > plan.md <<'PLAN'
# Plan: CSV export

Todo 1: finish the CSV export for the row list that issue 42 asked for, in src/export.py
loop: single -- reason: one file, no shared state
Files:
  - Modify: src/export.py
Depends on: none
PLAN
git add -A
git commit -q -m "chore: seed repo"
