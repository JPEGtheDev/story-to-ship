#!/usr/bin/env bash
# Hermetic test harness for the per-prompt UserPromptSubmit hook scripts:
#   hooks/pre-message-gates.sh
#   hooks/pre-message.sh
#
# Sibling to hooks/tests/run-bootstrap-gate.sh, following the same
# fixture-dir pattern: per-case directories under fixtures-pre-message/
# carry hook/input/expected files; this runner pipes input into the right
# hook and asserts stdout shape and additionalContext content.
#
# Case directory contract (all files optional except "hook" and "input"):
#   hook                     - "gates" -> run hooks/pre-message-gates.sh
#                              "message" -> run hooks/pre-message.sh
#                              (required)
#   input                    - stdin JSON fed to the hook; may be an empty
#                              file (required)
#   pre_flags                - newline list of flag file NAMES (e.g.
#                              .bootstrap-pending-sess-1); each is touched
#                              (created empty) in the state dir BEFORE the
#                              hook runs
#   expect_stdout_grep       - newline list; every line must appear
#                              (fixed-string) in the additionalContext value
#   expect_stdout_not_grep   - newline list; no line may appear in the
#                              additionalContext value
#
# Each case gets a fresh temp dir exported as BOOTSTRAP_GATE_STATE_DIR for
# the hook run, removed unconditionally at the end of the case.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATES_HOOK="$SCRIPT_DIR/../pre-message-gates.sh"
MESSAGE_HOOK="$SCRIPT_DIR/../pre-message.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures-pre-message"

pass=0
fail=0

run_case() {
  local case_dir="$1"
  local name
  name="$(basename "$case_dir")"

  local hook_file="$case_dir/hook"
  local input_file="$case_dir/input"
  local pre_flags_file="$case_dir/pre_flags"
  local expect_stdout_grep_file="$case_dir/expect_stdout_grep"
  local expect_stdout_not_grep_file="$case_dir/expect_stdout_not_grep"

  if [[ ! -f "$hook_file" ]]; then
    echo "FAIL: $name -- missing required 'hook' file"
    fail=$((fail + 1))
    return
  fi
  if [[ ! -f "$input_file" ]]; then
    echo "FAIL: $name -- missing required 'input' file"
    fail=$((fail + 1))
    return
  fi

  local hook_kind
  hook_kind="$(tr -d '[:space:]' <"$hook_file")"

  local hook_bin
  case "$hook_kind" in
    gates) hook_bin="$GATES_HOOK" ;;
    message) hook_bin="$MESSAGE_HOOK" ;;
    *)
      echo "FAIL: $name -- unknown hook kind: $hook_kind"
      fail=$((fail + 1))
      return
      ;;
  esac

  local state_dir
  state_dir="$(mktemp -d "${TMPDIR:-/tmp}/pre-message-test.XXXXXX")"

  if [[ -f "$pre_flags_file" ]]; then
    while IFS= read -r flag_name; do
      [[ -z "$flag_name" ]] && continue
      : >"$state_dir/$flag_name"
    done <"$pre_flags_file"
  fi

  local actual_stdout actual_exit
  actual_stdout="$(
    export BOOTSTRAP_GATE_STATE_DIR="$state_dir"
    bash "$hook_bin" <"$input_file"
  )"
  actual_exit=$?

  local ok=1
  local reason=""

  if [[ "$actual_exit" -ne 0 ]]; then
    ok=0
    reason="exit code mismatch: expected 0 got $actual_exit"
  fi

  if [[ "$ok" -eq 1 ]] && ! jq -e '.hookSpecificOutput.additionalContext' <<<"$actual_stdout" >/dev/null 2>&1; then
    ok=0
    reason="stdout did not parse as JSON with .hookSpecificOutput.additionalContext (got [$actual_stdout])"
  fi

  local additional_context=""
  if [[ "$ok" -eq 1 ]]; then
    additional_context="$(jq -r '.hookSpecificOutput.additionalContext' <<<"$actual_stdout")"
  fi

  if [[ "$ok" -eq 1 && -f "$expect_stdout_grep_file" ]]; then
    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue
      if ! grep -qF "$pattern" <<<"$additional_context"; then
        ok=0
        reason="additionalContext missing expected pattern: $pattern"
        break
      fi
    done <"$expect_stdout_grep_file"
  fi

  if [[ "$ok" -eq 1 && -f "$expect_stdout_not_grep_file" ]]; then
    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue
      if grep -qF "$pattern" <<<"$additional_context"; then
        ok=0
        reason="additionalContext contains forbidden pattern: $pattern"
        break
      fi
    done <"$expect_stdout_not_grep_file"
  fi

  if [[ "$ok" -eq 1 ]]; then
    echo "PASS: $name"
    pass=$((pass + 1))
  else
    echo "FAIL: $name -- $reason"
    fail=$((fail + 1))
  fi

  rm -rf "$state_dir"
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
