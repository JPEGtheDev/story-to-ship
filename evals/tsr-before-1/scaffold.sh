#!/usr/bin/env bash
set -eu
cat > report.md <<'REPORT'
# Todo 2 report

STATUS: BLOCKED
Worktree: /home/dev/repos/app/.worktrees/todo2
Branch: agent/todo2
Role: single
Tests: none run
Files changed: none
Limitations: the sandbox cannot reach the package index, so the test suite did not run.

Blocker: the package index host is unreachable from the sandbox. The change to the parser is written but unverified. Access to the index needs an owner action.
REPORT
