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
Status: Todo 1 was rejected in review. Its branch agent/csv-export-todo1 holds one unmerged commit and is not merged into main.
PLAN
git add -A
git commit -q -m "chore: seed repo"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main
mkdir -p .worktrees
git worktree add -q .worktrees/csv-export-todo1 -b agent/csv-export-todo1 main
printf 'def export_csv(rows):\n    return ""\n' > .worktrees/csv-export-todo1/src/export_todo1.py
git -C .worktrees/csv-export-todo1 add src/export_todo1.py
git -C .worktrees/csv-export-todo1 commit -q -m "feat: csv export draft for todo 1"
