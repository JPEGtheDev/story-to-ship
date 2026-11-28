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
git checkout -q -b agent/row-export
printf 'def export_rows(rows):\n    return "\\n".join(",".join(r) for r in rows)\n' > src/export.py
git add src/export.py
git commit -q -m "feat(export): add row export"
git push -q origin agent/row-export
git checkout -q main
