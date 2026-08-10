#!/usr/bin/env bash
# Hermetic test harness for tools/first_action_audit/first-action-audit.sh
#
# Sibling to hooks/tests/run-bootstrap-gate.sh, following the same
# fixture-dir pattern: per-case directories under fixtures/ carry an input
# transcript and expected outputs; this runner invokes the detector script
# and asserts exit code and stdout content.
#
# Case directory contract:
#   input.jsonl          - transcript JSONL fed as the default argument to
#                           the script (may be ABSENT for cases that test
#                           missing-file handling; see "args" below)
#   args                 - optional; if present, its single line is
#                           word-split and used as the full argument list
#                           to the script INSTEAD of the default
#                           "<case_dir>/input.jsonl" argument. Any literal
#                           token {{INPUT}} in the resulting argument list
#                           is substituted with "<case_dir>/input.jsonl",
#                           so a case can combine its own input.jsonl with
#                           extra arguments (e.g. an explicit N).
#   expect_exit          - required; exact integer exit code
#   expect_stdout_grep   - required; newline list, every pattern must be
#                           found in stdout via grep -qF. A 0-byte (empty)
#                           file means no stdout assertions for this case.
#
# stderr is captured by the script under test but NOT asserted by this
# runner (a later fixture will assert stderr warning content separately).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_UNDER_TEST="$SCRIPT_DIR/../first-action-audit.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

pass=0
fail=0

run_case() {
  local case_dir="$1"
  local name
  name="$(basename "$case_dir")"

  local input_file="$case_dir/input.jsonl"
  local args_file="$case_dir/args"
  local expect_exit_file="$case_dir/expect_exit"
  local expect_stdout_grep_file="$case_dir/expect_stdout_grep"

  local ok=1
  local reasons=()

  if [[ ! -f "$expect_exit_file" ]]; then
    ok=0
    reasons+=("missing required file: expect_exit")
  fi
  if [[ ! -f "$expect_stdout_grep_file" ]]; then
    ok=0
    reasons+=("missing required file: expect_stdout_grep")
  fi

  if [[ "$ok" -eq 0 ]]; then
    echo "FAIL: $name"
    for reason in "${reasons[@]}"; do
      echo "  - $reason"
    done
    fail=$((fail + 1))
    return
  fi

  if [[ ! -f "$SCRIPT_UNDER_TEST" ]]; then
    ok=0
    reasons+=("script missing: $SCRIPT_UNDER_TEST")
  fi

  local -a invoke_args
  if [[ -f "$args_file" ]]; then
    local args_line
    args_line="$(head -n 1 "$args_file")"
    # Unquoted on purpose (word-split into args); this also globs -- a literal * or ? in an args file would be pathname-expanded against CWD, not passed literally.
    # shellcheck disable=SC2206
    invoke_args=($args_line)
    # Substitute the {{INPUT}} token (if present) with this case's own
    # input.jsonl, so a case can pair its input with extra arguments.
    local i
    for i in "${!invoke_args[@]}"; do
      if [[ "${invoke_args[$i]}" == "{{INPUT}}" ]]; then
        invoke_args[$i]="$input_file"
      fi
    done
  else
    invoke_args=("$input_file")
  fi

  local actual_stdout actual_exit
  actual_stdout="$(bash "$SCRIPT_UNDER_TEST" "${invoke_args[@]}" 2>/dev/null)"
  actual_exit=$?

  local expect_exit
  expect_exit="$(tr -d '[:space:]' <"$expect_exit_file")"
  if [[ "$actual_exit" -ne "$expect_exit" ]]; then
    ok=0
    reasons+=("exit code mismatch: expected $expect_exit got $actual_exit")
  fi

  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    if ! grep -qF "$pattern" <<<"$actual_stdout"; then
      ok=0
      reasons+=("stdout missing expected substring: $pattern (got [$actual_stdout])")
    fi
  done <"$expect_stdout_grep_file"

  if [[ "$ok" -eq 1 ]]; then
    echo "PASS: $name"
    pass=$((pass + 1))
  else
    echo "FAIL: $name"
    for reason in "${reasons[@]}"; do
      echo "  - $reason"
    done
    fail=$((fail + 1))
  fi
}

for case_dir in "$FIXTURES_DIR"/*/; do
  run_case "${case_dir%/}"
done

echo ""
echo "Total: $((pass + fail))  Pass: $pass  Fail: $fail"

if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
exit 0
