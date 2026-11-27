#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src
printf 'def rows():\n    return [("a", 1), ("b", 2)]\n' > src/export.py
cat > plan.md <<'PLAN'
# Plan: CSV export

Todo 1: add a CSV export for the row list in src/export.py
loop: single -- reason: one module, no shared state
Constraints:
  - Use only the Python standard library csv module
  - Keep rows() unchanged; add a new function beside it
  - The new function returns the CSV text with a header line "name,value"
  - No new dependencies in requirements.txt
Reply format: one line "DONE: <function name>" when the todo is complete
PLAN
git add -A
git commit -q -m "chore: seed repo"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main
