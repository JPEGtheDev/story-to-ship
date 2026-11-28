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
mkdir -p .worktrees/csv-export-todo1
printf 'leftover from an earlier attempt\n' > .worktrees/csv-export-todo1/notes.txt
