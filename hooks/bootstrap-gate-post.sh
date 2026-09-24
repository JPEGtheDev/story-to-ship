#!/usr/bin/env bash
# PostToolUse hook (matcher Skill): bootstrap-gate-post.sh
#
# Clears one per-session pending flag once its matching skill completes:
#   Skill(session-bootstrap) clears .bootstrap-pending-<session_id>, so
#     bootstrap-gate-pre.sh stops gating further tool calls in this session.
#   Skill(honesty) clears .honesty-pending-<session_id>.
#   Skill(communication) clears .communication-pending-<session_id>.
# Any other Skill (or any other tool) is a no-op, and so is any call from a
# subagent (a payload carrying agent_id): only the main-thread session
# clears its own flags. Never blocks: always exits 0.
#
# Fail-open philosophy: this hook NEVER exits nonzero. Missing jq, malformed
# stdin, an unresolved state dir, an invalid session_id, or any other
# ambiguity all resolve to a plain exit 0 (flag left untouched) rather than
# blocking or guessing.
#
# State dir resolution: ${BOOTSTRAP_GATE_STATE_DIR:-$CLAUDE_PROJECT_DIR/.claude}.
# If neither variable is set, there is no safe place to look for the flag,
# so this hook allows silently.

# Guard against a TTY, and bound the read with timeout, so a manual or
# misbehaving invocation can never hang the hook.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

command -v jq &>/dev/null || exit 0
[[ -z "$RAW" ]] && exit 0
printf '%s' "$RAW" | jq empty 2>/dev/null || exit 0

# Subagents identify themselves via agent_id. A subagent loading one of these
# skills must not clear the main session's flag, so its calls are ignored,
# matching the exemption in bootstrap-gate-pre.sh.
AGENT_ID="$(printf '%s' "$RAW" | jq -r '.agent_id // empty' 2>/dev/null)"
if [[ -n "$AGENT_ID" ]]; then
  exit 0
fi

TOOL_NAME="$(printf '%s' "$RAW" | jq -r '.tool_name // empty' 2>/dev/null)"
SKILL_NAME="$(printf '%s' "$RAW" | jq -r '.tool_input.skill // empty' 2>/dev/null)"
# The harness lists plugin skills as "<plugin>:<skill>". Strip everything
# through the last colon so each mapped skill matches with or without a
# plugin prefix -- e.g. both "honesty" and "<plugin>:honesty" map to the
# honesty flag below; a trailing colon such as "honesty:" strips to an
# empty name and matches nothing.
SKILL_NAME="${SKILL_NAME##*:}"

if [[ "$TOOL_NAME" != "Skill" ]]; then
  exit 0
fi

# Map the loaded skill to the flag name it clears. Any skill not in this
# list is a no-op.
case "$SKILL_NAME" in
  session-bootstrap) FLAG_NAME="bootstrap" ;;
  honesty) FLAG_NAME="honesty" ;;
  communication) FLAG_NAME="communication" ;;
  *) exit 0 ;;
esac

STATE_DIR="${BOOTSTRAP_GATE_STATE_DIR:-}"
if [[ -z "$STATE_DIR" ]]; then
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    STATE_DIR="$CLAUDE_PROJECT_DIR/.claude"
  else
    exit 0
  fi
fi

SESSION_ID="$(printf '%s' "$RAW" | jq -r '.session_id // empty' 2>/dev/null)"
[[ -z "$SESSION_ID" ]] && exit 0

# A session_id outside this charset (e.g. containing "/" or "..") could
# traverse FLAG_FILE outside STATE_DIR once concatenated below. State can't
# be trusted for a hostile session_id, so fail open silently.
[[ "$SESSION_ID" =~ ^[A-Za-z0-9._-]+$ ]] || exit 0

FLAG_FILE="$STATE_DIR/.$FLAG_NAME-pending-$SESSION_ID"
rm -f -- "$FLAG_FILE" 2>/dev/null

exit 0
