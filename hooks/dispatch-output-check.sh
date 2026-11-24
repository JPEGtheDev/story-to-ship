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
# tool_input.prompt (each optional). Each check appends to the failed list;
# the verdict is fail when the list is non-empty.
#
# Fail closed, never block: the hook always exits 0 with empty stdout. Missing
# jq, unparseable stdin or a payload that is not a JSON object writes a
# message to stderr and a fail record. A records file that cannot be written
# gives the stderr message `cannot write records file` for a paired record
# only; on the fail-closed path a failed write adds no output of its own.

STATE="${DISPATCH_CHECK_STATE_DIR:-${CLAUDE_PROJECT_DIR:-.}/.claude}"
RECORDS="$STATE/dispatch-check-records.jsonl"
PENDING="$STATE/.dispatch-check-pending"
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- read payload -----------------------------------------------------------

event_name() {
  jq -r '.hook_event_name // empty' <<<"$1" 2>/dev/null
}

# Prints the agent id this event joins on, or nothing when the event is not
# a dispatch event or the id is unusable as a file name. Returns 1 when a
# jq read fails (a field of the wrong type); jq never prints an error.
event_agent_id() {
  local payload="$1" event tool agent_id=""
  event="$(event_name "$payload")" || return 1
  if [[ "$event" == "SubagentStop" ]]; then
    agent_id="$(jq -r '.agent_id // empty' <<<"$payload" 2>/dev/null)" || return 1
  elif [[ "$event" == "PostToolUse" ]]; then
    tool="$(jq -r '.tool_name // empty' <<<"$payload" 2>/dev/null)" || return 1
    if [[ "$tool" == "Agent" ]]; then
      agent_id="$(jq -r '.tool_response.agentId // empty' <<<"$payload" 2>/dev/null)" || return 1
    fi
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
# losing that race, or re-parking over a duplicate of our own kind while the
# slot filled meanwhile, means the other event is now parked: claim again, up
# to 3 attempts. Returns 0 only when a parked event of the other kind was
# claimed (it is left in $3).
claim_parked() {
  local payload="$1" id="$2" claim="$3"
  for _ in 1 2 3; do
    if mv "$PENDING/$id" "$claim" 2>/dev/null; then
      if [[ "$(event_name "$(cat "$claim")")" != "$(event_name "$payload")" ]]; then
        return 0
      fi
      # A duplicate of the parked kind: replace it with ours.
    fi
    park_payload "$payload" "$id" "$claim" && return 1
  done
  return 1
}

# --- build and append record ------------------------------------------------

# The directory a relative path is resolved in: the SubagentStop payload cwd,
# else the PostToolUse payload cwd, else the current directory.
payload_cwd() {
  local dir="" payload
  for payload in "$1" "$2"; do
    dir="$(jq -r '.cwd // empty' <<<"$payload" 2>/dev/null)" || return 1
    [[ -n "$dir" ]] && break
  done
  printf '%s' "${dir:-.}"
}

# Each check appends its failure strings to the array "failed" of the caller.
check_output_path() {
  local path="$1" cwd="$2" full="$1"
  [[ -z "$path" ]] && return 0
  if [[ "$path" == *[\{\}\<\>]* ]]; then
    failed+=("output path has a placeholder: $path")
    return 0
  fi
  [[ "$path" != /* ]] && full="$cwd/$path"
  if [[ ! -f "$full" ]]; then
    failed+=("output file missing: $path")
  fi
}

# True when the literal string $2 occurs in $1 not adjacent to a letter or
# digit on either side.
has_whole_token() {
  local rest="$1" id="$2" prev="" before after left
  while [[ "$rest" == *"$id"* ]]; do
    before="${rest%%"$id"*}"
    after="${rest#*"$id"}"
    left="${before: -1}"
    [[ -z "$before" ]] && left="$prev"
    if [[ ! "$left" =~ [[:alnum:]] && ! "${after:0:1}" =~ [[:alnum:]] ]]; then
      return 0
    fi
    prev="${id:0:1}"
    rest="${id:1}${after}"
  done
  return 1
}

# Checks that the first line of the output file carries the dispatch id.
# Runs only for an existing regular file at a path without a placeholder.
check_output_owner() {
  local path="$1" cwd="$2" id="$3" full="$1" first=""
  [[ -z "$path" || -z "$id" || "$path" == *[\{\}\<\>]* ]] && return 0
  [[ "$path" != /* ]] && full="$cwd/$path"
  [[ -f "$full" ]] || return 0
  IFS= read -r first <"$full" || true
  first="${first%$'\r'}"
  if [[ ! "$first" =~ [^[:space:]] ]]; then
    failed+=("output first line is empty: $path")
  elif ! has_whole_token "$first" "$id"; then
    failed+=("output first line lacks Dispatch id $id")
  fi
}

# build_record ID POST STOP: POST and STOP are the two parked payloads.
build_record() {
  local id="$1" post="$2" stop="$3" prompt dispatch_id output_path type cwd note=""
  local -a failed=()
  prompt="$(jq -r '.tool_input.prompt // empty' <<<"$post" 2>/dev/null)" || return 1
  dispatch_id="$(message_line "$prompt" 'Dispatch id')"
  output_path="$(message_line "$prompt" 'Output path' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  type="$(jq -r '.tool_input.subagent_type // "unknown"' <<<"$post" 2>/dev/null)" || return 1
  cwd="$(payload_cwd "$stop" "$post")" || return 1
  check_output_path "$output_path" "$cwd"
  check_output_owner "$output_path" "$cwd" "$dispatch_id"
  [[ -n "$output_path" && -z "$dispatch_id" ]] && note="ownership not checked"
  printf '%s\n' "${failed[@]}" | jq -n -c -R --arg d "$dispatch_id" --arg a "$id" \
    --arg s "$type" --arg o "$output_path" --arg t "$now" --arg n "$note" \
    '[inputs | select(. != "")] as $f
     | {dispatch_id:$d,agent_id:$a,subagent_type:$s,
        verdict:(if ($f | length) > 0 then "fail" else "pass" end),failed:$f,time:$t}
     | if $o == "" then . else .output_path = $o end
     | if $n == "" then . else .note = $n end' 2>/dev/null
}

append_record() {
  if ! { printf '%s\n' "$1" >>"$RECORDS"; } 2>/dev/null; then
    echo "dispatch-output-check: cannot write records file" >&2
  fi
}

# --- fail closed ------------------------------------------------------------

# fail_closed MESSAGE REASON [AGENT_ID]: one stderr line, one fail record.
# With an agent id the record also carries agent_id, dispatch_id and
# subagent_type. A failed write adds no output of its own.
fail_closed() {
  local message="$1" reason="$2" agent_id="${3:-}" record
  echo "dispatch-output-check: $message" >&2
  if command -v jq >/dev/null 2>&1; then
    record="$(jq -n -c --arg r "$reason" --arg t "$now" --arg a "$agent_id" \
      '{verdict:"fail",failed:[$r],time:$t}
       | if $a == "" then . else {dispatch_id:"",agent_id:$a,subagent_type:"unknown"} + . end' 2>/dev/null)"
  else
    record="$(printf '{"verdict":"fail","failed":["%s"],"time":"%s"}' "$reason" "$now")"
  fi
  { printf '%s\n' "$record" >>"$RECORDS"; } 2>/dev/null
}

# --- main -------------------------------------------------------------------

main() {
  local payload id claim parked post stop record
  payload="$(cat)"
  mkdir -p "$PENDING" 2>/dev/null
  if [[ ! -d "$PENDING" || ! -w "$PENDING" ]]; then
    echo "dispatch-output-check: state dir $PENDING is not a writable directory" >&2
    return 0
  fi
  sweep_stale_pending

  if ! command -v jq >/dev/null 2>&1; then
    fail_closed "jq not found; cannot check dispatch" "jq missing"
    return 0
  fi
  if ! jq empty >/dev/null 2>&1 <<<"$payload"; then
    fail_closed "stdin is not valid JSON" "bad json"
    return 0
  fi
  if ! jq -e 'type == "object"' >/dev/null 2>&1 <<<"$payload"; then
    fail_closed "stdin is not a JSON object" "bad payload"
    return 0
  fi

  id="$(event_agent_id "$payload")" || {
    fail_closed "bad payload" "bad payload"
    return 0
  }
  [[ -z "$id" ]] && return 0

  claim="$PENDING/$id.claim.$$"
  claim_parked "$payload" "$id" "$claim" || return 0
  parked="$(cat "$claim")"
  rm -f "$claim"

  post="$payload"
  stop="$parked"
  if [[ "$(event_name "$payload")" == "SubagentStop" ]]; then
    post="$parked"
    stop="$payload"
  fi
  record="$(build_record "$id" "$post" "$stop")" || {
    fail_closed "bad payload" "bad payload" "$id"
    return 0
  }
  append_record "$record"
}

main
exit 0
