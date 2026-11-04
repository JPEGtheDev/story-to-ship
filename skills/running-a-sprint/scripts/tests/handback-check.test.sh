#!/bin/sh
# Fixture tests for handback-check.sh: the state, draft, mergeable, head and ci lines, the gh failure
# path and usage errors. No network: the gh command is a stub that prints a JSON fixture file.
# HANDBACK_CHECK=<path> substitutes another script (used to prove a test can fail).
. "$(dirname "$0")/lib.sh"

SCRIPT=${HANDBACK_CHECK:-$(dirname "$0")/../handback-check.sh}
STUB=$TEST_TMP/gh-stub
REPO=$TEST_TMP/wt
JSON=$TEST_TMP/pr.json
export HANDBACK_GH=$STUB STUB_JSON=$JSON
unset STUB_EXIT

# GOOD_ROLLUP: one successful check run, the all-good rollup.
GOOD_ROLLUP='[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"SUCCESS"}]'

write_gh_stub "$STUB" || exit 2
make_repo "$REPO" || exit 2

# check_pr <state> <isDraft> <mergeable> <headRefOid> [rollup JSON]: write the PR document, then run
# the check with the default arguments. The rollup defaults to GOOD_ROLLUP. Sets RC and leaves stdout
# in $TEST_TMP/out, stderr in $TEST_TMP/err.
check_pr() {
  write_pr_json "$JSON" "$1" "$2" "$3" "$4" "${5:-$GOOD_ROLLUP}"
  sh "$SCRIPT" -n 431 -w "$REPO" -s 427 >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
  RC=$?
}

# assert_case <name> <expected exit> <expected stdout file>: exit, exact stdout, empty stderr.
assert_case() {
  assert_exit "$1 exit" "$2" "$RC"
  assert_file_eq "$1 lines" "$3" "$TEST_TMP/out"
  assert_empty "$1 stderr" "$TEST_TMP/err"
}

# check_ci <name> <expected exit> <rollup JSON> <expected ci line>: the rollup is the only change;
# the state, draft, mergeable and head lines stay OK.
check_ci() {
  check_pr OPEN false MERGEABLE "$FIX_HEAD" "$3"
  printf '%s\n' "OK state: OPEN" "OK draft: false" "OK mergeable: MERGEABLE" "OK head: $FIX_HEAD" "$4" \
    > "$TEST_TMP/want-$1"
  assert_case "$1" "$2" "$TEST_TMP/want-$1"
}

# Case 1: all good. Every line is OK and the exit is 0.
check_pr OPEN false MERGEABLE "$FIX_HEAD"
cat > "$TEST_TMP/want-good" <<EOF
OK state: OPEN
OK draft: false
OK mergeable: MERGEABLE
OK head: $FIX_HEAD
OK ci: 1 checks successful
EOF
assert_case "all-good" 0 "$TEST_TMP/want-good"

# Case 2: a closed PR fails the state line only.
check_pr CLOSED false MERGEABLE "$FIX_HEAD"
cat > "$TEST_TMP/want-closed" <<EOF
FAIL state: CLOSED
OK draft: false
OK mergeable: MERGEABLE
OK head: $FIX_HEAD
OK ci: 1 checks successful
EOF
assert_case "state-closed" 1 "$TEST_TMP/want-closed"

# Case 3: a draft PR fails the draft line only.
check_pr OPEN true MERGEABLE "$FIX_HEAD"
cat > "$TEST_TMP/want-draft" <<EOF
OK state: OPEN
FAIL draft: true
OK mergeable: MERGEABLE
OK head: $FIX_HEAD
OK ci: 1 checks successful
EOF
assert_case "draft-true" 1 "$TEST_TMP/want-draft"

# Case 4: mergeable UNKNOWN and CONFLICTING both fail the mergeable line.
check_pr OPEN false UNKNOWN "$FIX_HEAD"
cat > "$TEST_TMP/want-unknown" <<EOF
OK state: OPEN
OK draft: false
FAIL mergeable: UNKNOWN
OK head: $FIX_HEAD
OK ci: 1 checks successful
EOF
assert_case "mergeable-unknown" 1 "$TEST_TMP/want-unknown"

check_pr OPEN false CONFLICTING "$FIX_HEAD"
cat > "$TEST_TMP/want-conflicting" <<EOF
OK state: OPEN
OK draft: false
FAIL mergeable: CONFLICTING
OK head: $FIX_HEAD
OK ci: 1 checks successful
EOF
assert_case "mergeable-conflicting" 1 "$TEST_TMP/want-conflicting"

# Case 5: a PR head that differs from the worktree HEAD fails the head line with both shas.
check_pr OPEN false MERGEABLE "$FIX_BASE"
cat > "$TEST_TMP/want-head" <<EOF
OK state: OPEN
OK draft: false
OK mergeable: MERGEABLE
FAIL head: pr $FIX_BASE worktree $FIX_HEAD
OK ci: 1 checks successful
EOF
assert_case "head-differs" 1 "$TEST_TMP/want-head"

