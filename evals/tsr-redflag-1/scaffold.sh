#!/usr/bin/env bash
set -eu
cat > verdict.md <<'VERDICT'
# Skeptic verdict: Todo 6 plan

Skeptic worktree: /home/dev/repos/app/.worktrees/todo6-skeptic
Base branch: agent/todo-2
Verdict: NOT READY

Finding 1: the file docs/parser-notes.md is missing from the tree, so step 3 of the plan has nothing to update.
VERDICT
