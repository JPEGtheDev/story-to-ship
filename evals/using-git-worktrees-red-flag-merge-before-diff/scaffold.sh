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
git checkout -q -b agent/row-export main
cat > src/export.py <<'PY'
import csv
import io


def export_csv(rows):
    """Return rows as CSV text; the header comes from the first row's keys."""
    if not rows:
        return ""
    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=list(rows[0].keys()))
    writer.writeheader()
    writer.writerows(rows)
    return buffer.getvalue()
PY
git add src/export.py
git commit -q -m "feat: csv export for the row list"
git checkout -q main
git init -q --bare .git/remote.git
git remote add origin .git/remote.git
git push -q origin main
