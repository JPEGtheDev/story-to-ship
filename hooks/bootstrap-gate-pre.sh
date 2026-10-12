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
#    compaction or resume, hooks/session-start.sh writes the skills to
#    re-invoke into .reload-pending-<session_id>, one per line: the session's
#    role skill (if any) followed by five action skills.
#    hooks/bootstrap-gate-post.sh removes a name from that file each time the
#    matching Skill call completes. This gate runs once the bootstrap flag is
#    absent, or the call is the Skill(session-bootstrap) call. Each pending
#    name holds only the call it guards:
#      - role name (running-a-sprint): holds Edit, Write, NotebookEdit, Agent.
#      - subagent-driven-development, using-git-worktrees: hold Agent.
#      - writing-skills: holds Edit, Write, NotebookEdit when the path field
#        (tool_input.file_path, else tool_input.notebook_path) has a directory
#        named skills or agents anywhere in it; an absent or empty path never
#        triggers it.
#      - versioning, verification-before-completion: hold none of the tools
#        this gate handles.
#      - any other name is ignored: it holds nothing.
#    The deny reason lists only the names that hold the current call, in
#    pending-file order. If every listed name is a role name, the sentence
#    says "loaded before the last compaction or resume"; if any is an action
#    name it says "needed after the last compaction or resume". The gate
#    fails open (exits 0 with no output and no log line) for every other
#    tool, for a missing/unreadable/empty pending file, and when no pending
#    name holds the call.
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

# A session_id outside this charset (e.g. containing "/") could
# traverse FLAG_FILE outside STATE_DIR once concatenated below. State can't
# be trusted for a hostile session_id, so fail open silently.
# Every path built from the id appends it after a fixed file-name prefix, so
# an id without "/" stays in the state dir.
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

# Every >> append to LOG_FILE below relies on POSIX O_APPEND atomicity for
# writes under PIPE_BUF (4096 bytes) to stay safe against concurrent sessions
# logging at once; each invocation of this hook writes at most one record,
# and each JSON line here is far short of that limit, so a single write(2)
# per invocation is guaranteed not to interleave.
log_record() {
  local gate="$1"
  mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
  local ts
  ts="$(date -u +%FT%TZ)"
  jq -cn \
    --arg ts "$ts" \
    --arg sid "$SESSION_ID" \
    --arg tool "$TOOL_NAME" \
    --arg mode "$MODE" \
    --arg gate "$gate" \
    '{timestamp:$ts, session_id:$sid, tool_name:$tool, mode:$mode} + (if $gate == "" then {} else {gate:$gate} end)' \
    >>"$LOG_FILE" 2>/dev/null
}

emit_decision() {
  local deny_reason="$1"
  local nudge_context="$2"
  if [[ "$MODE" == "deny" ]]; then
    jq -cn \
      --arg reason "$deny_reason" \
      '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$reason}}'
  else
    jq -cn \
      --arg context "$nudge_context" \
      '{hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$context}}'
  fi
}

# Bootstrap flag present and this isn't the call that clears it: this gate
# alone decides, and the reload check below never runs.
if [[ -f "$FLAG_FILE" && "$IS_BOOTSTRAP_SKILL_CALL" -ne 1 ]]; then
  log_record ""
  emit_decision \
    "bootstrap-gate: this session has not completed Skill(session-bootstrap) yet. Run Skill(session-bootstrap) before any other tool call." \
    "[bootstrap-gate] This session has not completed Skill(session-bootstrap) yet. Run Skill(session-bootstrap) before continuing."
  exit 0
fi

# Reload gate: only Edit, Write, NotebookEdit and Agent can be held; every
# other tool exits 0 silently.
case "$TOOL_NAME" in
  Edit | Write | NotebookEdit | Agent) ;;
  *) exit 0 ;;
esac

PENDING_FILE="$STATE_DIR/.reload-pending-$SESSION_ID"
# A missing or unreadable file reads as empty (grep prints nothing), and a
# file with only empty lines also reduces to empty here -- both fail open
# silently.
PENDING_NAMES="$(grep -v '^$' -- "$PENDING_FILE" 2>/dev/null)"
[[ -z "$PENDING_NAMES" ]] && exit 0

# Path field for the writing-skills hold: the first non-empty string of
# file_path, else notebook_path. Edit, Write and NotebookEdit only.
TARGET_PATH=""
if [[ "$TOOL_NAME" != "Agent" ]]; then
  TARGET_PATH="$(printf '%s' "$RAW" | jq -r \
    '[.tool_input.file_path, .tool_input.notebook_path] | map(select(type == "string" and . != "")) | .[0] // empty' \
    2>/dev/null)"
fi

# is_role <name>: succeeds for a role name (the only one is running-a-sprint).
is_role() {
  [[ "$1" == "running-a-sprint" ]]
}

# holds_call <name>: succeeds when the pending name holds the current call.
# Role and action names are whitelisted here; any other name holds nothing.
# versioning and verification-before-completion hold none of the tools
# handled here.
holds_call() {
  is_role "$1" && return 0
  case "$1" in
    subagent-driven-development | using-git-worktrees)
      [[ "$TOOL_NAME" == "Agent" ]]
      ;;
    writing-skills)
      [[ "$TOOL_NAME" != "Agent" && "$TARGET_PATH" =~ (^|/)(skills|agents)/ ]]
      ;;
    *) return 1 ;;
  esac
}

MISSING=()
HAS_ACTION=0
while IFS= read -r NAME; do
  holds_call "$NAME" || continue
  # A duplicate line must not be listed twice.
  case " ${MISSING[*]:-} " in *" $NAME "*) continue ;; esac
  MISSING+=("$NAME")
  is_role "$NAME" || HAS_ACTION=1
done <<<"$PENDING_NAMES"
[[ "${#MISSING[@]}" -eq 0 ]] && exit 0

NAMES_JOINED=""
for NAME in "${MISSING[@]}"; do
  NAMES_JOINED+="${NAMES_JOINED:+, }$NAME"
done
NUM_NAMES="${#MISSING[@]}"

if [[ "$NUM_NAMES" -eq 1 ]]; then
  SKILL_NOUN="skill" SKILL_VERB="is"
else
  SKILL_NOUN="skills" SKILL_VERB="are"
fi
if [[ "$HAS_ACTION" -eq 1 ]]; then
  WHEN="needed after the last compaction or resume"
else
  WHEN="loaded before the last compaction or resume"
fi
REASON="reload-gate: $NUM_NAMES $SKILL_NOUN $WHEN $SKILL_VERB not re-invoked yet: $NAMES_JOINED. Invoke each with the Skill tool, then retry."
log_record "reload"
emit_decision "$REASON" "$REASON"
exit 0
