#!/usr/bin/env bash
# Hermetic test harness for the shell-write guard hook:
#   hooks/shell-write-guard.sh  (PreToolUse, matcher Bash)
#
# MISSING-HOOK DIAGNOSTIC: if hooks/shell-write-guard.sh does not exist,
# every case in this suite fails with a distinct "missing hook script"
# failure reason (see below), deliberately distinct from a fixture/assertion
# failure so a reader can tell "hook not built" apart from "hook built
# wrong" at a glance.
#
# Sibling to hooks/tests/run-workflow-model-guard.sh and
# hooks/tests/run-bootstrap-gate.sh, following the same fixture-dir
# pattern: per-case directories under fixtures-shell-write-guard/ carry
# input/expected files; this runner pipes the case's input into the hook
# and asserts stdout shape and exit code. Case directory contract (input,
# expect_exit, expect_stdout, expect_stdout_grep, notes) is the same
# vocabulary and semantics as run-workflow-model-guard.sh.
#
# SANDBOX: unlike the stateless workflow-model-guard suite, this hook's
# verdict depends on real filesystem state (does a path exist? is it
# tracked/ignored by git?). Before running any case, this runner builds a
# throwaway git repo under $SANDBOX and a non-repo scratch dir under
# $OUTSIDE (see setup_sandbox below) and tears both down in a trap on exit.
# A case's "input" file may contain the literal tokens __CWD__ and
# __OUTSIDE__; this runner substitutes them with the live sandbox/outside
# paths (via sed) before piping the input to the hook, so fixture files
# stay portable across machines/runs.
#
# Sandbox layout (see setup_sandbox):
#   $SANDBOX/target.txt           tracked, protected
#   $SANDBOX/other.txt            tracked, protected
#   $SANDBOX/sub/target.txt       tracked, protected (nested)
#   $SANDBOX/link-to-target.txt   tracked symlink to target.txt, protected
#                                  (resolves to target.txt)
#   $SANDBOX/.gitignore           tracked (contents: "scratch/", "inner/")
#   $SANDBOX/scratch/dump.txt     gitignored, NOT protected
#   $SANDBOX/inner/               a separate git repo nested under $SANDBOX;
#                                  ignored by the OUTER .gitignore, but its
#                                  own repo decides its own targets
#   $SANDBOX/inner/nested.txt     tracked in the inner repo, protected
#   $SANDBOX/plan.md              untracked, NOT gitignored, protected
#   $OUTSIDE/outside.txt          not inside any git repo, NOT protected
#
# Case directory contract (all files optional except "input"):
#   input                  - stdin JSON fed to the hook (required). May
#                             contain __CWD__ / __OUTSIDE__ tokens, which
#                             this runner substitutes before invoking the
#                             hook (see token note above).
#   expect_exit             - exact exit code (default 0). This hook
#                             communicates deny via JSON on stdout while
#                             still exiting 0 (bootstrap-gate-pre.sh /
#                             workflow-model-guard.sh precedent) --
#                             expect_exit is left at its default for every
#                             deny case in this suite.
#   expect_stdout           - exact-match stdout (unused by the deny-only
#                             fixtures in this suite; reserved for a later
#                             allow-case todo).
#   expect_stdout_grep      - newline list; every pattern must appear in
#                             stdout (used for deny cases -- asserts both
#                             the deny shape and a snippet naming the
#                             offending path).
#   notes                   - free-text disclosure of what the case pins
#                             and why (not read by the runner; for
#                             reviewers).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/../shell-write-guard.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures-shell-write-guard"

SANDBOX=""
OUTSIDE=""

# shellcheck disable=SC2329 # invoked indirectly via `trap cleanup EXIT` below
cleanup() {
  [[ -n "$SANDBOX" && -d "$SANDBOX" ]] && rm -rf "$SANDBOX"
  [[ -n "$OUTSIDE" && -d "$OUTSIDE" ]] && rm -rf "$OUTSIDE"
}
trap cleanup EXIT

setup_sandbox() {
  SANDBOX="$(mktemp -d)"
  OUTSIDE="$(mktemp -d)"

  (
    cd "$SANDBOX" || exit 1
    git init -q
    echo "target" >target.txt
    echo "other" >other.txt
    git add -A
    git -c user.name=t -c user.email=t@t commit -qm init

    mkdir scratch
    echo x >scratch/dump.txt
    printf 'scratch/\n' >.gitignore
    git add .gitignore
    git -c user.name=t -c user.email=t@t commit -qm gitignore

    mkdir -p sub
    cp target.txt sub/target.txt
    git add -A
    git -c user.name=t -c user.email=t@t commit -qm sub

    ln -s target.txt link-to-target.txt
    git add -A
    git -c user.name=t -c user.email=t@t commit -qm symlink

    mkdir inner
    git -C inner init -q
    echo n >inner/nested.txt
    git -C inner add -A
    git -C inner -c user.name=t -c user.email=t@t commit -qm init
    printf 'inner/\n' >>.gitignore
    git add .gitignore
    git -c user.name=t -c user.email=t@t commit -qm ignore-inner

    cat >plan.md <<'PLANEOF'
plan
PLANEOF
  )

  echo "outside" >"$OUTSIDE/outside.txt"
}

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

  # Fail loudly and specifically when the hook under test does not exist,
  # rather than letting `bash "$HOOK"` blow up with an opaque "No such file
  # or directory" per case.
  if [[ ! -f "$HOOK" ]]; then
    echo "FAIL: $name"
    echo "  - hook script not found at $HOOK"
    echo "  - hooks/shell-write-guard.sh is missing -- distinct from a fixture assertion failure"
    fail=$((fail + 1))
    return
  fi

  local expect_exit=0
  [[ -f "$expect_exit_file" ]] && expect_exit="$(tr -d '[:space:]' <"$expect_exit_file")"

  local actual_stdout actual_exit
  actual_stdout="$(
    sed "s|__CWD__|$SANDBOX|g; s|__OUTSIDE__|$OUTSIDE|g" "$input_file" | bash "$HOOK"
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

setup_sandbox

for case_dir in "$FIXTURES_DIR"/*/; do
  run_case "${case_dir%/}"
done

echo ""
echo "Total: $((pass + fail))  Pass: $pass  Fail: $fail"

if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
exit 0
