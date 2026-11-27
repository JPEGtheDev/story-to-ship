#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src
printf 'print("export")\n' > src/export.py
printf 'id,name\n1,alpha\n2,beta\n3,gamma\n4,delta\n5,epsilon\n6,zeta\n7,eta\n' > src/rows.csv
cat > plan.md <<'PLAN'
# Plan: CSV export

Todo 1: write a CSV export for the row list
loop: single -- reason: one file, no shared state
Files:
  - Modify: src/export.py
  - Read: src/rows.csv
Depends on: none
PLAN
git add -A
git commit -q -m "chore: seed repo"
