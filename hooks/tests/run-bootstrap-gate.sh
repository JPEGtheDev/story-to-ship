#!/usr/bin/env bash
# Hermetic test harness for the bootstrap-gate hook family:
#   hooks/bootstrap-gate-pre.sh   (PreToolUse, matcher *)
#   hooks/bootstrap-gate-post.sh  (PostToolUse, matcher Skill)
#   hooks/session-start.sh        (SessionStart, extended to stamp a flag file)
#
# Sibling to hooks/tests/run.sh, following the same fixture-dir pattern:
# per-case directories under fixtures-bootstrap-gate/ carry env/input/expected
# files; this runner sources env, pipes input into the right hook, and asserts
# stdout shape, exit code, log-file effects, and flag-file effects.
#
# Case directory contract (all files optional except "hook" and "input"):
#   hook                    - "pre" | "post" | "session-start" (required)
#   env                     - sourced before invocation (e.g. sets
#                             BOOTSTRAP_GATE_MODE). Never sets
#                             BOOTSTRAP_GATE_STATE_DIR -- the runner always
#                             points that at a fresh per-case temp dir.
#   input                   - stdin JSON fed to the hook (required)
#   pre_flag_sessions       - newline list of session_ids; a flag file is
#                             created for each BEFORE the hook runs
#   pre_dirs                - newline list of directory path templates;
#                             each is mkdir -p'd BEFORE the hook runs. Used
#                             to stage adversarial fixtures (e.g. an
#                             intermediate directory a hostile session_id's
#                             ".." segments must traverse through). Templates
#                             may use the tokens STATE_DIR and
#                             STATE_DIR_PARENT (see token note below).
#   pre_files               - newline list of file path templates; each is
#                             touched (created empty) BEFORE the hook runs.
#                             Same token support as pre_dirs -- used to plant
#                             a traversal-target "canary" file.
#   expect_exit             - exact exit code (default 0)
#   expect_stdout           - exact-match stdout (used when deterministic,
#                             e.g. empty string for a plain allow)
#   expect_stdout_grep      - newline list; every pattern must appear in stdout
#   expect_stdout_not_grep  - newline list; no pattern may appear in stdout
#   expect_log_lines        - exact required line count in the gate log
#                             (0 means the log file must be absent or empty)
#   expect_log_min_lines    - minimum required line count in the gate log
#   expect_log_grep         - newline list; every pattern must appear
#                             somewhere in the gate log file
#   expect_flag_exists      - newline list of session_ids whose flag file
#                             must exist AFTER the hook runs
#   expect_flag_absent      - newline list of session_ids whose flag file
#                             must NOT exist AFTER the hook runs
#   expect_file_exists      - newline list of file path templates that must
#                             exist AFTER the hook runs. Same token support
#                             as pre_dirs/pre_files -- used to assert a
#                             traversal-target "canary" file survived a hook
#                             invocation that carried a hostile session_id.
#
# State dir layout matches the bootstrap-gate contract:
#   $BOOTSTRAP_GATE_STATE_DIR/.bootstrap-pending-<session_id>
#   $BOOTSTRAP_GATE_STATE_DIR/.bootstrap-gate-log.jsonl
#
# Sandbox layout: each case gets a fresh outer sandbox dir, with
# BOOTSTRAP_GATE_STATE_DIR pointed at a "state" subdirectory one level
# inside it. This leaves room, ABOVE the state dir but still INSIDE the
# per-case sandbox, to stage adversarial fixtures whose hostile session_id
# is designed to traverse out of the state dir (e.g. "a/../../CANARY") --
# the traversal target lands in the sandbox, never a shared path, and
# `rm -rf "$sandbox"` cleans it up unconditionally at the end of the case.
# pre_dirs/pre_files/expect_file_exists templates may reference:
#   STATE_DIR         - the state subdirectory itself
#   STATE_DIR_PARENT  - the sandbox root (one level above STATE_DIR)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRE_HOOK="$SCRIPT_DIR/../bootstrap-gate-pre.sh"
POST_HOOK="$SCRIPT_DIR/../bootstrap-gate-post.sh"
SESSION_START_HOOK="$SCRIPT_DIR/../session-start.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures-bootstrap-gate"

pass=0
fail=0

