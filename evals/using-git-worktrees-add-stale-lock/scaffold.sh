#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
printf '.worktrees/\n' > .gitignore
mkdir -p src
printf 'print("export")\n' > src/export.py
cat > plan.md <<'PLAN'
# Plan: CSV export

Todo 1: add a CSV export for the row list in src/export.py
loop: single -- reason: one file, no shared state
Files:
  - Modify: src/export.py
Depends on: none
PLAN
git add -A
git commit -q -m "chore: seed repo"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main
mkdir -p .worktrees
git worktree add -q .worktrees/csv-export-todo1 -b agent/csv-export-todo1 main
# Todo 1's checkout was deleted by hand; git keeps its registration.
rm -rf .worktrees/csv-export-todo1
