#!/bin/sh
# Fixture tests for handback-check.sh: the state, draft, mergeable and head lines, the gh failure
# path and usage errors. No network: the gh command is a stub that prints a JSON fixture file.
# HANDBACK_CHECK=<path> substitutes another script (used to prove a test can fail).
. "$(dirname "$0")/lib.sh"

SCRIPT=${HANDBACK_CHECK:-$(dirname "$0")/../handback-check.sh}
STUB=$TEST_TMP/gh-stub
REPO=$TEST_TMP/wt
JSON=$TEST_TMP/pr.json
export HANDBACK_GH=$STUB STUB_JSON=$JSON
unset STUB_EXIT

write_gh_stub "$STUB" || exit 2
make_repo "$REPO" || exit 2

# check_pr <state> <isDraft> <mergeable> <headRefOid>: write the PR document, then run the check
# with the default arguments. Sets RC and leaves stdout in $TEST_TMP/out, stderr in $TEST_TMP/err.
check_pr() {
  write_pr_json "$JSON" "$1" "$2" "$3" "$4"
  sh "$SCRIPT" -n 431 -w "$REPO" -s 427 >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
  RC=$?
}

# assert_case <name> <expected exit> <expected stdout file>: exit, exact stdout, empty stderr.
assert_case() {
  assert_exit "$1 exit" "$2" "$RC"
  assert_file_eq "$1 lines" "$3" "$TEST_TMP/out"
  assert_empty "$1 stderr" "$TEST_TMP/err"
}

# Case 1: all good. Every line is OK and the exit is 0.
check_pr OPEN false MERGEABLE "$FIX_HEAD"
cat > "$TEST_TMP/want-good" <<EOF
OK state: OPEN
OK draft: false
OK mergeable: MERGEABLE
OK head: $FIX_HEAD
EOF
assert_case "all-good" 0 "$TEST_TMP/want-good"

# Case 2: a closed PR fails the state line only.
check_pr CLOSED false MERGEABLE "$FIX_HEAD"
cat > "$TEST_TMP/want-closed" <<EOF
FAIL state: CLOSED
OK draft: false
OK mergeable: MERGEABLE
OK head: $FIX_HEAD
EOF
assert_case "state-closed" 1 "$TEST_TMP/want-closed"

# Case 3: a draft PR fails the draft line only.
check_pr OPEN true MERGEABLE "$FIX_HEAD"
cat > "$TEST_TMP/want-draft" <<EOF
OK state: OPEN
FAIL draft: true
OK mergeable: MERGEABLE
OK head: $FIX_HEAD
EOF
assert_case "draft-true" 1 "$TEST_TMP/want-draft"

# Case 4: mergeable UNKNOWN and CONFLICTING both fail the mergeable line.
check_pr OPEN false UNKNOWN "$FIX_HEAD"
cat > "$TEST_TMP/want-unknown" <<EOF
OK state: OPEN
OK draft: false
FAIL mergeable: UNKNOWN
OK head: $FIX_HEAD
EOF
assert_case "mergeable-unknown" 1 "$TEST_TMP/want-unknown"

check_pr OPEN false CONFLICTING "$FIX_HEAD"
cat > "$TEST_TMP/want-conflicting" <<EOF
OK state: OPEN
OK draft: false
FAIL mergeable: CONFLICTING
OK head: $FIX_HEAD
EOF
assert_case "mergeable-conflicting" 1 "$TEST_TMP/want-conflicting"

# Case 5: a PR head that differs from the worktree HEAD fails the head line with both shas.
check_pr OPEN false MERGEABLE "$FIX_BASE"
cat > "$TEST_TMP/want-head" <<EOF
OK state: OPEN
OK draft: false
OK mergeable: MERGEABLE
FAIL head: pr $FIX_BASE worktree $FIX_HEAD
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
EOF
assert_case "gh-exit-nonzero" 1 "$TEST_TMP/want-ghfail"

# Case 6b: the gh stub prints invalid JSON. The same four FAIL lines and no crash message.
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
write_pr_json "$JSON" OPEN false MERGEABLE "$FIX_HEAD"
sh "$SCRIPT" -n 431 -w "$REPO" -s 427 -b origin/main >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
assert_case "base-ref-accepted" 0 "$TEST_TMP/want-good"

test_summary
