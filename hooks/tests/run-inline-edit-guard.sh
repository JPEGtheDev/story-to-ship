#!/usr/bin/env bash
# Hermetic test harness for the inline-edit guard hook:
#   hooks/inline-edit-guard.sh  (PreToolUse, matcher Edit|Write)
#
# MISSING-HOOK DIAGNOSTIC: if hooks/inline-edit-guard.sh does not exist,
# every case in this suite fails with a distinct "hook script not found"
# failure reason (see below), deliberately distinct from a fixture/assertion
# failure so a reader can tell "hook not built" apart from "hook built
# wrong" at a glance.
#
# Sibling to hooks/tests/run-shell-write-guard.sh, following the same
# fixture-dir pattern, but this hook's verdict also depends on a per-session
# ledger of previously counted edits, so each case gets its OWN throwaway
# git repo, state dir, and outside-of-any-repo dir (built fresh per case,
# not once for the whole suite) plus an optional pre-seeded ledger.
#
# Case directory contract (all files optional except "input"):
#   input               - stdin JSON fed to the hook (required). May contain
#                          the literal tokens __REPO__ and __OUTSIDE__,
#                          substituted (via sed) with the case's live
#                          temp-repo / outside-dir realpaths before the
#                          hook runs.
#   repo/               - a directory tree copied into the temp repo before
#                          `git add -A && git commit` (so its files are
#                          tracked at commit time).
#   symlinks            - one "<link-relative-path> <target-relative-path>"
#                          pair per line; each is created inside the temp
#                          repo with `ln -s <target> <link>` before the
#                          commit. A link's path must NOT already exist
#                          under repo/ (the runner copies repo/ before
#                          creating symlinks, so `ln -s` would collide); a
#                          case needing "a prose path that is really a
#                          symlink to code" ships the code file under repo/
#                          and lists the prose path only in symlinks, never
#                          as a repo/ file too.
#   pre_ledger          - JSONL lines (may contain __REPO__ / __OUTSIDE__
#                          tokens, substituted the same way as input)
#                          written to THIS session's ledger file before the
#                          hook runs, simulating prior counted edits in the
#                          same session.
#   pre_ledger_other    - JSONL lines, substituted exactly like pre_ledger,
#                          written to a DIFFERENT session's ledger file
#                          (session id "sess-other") in the same state dir
#                          -- simulates another session's history to prove
#                          the caps are per-session, not shared.
#   env                 - "KEY=VALUE" lines exported for this case's hook
#                          invocation only (e.g. cap overrides).
#   expect_exit         - exact exit code (default 0).
#   expect_stdout       - exact-match stdout. An empty (0-byte) file means
#                          "expect empty stdout" (allow).
#   expect_stdout_grep  - newline list; every line must appear in stdout
#                          (grep -F). Used for deny cases.
#   expect_ledger_lines - integer; expected line count of the session's
#                          ledger file after the run (0 when the file does
#                          not exist).
#   expect_ledger_sum   - integer; expected sum of the "lines" field over
#                          every entry in the session's ledger file after
#                          the run (0 when the file does not exist).
#   expect_ledger_files - integer; expected count of
#                          .inline-edit-ledger-* entries directly under the
#                          state dir, across every session (catches a hook
#                          that writes its ledger under a differently-named
#                          session id than the one the runner looked up).
#   notes               - free-text disclosure of what the case pins and
#                          why (not read by the runner; for reviewers).
#
# A failure while building a case's temp repo (copying repo/, creating a
# symlink, `git add`, or the commit) fails that case with the reason
# "case setup failed" and the hook is never invoked for it -- this is
# distinct from both the missing-hook diagnostic and a fixture/assertion
# failure.
#
# Session id: `jq -r '.session_id // "sess-1"'` run on the SUBSTITUTED
# input; falls back to "sess-1" when the input is not valid JSON (jq's
# stderr is discarded, its empty/failed output collapses to the fallback).
# The ledger path is $STATE/.inline-edit-ledger-<session_id>.jsonl, where
# $STATE is this case's fresh temp dir, exported as BOOTSTRAP_GATE_STATE_DIR
# for the hook run (CLAUDE_PROJECT_DIR is unset for the run so the hook
# cannot fall back to it).
#
# CLEANUP / INTERRUPT SAFETY: repo, outside, state, and sub_input are
# top-level (not `local`) variables holding the CURRENT case's temp paths.
# case_cleanup (top level, not nested in run_case) removes all four and
# resets the variables to empty; it is registered both as `trap
# case_cleanup EXIT` (so a SIGINT/SIGTERM mid-case -- or any other abnormal
# exit -- still removes that case's leftovers) and as `trap case_cleanup
# RETURN` inside run_case (so each case's temp paths are removed, and the
# variables reset, before the next case's mktemp calls run).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../inline-edit-guard.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures-inline-edit-guard"

