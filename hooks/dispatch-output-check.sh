#!/usr/bin/env bash
# dispatch-output-check.sh -- PostToolUse (Agent) and SubagentStop hook.
#
# Joins the two events of one subagent dispatch by agent id and appends one
# JSON record line per pairing to $STATE/dispatch-check-records.jsonl, where
# STATE is $DISPATCH_CHECK_STATE_DIR (default $CLAUDE_PROJECT_DIR/.claude).
# PostToolUse carries the agent id as tool_response.agentId and SubagentStop
# as agent_id. Either event can arrive first: the first one is parked as
# $STATE/.dispatch-check-pending/<agent id>; the second claims it with an
# atomic mv and writes the record. A SubagentStop with no PostToolUse never
# produces a record. Parked files older than 1 hour are swept on every run.
#
# The dispatch message lines `Dispatch id:` and `Output path:` are read from
# tool_input.prompt (each optional). The verdict is always pass with an empty
# failed list until the checks are added.
#
# Fail closed, never block: the hook always exits 0 with empty stdout. Missing
# jq or unparseable stdin writes a message to stderr and a fail record.

STATE="${DISPATCH_CHECK_STATE_DIR:-${CLAUDE_PROJECT_DIR:-.}/.claude}"
RECORDS="$STATE/dispatch-check-records.jsonl"
PENDING="$STATE/.dispatch-check-pending"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- read payload -----------------------------------------------------------

event_name() {
  jq -r '.hook_event_name // empty' <<<"$1"
}

# Prints the agent id this event joins on, or nothing when the event is not
# a dispatch event or the id is unusable as a file name.
event_agent_id() {
  local payload="$1" event agent_id=""
  event="$(event_name "$payload")"
  if [[ "$event" == "SubagentStop" ]]; then
    agent_id="$(jq -r '.agent_id // empty' <<<"$payload")"
  elif [[ "$event" == "PostToolUse" && "$(jq -r '.tool_name // empty' <<<"$payload")" == "Agent" ]]; then
    agent_id="$(jq -r '.tool_response.agentId // empty' <<<"$payload")"
  fi
  [[ "$agent_id" == */* ]] && agent_id=""
  printf '%s' "$agent_id"
}

# First line of the dispatch message that starts with the given label.
message_line() {
  sed -n "s/^$2: *//p" <<<"$1" | head -n 1 | tr -d '\r'
}

# --- park and claim ---------------------------------------------------------

sweep_stale_pending() {
  find "$PENDING" -type f -mmin +60 -delete 2>/dev/null
}

# Parks the payload at $PENDING/<id> with an atomic create-if-absent (ln
# fails when the name exists). Uses the file $3 for staging and removes it.
park_payload() {
  local payload="$1" id="$2" staging="$3" status
  printf '%s' "$payload" >"$staging" && ln "$staging" "$PENDING/$id" 2>/dev/null
  status=$?
  rm -f "$staging"
  return "$status"
}

# Claims the parked event into the file $3. With none parked, parks ours;
# losing that race means the other event is now parked, so loop and claim it.
# Returns 0 only when a parked event was claimed.
claim_parked() {
  local payload="$1" id="$2" claim="$3"
  for _ in 1 2 3; do
    if mv "$PENDING/$id" "$claim" 2>/dev/null; then
      return 0
    fi
    park_payload "$payload" "$id" "$claim" && return 1
  done
  return 1
}

# --- build and append record ------------------------------------------------

build_record() {
  local id="$1" post="$2" prompt dispatch_id output_path type
  prompt="$(jq -r '.tool_input.prompt // empty' <<<"$post")"
  dispatch_id="$(message_line "$prompt" 'Dispatch id')"
  output_path="$(message_line "$prompt" 'Output path')"
  type="$(jq -r '.tool_input.subagent_type // "unknown"' <<<"$post")"
  jq -n -c --arg d "$dispatch_id" --arg a "$id" --arg s "$type" \
    --arg o "$output_path" --arg t "$now" \
    '{dispatch_id:$d,agent_id:$a,subagent_type:$s,verdict:"pass",failed:[],time:$t}
     | if $o == "" then . else .output_path = $o end'
}

append_record() {
  printf '%s\n' "$1" >>"$RECORDS"
}

# --- fail closed ------------------------------------------------------------

fail_closed() {
  local message="$1" reason="$2"
  echo "dispatch-output-check: $message" >&2
  if command -v jq >/dev/null 2>&1; then
    jq -n -c --arg r "$reason" --arg t "$now" \
      '{verdict:"fail",failed:[$r],time:$t}' >>"$RECORDS" 2>/dev/null
  else
    printf '{"verdict":"fail","failed":["%s"],"time":"%s"}\n' "$reason" "$now" >>"$RECORDS" 2>/dev/null
  fi
}

# --- main -------------------------------------------------------------------

main() {
  local payload id claim parked post
  payload="$(cat)"
  mkdir -p "$PENDING" 2>/dev/null
  sweep_stale_pending

  if ! command -v jq >/dev/null 2>&1; then
    fail_closed "jq not found; cannot check dispatch" "jq missing"
    return 0
  fi
  if ! jq -e . >/dev/null 2>&1 <<<"$payload"; then
    fail_closed "stdin is not valid JSON" "bad json"
    return 0
  fi

  id="$(event_agent_id "$payload")"
  [[ -z "$id" ]] && return 0

  claim="$PENDING/$id.claim.$$"
  claim_parked "$payload" "$id" "$claim" || return 0
  parked="$(cat "$claim")"
  if [[ "$(event_name "$parked")" == "$(event_name "$payload")" ]]; then
    # A duplicate of the parked kind: replace it with ours.
    park_payload "$payload" "$id" "$claim"
    return 0
  fi
  rm -f "$claim"

  post="$payload"
  [[ "$(event_name "$payload")" == "SubagentStop" ]] && post="$parked"
  append_record "$(build_record "$id" "$post")"
}

main
exit 0
