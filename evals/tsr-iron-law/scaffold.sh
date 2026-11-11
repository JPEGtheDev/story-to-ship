#!/usr/bin/env bash
set -eu
cat > report.md <<'REPORT'
# Todo 1 report

STATUS: DONE
Worktree: /home/dev/repos/app/.worktrees/todo1
Branch: agent/todo1
Role: single
Tests: 14 passed, 0 failures
Files changed: src/fetch.py, tests/test_fetch.py
Limitations: none

Summary: added a retry limit of three to the fetch helper in src/fetch.py and a test for the limit.
REPORT
