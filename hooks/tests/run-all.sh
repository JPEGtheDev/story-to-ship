#!/usr/bin/env bash
# Single entrypoint for every hook test suite under hooks/tests/.
#
# Discovery is dynamic: this script globs for run.sh and run-*.sh siblings
# in its own directory, excluding itself. A future hooks/tests/run-<hook>.sh
# suite is picked up automatically with ZERO edits to this file -- just drop
# the new runner next to the existing ones.
#
# For each discovered suite: prints a per-suite header, runs the suite,
# prints its full output, and records pass/fail. Every suite always runs to
# completion regardless of earlier suites' results (no `set -e`, matching
# the existing runners' style) -- a failing suite's exit code is captured
# for aggregation, never allowed to abort the remaining suites or the
# summary. Exits nonzero if any suite failed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "${BASH_SOURCE[0]}")"

overall_exit=0
total=0
failed_suites=()

for suite in "$SCRIPT_DIR"/run*.sh; do
  name="$(basename "$suite")"
  [[ "$name" == "$SELF" ]] && continue

  total=$((total + 1))

  echo "=================================================="
  echo "Suite: $name"
  echo "=================================================="
  bash "$suite"
  suite_exit=$?
  echo ""

  if [[ "$suite_exit" -ne 0 ]]; then
    overall_exit=1
    failed_suites+=("$name")
  fi
done

echo "=================================================="
echo "Overall: $total suite(s) run"

if [[ "$overall_exit" -ne 0 ]]; then
  echo "FAILING SUITES:"
  for f in "${failed_suites[@]}"; do
    echo "  - $f"
  done
else
  echo "All suites passed."
fi

exit "$overall_exit"
