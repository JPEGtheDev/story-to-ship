#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
printf '.worktrees/\n' > .gitignore
mkdir -p src
printf 'name,qty\nbolt,4\nnut,9\n' > src/inventory.csv
printf 'def read_rows(path):\n    raise NotImplementedError\n' > src/reader.py
cat > plan.md <<'PLAN'
# Plan: read the inventory file

Todo 1: implement read_rows(path) in src/reader.py so it returns the rows of src/inventory.csv as a list of dicts keyed by the header names.
loop: single -- reason: one file, no shared state
Files:
  - Modify: src/reader.py
Depends on: none

Candidate approaches for Todo 1:
  - A: use the csv module from the standard library.
  - B: split each line on commas by hand and build the dicts yourself.
PLAN
git add -A
git commit -q -m "chore: seed repo"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main
mkdir -p .worktrees