pass=0
fail=0

repo=""
outside=""
state=""
sub_input=""

# shellcheck disable=SC2317,SC2329 # invoked via `trap case_cleanup EXIT|RETURN` below
case_cleanup() {
  [[ -n "$repo" && -d "$repo" ]] && rm -rf "$repo"
  [[ -n "$outside" && -d "$outside" ]] && rm -rf "$outside"
  [[ -n "$state" && -d "$state" ]] && rm -rf "$state"
  [[ -n "$sub_input" && -f "$sub_input" ]] && rm -f "$sub_input"
  repo=""
  outside=""
  state=""
  sub_input=""
}
trap case_cleanup EXIT

# `[[ "$a" -ne "$b" ]]` is an arithmetic comparison: a non-integer operand
# (a JSON string like "5", or "5.0") makes `-ne` error out with status 1,
# which every caller below reads as "equal" -- silently passing a hook that
# writes the wrong-typed value. int_equal requires both sides to already be
# plain unsigned integers before comparing.
int_equal() {
  [[ "$1" =~ ^[0-9]+$ && "$2" =~ ^[0-9]+$ ]] && ((10#$1 == 10#$2))
}

run_case() {
  local case_dir="$1"
  local name
  name="$(basename "$case_dir")"

  local input_file="$case_dir/input"
  if [[ ! -f "$input_file" ]]; then
    echo "FAIL: $name"
    echo "  - missing required 'input' file"
    fail=$((fail + 1))
    return
  fi

  # Fail loudly and specifically when the hook under test does not exist,
  # rather than letting `bash "$HOOK"` blow up with an opaque "No such file
  # or directory" per case.
  if [[ ! -f "$HOOK" ]]; then
    echo "FAIL: $name"
    echo "  - hook script not found at $HOOK"
    echo "  - hooks/inline-edit-guard.sh is missing -- distinct from a fixture assertion failure"
    fail=$((fail + 1))
    return
  fi

  trap case_cleanup RETURN

  repo="$(mktemp -d)"
  outside="$(mktemp -d)"
  state="$(mktemp -d)"

  local repo_real outside_real
  repo_real="$(cd "$repo" && pwd -P)"
  outside_real="$(cd "$outside" && pwd -P)"

  # Run as a plain statement (not directly as an `if`/`!` condition) so
  # `set -e` inside the subshell actually takes effect: bash suspends
  # errexit for a compound command that is itself the tested condition of
  # `if`/`while`/`!`, which would silently swallow a failing `ln`/`cp`/git
  # step here if this subshell were written as `if ! ( ... ); then`.
  (
    set -e
    cd "$repo"
    git init -q
    printf 'scratch/\n' >.gitignore
    if [[ -d "$case_dir/repo" ]]; then
      cp -r "$case_dir/repo/." .
    fi
    if [[ -f "$case_dir/symlinks" ]]; then
      while IFS=' ' read -r link target || [[ -n "$link" ]]; do
        [[ -z "$link" ]] && continue
        mkdir -p "$(dirname "$link")"
        ln -s "$target" "$link"
      done <"$case_dir/symlinks"
    fi
    git add -A
    git -c user.name=t -c user.email=t@t commit -qm init
  )
  local setup_status=$?
  if [[ "$setup_status" -ne 0 ]]; then
    echo "FAIL: $name"
    echo "  - case setup failed"
    fail=$((fail + 1))
    return
  fi

  sub_input="$(mktemp)"
  sed "s|__REPO__|$repo_real|g; s|__OUTSIDE__|$outside_real|g" "$input_file" >"$sub_input"

  local sid
  sid="$(jq -r '.session_id // "sess-1"' "$sub_input" 2>/dev/null)"
  [[ -z "$sid" || "$sid" == "null" ]] && sid="sess-1"

  local ledger_file="$state/.inline-edit-ledger-$sid.jsonl"
  if [[ -f "$case_dir/pre_ledger" ]]; then
    sed "s|__REPO__|$repo_real|g; s|__OUTSIDE__|$outside_real|g" "$case_dir/pre_ledger" >"$ledger_file"
  fi

  if [[ -f "$case_dir/pre_ledger_other" ]]; then
    sed "s|__REPO__|$repo_real|g; s|__OUTSIDE__|$outside_real|g" "$case_dir/pre_ledger_other" \
      >"$state/.inline-edit-ledger-sess-other.jsonl"
  fi

  local -a env_kv=()
  if [[ -f "$case_dir/env" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" ]] && continue
      env_kv+=("$line")
    done <"$case_dir/env"
  fi

  local actual_stdout actual_exit
  actual_stdout="$(
    unset CLAUDE_PROJECT_DIR
    export BOOTSTRAP_GATE_STATE_DIR="$state"
    for kv in "${env_kv[@]}"; do
      export "${kv?}"
    done
    bash "$HOOK" <"$sub_input"
  )"
  actual_exit=$?

  local expect_exit=0
  [[ -f "$case_dir/expect_exit" ]] && expect_exit="$(tr -d '[:space:]' <"$case_dir/expect_exit")"

  local ok=1
  local reasons=()

  if ! int_equal "$expect_exit" "$actual_exit"; then
    ok=0
    reasons+=("exit code mismatch: expected $expect_exit got $actual_exit")
  fi

  if [[ -f "$case_dir/expect_stdout" ]]; then
    local expected_stdout
    expected_stdout="$(cat "$case_dir/expect_stdout")"
    if [[ "$actual_stdout" != "$expected_stdout" ]]; then
      ok=0
      reasons+=("stdout mismatch: expected [$expected_stdout] got [$actual_stdout]")
    fi
  fi

  if [[ -f "$case_dir/expect_stdout_grep" ]]; then
    while IFS= read -r pattern || [[ -n "$pattern" ]]; do
      [[ -z "$pattern" ]] && continue
      if ! grep -qF "$pattern" <<<"$actual_stdout"; then
        ok=0
        reasons+=("stdout missing expected substring: $pattern (got [$actual_stdout])")
      fi
    done <"$case_dir/expect_stdout_grep"
  fi

  if [[ -f "$case_dir/expect_ledger_lines" ]]; then
    local expect_ledger_lines actual_ledger_lines
    expect_ledger_lines="$(tr -d '[:space:]' <"$case_dir/expect_ledger_lines")"
    if [[ -f "$ledger_file" ]]; then
      actual_ledger_lines="$(grep -c '' "$ledger_file")"
    else
      actual_ledger_lines=0
    fi
    if ! int_equal "$expect_ledger_lines" "$actual_ledger_lines"; then
      ok=0
      reasons+=("ledger line count mismatch: expected $expect_ledger_lines got $actual_ledger_lines")
    fi
  fi

  if [[ -f "$case_dir/expect_ledger_sum" ]]; then
    local expect_ledger_sum actual_ledger_sum
    expect_ledger_sum="$(tr -d '[:space:]' <"$case_dir/expect_ledger_sum")"
    if [[ -f "$ledger_file" ]]; then
      actual_ledger_sum="$(jq -s 'map(.lines) | add // 0' "$ledger_file")"
    else
      actual_ledger_sum=0
    fi
    if ! int_equal "$expect_ledger_sum" "$actual_ledger_sum"; then
      ok=0
      reasons+=("ledger lines sum mismatch: expected $expect_ledger_sum got $actual_ledger_sum")
    fi
  fi

  if [[ -f "$case_dir/expect_ledger_files" ]]; then
    local expect_ledger_files actual_ledger_files
    expect_ledger_files="$(tr -d '[:space:]' <"$case_dir/expect_ledger_files")"
    actual_ledger_files="$(find "$state" -mindepth 1 -maxdepth 1 -name '.inline-edit-ledger-*' | grep -c '')"
    if ! int_equal "$expect_ledger_files" "$actual_ledger_files"; then
      ok=0
      reasons+=("ledger file count mismatch: expected $expect_ledger_files got $actual_ledger_files")
    fi
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