flag_path() {
  local state_dir="$1"
  local session_id="$2"
  printf '%s/.bootstrap-pending-%s' "$state_dir" "$session_id"
}

log_path() {
  local state_dir="$1"
  printf '%s/.bootstrap-gate-log.jsonl' "$state_dir"
}

# Expands the STATE_DIR / STATE_DIR_PARENT tokens in a pre_dirs/pre_files/
# expect_file_exists template into a concrete path. STATE_DIR_PARENT must be
# substituted before STATE_DIR since it contains STATE_DIR as a substring.
resolve_token_path() {
  local state_dir="$1"
  local template="$2"
  local parent
  parent="$(dirname "$state_dir")"
  template="${template//STATE_DIR_PARENT/$parent}"
  template="${template//STATE_DIR/$state_dir}"
  printf '%s' "$template"
}

run_case() {
  local case_dir="$1"
  local name
  name="$(basename "$case_dir")"

  local hook_file="$case_dir/hook"
  local env_file="$case_dir/env"
  local input_file="$case_dir/input"
  local pre_flag_sessions_file="$case_dir/pre_flag_sessions"
  local pre_dirs_file="$case_dir/pre_dirs"
  local pre_files_file="$case_dir/pre_files"
  local expect_exit_file="$case_dir/expect_exit"
  local expect_stdout_file="$case_dir/expect_stdout"
  local expect_stdout_grep_file="$case_dir/expect_stdout_grep"
  local expect_stdout_not_grep_file="$case_dir/expect_stdout_not_grep"
  local expect_log_lines_file="$case_dir/expect_log_lines"
  local expect_log_min_lines_file="$case_dir/expect_log_min_lines"
  local expect_log_grep_file="$case_dir/expect_log_grep"
  local expect_flag_exists_file="$case_dir/expect_flag_exists"
  local expect_flag_absent_file="$case_dir/expect_flag_absent"
  local expect_file_exists_file="$case_dir/expect_file_exists"

  if [[ ! -f "$hook_file" ]]; then
    echo "FAIL: $name"
    echo "  - missing required 'hook' file"
    fail=$((fail + 1))
    return
  fi
  if [[ ! -f "$input_file" ]]; then
    echo "FAIL: $name"
    echo "  - missing required 'input' file"
    fail=$((fail + 1))
    return
  fi

  local hook_kind
  hook_kind="$(cat "$hook_file" | tr -d '[:space:]')"

  local hook_bin
  case "$hook_kind" in
    pre) hook_bin="$PRE_HOOK" ;;
    post) hook_bin="$POST_HOOK" ;;
    session-start) hook_bin="$SESSION_START_HOOK" ;;
    *)
      echo "FAIL: $name"
      echo "  - unknown hook kind: $hook_kind"
      fail=$((fail + 1))
      return
      ;;
  esac

  local sandbox
  sandbox="$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-gate-test.XXXXXX")"
  local state_dir="$sandbox/state"
  mkdir -p "$state_dir"

  # Pre-seed flag files, if requested, before the hook runs.
  if [[ -f "$pre_flag_sessions_file" ]]; then
    while IFS= read -r sid; do
      [[ -z "$sid" ]] && continue
      : >"$(flag_path "$state_dir" "$sid")"
    done <"$pre_flag_sessions_file"
  fi

  # Pre-create directories, if requested (see pre_dirs in the contract
  # comment above).
  if [[ -f "$pre_dirs_file" ]]; then
    while IFS= read -r template; do
      [[ -z "$template" ]] && continue
      mkdir -p "$(resolve_token_path "$state_dir" "$template")"
    done <"$pre_dirs_file"
  fi

  # Pre-create files, if requested (see pre_files in the contract comment
  # above).
  if [[ -f "$pre_files_file" ]]; then
    while IFS= read -r template; do
      [[ -z "$template" ]] && continue
      : >"$(resolve_token_path "$state_dir" "$template")"
    done <"$pre_files_file"
  fi

  local expect_exit=0
  [[ -f "$expect_exit_file" ]] && expect_exit="$(cat "$expect_exit_file" | tr -d '[:space:]')"

  local actual_stdout actual_exit
  actual_stdout="$(
    export BOOTSTRAP_GATE_STATE_DIR="$state_dir"
    unset CLAUDE_PROJECT_DIR
    if [[ -f "$env_file" ]]; then
      set -a
      # shellcheck disable=SC1090
      source "$env_file"
      set +a
    fi
    bash "$hook_bin" <"$input_file"
  )"
  actual_exit=$?

  local ok=1
  local reasons=()

  if [[ "$actual_exit" -ne "$expect_exit" ]]; then
    ok=0
    reasons+=("exit code mismatch: expected $expect_exit got $actual_exit")
  fi

  if [[ -f "$expect_stdout_file" ]]; then
    local expected_stdout
    expected_stdout="$(cat "$expect_stdout_file")"
    if [[ "$actual_stdout" != "$expected_stdout" ]]; then
      ok=0
      reasons+=("stdout mismatch: expected [$expected_stdout] got [$actual_stdout]")
    fi
  fi

  if [[ -f "$expect_stdout_grep_file" ]]; then
    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue
      if ! grep -qF "$pattern" <<<"$actual_stdout"; then
        ok=0
        reasons+=("stdout missing expected substring: $pattern (got [$actual_stdout])")
      fi
    done <"$expect_stdout_grep_file"
  fi

  if [[ -f "$expect_stdout_not_grep_file" ]]; then
    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue
      if grep -qF "$pattern" <<<"$actual_stdout"; then
        ok=0
        reasons+=("stdout contains forbidden substring: $pattern (got [$actual_stdout])")
      fi
    done <"$expect_stdout_not_grep_file"
  fi

  local log_file
  log_file="$(log_path "$state_dir")"
  local log_line_count=0
  if [[ -f "$log_file" ]]; then
    log_line_count="$(wc -l <"$log_file" | tr -d ' ')"
  fi

  if [[ -f "$expect_log_lines_file" ]]; then
    local expected_lines
    expected_lines="$(cat "$expect_log_lines_file" | tr -d '[:space:]')"
    if [[ "$log_line_count" -ne "$expected_lines" ]]; then
      ok=0
      reasons+=("log line count mismatch: expected $expected_lines got $log_line_count")
    fi
  fi

  if [[ -f "$expect_log_min_lines_file" ]]; then
    local expected_min
    expected_min="$(cat "$expect_log_min_lines_file" | tr -d '[:space:]')"
    if [[ "$log_line_count" -lt "$expected_min" ]]; then
      ok=0
      reasons+=("log line count too low: expected >= $expected_min got $log_line_count")
    fi
  fi

  if [[ -f "$expect_log_grep_file" ]]; then
    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue
      if [[ ! -f "$log_file" ]] || ! grep -qF "$pattern" "$log_file"; then
        ok=0
        reasons+=("log missing expected substring: $pattern")
      fi
    done <"$expect_log_grep_file"
  fi

  # If the log file exists and has content, every line must parse as JSON.
  if [[ -f "$log_file" && "$log_line_count" -gt 0 ]] && command -v jq &>/dev/null; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if ! printf '%s' "$line" | jq empty 2>/dev/null; then
        ok=0
        reasons+=("log line is not valid JSON: $line")
      fi
    done <"$log_file"
  fi

  if [[ -f "$expect_flag_exists_file" ]]; then
    while IFS= read -r sid; do
      [[ -z "$sid" ]] && continue
      if [[ ! -e "$(flag_path "$state_dir" "$sid")" ]]; then
        ok=0
        reasons+=("expected flag file to exist for session: $sid")
      fi
    done <"$expect_flag_exists_file"
  fi

  if [[ -f "$expect_flag_absent_file" ]]; then
    while IFS= read -r sid; do
      [[ -z "$sid" ]] && continue
      if [[ -e "$(flag_path "$state_dir" "$sid")" ]]; then
        ok=0
        reasons+=("expected flag file to be absent for session: $sid")
      fi
    done <"$expect_flag_absent_file"
  fi

  if [[ -f "$expect_file_exists_file" ]]; then
    while IFS= read -r template; do
      [[ -z "$template" ]] && continue
      local resolved
      resolved="$(resolve_token_path "$state_dir" "$template")"
      if [[ ! -f "$resolved" ]]; then
        ok=0
        reasons+=("expected file to exist: $resolved")
      fi
    done <"$expect_file_exists_file"
  fi

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

  rm -rf "$sandbox"
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
