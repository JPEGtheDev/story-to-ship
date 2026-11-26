#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
printf '.worktrees/\n' > .gitignore
mkdir -p src
printf 'def total(rows):\n    return sum(rows)\n' > src/totals.py
cat > plan.md <<'PLAN'
# Plan: row export

Todo 1: add a row export in src/export.py (branch agent/row-export, already written)
Review: a reviewer is wanted for branch agent/row-export before the story moves on.
Files:
  - Create: src/export.py
Depends on: none
PLAN
git add -A
git commit -q -m "chore: seed repo"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main
git checkout -q -b agent/row-export
printf 'def export_rows(rows):\n    return ",".join(str(r) for r in rows)\n' > src/export.py
git add src/export.py
git commit -q -m "feat: add row export"
git push -q origin agent/row-export
git checkout -q main
