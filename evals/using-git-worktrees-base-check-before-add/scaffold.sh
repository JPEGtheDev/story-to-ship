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
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main
git branch feature/csv-export main
git worktree add -q .worktrees/csv-export feature/csv-export
printf 'print("upstream")\n' > src/upstream.py
git add -A
git commit -q -m "feat: add upstream module"
git push -q origin main
git fetch -q origin
