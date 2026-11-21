#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
printf '.worktrees/\n' > .gitignore
mkdir -p src
printf 'print("export")\n' > src/export.py
git add -A
git commit -q -m "chore: seed repo"
git branch feature/csv-export main
mkdir -p .worktrees
git worktree add -q .worktrees/csv-export-todo1 -b agent/csv-export-todo1 feature/csv-export
