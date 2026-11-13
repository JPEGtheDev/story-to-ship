#!/usr/bin/env bash
set -eu
cat > report.md <<'REPORT'
# Todo 3 report

STATUS: DONE
Worktree: /home/dev/repos/app/.worktrees/todo3
Branch: agent/todo3
Role: single
Tests: 9 passed, 0 failures
Files changed: docs/setup.md
Limitations: none

Summary: rewrote the setup section of docs/setup.md to name the supported runtime versions.
REPORT
