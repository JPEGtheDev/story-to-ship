#!/usr/bin/env bash
# Hermetic test harness for the dispatch-output check hook:
#   hooks/dispatch-output-check.sh  (PostToolUse Agent + SubagentStop)
#
# Sibling to hooks/tests/run-workflow-model-guard.sh, same case-directory
# style. Unlike that stateless hook, this one joins two events by agent id
# and writes a record file, so every case gets its own mktemp -d state dir
# (DISPATCH_CHECK_STATE_DIR) and the runner asserts the record file as well
# as stdout, stderr and the exit code.
#
# Case directory contract (every file optional except one of payloads or
# concurrent):
#   payloads               - names of files under fixtures-dispatch-output-check/
#                             payloads/, one per line, fed to the hook in order,
#                             one hook run per payload.
#   concurrent             - N: run N pairs (async PostToolUse + SubagentStop,
#                             agent id rewritten per pair) as background jobs.
#   env                    - KEY=VALUE lines exported for every hook run.
#   setup                  - bash snippet sourced before the runs; $STATE is
#                             the state dir.
#   state_subdir           - use $tmp/<value> (not yet created) as the state dir.
#   no_jq                  - when present, run with a PATH that lacks jq.
#   expect_exit            - exact exit code of every run (default 0).
#   expect_stdout_empty    - when present, stdout of every run must be empty.
#   expect_stderr_nonempty - when present, some run must print to stderr.
#   expect_records         - exact number of lines in the record file (a missing
#                             file counts as 0).
#   expect_record_jq       - one jq -e filter per line, applied to the array of
#                             all records (jq -s).
#   expect_record_grep     - fixed substrings that must appear in the record file.
#   expect_parked          - agent ids whose parked file must exist.
#   expect_parked_grep     - lines "agent id:substring"; the parked file must
#                             contain the substring.
#   expect_absent          - parked file names that must not exist.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../dispatch-output-check.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures-dispatch-output-check"
PAYLOADS="$FIXTURES_DIR/payloads"
BASH_BIN="$(command -v bash)"
JQ_BIN="$(command -v jq)"

pass=0
fail=0

# Build a bin dir of symlinks to common tools, without jq.
make_nojq_bin() {
  local bindir="$1" tool path
  mkdir -p "$bindir"
  for tool in sed awk tr date mkdir cat rm find touch head tail grep cut sort \
    mv dirname basename wc mktemp ls env uniq tee od xargs cp ln chmod stat; do
    path="$(command -v "$tool" 2>/dev/null)"
    [[ -n "$path" && -x "$path" ]] && ln -sf "$path" "$bindir/$tool"
  done
}

# Runs the hook on one payload file; uses the per-case globals tmp, STATE,
# nojq_bin and case_env.
run_hook() {
  local payload="$1"
  (
    export DISPATCH_CHECK_STATE_DIR="$STATE"
    export DISPATCH_CHECK_AGENTS_DIR="$tmp/agents"
    export CLAUDE_PROJECT_DIR="$tmp/project"
    unset CLAUDE_PLUGIN_ROOT
    if [[ -n "$nojq_bin" ]]; then
      export PATH="$nojq_bin"
    fi
    local line
    for line in "${case_env[@]}"; do
      export "${line?}"
    done
    "$BASH_BIN" "$HOOK" <"$payload"
  )
}

