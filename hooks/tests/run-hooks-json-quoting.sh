#!/usr/bin/env bash
# Guard test for hooks/hooks.json: every ${CLAUDE_PLUGIN_ROOT} placeholder in a
# hook command must sit inside double quotes, so that an install path holding a
# space still starts the hook.
#
# Checks, per hook command read from hooks/hooks.json:
#   1. Quoting: each ${CLAUDE_PLUGIN_ROOT} is immediately preceded by a double
#      quote character.
#   2. Runtime: the command runs with sh -c and CLAUDE_PLUGIN_ROOT set to a
#      temp path that contains a space ("a b"), and prints exactly "ran" from
#      a stub hook script.
#
#   3. Registration (pins dispatch-output-check.sh): a PostToolUse entry with
#      matcher exactly "Agent" and a SubagentStop entry with no matcher key each
#      hold a command that ends in hooks/dispatch-output-check.sh inside the
#      closing quote.
#
# Mutation self-check: the same checks run on a copy of the commands in which
# the first command's placeholder is unquoted. That copy must FAIL, which shows
# the checks can fail at all. The registration check has its own mutation
# self-check on copies of hooks.json (SubagentStop key removed, PostToolUse
# matcher changed to "Task", SubagentStop entry given a matcher).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_JSON="$SCRIPT_DIR/../hooks.json"
# shellcheck disable=SC2016 # literal placeholder, not an expansion
PLACEHOLDER='${CLAUDE_PLUGIN_ROOT}'

pass_count=0
fail_count=0

pass() {
  echo "[+] $1"
  pass_count=$((pass_count + 1))
}

fail() {
  echo "[-] $1"
  fail_count=$((fail_count + 1))
}

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

PLUGIN_ROOT="$TMP_ROOT/a b"
mkdir -p "$PLUGIN_ROOT/hooks"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"

# run_checks COMMANDS_TEXT
# Runs the quoting and runtime checks on each newline-separated command.
# Prints one [+]/[-] line per check and returns the number of failed checks
# in the global run_failures.
run_checks() {
  local cmds="$1" cmd rest before out
  local -a names=()
  run_failures=0

  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue

    # 1. Quoting: every placeholder must be preceded by a double quote.
    rest="$cmd"
    local quoted=1
    while [[ "$rest" == *"$PLACEHOLDER"* ]]; do
      before="${rest%%"$PLACEHOLDER"*}"
      if [[ "$before" != *'"' ]]; then
        quoted=0
      fi
      rest="${rest#*"$PLACEHOLDER"}"
    done
    if [[ "$quoted" -eq 1 ]]; then
      echo "[+] quoted: $cmd"
    else
      echo "[-] placeholder without quotes: $cmd"
      run_failures=$((run_failures + 1))
    fi

    # Collect the stub script name the command references.
    if [[ "$cmd" =~ hooks/([A-Za-z0-9._-]+\.sh) ]]; then
      names+=("${BASH_REMATCH[1]}")
    else
      echo "[-] no hooks/<name>.sh reference: $cmd"
      run_failures=$((run_failures + 1))
    fi
  done <<< "$cmds"

  # Create one stub per referenced script name under the spaced path.
  local n
  for n in "${names[@]}"; do
    printf '#!/bin/sh\necho ran\n' > "$PLUGIN_ROOT/hooks/$n"
    chmod +x "$PLUGIN_ROOT/hooks/$n"
  done

  # 2. Runtime: each command must print exactly "ran".
  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    out="$(sh -c "$cmd" 2>&1)"
    if [[ "$out" == "ran" ]]; then
      echo "[+] runs with spaced root: $cmd"
    else
      echo "[-] did not print ran: $cmd (output: $out)"
      run_failures=$((run_failures + 1))
    fi
  done <<< "$cmds"
}

# Read the real hook commands.
if ! command -v jq >/dev/null 2>&1; then
  fail "jq is required to read $HOOKS_JSON"
  echo "Results: $pass_count passed, $fail_count failed"
  exit 1
fi

if ! commands_text="$(jq -r '.hooks[][].hooks[].command' "$HOOKS_JSON")"; then
  fail "could not read hook commands from $HOOKS_JSON"
  echo "Results: $pass_count passed, $fail_count failed"
  exit 1
fi

echo "== Real hooks.json commands =="
run_checks "$commands_text"
if [[ "$run_failures" -eq 0 ]]; then
  pass "all hook commands quote the placeholder and run from a spaced path"
else
  fail "$run_failures check(s) failed on hooks.json commands"
fi

# Mutation self-check: unquote the placeholder in the first command only.
# shellcheck disable=SC2016 # literal placeholder, not an expansion
mutated_text="$(printf '%s\n' "$commands_text" | sed '1s/"\(\${CLAUDE_PLUGIN_ROOT}[^"]*\)"/\1/')"
echo "== Mutation self-check (first command unquoted) =="
run_checks "$mutated_text"
if [[ "$run_failures" -gt 0 ]]; then
  pass "mutated commands fail the checks ($run_failures failure(s)), so the test can fail"
else
  fail "mutated commands passed the checks; the test cannot detect unquoted placeholders"
fi

# check_registration FILE
# Prints one [+]/[-] line per registration and returns the number of failures
# in the global reg_failures.
check_registration() {
  local file="$1" suffix='hooks/dispatch-output-check.sh"'
  reg_failures=0

  if jq -e --arg s "$suffix" \
    '[.hooks.PostToolUse[]? | select(.matcher == "Agent") | .hooks[].command | endswith($s)] | any' \
    "$file" >/dev/null 2>&1; then
    echo "[+] PostToolUse matcher Agent runs dispatch-output-check.sh"
  else
    echo "[-] PostToolUse matcher Agent does not run dispatch-output-check.sh"
    reg_failures=$((reg_failures + 1))
  fi

  if jq -e --arg s "$suffix" \
    '[.hooks.SubagentStop[]? | select(has("matcher") | not) | .hooks[].command | endswith($s)] | any' \
    "$file" >/dev/null 2>&1; then
    echo "[+] SubagentStop (no matcher) runs dispatch-output-check.sh"
  else
    echo "[-] SubagentStop (no matcher) does not run dispatch-output-check.sh"
    reg_failures=$((reg_failures + 1))
  fi
}

echo "== Registration of dispatch-output-check.sh =="
check_registration "$HOOKS_JSON"
if [[ "$reg_failures" -eq 0 ]]; then
  pass "dispatch-output-check.sh is registered on PostToolUse Agent and SubagentStop"
else
  fail "$reg_failures registration check(s) failed on hooks.json"
fi

# Mutation self-check for the registration: each broken copy must fail.
reg_mutant() {
  local label="$1" filter="$2" copy="$TMP_ROOT/mutant.json"
  jq "$filter" "$HOOKS_JSON" > "$copy"
  echo "== Registration mutation ($label) =="
  check_registration "$copy"
  if [[ "$reg_failures" -gt 0 ]]; then
    pass "mutant '$label' fails the registration check"
  else
    fail "mutant '$label' passed the registration check; the test cannot detect it"
  fi
}
reg_mutant "SubagentStop removed" 'del(.hooks.SubagentStop)'
reg_mutant "PostToolUse matcher Task" '(.hooks.PostToolUse[] | select(.matcher == "Agent") | .matcher) = "Task"'
reg_mutant "SubagentStop with matcher" '.hooks.SubagentStop[0].matcher = "x"'

echo "Results: $pass_count passed, $fail_count failed"

if [[ "$fail_count" -ne 0 ]]; then
  exit 1
fi
exit 0
