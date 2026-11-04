#!/bin/sh
# Fixture tests for tests/run.sh: the PASS and FAIL lines, the summary line, and the exit codes for
# a directory whose test file passes, one whose test files pass and fail, and one with no
# *.test.sh file. RUN_SH=<path> substitutes another runner (used to prove a test can fail).
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

RUNNER=${RUN_SH:-$(dirname "$0")/run.sh}

# make_case <name>: a fresh directory under TEST_TMP holding a copy of the runner as run.sh.
# Sets CASE to its path. The runner finds its test files next to itself, so each case is isolated.
make_case() {
  CASE=$TEST_TMP/$1
  mkdir "$CASE" || exit 2
  cp "$RUNNER" "$CASE/run.sh" || exit 2
}

# Case 1: one passing test file. Exit 0, a PASS line and the summary.
make_case pass-only
printf '%s\n' 'exit 0' > "$CASE/ok.test.sh"
sh "$CASE/run.sh" >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
cat > "$TEST_TMP/want-pass" <<EOF
PASS ok.test.sh
run.sh: 1 test files, 0 failed
EOF
assert_exit "pass-only exit" 0 "$RC"
assert_file_eq "pass-only lines" "$TEST_TMP/want-pass" "$TEST_TMP/out"

# Case 2: one failing and one passing test file. Exit 1, a FAIL and a PASS line, the summary.
make_case pass-and-fail
printf '%s\n' 'exit 0' > "$CASE/ok.test.sh"
printf '%s\n' 'exit 1' > "$CASE/bad.test.sh"
sh "$CASE/run.sh" >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
cat > "$TEST_TMP/want-fail" <<EOF
FAIL bad.test.sh
PASS ok.test.sh
run.sh: 2 test files, 1 failed
EOF
assert_exit "pass-and-fail exit" 1 "$RC"
assert_file_eq "pass-and-fail lines" "$TEST_TMP/want-fail" "$TEST_TMP/out"

# Case 3: no *.test.sh file (a non-test file alone). Exit 1 and the no-files message.
make_case no-files
printf '%s\n' 'not a test' > "$CASE/readme.txt"
sh "$CASE/run.sh" >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
assert_exit "no-files exit" 1 "$RC"
assert_grep "no-files message" 'run[.]sh: no [*][.]test[.]sh files' "$TEST_TMP/out"

test_summary