# Case 6a: the gh stub exits non-zero. Exactly one FAIL line per check name, value "gh failed".
export STUB_EXIT=1
check_pr OPEN false MERGEABLE "$FIX_HEAD"
unset STUB_EXIT
cat > "$TEST_TMP/want-ghfail" <<EOF
FAIL state: gh failed
FAIL draft: gh failed
FAIL mergeable: gh failed
FAIL head: gh failed
FAIL ci: gh failed
EOF
assert_case "gh-exit-nonzero" 1 "$TEST_TMP/want-ghfail"

# Case 6b: the gh stub prints invalid JSON. The same five FAIL lines and no crash message.
printf '%s\n' 'not json at all' > "$TEST_TMP/bad.json"
STUB_JSON=$TEST_TMP/bad.json
export STUB_JSON
sh "$SCRIPT" -n 431 -w "$REPO" -s 427 >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
export STUB_JSON=$JSON
assert_case "gh-invalid-json" 1 "$TEST_TMP/want-ghfail"

# Case 7: usage errors exit 2, print a usage message on stderr and nothing on stdout.
# Each run uses the all-good document so a script that ignores the usage error would print OK lines.
write_pr_json "$JSON" OPEN false MERGEABLE "$FIX_HEAD"
for usage in "missing-n|-w $REPO -s 427" "missing-w|-n 431 -s 427" "missing-s|-n 431 -w $REPO" "unknown-option|-n 431 -w $REPO -s 427 -z"; do
  name=${usage%%|*}
  args=${usage#*|}
  # shellcheck disable=SC2086
  sh "$SCRIPT" $args >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
  RC=$?
  assert_exit "usage-$name exit" 2 "$RC"
  assert_empty "usage-$name stdout" "$TEST_TMP/out"
  assert_nonempty "usage-$name stderr" "$TEST_TMP/err"
  assert_grep "usage-$name message" 'usage' "$TEST_TMP/err"
done

# Case 8: -b is accepted and ignored by these checks. The fixture has a ref origin/main.
git_c "$REPO" update-ref refs/remotes/origin/main "$FIX_BASE" || exit 2
write_pr_json "$JSON" OPEN false MERGEABLE "$FIX_HEAD" "$GOOD_ROLLUP"
sh "$SCRIPT" -n 431 -w "$REPO" -s 427 -b origin/main >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
assert_case "base-ref-accepted" 0 "$TEST_TMP/want-good"

# Case 9: the ci line. Each entry's effective state is its conclusion when non-empty, else its
# status (CheckRun); a StatusContext uses its state. Only SUCCESS passes.
check_ci ci-in-progress 1 '[{"__typename":"CheckRun","name":"build","status":"IN_PROGRESS","conclusion":""}]' \
  "FAIL ci: 1 of 1 not successful: build=IN_PROGRESS"

check_ci ci-failure 1 '[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"FAILURE"}]' \
  "FAIL ci: 1 of 1 not successful: build=FAILURE"

check_ci ci-neutral 1 '[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"NEUTRAL"}]' \
  "FAIL ci: 1 of 1 not successful: build=NEUTRAL"

check_ci ci-only-skipped 1 '[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"SKIPPED"}]' \
  "FAIL ci: 1 of 1 not successful: build=SKIPPED"

check_ci ci-success-and-skipped 1 '[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"SUCCESS"},{"__typename":"CheckRun","name":"lint","status":"COMPLETED","conclusion":"SKIPPED"}]' \
  "FAIL ci: 1 of 2 not successful: lint=SKIPPED"

check_ci ci-empty-array 1 '[]' "FAIL ci: no checks"

# A missing statusCheckRollup field is the same as an empty rollup: FAIL ci: no checks.
printf '%s\n' "{\"number\":431,\"state\":\"OPEN\",\"isDraft\":false,\"mergeable\":\"MERGEABLE\",\"headRefOid\":\"$FIX_HEAD\",\"body\":\"\"}" > "$JSON"
sh "$SCRIPT" -n 431 -w "$REPO" -s 427 >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
printf '%s\n' "OK state: OPEN" "OK draft: false" "OK mergeable: MERGEABLE" "OK head: $FIX_HEAD" \
  "FAIL ci: no checks" > "$TEST_TMP/want-ci-missing-field"
assert_case "ci-missing-field" 1 "$TEST_TMP/want-ci-missing-field"

# StatusContext entries: a SUCCESS state passes, a PENDING state fails with the context name.
check_ci ci-status-context-success 0 '[{"__typename":"StatusContext","context":"lint","state":"SUCCESS"}]' \
  "OK ci: 1 checks successful"

check_ci ci-status-context-pending 1 '[{"__typename":"StatusContext","context":"lint","state":"PENDING"}]' \
  "FAIL ci: 1 of 1 not successful: lint=PENDING"

# Two failing entries are both listed, in input order, comma-separated with no spaces.
check_ci ci-two-failing 1 '[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"FAILURE"},{"__typename":"CheckRun","name":"test","status":"COMPLETED","conclusion":"SUCCESS"},{"__typename":"StatusContext","context":"lint","state":"PENDING"}]' \
  "FAIL ci: 2 of 3 not successful: build=FAILURE,lint=PENDING"

test_summary
