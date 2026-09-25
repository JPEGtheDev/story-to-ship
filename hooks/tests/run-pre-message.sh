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
#   state_dir_missing        - if present (contents ignored), the hook is
#                              pointed at a path inside the per-case temp
#                              dir that does not exist, instead of the temp
#                              dir itself, so it still gets swept by the
#                              unconditional cleanup at the end of the case
#   loaded_file_missing      - if present (contents ignored), the hook runs
#                              from a copy of its script and its full .md
#                              file in the per-case temp dir, with no
#                              -loaded .md file beside them
#   state_via_project_dir    - if present (contents ignored), the hook runs
#                              with CLAUDE_PROJECT_DIR set to a "project"
#                              dir inside the per-case temp dir and with
#                              BOOTSTRAP_GATE_STATE_DIR unset, so it
#                              resolves its state dir as <project>/.claude,
#                              the path real sessions use; that dir is
#                              created and pre_flags are touched there.
#                              state_dir_missing is ignored in such a case
#   expect_stdout_grep       - newline list; every line must appear
#                              (fixed-string) in the additionalContext value
#   expect_stdout_not_grep   - newline list; no line may appear in the
#                              additionalContext value
#
# Each case gets a fresh temp dir; BOOTSTRAP_GATE_STATE_DIR is exported as
# that temp dir for the hook run (or, for a state_dir_missing case, a
# non-existent path inside it) and CLAUDE_PROJECT_DIR is unset, except in a
# state_via_project_dir case (see above). The temp dir is removed
# unconditionally at the end of the case.

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
  local state_dir_missing_file="$case_dir/state_dir_missing"
  local loaded_file_missing_file="$case_dir/loaded_file_missing"
  local state_via_project_dir_file="$case_dir/state_via_project_dir"
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

  if [[ -z "$state_dir" ]]; then
    echo "FAIL: $name -- mktemp failed"
    fail=$((fail + 1))
    return
  fi

  local project_dir="$state_dir/project"
  local flags_dir="$state_dir"
  if [[ -f "$state_via_project_dir_file" ]]; then
    flags_dir="$project_dir/.claude"
    if ! mkdir -p "$flags_dir"; then
      echo "FAIL: $name -- could not create $flags_dir"
      fail=$((fail + 1))
      rm -rf "$state_dir"
      return
    fi
  fi

  if [[ -f "$pre_flags_file" ]]; then
    while IFS= read -r flag_name; do
      [[ -z "$flag_name" ]] && continue
      : >"$flags_dir/$flag_name"
    done <"$pre_flags_file"
  fi

  local hook_state_dir="$state_dir"
  if [[ -f "$state_dir_missing_file" ]]; then
    hook_state_dir="$state_dir/absent"
  fi

  if [[ -f "$loaded_file_missing_file" ]]; then
    local hook_copy_dir="$state_dir/hook-copy"
    if ! mkdir "$hook_copy_dir" || ! cp "$hook_bin" "${hook_bin%.sh}.md" "$hook_copy_dir/"; then
      echo "FAIL: $name -- could not copy the hook into $hook_copy_dir"
      fail=$((fail + 1))
      rm -rf "$state_dir"
      return
    fi
    hook_bin="$hook_copy_dir/$(basename "$hook_bin")"
  fi

  local actual_stdout actual_exit
  actual_stdout="$(
    if [[ -f "$state_via_project_dir_file" ]]; then
      unset BOOTSTRAP_GATE_STATE_DIR
      export CLAUDE_PROJECT_DIR="$project_dir"
    else
      export BOOTSTRAP_GATE_STATE_DIR="$hook_state_dir"
      unset CLAUDE_PROJECT_DIR
    fi
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
