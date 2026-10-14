#!/usr/bin/env bash
# PreToolUse hook (matcher *): bootstrap-gate-pre.sh
#
# Runs two gates in order, for every PreToolUse call in the main session:
#
# 1. Bootstrap gate (first, every tool). Blocks (deny mode) or nudges (warn
#    mode) tool use in a session that has not yet completed
#    Skill(session-bootstrap), as recorded by a
#    .bootstrap-pending-<session_id> flag file that hooks/session-start.sh
#    stamps on every SessionStart whose payload has no non-empty agent_id
#    (a subagent payload stamps nothing) and hooks/bootstrap-gate-post.sh
#    clears once the session-bootstrap Skill call completes. While this
#    flag is present and the call is not the Skill(session-bootstrap) call
#    itself, this gate alone decides the outcome and the reload gate below
#    never runs.
#
# 2. Reload gate (second, only Edit, Write, NotebookEdit, Agent and Bash).
#    After a compaction or resume, hooks/session-start.sh writes the skills
#    to re-invoke into .reload-pending-<session_id>, one per line: the
#    session's role skill (if any) followed by five action skills.
#    hooks/bootstrap-gate-post.sh removes a name from that file each time the
#    matching Skill call completes. This gate runs once the bootstrap flag is
#    absent, or the call is the Skill(session-bootstrap) call. Each pending
#    name holds only the call it guards:
#      - role name (running-a-sprint): holds Edit, Write, NotebookEdit, Agent;
#        never Bash.
#      - subagent-driven-development, using-git-worktrees: hold Agent.
#      - writing-skills: holds Edit, Write, NotebookEdit when the path field
#        (tool_input.file_path, else tool_input.notebook_path) has a directory
#        named skills or agents anywhere in it; an absent or empty path never
#        triggers it.
#      - versioning, verification-before-completion: hold Bash, and only a
#        Bash command that runs git commit or gh pr create at command
#        position (start of the command, or after ;, &, |, ( or $( ; with
#        optional VAR=value prefixes and the git or gh options listed at
#        BASH_COMMIT_RE and BASH_PR_RE). Text inside a well-formed quoted
#        span is not matched. The command is read and scanned only when one
#        of these two names is pending, so every other Bash call exits
#        before looking at it. In a UTF-8 locale GNU grep 3.12 takes about
#        1.6 s to scan a 200,000-character unbroken word followed by
#        ' git commit' or ' gh pr create' (0.09 s at 50,000). A lone long
#        word, and the same input in the C locale (0.03 s), scan quickly;
#        ordinary commands are far below this. A role name never holds
#        Bash.
#        The Bash hold misses by design: git push, gh pr merge, edit and
#        ready, gh api, MCP pull-request tools, bash -c '...', aliases, and
#        command git commit; a command behind a wrapper (time, env FOO=1,
#        sudo, nohup, xargs), behind a compound-command keyword or brace (if
#        ...; then, { ...; }, ! git commit), or inside backticks; a real git
#        commit that follows a quote with no partner, which can be missed: an
#        escaped quote (\" or \') anywhere in the command, or an apostrophe
#        or an unpaired double quote (5" screen) in a # comment or in a
#        heredoc body on an earlier line (the single quote-stripping pass
#        pairs such a stray quote with the next quote of the same kind, which
#        can shift the pairing of the later quotes of that kind, so unquoted
#        text between later quoted spans can be hidden too; with no later
#        quote of that kind nothing is hidden); option spellings other than
#        the listed ones (git --git-dir .git commit,
#        gh --repo=o/r pr create); and a redirection attached to the
#        subcommand (git commit>out). It also over-holds a heredoc body line
#        that starts with git commit or gh pr create, whatever quoting the
#        delimiter has (<<EOF or <<'EOF'), unless quote pairing (above) hides
#        it.
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

# Reload gate: only Edit, Write, NotebookEdit, Agent and Bash can be held;
# every other tool exits 0 silently.
case "$TOOL_NAME" in
  Edit | Write | NotebookEdit | Agent | Bash) ;;
  *) exit 0 ;;
esac

PENDING_FILE="$STATE_DIR/.reload-pending-$SESSION_ID"
# A missing or unreadable file reads as empty (grep prints nothing), and a
# file with only empty lines also reduces to empty here -- both fail open
# silently.
PENDING_NAMES="$(grep -v '^$' -- "$PENDING_FILE" 2>/dev/null)"
[[ -z "$PENDING_NAMES" ]] && exit 0

# Bash is held only by versioning and verification-before-completion. Cost of
# a Bash call: one grep of the pending file; one more grep when that file has
# names; the command is read and scanned only when versioning or
# verification-before-completion is pending, otherwise this exits first.
if [[ "$TOOL_NAME" == "Bash" ]]; then
  grep -qxE 'versioning|verification-before-completion' <<<"$PENDING_NAMES" || exit 0
fi

# Command-position patterns for the Bash hold (grep -E, no \b or other
# non-portable escapes). A command starts at the beginning of the string or
# after ; & | or (, which also covers && || and $( ; optional VAR=value
# assignments may precede it. The end set after commit and create is a
# space, ; & | ), or the end of the string, so commit-tree and commit-graph
# do not match.
BASH_START='(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
BASH_END='($|[[:space:];&|)])'
BASH_COMMIT_RE="${BASH_START}git[[:space:]]+(((-C|-c)[[:space:]]+[^[:space:]]+|--git-dir=[^[:space:]]+|--work-tree=[^[:space:]]+|--no-pager|-P)[[:space:]]+)*commit${BASH_END}"
BASH_PR_RE="${BASH_START}gh[[:space:]]+((-R|--repo)[[:space:]]+[^[:space:]]+[[:space:]]+)*pr[[:space:]]+create${BASH_END}"

# bash_command_hits: succeeds when .tool_input.command (a non-empty string)
# runs git commit or gh pr create. Newlines become ; (a newline separates
# commands, and quoted spans can cross lines), then each double- or
# single-quoted span is replaced by Q in ONE sed pass; the leftmost span
# wins, so an apostrophe inside double quotes does not open a span.
bash_command_hits() {
  local cmd
  cmd="$(printf '%s' "$RAW" | jq -r \
    '.tool_input.command | select(type == "string") // empty' 2>/dev/null)"
  [[ -z "$cmd" ]] && return 1
  cmd="$(printf '%s' "$cmd" | tr '\n' ';' | sed -E "s/\"[^\"]*\"|'[^']*'/Q/g")"
  printf '%s' "$cmd" | grep -qE -e "$BASH_COMMIT_RE" -e "$BASH_PR_RE"
}
BASH_HIT=0
if [[ "$TOOL_NAME" == "Bash" ]] && bash_command_hits; then
  BASH_HIT=1
fi

# Path field for the writing-skills hold: the first non-empty string of
# file_path, else notebook_path. Edit, Write and NotebookEdit only.
TARGET_PATH=""
if [[ "$TOOL_NAME" != "Agent" && "$TOOL_NAME" != "Bash" ]]; then
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
# A role name holds every handled tool except Bash.
# subagent-driven-development and using-git-worktrees hold Agent.
# writing-skills holds Edit, Write and NotebookEdit on a skills or agents
# path. versioning and verification-before-completion hold a Bash call whose
# command runs git commit or gh pr create (BASH_HIT, set above).
holds_call() {
  if is_role "$1"; then
    [[ "$TOOL_NAME" != "Bash" ]]
    return
  fi
  case "$1" in
    versioning | verification-before-completion)
      [[ "$TOOL_NAME" == "Bash" && "$BASH_HIT" -eq 1 ]]
      ;;
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
