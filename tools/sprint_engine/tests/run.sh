#!/usr/bin/env bash
# run.sh -- the single test entrypoint for tools/sprint_engine. Runs, in
# order: (1) reports the node version in use, (2) node --check on
# engine-core.js, (3) the runner-syntax-check.sh loadability proxy, (4)
# every tests/test-*.js suite, discovered by glob rather than a
# hard-coded list so a new suite file is picked up automatically, and (5)
# the inline-copy-check.sh marker-region byte-match gate. Every step runs
# regardless of an earlier step's outcome, so a single invocation reports
# every failure at once instead of stopping at the first one; the exit
# code is nonzero if ANY step failed, and every failing step is named in
# the output.
#
# Suite exit semantics (verified before writing this script, not assumed):
# every tests/test-*.js file in this directory ends with
# `process.exit(failCount === 0 ? 0 : 1)` on its normal path (some also
# have a second `process.exit(1)` on an uncaught-exception path). The
# process exit status is therefore a reliable, direct function of the
# suite's own pass/fail count today -- asserting on exit status alone is
# sufficient for these 12 files. This script still asserts on exit status
# as the PRIMARY signal (never by parsing stdout for a "0 failed" string,
# per this repo's standing rule that gate checks assert on exit status,
# not on parsed or empty stdout), but adds a belt-and-suspenders secondary
# check: if a suite ever exits 0 while its own final "<N> passed, <M>
# failed" line reports M != 0 -- a combination not reachable with the
# current process.exit(failCount === 0 ? 0 : 1) suites, but not something
# this script should silently trust forever -- that mismatch is itself
# reported as a failure, naming the inconsistency.
#
# Usage: run.sh
#   No arguments. Paths are derived from this script's own location (via
#   BASH_SOURCE), so it works identically whether invoked from the repo
#   root or from this tests/ directory.
#
# Exit codes: 0 when every step above passed and at least one test-*.js
# suite was discovered and run; nonzero if any step failed, INCLUDING a
# zero-suite glob match -- that case is reported as a failure, never as a
# vacuous pass.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="$SCRIPT_DIR/.."
ENGINE_CORE="$ENGINE_DIR/engine-core.js"
RUNNER_SYNTAX_CHECK="$SCRIPT_DIR/runner-syntax-check.sh"
INLINE_COPY_CHECK="$SCRIPT_DIR/inline-copy-check.sh"

OVERALL_FAILED=0
FAILED_STEPS=()

# run_gate NAME -- CMD [ARGS...] -- runs CMD, prints its combined
# stdout/stderr, and reports a [NAME] PASS/FAIL line based on CMD's exit
# status alone (never on parsing that output). On failure, NAME is
# appended to FAILED_STEPS and OVERALL_FAILED is set, but the function
# still returns normally so the caller can continue to the next step.
run_gate() {
  local name="$1"
  shift
  local output status
  output="$("$@" 2>&1)"
  status=$?
  printf '%s\n' "$output"
  if [[ "$status" -eq 0 ]]; then
    echo "[$name] PASS"
    return 0
  fi
  echo "[$name] FAIL (exit $status)" >&2
  OVERALL_FAILED=1
  FAILED_STEPS+=("$name")
  return "$status"
}

echo "=== step 1: node --version ==="
echo "node --version: $(node --version 2>&1)"

echo "=== step 2: node --check engine-core.js ==="
run_gate "node --check engine-core.js" node --check "$ENGINE_CORE"

echo "=== step 3: runner-syntax-check.sh ==="
run_gate "runner-syntax-check.sh" bash "$RUNNER_SYNTAX_CHECK"

echo "=== step 4: test-*.js suites ==="
shopt -s nullglob
TEST_FILES=("$SCRIPT_DIR"/test-*.js)
shopt -u nullglob

if [[ "${#TEST_FILES[@]}" -eq 0 ]]; then
  echo "run.sh: FAIL -- glob $SCRIPT_DIR/test-*.js matched zero files (a zero-suite run is never a vacuous pass)" >&2
  OVERALL_FAILED=1
  FAILED_STEPS+=("test-*.js discovery")
else
  SUITES_PASSED=0
  SUITES_FAILED=0
  for test_file in "${TEST_FILES[@]}"; do
    suite_name="$(basename "$test_file")"
    suite_output="$(node "$test_file" 2>&1)"
    suite_status=$?
    last_line="$(printf '%s\n' "$suite_output" | tail -n 1)"
    printf '%s\n' "$suite_output"

    inconsistent=0
    if [[ "$suite_status" -eq 0 && "$last_line" =~ ([0-9]+)\ passed,\ ([0-9]+)\ failed ]]; then
      reported_failed="${BASH_REMATCH[2]}"
      if [[ "$reported_failed" -ne 0 ]]; then
        inconsistent=1
      fi
    fi

    if [[ "$suite_status" -ne 0 ]]; then
      echo "[suite: $suite_name] FAIL (exit $suite_status)" >&2
      OVERALL_FAILED=1
      FAILED_STEPS+=("test-suite:$suite_name")
      SUITES_FAILED=$((SUITES_FAILED + 1))
    elif [[ "$inconsistent" -eq 1 ]]; then
      echo "[suite: $suite_name] FAIL -- exited 0 but its own summary line reports a nonzero failed count ($last_line); exit status and reported count disagree" >&2
      OVERALL_FAILED=1
      FAILED_STEPS+=("test-suite:$suite_name")
      SUITES_FAILED=$((SUITES_FAILED + 1))
    else
      echo "[suite: $suite_name] PASS -- $last_line"
      SUITES_PASSED=$((SUITES_PASSED + 1))
    fi
  done
  echo "suites: ${#TEST_FILES[@]} run, $SUITES_PASSED passed, $SUITES_FAILED failed"
fi

echo "=== step 5: inline-copy-check.sh ==="
run_gate "inline-copy-check.sh" bash "$INLINE_COPY_CHECK"

echo "=== summary ==="
if [[ "$OVERALL_FAILED" -eq 0 ]]; then
  echo "run.sh: PASS -- all steps succeeded"
  exit 0
fi

echo "run.sh: FAIL -- failing step(s): ${FAILED_STEPS[*]}" >&2
exit 1
