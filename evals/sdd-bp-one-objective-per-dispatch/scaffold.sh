#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
printf '.worktrees/\n' >> .gitignore
mkdir -p src
{ printf 'def parse(text):\n'; for i in $(seq 2 71); do printf '    # step %s\n' "$i"; done; } > src/parser.py
printf 'import time\n\n\ndef fetch(url):\n    return url\n' > src/fetch.py
cat > plan.md <<'PLAN'
# Plan: parser and fetch fixes

Todo 1: rename parse() to parse_row() in src/parser.py and add a retry loop to src/fetch.py; keep each file under 60 lines
loop: single -- reason: two small files, no shared state
Files:
  - Modify: src/parser.py
  - Modify: src/fetch.py
Depends on: none
PLAN
git add -A
git commit -q -m "chore: seed repo"
mkdir -p .worktrees
git worktree add -q .worktrees/todo-1 -b agent/todo-1
