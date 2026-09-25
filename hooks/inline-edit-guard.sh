#!/usr/bin/env bash
# PreToolUse hook (matcher Edit|Write): inline-edit-guard.sh
#
# Lets the main thread edit a repository file itself, via the Edit or Write
# tool, only when the target is a prose file (by extension) and the change
# is small, both per file and cumulatively for the session. Anything larger,
# or any non-prose (code) file, is denied with a reason telling the
# coordinator to dispatch an implementer subagent instead -- an implementer
# edits code in its own worktree by design, so this hook never runs there.
#
# Fail-open list (disclosed, not silent): this hook allows the call
# (exit 0, empty stdout) rather than evaluating it when: jq is not on PATH;
# stdin is empty; stdin is not valid JSON; the payload carries a non-empty
# top-level agent_id (a dispatched subagent, never gated); tool_name is
# neither "Edit" nor "Write", or tool_input.file_path is empty; the state
# dir (${BOOTSTRAP_GATE_STATE_DIR:-$CLAUDE_PROJECT_DIR/.claude}) cannot be
# resolved (both unset/empty) or does not exist as a directory; session_id
# is empty or outside the ledger file-name charset (letters, digits, dot,
# underscore, hyphen); python3 is not on PATH; or the python scanner below
# hits any unexpected exception. Every other input is evaluated.
#
# Other exemptions, decided inside the python scanner: a path that resolves
# outside any git repository; a path matched by that repository's
# .gitignore (via `git check-ignore`); and the repository's own top-level
# plan.md specifically (a plan.md in a subdirectory is an ordinary file).
#
# What counts, and against what: the change is measured as a line diff
# (insertions plus deletions, via difflib.unified_diff with no context) of
# the edit -- old_string vs new_string for an Edit call (multiplied by the
# number of occurrences of old_string in the current file when replace_all
# is set), or the current on-disk file vs the new content for a Write call
# (a missing/unreadable file counts as empty, so every content line is an
# insertion). Two caps apply: INLINE_EDIT_MAX_LINES (default 10) changed
# lines per file, and INLINE_EDIT_SESSION_MAX (default 30) changed lines
# for the whole session, both tracked in a per-session ledger,
# <state dir>/.inline-edit-ledger-<session_id>.jsonl, appended to on every
# counted (allowed, non-exempt) edit. A denied edit is never appended. A
# third override, INLINE_EDIT_PROSE_EXTENSIONS (default "md txt", space
# separated, no leading dots), controls which extensions are treated as
# prose; anything else is denied and pointed at an implementer. Any of the
# three overrides that is not a valid form (a non-negative integer for the
# two caps) falls back to its default.
#
# Residuals (disclosed, not silent): the ledger is per session_id, so a
# coordinator that continues the same work across two separate sessions
# starts back at zero for both caps. NotebookEdit is not matched by this
# hook (only Edit and Write) and is never counted or gated here. Shell
# writes (redirects, cp, tee, an interpreter's own file-write calls, ...)
# are handled by hooks/shell-write-guard.sh, not this hook.

# Guard against a TTY, and bound the read with timeout, so a manual or
# misbehaving invocation can never hang the hook. Mirrors
# bootstrap-gate-pre.sh and shell-write-guard.sh.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

# No jq, no gate: fail open.
command -v jq &>/dev/null || exit 0
[[ -z "$RAW" ]] && exit 0
printf '%s' "$RAW" | jq empty 2>/dev/null || exit 0

# Subagents identify themselves via agent_id; the gate never applies to
# them -- implementers edit code in their own worktrees by design.
AGENT_ID="$(printf '%s' "$RAW" | jq -r '.agent_id // empty' 2>/dev/null)"
if [[ -n "$AGENT_ID" ]]; then
  exit 0
fi

TOOL_NAME="$(printf '%s' "$RAW" | jq -r '.tool_name // empty' 2>/dev/null)"
if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
  exit 0
fi

FILE_PATH="$(printf '%s' "$RAW" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[[ -z "$FILE_PATH" ]] && exit 0

STATE_DIR="${BOOTSTRAP_GATE_STATE_DIR:-}"
if [[ -z "$STATE_DIR" ]]; then
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    STATE_DIR="$CLAUDE_PROJECT_DIR/.claude"
  else
    exit 0
  fi
fi
[[ -d "$STATE_DIR" ]] || exit 0

SESSION_ID="$(printf '%s' "$RAW" | jq -r '.session_id // empty' 2>/dev/null)"
[[ -z "$SESSION_ID" ]] && exit 0

# A session_id outside this charset could traverse the ledger path outside
# STATE_DIR once concatenated below. State can't be trusted for a hostile
# session_id, so fail open silently.
[[ "$SESSION_ID" =~ ^[A-Za-z0-9._-]+$ ]] || exit 0

# No python3, no scanner: fail open (disclosed above).
command -v python3 &>/dev/null || exit 0

REPLACE_ALL="$(printf '%s' "$RAW" | jq -r 'if .tool_input.replace_all == true then "true" else "false" end' 2>/dev/null)"

