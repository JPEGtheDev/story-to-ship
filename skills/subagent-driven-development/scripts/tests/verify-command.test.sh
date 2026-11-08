#!/bin/sh
# Kept test for verify-command-check.sh: the echo-redirect and digit-count forms.
# Runs the checker on three fixtures under tests/verify-command/ and on two usage errors.
# Usage cases fail when the checker is absent, so sh's own exit 2 cannot pass them.
# Prints one "ok <case>" or "FAIL <case>: <detail>" line per case.
# Usage: sh skills/subagent-driven-development/scripts/tests/verify-command.test.sh
# Exit 0 when every case passes, 1 when any case fails.
set -u
DIR=$(cd "$(dirname "$0")" && pwd) || exit 2
CHECK=$DIR/../verify-command-check.sh
FIX=$DIR/verify-command
FAILED=0

# case_ok <case>: print the pass line.
case_ok() { printf 'ok %s\n' "$1"; }

# case_fail <case> <detail>: print the failure line and record it.
case_fail() { printf 'FAIL %s: %s\n' "$1" "$2"; FAILED=1; }

# run_check <path>: run the checker on one prompt file; OUT holds combined output, RC the status.
run_check() {
  OUT=$(sh "$CHECK" "$1" 2>&1)
  RC=$?
}

# checker_present <case>: report a failure and return 1 when the checker script is absent.
checker_present() {
  if [ -f "$CHECK" ]; then
    return 0
  fi
  case_fail "$1" "checker missing: $CHECK"
  return 1
}

# Case: echo form on line 1 is flagged.
run_check "$FIX/fail-echo-evidence.md"
if [ "$RC" -ne 1 ]; then
  case_fail fail-echo-evidence "exit $RC, expected 1: $OUT"
elif printf '%s\n' "$OUT" | grep -qF 'VIOLATION line 1: echo'; then
  case_ok fail-echo-evidence
else
  case_fail fail-echo-evidence "no 'VIOLATION line 1: echo' in output: $OUT"
fi

# Case: digit-count form on line 1 is flagged.
run_check "$FIX/fail-digits-count.md"
if [ "$RC" -ne 1 ]; then
  case_fail fail-digits-count "exit $RC, expected 1: $OUT"
elif printf '%s\n' "$OUT" | grep -qF 'VIOLATION line 1: digit-count'; then
  case_ok fail-digits-count
else
  case_fail fail-digits-count "no 'VIOLATION line 1: digit-count' in output: $OUT"
fi

# Case: each digit-pattern and count-step variant on lines 2 to 4 is flagged (the digit class,
# the \d pattern, and a bare grep -c with no wc).
if printf '%s\n' "$OUT" | grep -qF 'VIOLATION line 2: digit-count' &&
  printf '%s\n' "$OUT" | grep -qF 'VIOLATION line 3: digit-count' &&
  printf '%s\n' "$OUT" | grep -qF 'VIOLATION line 4: digit-count'; then
  case_ok fail-digits-count-variants
else
  case_fail fail-digits-count-variants "lines 2-4 not all flagged as digit-count: $OUT"
fi

# Case: the clean fixture passes with exit 0 and no output.
run_check "$FIX/clean.md"
if [ "$RC" -ne 0 ]; then
  case_fail clean "exit $RC, expected 0: $OUT"
elif [ -n "$OUT" ]; then
  case_fail clean "expected no output, got: $OUT"
else
  case_ok clean
fi

# Case: no argument is a usage error with exit 2.
if checker_present no-argument; then
  OUT=$(sh "$CHECK" 2>&1)
  RC=$?
  if [ "$RC" -eq 2 ]; then
    case_ok no-argument
  else
    case_fail no-argument "exit $RC, expected 2: $OUT"
  fi
fi

# Case: an unreadable (missing) file is a usage error with exit 2.
if checker_present missing-file; then
  run_check "$FIX/does-not-exist.md"
  if [ "$RC" -eq 2 ]; then
    case_ok missing-file
  else
    case_fail missing-file "exit $RC, expected 2: $OUT"
  fi
fi

exit "$FAILED"
