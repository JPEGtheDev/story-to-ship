#!/usr/bin/env bash
# Hermetic test harness for hooks/stop-verdict-log.sh.
#
# For each case directory under fixtures/, sets the case's env (always pointing
# B2_GATE_LOG at a fresh temp file so cases never interfere with each other),
# pipes the case's input into the hook, and asserts stdout plus log-file behavior
# match the case's expectations. Prints PASS/FAIL per case and a total; exits
# nonzero if any case fails.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../stop-verdict-log.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

pass=0
fail=0

run_case() {
  local case_dir="$1"
  local name
  name="$(basename "$case_dir")"

  local input_file="$case_dir/input"
  local env_file="$case_dir/env"
  local expected_stdout_file="$case_dir/expected_stdout"
  local expect_log_file="$case_dir/expect_log"
  local expect_log_grep_file="$case_dir/expect_log_grep"

  local expected_stdout expect_log
  expected_stdout="$(cat "$expected_stdout_file")"
  expect_log="$(cat "$expect_log_file")"

  local tmp_log
  tmp_log="$(mktemp -u "${TMPDIR:-/tmp}/b2-verdict-log.XXXXXX.jsonl")"
  # Do not pre-create the log file: "off" cases must assert it was never created.

  local actual_stdout actual_exit
  actual_stdout="$(
    unset B2_GATE
    export B2_GATE_LOG="$tmp_log"
    unset CLAUDE_PROJECT_DIR
    if [[ -f "$env_file" ]]; then
      # shellcheck disable=SC1090
      source "$env_file"
    fi
    bash "$HOOK" <"$input_file"
  )"
  actual_exit=$?

  local ok=1
  local reasons=()

  if [[ "$actual_stdout" != "$expected_stdout" ]]; then
    ok=0
    reasons+=("stdout mismatch: expected [$expected_stdout] got [$actual_stdout]")
  fi

  if [[ "$actual_exit" -ne 0 ]]; then
    ok=0
    reasons+=("exit code mismatch: expected 0 got $actual_exit")
  fi

  case "$expect_log" in
    no)
      if [[ -e "$tmp_log" ]]; then
        ok=0
        reasons+=("expected no log file, but $tmp_log was created")
      fi
      ;;
    yes)
      if [[ ! -e "$tmp_log" ]]; then
        ok=0
        reasons+=("expected a log line, but $tmp_log was not created")
      else
        local line_count
        line_count="$(wc -l <"$tmp_log" | tr -d ' ')"
        if [[ "$line_count" -ne 1 ]]; then
          ok=0
          reasons+=("expected exactly 1 log line, got $line_count")
        fi
        if [[ -f "$expect_log_grep_file" ]]; then
          while IFS= read -r pattern; do
            [[ -z "$pattern" ]] && continue
            if ! grep -qF "$pattern" "$tmp_log"; then
              ok=0
              reasons+=("log line missing expected substring: $pattern")
            fi
          done <"$expect_log_grep_file"
        fi
      fi
      ;;
    *)
      ok=0
      reasons+=("unknown expect_log value: $expect_log")
      ;;
  esac

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

  rm -f "$tmp_log"
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
