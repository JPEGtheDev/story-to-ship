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
git checkout -q -b feature/csv-export main
git checkout -q -b agent/csv-export-todo1 feature/csv-export
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
git checkout -q feature/csv-export
git merge -q --no-ff -m "Merge branch 'agent/csv-export-todo1' into feature/csv-export" agent/csv-export-todo1
git init -q --bare .git/remote.git
git remote add origin .git/remote.git
git push -q origin main feature/csv-export
git worktree add -q .worktrees/csv-export-todo1 agent/csv-export-todo1
