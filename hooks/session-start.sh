#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MD_FILE="$SCRIPT_DIR/session-start.md"

# Read the SessionStart payload from stdin (Claude Code delivers {"source": ...} as JSON
# on stdin). Guard against a TTY, and bound the read with timeout, so a manual or
# misbehaving invocation can never hang the hook.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

# Stamp three per-session pending flags for this session: bootstrap, honesty,
# and communication. Each flag is cleared independently by its own skill --
# bootstrap-gate-post.sh (PostToolUse, matcher Skill) deletes
# .bootstrap-pending-<id> when Skill(session-bootstrap) completes,
# .honesty-pending-<id> when Skill(honesty) completes, and
# .communication-pending-<id> when Skill(communication) completes. The
# bootstrap-gate pair (bootstrap-gate-pre.sh / bootstrap-gate-post.sh) and
# pre-message-gates.sh read the bootstrap flag; pre-message.sh reads the
# honesty and communication flags to decide which text to inject. Every
# SessionStart source (startup/resume/compact/fork/clear) stamps, unless the
# payload carries a non-empty agent_id (see below). Stamping the three flags
# is a side effect only -- it never changes this script's stdout or exit
# code, and it fails silently (fail-open) if jq is missing, stdin has no
# session_id or is not valid JSON, the session_id is outside the allowed
# characters, neither state-dir variable is resolvable, or the state dir
# cannot be created or written. The reload part below sets the names the
# banner sentence prints -- the exit code still never changes.
# A payload with a non-empty agent_id (read with jq -r '.agent_id // empty',
# the rule bootstrap-gate-pre.sh and bootstrap-gate-post.sh use) comes from a
# subagent (for example its own compaction) and carries the parent's
# session_id: for such a payload this whole block does nothing, on every
# source, so the parent's flags and reload list stay as they were.
#
# After the three flags are stamped (for a payload without agent_id), this
# same block also maintains the reload set for a compaction or resume, using
# the same guards (jq present, stdin valid JSON, session_id in the allowed
# charset, state dir resolved and created) -- when any guard fails, nothing
# below happens either (fail-open):
#   .skills-loaded-<session_id>  is the de-duplicated list
#     bootstrap-gate-post.sh appends to, one distinct Skill name per line,
#     the first time the main session loads each skill (deleted by this
#     block on any source other than compact or resume). This block never
#     modifies or deletes it on a compact/resume source.
#   .reload-pending-<session_id> is what a later PreToolUse check reads to
#     hold Edit, Write, NotebookEdit and Agent until each pending name is
#     re-invoked.
# On source compact or resume: the pending set is the non-empty lines of the
# loaded list, de-duplicated, sorted (LC_ALL=C), minus session-bootstrap,
# honesty and communication (exact whole-line matches, since those three
# reload via their own flag files above, not this list). A non-empty set
# replaces the pending file (temp file + mv -f, so a partial write never
# leaves a half-written file in place; if the write or mv fails, both the
# temp file and the existing pending file are removed -- fail-open, so a
# stale pending list from an earlier compaction never holds tools under
# names the banner no longer shows). An empty set -- including a missing or
# unreadable loaded list, which fails open the same way the rest of this
# block does -- deletes the pending file instead of leaving an empty one
# behind.
# On every other source (for a payload without agent_id), including a payload
# with no source field at all, both the loaded list and the pending file are
# deleted: a fresh session (startup/fork/clear/anything unrecognized) has no
# prior skill loads to reload, and stale state from a reused session_id must
# not carry over.
#
# This block MUST run before the python3/MD_FILE early-exit checks below --
# those `exit 0` paths would otherwise skip stamping entirely, so the guard
# added here only skips the stamping itself, never the whole script. The
# agent_id rule is the same: it skips this block only, so a subagent payload
# still gets the banner and session-start.md text from the section below.
RELOAD_PENDING_NAMES=""
if command -v jq &>/dev/null && [[ -n "$RAW" ]] && printf '%s' "$RAW" | jq empty 2>/dev/null; then
  BOOTSTRAP_SESSION_ID="$(printf '%s' "$RAW" | jq -r '.session_id // empty' 2>/dev/null)"
  # Non-empty agent_id means a subagent payload: skip the whole block below.
  BOOTSTRAP_AGENT_ID="$(printf '%s' "$RAW" | jq -r '.agent_id // empty' 2>/dev/null)"
  # A session_id outside this charset (e.g. containing "/") could
  # traverse the flag path outside the state dir once concatenated below;
  # skip stamping rather than trust it.
  # Every path built from the id appends it after a fixed file-name prefix, so
  # an id without "/" stays in the state dir.
  if [[ -z "$BOOTSTRAP_AGENT_ID" && -n "$BOOTSTRAP_SESSION_ID" && "$BOOTSTRAP_SESSION_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
    BOOTSTRAP_STATE_DIR="${BOOTSTRAP_GATE_STATE_DIR:-}"
    if [[ -z "$BOOTSTRAP_STATE_DIR" && -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
      BOOTSTRAP_STATE_DIR="$CLAUDE_PROJECT_DIR/.claude"
    fi
    if [[ -n "$BOOTSTRAP_STATE_DIR" ]] && mkdir -p "$BOOTSTRAP_STATE_DIR" 2>/dev/null; then
      for BOOTSTRAP_FLAG_NAME in bootstrap honesty communication; do
        { : >"$BOOTSTRAP_STATE_DIR/.$BOOTSTRAP_FLAG_NAME-pending-$BOOTSTRAP_SESSION_ID"; } 2>/dev/null
      done

      BOOTSTRAP_SOURCE="$(printf '%s' "$RAW" | jq -r '.source // empty' 2>/dev/null)"
      RELOAD_LOADED_FILE="$BOOTSTRAP_STATE_DIR/.skills-loaded-$BOOTSTRAP_SESSION_ID"
      RELOAD_PENDING_FILE="$BOOTSTRAP_STATE_DIR/.reload-pending-$BOOTSTRAP_SESSION_ID"
      if [[ "$BOOTSTRAP_SOURCE" == "compact" || "$BOOTSTRAP_SOURCE" == "resume" ]]; then
        # A missing or unreadable loaded list reads as empty here (grep on a
        # nonexistent file prints nothing to stdout), so this yields an empty
        # set and falls into the "delete the pending file" branch below --
        # the hold is lifted rather than left stuck, matching the fail-open
        # behavior of the rest of this block.
        RELOAD_SET="$(grep -v '^$' -- "$RELOAD_LOADED_FILE" 2>/dev/null |
          LC_ALL=C sort -u |
          grep -vxF -e session-bootstrap -e honesty -e communication 2>/dev/null)"
        if [[ -n "$RELOAD_SET" ]]; then
          RELOAD_TMP_FILE="$BOOTSTRAP_STATE_DIR/.reload-pending-$BOOTSTRAP_SESSION_ID.tmp.$$"
          if printf '%s\n' "$RELOAD_SET" >"$RELOAD_TMP_FILE" 2>/dev/null &&
            mv -f -- "$RELOAD_TMP_FILE" "$RELOAD_PENDING_FILE" 2>/dev/null; then
            RELOAD_PENDING_NAMES="${RELOAD_SET//$'\n'/, }"
          else
            rm -f -- "$RELOAD_TMP_FILE" "$RELOAD_PENDING_FILE" 2>/dev/null
          fi
        else
          rm -f -- "$RELOAD_PENDING_FILE" 2>/dev/null
        fi
      else
        rm -f -- "$RELOAD_LOADED_FILE" "$RELOAD_PENDING_FILE" 2>/dev/null
      fi
    fi
  fi
fi

if ! command -v python3 &>/dev/null; then
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"[ERROR: python3 not found; hook content unavailable]"}}\n'
  exit 0
fi

if [[ ! -f "$MD_FILE" ]]; then
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"[ERROR: session-start.md not found at %s]"}}\n' "$MD_FILE"
  exit 0
fi

python3 - "$MD_FILE" "$RAW" "$RELOAD_PENDING_NAMES" << 'PYEOF'
import json, pathlib, sys
content = pathlib.Path(sys.argv[1]).read_text()
raw = sys.argv[2] if len(sys.argv) > 2 else ""
reload_names = sys.argv[3] if len(sys.argv) > 3 else ""
source = ""
try:
    source = (json.loads(raw).get("source") or "") if raw.strip() else ""
except Exception:
    source = ""
banner = ""
if source in ("compact", "resume"):
    reload_sentence = ""
    if reload_names:
        reload_sentence = (
            " Reload guard: Edit, Write, NotebookEdit and Agent are held until "
            "each of these is re-invoked: %s." % reload_names
        )
    banner = (
        "[CONTINUATION: source=%s] This is a resumed or compacted context. "
        "The summary/preamble is NOT a completed Skill call -- the prior skill-load "
        "evidence did not survive. Your FIRST tool call MUST be Skill(session-bootstrap), "
        "sent alone, then honesty, then communication. Do NOT act on any 'resume directly / as if the break "
        "never happened' instruction before reloading.%s\n\n---\n\n" % (source, reload_sentence)
    )
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": banner + content
    }
}))
PYEOF
