#!/usr/bin/env bash
# PostToolUse hook (matcher Skill): bootstrap-gate-post.sh
#
# Every Skill call from the main session is recorded, one line per skill
# name, in .skills-loaded-<session_id>, deduplicated by exact line match.
# The same call also clears its name from the reload-pending list, if one
# is pending:
#   Skill(session-bootstrap) also clears .bootstrap-pending-<session_id>, so
#     bootstrap-gate-pre.sh stops gating further tool calls in this session.
#   Skill(honesty) also clears .honesty-pending-<session_id>.
#   Skill(communication) also clears .communication-pending-<session_id>.
# Any other Skill name is still recorded and still clears its own pending
# entry, but maps to no flag file and is otherwise a no-op; any other tool
# is a no-op. A call from a subagent (a payload carrying agent_id) is a
# no-op before any state file is touched: only the main-thread session
# records skills or clears its own flags. Never blocks: always exits 0.
#
# Fail-open philosophy: this hook NEVER exits nonzero. Missing jq, malformed
# stdin, an unresolved state dir, an invalid session_id or skill name, or
# any other ambiguity all resolve to a plain exit 0 (state left untouched)
# rather than blocking or guessing.
#
# State dir resolution: ${BOOTSTRAP_GATE_STATE_DIR:-$CLAUDE_PROJECT_DIR/.claude}.
# If neither variable is set, there is no safe place to read or write the
# flag files, the loaded-skills list, or the pending list, so this hook
# allows silently.
#
# Known race: two Skill calls running in parallel for the same session can
# each read the pending list, rewrite it from that same original content,
# and mv their own copy over it -- one call's removal can be overwritten by
# the other's, so that skill's name can stay pending until it is invoked
# again. No lock is taken to close this window.

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

# Subagents identify themselves via agent_id. A subagent's payload carries the
# main session's session_id, so without this check a subagent loading one of
# these skills would clear the main session's flag. Its calls are ignored,
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
# traverse the state file paths below once concatenated. State can't be
# trusted for a hostile session_id, so fail open silently.
# Every path built from the id appends it after a fixed file-name prefix, so
# an id without "/" stays in the state dir.
[[ "$SESSION_ID" =~ ^[A-Za-z0-9._-]+$ ]] || exit 0

# Record the skill and clear its own pending entry only for a name in this
# same safe charset (an empty or malformed name -- e.g. a bare trailing
# colon, or a slash from an untrusted skill field -- is left unrecorded).
if [[ -n "$SKILL_NAME" && "$SKILL_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  LOADED_FILE="$STATE_DIR/.skills-loaded-$SESSION_ID"
  if ! grep -qxF -- "$SKILL_NAME" "$LOADED_FILE" 2>/dev/null; then
    printf '%s\n' "$SKILL_NAME" >>"$LOADED_FILE" 2>/dev/null
  fi

  PENDING_FILE="$STATE_DIR/.reload-pending-$SESSION_ID"
  if [[ -f "$PENDING_FILE" ]]; then
    TMP_FILE="$STATE_DIR/.reload-pending-$SESSION_ID.tmp.$$"
    grep -vxF -- "$SKILL_NAME" "$PENDING_FILE" >"$TMP_FILE" 2>/dev/null
    GREP_STATUS=$?
    if [[ "$GREP_STATUS" -eq 0 ]]; then
      # Some lines remain (not every line matched): replace the pending
      # file with the filtered list.
      mv -f -- "$TMP_FILE" "$PENDING_FILE" 2>/dev/null || rm -f -- "$TMP_FILE" 2>/dev/null
    elif [[ "$GREP_STATUS" -eq 1 ]]; then
      # grep exits 1 with empty output when every line matched -- the
      # pending list is now empty, so drop both the temp file and the
      # pending file itself rather than leaving an empty file behind.
      rm -f -- "$TMP_FILE" "$PENDING_FILE" 2>/dev/null
    else
      # Any other status (e.g. 2: the pending file could not be read) is
      # an error, not "now empty" -- leave the pending file untouched and
      # only clean up the temp file, so an unreadable file never loses
      # its remaining names.
      rm -f -- "$TMP_FILE" 2>/dev/null
    fi
  fi
fi

# Map the loaded skill to the flag name it clears. Any skill not in this
# list is a no-op past this point.
case "$SKILL_NAME" in
  session-bootstrap) FLAG_NAME="bootstrap" ;;
  honesty) FLAG_NAME="honesty" ;;
  communication) FLAG_NAME="communication" ;;
  *) exit 0 ;;
esac

FLAG_FILE="$STATE_DIR/.$FLAG_NAME-pending-$SESSION_ID"
rm -f -- "$FLAG_FILE" 2>/dev/null

exit 0
