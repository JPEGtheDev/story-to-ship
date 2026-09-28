#!/usr/bin/env bash
# PreToolUse hook (matcher *): bootstrap-gate-pre.sh
#
# Runs two gates in order, for every PreToolUse call in the main session:
#
# 1. Bootstrap gate (first, every tool). Blocks (deny mode) or nudges (warn
#    mode) tool use in a session that has not yet completed
#    Skill(session-bootstrap), as recorded by a
#    .bootstrap-pending-<session_id> flag file that hooks/session-start.sh
#    stamps on every SessionStart and hooks/bootstrap-gate-post.sh clears
#    once the session-bootstrap Skill call completes. While this flag is
#    present and the call is not the Skill(session-bootstrap) call itself,
#    this gate alone decides the outcome and the reload gate below never
#    runs.
#
# 2. Reload gate (second, only Edit, Write, NotebookEdit and Agent). After a
#    compaction or resume, hooks/session-start.sh writes the names of the
#    skills that were loaded before the break into
#    .reload-pending-<session_id>, one per line; hooks/bootstrap-gate-post.sh
#    removes a name from that file each time the matching Skill call
#    completes. This gate runs once the bootstrap flag is absent, or the
#    call is the Skill(session-bootstrap) call, and holds Edit, Write,
#    NotebookEdit and Agent until every remaining pending name is
#    re-invoked. It fails open (exits 0 with no output and no log line) for
#    every other tool, for a missing/unreadable/empty pending file, and for
#    a pending file that contains no non-empty lines.
#
# Fail-open philosophy: this hook NEVER exits nonzero. Missing jq, malformed
# stdin, an unresolved state dir, an invalid session_id, or any other
# ambiguity all resolve to a plain allow (exit 0, empty stdout, no log line)
# rather than blocking, for both gates.
#
# State dir resolution: ${BOOTSTRAP_GATE_STATE_DIR:-$CLAUDE_PROJECT_DIR/.claude}.
# If neither variable is set, there is no safe place to look for a flag file
# or write a log, so this hook allows silently.

# Guard against a TTY, and bound the read with timeout, so a manual or
# misbehaving invocation can never hang the hook.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

# No jq, no gate: fail open.
command -v jq &>/dev/null || exit 0
[[ -z "$RAW" ]] && exit 0
printf '%s' "$RAW" | jq empty 2>/dev/null || exit 0

# Subagents identify themselves via agent_id; the gate never applies to them.
AGENT_ID="$(printf '%s' "$RAW" | jq -r '.agent_id // empty' 2>/dev/null)"
if [[ -n "$AGENT_ID" ]]; then
  exit 0
fi

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

TOOL_NAME="$(printf '%s' "$RAW" | jq -r '.tool_name // empty' 2>/dev/null)"
SKILL_NAME="$(printf '%s' "$RAW" | jq -r '.tool_input.skill // empty' 2>/dev/null)"
# The harness lists plugin skills as "<plugin>:<skill>". Strip everything
# through the last colon so both "session-bootstrap" and
# "<plugin>:session-bootstrap" satisfy the gate; "session-bootstrap:" does not.
SKILL_NAME="${SKILL_NAME##*:}"

FLAG_FILE="$STATE_DIR/.bootstrap-pending-$SESSION_ID"

IS_BOOTSTRAP_SKILL_CALL=0
if [[ "$TOOL_NAME" == "Skill" && "$SKILL_NAME" == "session-bootstrap" ]]; then
  IS_BOOTSTRAP_SKILL_CALL=1
fi

MODE="${BOOTSTRAP_GATE_MODE:-warn}"
LOG_FILE="$STATE_DIR/.bootstrap-gate-log.jsonl"

# Bootstrap flag present and this isn't the call that clears it: this gate
# alone decides, and the reload check below never runs.
if [[ -f "$FLAG_FILE" && "$IS_BOOTSTRAP_SKILL_CALL" -ne 1 ]]; then
  TS="$(date -u +%FT%TZ)"

  mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
  # The >> append below relies on POSIX O_APPEND atomicity for writes under
  # PIPE_BUF (4096 bytes) to stay safe against concurrent sessions logging at
  # once; each JSON line here is far short of that, so a single write(2) per
  # invocation is guaranteed not to interleave.
  jq -cn \
    --arg ts "$TS" \
    --arg sid "$SESSION_ID" \
    --arg tool "$TOOL_NAME" \
    --arg mode "$MODE" \
    '{timestamp:$ts, session_id:$sid, tool_name:$tool, mode:$mode}' \
    >>"$LOG_FILE" 2>/dev/null

  if [[ "$MODE" == "deny" ]]; then
    REASON="bootstrap-gate: this session has not completed Skill(session-bootstrap) yet. Run Skill(session-bootstrap) before any other tool call."
    jq -cn \
      --arg reason "$REASON" \
      '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$reason}}'
  else
    CONTEXT="[bootstrap-gate] This session has not completed Skill(session-bootstrap) yet. Run Skill(session-bootstrap) before continuing."
    jq -cn \
      --arg context "$CONTEXT" \
      '{hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$context}}'
  fi

  exit 0
fi

# Reload gate: only Edit, Write, NotebookEdit and Agent are held for a
# reload-pending name; every other tool exits 0 silently.
case "$TOOL_NAME" in
  Edit | Write | NotebookEdit | Agent) ;;
  *) exit 0 ;;
esac

PENDING_FILE="$STATE_DIR/.reload-pending-$SESSION_ID"
# A missing or unreadable file reads as empty (grep prints nothing), and an
# all-blank file also reduces to empty here -- both fail open silently.
PENDING_NAMES="$(grep -v '^$' -- "$PENDING_FILE" 2>/dev/null)"
[[ -z "$PENDING_NAMES" ]] && exit 0

NAMES_JOINED=""
while IFS= read -r NAME; do
  if [[ -z "$NAMES_JOINED" ]]; then
    NAMES_JOINED="$NAME"
  else
    NAMES_JOINED="$NAMES_JOINED, $NAME"
  fi
done <<<"$PENDING_NAMES"
NUM_NAMES="$(printf '%s\n' "$PENDING_NAMES" | grep -c '.')"

TS="$(date -u +%FT%TZ)"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
jq -cn \
  --arg ts "$TS" \
  --arg sid "$SESSION_ID" \
  --arg tool "$TOOL_NAME" \
  --arg mode "$MODE" \
  '{timestamp:$ts, session_id:$sid, tool_name:$tool, mode:$mode, gate:"reload"}' \
  >>"$LOG_FILE" 2>/dev/null

REASON="reload-gate: $NUM_NAMES skills loaded before the compaction are not re-invoked yet: $NAMES_JOINED. Invoke each with the Skill tool, then retry."

if [[ "$MODE" == "deny" ]]; then
  jq -cn \
    --arg reason "$REASON" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$reason}}'
else
  jq -cn \
    --arg context "$REASON" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$context}}'
fi

exit 0