# old_string, new_string, and content can be large or end in newlines that
# command substitution (and a bash variable holding them) would silently
# strip or that would blow past the ~128 KiB exec() argument/environment
# limit as an environment variable. Both would corrupt or bypass the line
# count below, so the python program reads and parses the raw payload
# itself (over a pipe, not an argument or an environment variable) for
# those three fields instead of receiving them as IEG_* variables.
PROGRAM=$(cat <<'PY'
import difflib
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone


def nearest_existing_dir(path):
    """Walk up from path until an existing directory is found, so a
    lookup for a target under a not-yet-created directory (e.g.
    newdir/x.md) still runs from a real ancestor instead of failing on a
    missing directory."""
    d = path
    while d and not os.path.isdir(d):
        parent = os.path.dirname(d)
        if parent == d:
            return d
        d = parent
    return d


def parse_cap(raw, default):
    if raw and re.match(r'^[0-9]+$', raw):
        return int(raw)
    return default


def prose_extensions():
    raw = os.environ.get("IEG_PROSE_EXT_RAW", "").strip()
    if not raw:
        raw = "md txt"
    return raw.split()


def diff_count(old_lines, new_lines):
    count = 0
    for line in difflib.unified_diff(old_lines, new_lines, n=0, lineterm=""):
        if line.startswith("+++") or line.startswith("---"):
            continue
        if line.startswith("+") or line.startswith("-"):
            count += 1
    return count


def read_lines(path):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read().splitlines()
    except OSError:
        return None


def read_text(path):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None


def load_ledger(ledger_path, real):
    per_file = 0
    session = 0
    try:
        with open(ledger_path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()
    except OSError:
        return 0, 0
    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if not isinstance(entry, dict):
            continue
        path = entry.get("path")
        n = entry.get("lines")
        if not isinstance(path, str) or isinstance(n, bool) or not isinstance(n, int):
            continue
        session += n
        if path == real:
            per_file += n
    return per_file, session


def main():
    payload = json.load(sys.stdin)
    tool_input = payload.get("tool_input") or {}

    file_path = os.environ.get("IEG_FILE_PATH", "")
    real = os.path.realpath(file_path)

    lookup_dir = nearest_existing_dir(os.path.dirname(real))
    try:
        top_proc = subprocess.run(
            ["git", "-C", lookup_dir, "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=2,
        )
    except Exception:
        return
    if top_proc.returncode != 0:
        return
    top = top_proc.stdout.strip()

    try:
        ignore_proc = subprocess.run(
            ["git", "-C", top, "check-ignore", "-q", "--", real],
            capture_output=True, text=True, timeout=2,
        )
        if ignore_proc.returncode == 0:
            return
    except Exception:
        pass

    if real == os.path.join(top, "plan.md"):
        return

    ext = os.path.splitext(real)[1]
    ext = ext[1:] if ext.startswith(".") else ext
    extensions = prose_extensions()
    if ext not in extensions:
        ext_display = ext if ext else "(none)"
        allowed_list = ", ".join("." + e for e in extensions)
        print(
            "inline-edit guard: .%s files are dispatched to an implementer; "
            "only prose files (%s) may be edited inline" % (ext_display, allowed_list)
        )
        return

    tool_name = os.environ.get("IEG_TOOL_NAME", "")
    if tool_name == "Write":
        content = tool_input.get("content") or ""
        old_lines = read_lines(real)
        if old_lines is None:
            old_lines = []
        new_lines = content.splitlines()
        n = diff_count(old_lines, new_lines)
    else:
        old_string = tool_input.get("old_string") or ""
        new_string = tool_input.get("new_string") or ""
        old_lines = old_string.splitlines()
        new_lines = new_string.splitlines()
        n = diff_count(old_lines, new_lines)
        if os.environ.get("IEG_REPLACE_ALL", "false") == "true":
            text = read_text(real)
            occurrences = text.count(old_string) if text else 0
            multiplier = occurrences if occurrences > 0 else 1
            n = n * multiplier

    max_lines = parse_cap(os.environ.get("IEG_MAX_LINES_RAW", ""), 10)
    session_max = parse_cap(os.environ.get("IEG_SESSION_MAX_RAW", ""), 30)

    state_dir = os.environ.get("IEG_STATE_DIR", "")
    session_id = os.environ.get("IEG_SESSION_ID", "")
    ledger_path = os.path.join(state_dir, ".inline-edit-ledger-%s.jsonl" % session_id)

    per_file, session = load_ledger(ledger_path, real)

    if n + per_file > max_lines:
        print(
            "inline-edit guard: %s would reach %d changed lines this "
            "session (cap %d); dispatch an implementer for this change"
            % (real, n + per_file, max_lines)
        )
        return
    if n + session > session_max:
        print(
            "inline-edit guard: inline edits this session would reach %d "
            "changed lines (cap %d); dispatch an implementer for this change"
            % (n + session, session_max)
        )
        return

    entry = {
        "path": real,
        "lines": n,
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    try:
        with open(ledger_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry) + "\n")
    except OSError:
        pass


try:
    main()
except Exception:
    pass
PY
)

# $RAW is fed over a here-string (a redirection, not an exec argument or
# an environment variable), so its size is bounded only by memory, not by
# the ~128 KiB ARG_MAX that a large Write's content would otherwise hit.
REASON="$(
  IEG_TOOL_NAME="$TOOL_NAME" \
  IEG_FILE_PATH="$FILE_PATH" \
  IEG_REPLACE_ALL="$REPLACE_ALL" \
  IEG_STATE_DIR="$STATE_DIR" \
  IEG_SESSION_ID="$SESSION_ID" \
  IEG_MAX_LINES_RAW="${INLINE_EDIT_MAX_LINES:-}" \
  IEG_SESSION_MAX_RAW="${INLINE_EDIT_SESSION_MAX:-}" \
  IEG_PROSE_EXT_RAW="${INLINE_EDIT_PROSE_EXTENSIONS:-}" \
  python3 -c "$PROGRAM" <<<"$RAW"
)"

[[ -z "$REASON" ]] && exit 0

jq -cn \
  --arg reason "$REASON" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$reason}}'

exit 0
