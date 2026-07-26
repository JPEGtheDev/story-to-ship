#!/usr/bin/env bash
# Mechanical drift check between the core skill tags and the per-turn
# routing block.
#
# skills/session-bootstrap/references/SKILL_DISPATCH_TABLE.md tags each
# dispatch row `core` or `domain` in a trailing Tier column. Every skill
# tagged `core` there is a skill the per-turn routing block injected by
# hooks/pre-message-gates.md is supposed to name (see the "Core Skill Tags"
# section of that file for the contract). This script asserts that
# contract mechanically: it extracts every core-tagged skill name from the
# dispatch table, then greps hooks/pre-message-gates.md for each one.
#
# Sibling to hooks/tests/run.sh and hooks/tests/run-bootstrap-gate.sh:
# prints PASS/FAIL per skill and a Total/Pass/Fail summary; exits nonzero
# if any skill is missing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DISPATCH_TABLE="$REPO_ROOT/skills/session-bootstrap/references/SKILL_DISPATCH_TABLE.md"
GATES_FILE="$REPO_ROOT/hooks/pre-message-gates.md"

pass=0
fail=0

if [[ ! -f "$DISPATCH_TABLE" ]]; then
  echo "FAIL: dispatch table not found at $DISPATCH_TABLE"
  echo ""
  echo "Total: 1  Pass: 0  Fail: 1"
  exit 1
fi

if [[ ! -f "$GATES_FILE" ]]; then
  echo "FAIL: gates file not found at $GATES_FILE"
  echo ""
  echo "Total: 1  Pass: 0  Fail: 1"
  exit 1
fi

# Extract core-tagged skill names: a pipe-table row whose last cell is the
# literal word "core", with the skill name as the first backtick-quoted
# token on that line. Dedup preserves first-seen order.
core_skills=()
while IFS= read -r row; do
  # shellcheck disable=SC2016 # literal backtick chars in the regex, not expansion
  skill="$(grep -oE '`[A-Za-z0-9_-]+`' <<<"$row" | head -1 | tr -d '`')"
  [[ -z "$skill" ]] && continue
  already=0
  for existing in "${core_skills[@]}"; do
    [[ "$existing" == "$skill" ]] && already=1 && break
  done
  [[ "$already" -eq 0 ]] && core_skills+=("$skill")
done < <(grep -E '^\|.*\|[[:space:]]*core[[:space:]]*\|' "$DISPATCH_TABLE")

if [[ "${#core_skills[@]}" -eq 0 ]]; then
  echo "FAIL: no core-tagged skills found in $DISPATCH_TABLE"
  echo ""
  echo "Total: 1  Pass: 0  Fail: 1"
  exit 1
fi

for skill in "${core_skills[@]}"; do
  if grep -qF -- "$skill" "$GATES_FILE"; then
    echo "PASS: $skill"
    pass=$((pass + 1))
  else
    echo "FAIL: $skill (core-tagged in SKILL_DISPATCH_TABLE.md) not found in $GATES_FILE"
    fail=$((fail + 1))
  fi
done

echo ""
echo "Total: $((pass + fail))  Pass: $pass  Fail: $fail"

if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
exit 0
