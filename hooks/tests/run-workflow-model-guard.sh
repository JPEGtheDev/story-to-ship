#!/usr/bin/env bash
# Hermetic test harness for the workflow-model-pin guard hook:
#   hooks/workflow-model-guard.sh  (PreToolUse, matcher Workflow)
#
# RED PHASE NOTE (T4): hooks/workflow-model-guard.sh does not exist yet. This
# suite is expected to fail every case until the GREEN todo (T5) implements
# it -- see the per-case "missing hook script" failure reason below, which is
# deliberately distinct from a fixture/assertion failure so a reader can tell
# "hook not built" apart from "hook built wrong" at a glance.
#
# CI WIRING NOTE (disclosed, not silent): the lint job in
# .github/workflows/validate.yml enumerates an explicit file list (not a
# glob) and does NOT list this runner yet. That wiring deliberately lands
# with T5 (GREEN) alongside the hook implementation itself -- until then
# this file's absence from the list means CI simply never lints it (CI
# still passes; the file is just uncovered), not that CI is expected to
# fail.
#
# Sibling to hooks/tests/run-bootstrap-gate.sh and hooks/tests/run.sh,
# following the same fixture-dir pattern: per-case directories under
# fixtures-workflow-model-guard/ carry input/expected files; this runner
# pipes the case's input into the hook and asserts stdout shape and exit
# code. Unlike run-bootstrap-gate.sh, this hook is STATELESS (it inspects
# only the PreToolUse envelope handed to it on stdin -- no flag files, no
# state dir, no log file), and there is only ONE hook under test, so this
# runner drops the multi-hook "hook" selector field and the log/flag
# assertion vocabulary that hook family needed. Everything else (input,
# expect_exit, expect_stdout, expect_stdout_grep) is the same vocabulary and
# the same semantics as run-bootstrap-gate.sh.
#
# Case directory contract (all files optional except "input"):
#   input                  - stdin JSON fed to the hook (required). Every
#                             fixture using tool_name "Workflow" carries a
#                             per-case "notes" file disclosing that the
#                             Workflow tool_input shape is schema-doc-derived
#                             (research input R5), not captured from a live
#                             session -- see fixtures-workflow-model-guard/
#                             for the disclosure text and any per-case
#                             contract choices the GREEN implementer must
#                             honor or explicitly renegotiate.
#   expect_exit             - exact exit code (default 0). Every PreToolUse
#                             hook in this repo communicates deny via JSON
#                             on stdout while still exiting 0 (bootstrap-
#                             gate-pre.sh precedent) -- expect_exit is left
#                             at its default for every case in this suite.
#   expect_stdout           - exact-match stdout. This hook has no warn mode,
#                             so every ALLOW path in this suite (b, c, d, e,
#                             f) is pinned to BYTE-EXACT EMPTY STDOUT + exit
#                             0 -- not merely "no deny" -- via this field.
#                             (Tightened in the Stage 1 fix round: an earlier
#                             draft used expect_stdout_not_grep on deny/
#                             permissionDecision for the allow cases, which
#                             could not distinguish a correct silent allow
#                             from an allow that emits some other, wrong-
#                             reason non-deny text.)
#   expect_stdout_grep      - newline list; every pattern must appear in
#                             stdout (used for deny cases -- asserts both the
#                             deny shape and a snippet naming the offending
#                             call).
#
# (Stage 2 fix round: this runner previously also supported an
# expect_stdout_not_grep field, carried over from run-bootstrap-gate.sh for
# vocabulary parity. No fixture in this suite ever exercised it -- every
# allow case uses the stricter byte-exact expect_stdout field instead (see
# above) -- so the reviewer ruled it out as an untested branch and it has
# been dropped rather than carried unexercised.)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../workflow-model-guard.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures-workflow-model-guard"

pass=0
fail=0

run_case() {
  local case_dir="$1"
  local name
  name="$(basename "$case_dir")"

  local input_file="$case_dir/input"
  local expect_exit_file="$case_dir/expect_exit"
  local expect_stdout_file="$case_dir/expect_stdout"
  local expect_stdout_grep_file="$case_dir/expect_stdout_grep"

  if [[ ! -f "$input_file" ]]; then
    echo "FAIL: $name"
    echo "  - missing required 'input' file"
    fail=$((fail + 1))
    return
  fi

  # Fail loudly and specifically when the hook under test does not exist yet
  # (expected during the RED phase), rather than letting `bash "$HOOK"` blow
  # up with an opaque "No such file or directory" per case.
  if [[ ! -f "$HOOK" ]]; then
    echo "FAIL: $name"
    echo "  - hook script not found at $HOOK"
    echo "  - hooks/workflow-model-guard.sh has not been implemented yet (RED phase, T4/T5 pair)"
    fail=$((fail + 1))
    return
  fi

  local expect_exit=0
  [[ -f "$expect_exit_file" ]] && expect_exit="$(cat "$expect_exit_file" | tr -d '[:space:]')"

  local actual_stdout actual_exit
  actual_stdout="$(
    unset CLAUDE_PROJECT_DIR
    bash "$HOOK" <"$input_file"
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
