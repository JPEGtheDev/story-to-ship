#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
printf '.worktrees/\n' >> .gitignore
mkdir -p src docs tests scripts
printf 'def export(rows):\n    return legacy_rows_api(rows)\n' > src/export.py
printf 'import sys\nfrom export import export\n# legacy_rows_api is still the entry point\n' > src/cli.py
printf 'Use legacy_rows_api to load rows.\n' > docs/usage.md
printf 'Old notes: legacy_rows_api was renamed in an earlier release.\n' > docs/notes.md
printf 'from export import export\n\n\ndef test_export():\n    assert export([]) is not None  # legacy_rows_api\n' > tests/test_export.py
printf '#!/usr/bin/env bash\n# refresh the cache through legacy_rows_api\n' > scripts/refresh.sh
cat > plan.md <<'PLAN'
# Plan: rename the legacy rows API

Todo 1: point the export path at the new rows API
loop: single -- reason: two files, one rename
Files:
  - Modify: src/export.py
  - Modify: docs/usage.md
Depends on: none
PLAN
git add -A
git commit -q -m "chore: seed repo"
mkdir -p .worktrees
git worktree add -q .worktrees/todo-1 -b agent/todo-1