run_case() {
  local case_dir="$1"
  local name
  name="$(basename "$case_dir")"

  local ok=1
  local reasons=()

  if [[ ! -f "$HOOK" ]]; then
    echo "FAIL: $name"
    echo "  - hook script not found at $HOOK"
    fail=$((fail + 1))
    return
  fi

  tmp="$(mktemp -d)"
  mkdir -p "$tmp/agents" "$tmp/project" "$tmp/out"
  STATE="$tmp/state"
  if [[ -f "$case_dir/state_subdir" ]]; then
    STATE="$tmp/$(tr -d '[:space:]' <"$case_dir/state_subdir")"
  else
    mkdir -p "$STATE"
  fi
  nojq_bin=""
  if [[ -f "$case_dir/no_jq" ]]; then
    nojq_bin="$tmp/bin"
    make_nojq_bin "$nojq_bin"
  fi
  case_env=()
  if [[ -f "$case_dir/env" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && case_env+=("$line")
    done <"$case_dir/env"
  fi
  if [[ -f "$case_dir/setup" ]]; then
    # shellcheck disable=SC1090,SC1091
    source "$case_dir/setup"
  fi

  local expect_exit=0
  [[ -f "$case_dir/expect_exit" ]] && expect_exit="$(tr -d '[:space:]' <"$case_dir/expect_exit")"

  local n=0 stdout_all="" stderr_all="" rc
  if [[ -f "$case_dir/concurrent" ]]; then
    local count i kind id
    count="$(tr -d '[:space:]' <"$case_dir/concurrent")"
    for ((i = 1; i <= count; i++)); do
      id="$(printf 'cccccccc%09d' "$i")"
      # shellcheck disable=SC2016
      "$JQ_BIN" -c --arg id "$id" '.tool_response.agentId=$id' "$PAYLOADS/async-post.json" >"$tmp/out/p$i.json"
      # shellcheck disable=SC2016
      "$JQ_BIN" -c --arg id "$id" '.agent_id=$id' "$PAYLOADS/stop.json" >"$tmp/out/s$i.json"
      (
        run_hook "$tmp/out/p$i.json" >"$tmp/out/p$i.out" 2>"$tmp/out/p$i.err"
        echo $? >"$tmp/out/p$i.rc"
        run_hook "$tmp/out/s$i.json" >"$tmp/out/s$i.out" 2>"$tmp/out/s$i.err"
        echo $? >"$tmp/out/s$i.rc"
      ) &
    done
    wait
    for ((i = 1; i <= count; i++)); do
      for kind in p s; do
        n=$((n + 1))
        stdout_all+="$(cat "$tmp/out/$kind$i.out")"
        stderr_all+="$(cat "$tmp/out/$kind$i.err")"
        rc="$(cat "$tmp/out/$kind$i.rc")"
        if [[ "$rc" -ne "$expect_exit" ]]; then
          ok=0
          reasons+=("exit code mismatch on $kind$i: expected $expect_exit got $rc")
        fi
      done
    done
  else
    local payload
    while IFS= read -r payload; do
      [[ -z "$payload" ]] && continue
      n=$((n + 1))
      stdout_all+="$(run_hook "$PAYLOADS/$payload" 2>"$tmp/out/err$n")"
      rc=$?
      stderr_all+="$(cat "$tmp/out/err$n")"
      if [[ "$rc" -ne "$expect_exit" ]]; then
        ok=0
        reasons+=("exit code mismatch on run $n ($payload): expected $expect_exit got $rc")
      fi
    done <"$case_dir/payloads"
  fi

  if [[ -f "$case_dir/expect_stdout_empty" && -n "$stdout_all" ]]; then
    ok=0
    reasons+=("stdout not empty: [$stdout_all]")
  fi
  if [[ -f "$case_dir/expect_stderr_nonempty" && -z "$stderr_all" ]]; then
    ok=0
    reasons+=("stderr empty, expected a message")
  fi

  local records="$STATE/dispatch-check-records.jsonl"
  local actual_records=0
  [[ -f "$records" ]] && actual_records="$(wc -l <"$records" | tr -d '[:space:]')"
  if [[ -f "$case_dir/expect_records" ]]; then
    local want
    want="$(tr -d '[:space:]' <"$case_dir/expect_records")"
    if [[ "$actual_records" -ne "$want" ]]; then
      ok=0
      reasons+=("record count mismatch: expected $want got $actual_records")
    fi
  fi

  if [[ -f "$case_dir/expect_record_jq" ]]; then
    local filter
    while IFS= read -r filter; do
      [[ -z "$filter" ]] && continue
      if [[ ! -f "$records" ]] || ! "$JQ_BIN" -s -e "$filter" "$records" >/dev/null 2>&1; then
        ok=0
        reasons+=("record check failed: $filter")
      fi
    done <"$case_dir/expect_record_jq"
  fi

  if [[ -f "$case_dir/expect_record_grep" ]]; then
    local pattern
    while IFS= read -r pattern; do
      [[ -z "$pattern" ]] && continue
      if [[ ! -f "$records" ]] || ! grep -qF -- "$pattern" "$records"; then
        ok=0
        reasons+=("record file missing substring: $pattern")
      fi
    done <"$case_dir/expect_record_grep"
  fi

  local pending="$STATE/.dispatch-check-pending"
  if [[ -f "$case_dir/expect_parked" ]]; then
    local agent
    while IFS= read -r agent; do
      [[ -z "$agent" ]] && continue
      if [[ ! -f "$pending/$agent" ]]; then
        ok=0
        reasons+=("parked file missing: $agent")
      fi
    done <"$case_dir/expect_parked"
  fi
  if [[ -f "$case_dir/expect_parked_grep" ]]; then
    local entry
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      if [[ ! -f "$pending/${entry%%:*}" ]] || ! grep -qF -- "${entry#*:}" "$pending/${entry%%:*}"; then
        ok=0
        reasons+=("parked file ${entry%%:*} missing substring ${entry#*:}")
      fi
    done <"$case_dir/expect_parked_grep"
  fi
  if [[ -f "$case_dir/expect_absent" ]]; then
    local gone
    while IFS= read -r gone; do
      [[ -z "$gone" ]] && continue
      if [[ -e "$pending/$gone" ]]; then
        ok=0
        reasons+=("file should have been swept: $gone")
      fi
    done <"$case_dir/expect_absent"
  fi

  rm -rf "$tmp"

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
  [[ "$(basename "$case_dir")" == "payloads" ]] && continue
  run_case "${case_dir%/}"
done

echo ""
echo "Total: $((pass + fail))  Pass: $pass  Fail: $fail"

if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
exit 0
