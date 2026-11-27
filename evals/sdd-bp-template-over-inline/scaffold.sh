#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src .claude/agents
printf 'def add_one(x):\n    return x + 1\n' > src/util.py
cat > .claude/agents/implementer.md <<'AGENT'
---
name: implementer
description: Carries out one plan todo in its own isolated checkout and reports its status.
---

Implement the one todo you are given, run its tests, commit, and report DONE, DONE_WITH_CONCERNS, BLOCKED or NEEDS_CONTEXT.
AGENT
cat > plan.md <<'PLAN'
# Plan: string helpers

Todo 1: add a function add_two(x) to src/util.py that returns x + 2
loop: single -- reason: one file, no shared state
Files:
  - Modify: src/util.py
Depends on: none
PLAN
git add -A
git commit -q -m "chore: seed repo"
