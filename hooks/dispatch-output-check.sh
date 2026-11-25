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
# The dispatch message lines `Dispatch id:`, `Output path:` and `Source path:`
# are read from tool_input.prompt (each optional). The checks are:
# - the Output path file exists and is readable, and its first line carries
#   the dispatch id;
# - the output (that file, else the last assistant message) has a line for
#   each field the agent template declares as output-fields;
# - the quotes check: each quote the template declares as output-quotes must
#   occur in the file named by the `Source path:` line, both normalized
#   (markup removed, whitespace collapsed).
# Each check appends to the failed list; the verdict is fail when the list is
# non-empty. A check that has nothing to run adds a note to the record
# instead: "no template" without a template, "no declarations" when the
# template declares neither key, and "ownership not checked" for an Output
# path with no Dispatch id. A quotes check that cannot read its source, or
# whose source ends mid-sentence, fails instead.
#
# Fail closed, never block: the hook always exits 0. Its stdout is empty
# except for the line described under "Surfacing a failure". Missing jq,
# unparseable stdin or a payload that is not a JSON object writes a message
# to stderr and a fail record. A records file that cannot be written gives
# the stderr message `cannot write records file` for a paired record only;
# on the fail-closed path a failed write adds no output of its own.
#
# Surfacing a failure: when PostToolUse is the second event and the record's
# verdict is fail, stdout gets one compact JSON line, a hookSpecificOutput
# with additionalContext "Dispatch output check failed (agent <id>): <failed
# strings joined with "; ">". That line is printed even when the records file
# cannot be written. A pass, a SubagentStop second event, a run that only
# parks and every fail-closed path print nothing.
#
# The agent template for a dispatch is $DISPATCH_CHECK_AGENTS_DIR/<type>.md;
# the directory defaults to ${CLAUDE_PLUGIN_ROOT}/agents. With neither set
# there is no template and the fields check and the quotes check are skipped
# with the note "no template".

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

# First line of the dispatch message $1 that starts with the label $2, with
# the label, carriage returns and surrounding blanks removed.
message_line() {
  sed -n "s/^$2: *//p" <<<"$1" | head -n 1 | tr -d '\r' |
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
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

# True when the path still holds an unfilled template placeholder.
has_placeholder() {
  [[ "$1" == *[\{\}\<\>]* ]]
}

# resolve_path PATH CWD: PATH as is when absolute, else under CWD.
resolve_path() {
  if [[ "$1" == /* ]]; then
    printf '%s' "$1"
  else
    printf '%s/%s' "$2" "$1"
  fi
}

# resolve_output_file PATH CWD: prints the resolved path when PATH has no
# placeholder and names an existing regular file; else prints nothing and
# returns 1.
resolve_output_file() {
  local full
  has_placeholder "$1" && return 1
  full="$(resolve_path "$1" "$2")"
  [[ -f "$full" ]] || return 1
  printf '%s' "$full"
}

# add_note TEXT: appends TEXT to the "note" of the caller, with "; " between.
add_note() {
  note="${note:+$note; }$1"
}

# Each check takes its inputs as arguments and appends its failure strings to
# the array "failed" of the caller.
check_output_path() {
  local path="$1" cwd="$2"
  [[ -z "$path" ]] && return 0
  if has_placeholder "$path"; then
    failed+=("output path has a placeholder: $path")
    return 0
  fi
  if [[ ! -f "$(resolve_path "$path" "$cwd")" ]]; then
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

# Fails an existing regular file at a path without a placeholder that cannot
# be read. The one place that reports it, with or without a dispatch id.
check_output_readable() {
  local path="$1" cwd="$2" full
  [[ -z "$path" ]] && return 0
  full="$(resolve_output_file "$path" "$cwd")" || return 0
  [[ -r "$full" ]] || failed+=("output file is not readable: $path")
}

# Checks that the first line of the output file carries the dispatch id.
# Runs only for a readable existing regular file at a path without a
# placeholder.
check_output_owner() {
  local path="$1" cwd="$2" id="$3" full first=""
  [[ -z "$path" || -z "$id" ]] && return 0
  full="$(resolve_output_file "$path" "$cwd")" || return 0
  [[ -r "$full" ]] || return 0
  IFS= read -r first <"$full" || true
  if [[ ! "$first" =~ [^[:space:]] ]]; then
    failed+=("output first line is empty: $path")
  elif ! has_whole_token "$first" "$id"; then
    failed+=("output first line lacks Dispatch id $id")
  fi
}

# Status codes of template_declaration.
readonly DECL_NO_TEMPLATE=1 DECL_NO_DECLARATION=2 DECL_MALFORMED=3

# template_declaration KEY TYPE: prints the declared value of the frontmatter
# key KEY (output-fields or output-quotes) in the template for type TYPE, or
# nothing. Status 0 with a value, else DECL_NO_TEMPLATE, DECL_NO_DECLARATION
# or DECL_MALFORMED (a bad line, a second line, an item with a leading or
# trailing space or tab, or frontmatter that opens with `---`, never closes
# and holds a line for KEY). A file with no leading `---` has no declaration.
# The type loses everything up to its last colon; a type that is empty or
# holds a slash or `..` has no template.
template_declaration() {
  local key="$1" type="${2##*:}"
  local dir="${DISPATCH_CHECK_AGENTS_DIR:-${CLAUDE_PLUGIN_ROOT:+$CLAUDE_PLUGIN_ROOT/agents}}"
  local file line value
  if [[ -z "$dir" || -z "$type" || "$type" == */* || "$type" == *..* ]]; then
    return "$DECL_NO_TEMPLATE"
  fi
  file="$dir/$type.md"
  [[ -f "$file" && -r "$file" ]] || return "$DECL_NO_TEMPLATE"
  line="$(tr -d '\r' <"$file" | awk -v key="$key:" '
    NR == 1 { if ($0 !~ /^---[[:space:]]*$/) exit; open = 1; next }
    /^---[[:space:]]*$/ { closed = 1; exit }
    index($0, key) == 1 { print; found = 1 }
    END { exit (open && !closed && found) }')" || return "$DECL_MALFORMED"
  [[ -z "$line" ]] && return "$DECL_NO_DECLARATION"
  [[ "$line" == *$'\n'* ]] && return "$DECL_MALFORMED"
  value="${line#"$key:"}"
  if [[ ! "$value" =~ ^[[:space:]]*\"([^\"]+)\"[[:space:]]*$ ]]; then
    return "$DECL_MALFORMED"
  fi
  value="${BASH_REMATCH[1]}"
  if [[ "$value" == '|'* || "$value" == *'|' || "$value" == *'||'* ||
    "$value" =~ ^[[:blank:]]|[[:blank:]]$|[[:blank:]]\||\|[[:blank:]] ]]; then
    return "$DECL_MALFORMED"
  fi
  printf '%s' "$value"
}

# Adds the record note for the declarations of type $1: "no template" when
# there is no template, "no declarations" when the template declares neither
# key. A template with one key adds no note.
note_declarations() {
  local fields_status=0 quotes_status=0
  template_declaration output-fields "$1" >/dev/null || fields_status=$?
  template_declaration output-quotes "$1" >/dev/null || quotes_status=$?
  if [[ "$fields_status" -eq "$DECL_NO_TEMPLATE" ]]; then
    add_note "no template"
  elif [[ "$fields_status" -eq "$DECL_NO_DECLARATION" &&
    "$quotes_status" -eq "$DECL_NO_DECLARATION" ]]; then
    add_note "no declarations"
  fi
}

# load_declaration KEY TYPE: sets the array "items" of the caller to the
# items declared for KEY in the template for TYPE. A malformed declaration
# appends its failure to "failed" of the caller. Returns 1 when there is
# nothing to check: no template, no declaration or a malformed one.
load_declaration() {
  local key="$1" type="$2" declared status=0
  declared="$(template_declaration "$key" "$type")" || status=$?
  if [[ "$status" -ne 0 ]]; then
    [[ "$status" -eq "$DECL_MALFORMED" ]] &&
      failed+=("$key line is malformed in ${type##*:}.md")
    return 1
  fi
  IFS='|' read -r -a items <<<"$declared"
}

# True when some line of $1 starts, after optional spaces or tabs, with the
# literal text $2.
has_line_starting_with() {
  local text="$1" field="$2" row
  while IFS= read -r row || [[ -n "$row" ]]; do
    row="${row#"${row%%[! $'\t']*}"}"
    [[ "$row" == "$field"* ]] && return 0
  done <<<"$text"
  return 1
}

# Checks the output fields the template of the dispatch type declares. The
# text is the output file when there is an Output path line, else the last
# assistant message; a missing or unreadable output file is reported by
# check_output_path and check_output_readable, so this check adds nothing.
# Appends to "failed" of the caller. Returns 1 when the payload cannot be
# read.
check_declared_fields() {
  local type="$1" path="$2" cwd="$3" stop="$4" text full field
  local -a items
  load_declaration output-fields "$type" || return 0
  if [[ -n "$path" ]]; then
    full="$(resolve_output_file "$path" "$cwd")" || return 0
    [[ -r "$full" ]] || return 0
    text="$(cat "$full")" || return 0
  else
    text="$(jq -r '.last_assistant_message // empty' <<<"$stop" 2>/dev/null)" || return 1
  fi
  for field in "${items[@]}"; do
    has_line_starting_with "$text" "$field" || failed+=("output lacks required field: $field")
  done
}

# Prints stdin as one normalized line: newlines and carriage returns become
# spaces, markup (`<` followed by a letter, `/` or `!`, up to the next `>`) is
# removed, runs of spaces and tabs collapse to one space, ends are trimmed.
# Case is kept.
normalize_text() {
  tr '\r\n' '  ' | sed -E 's/<[A-Za-z\/!][^>]*>//g; s/[ \t]+/ /g; s/^ //; s/ $//'
}

# Sets "source_text" of the caller to the normalized text of the source file.
# Returns 1 after adding a failure to "failed" when the file cannot supply
# text: no path, a placeholder, missing, unreadable or empty.
read_quote_source() {
  local path="$1" cwd="$2" full
  if [[ -z "$path" ]]; then
    failed+=("no source path for declared quotes")
    return 1
  fi
  if has_placeholder "$path"; then
    failed+=("source path has a placeholder: $path")
    return 1
  fi
  full="$(resolve_path "$path" "$cwd")"
  if [[ ! -f "$full" ]]; then
    failed+=("source file missing: $path")
    return 1
  fi
  if [[ ! -r "$full" ]]; then
    failed+=("source file is not readable: $path")
    return 1
  fi
  source_text="$(normalize_text <"$full")"
  if [[ -z "$source_text" ]]; then
    failed+=("source file is empty: $path")
    return 1
  fi
}

# Fails a source whose normalized text does not end in one of . ! ? : ) " `
# ] } * _ (matched as literal text). Appends to "failed" of the caller.
check_source_complete() {
  local last="${1: -1}" allowed='.!?:)"`]}*_'
  [[ "$allowed" == *"$last"* ]] || failed+=("source truncated: $2")
}

# Checks that every output quote the template of the dispatch type declares
# occurs, normalized, as a literal substring of the normalized source file.
# Appends to "failed" of the caller.
check_declared_quotes() {
  local type="$1" source_path="$2" cwd="$3" source_text quote norm
  local -a items
  load_declaration output-quotes "$type" || return 0
  read_quote_source "$source_path" "$cwd" || return 0
  check_source_complete "$source_text" "$source_path"
  for quote in "${items[@]}"; do
    norm="$(normalize_text <<<"$quote")"
    if [[ -z "$norm" || "$source_text" != *"$norm"* ]]; then
      failed+=("output quote not found in source: $quote")
    fi
  done
}

# build_record ID POST STOP: POST and STOP are the two parked payloads.
build_record() {
  local id="$1" post="$2" stop="$3" prompt dispatch_id output_path source_path type cwd note=""
  local -a failed=()
  prompt="$(jq -r '.tool_input.prompt // empty' <<<"$post" 2>/dev/null)" || return 1
  dispatch_id="$(message_line "$prompt" 'Dispatch id')"
  output_path="$(message_line "$prompt" 'Output path')"
  source_path="$(message_line "$prompt" 'Source path')"
  type="$(jq -r '.tool_input.subagent_type // "unknown"' <<<"$post" 2>/dev/null)" || return 1
  cwd="$(payload_cwd "$stop" "$post")" || return 1
  check_output_path "$output_path" "$cwd"
  check_output_readable "$output_path" "$cwd"
  check_output_owner "$output_path" "$cwd" "$dispatch_id"
  [[ -n "$output_path" && -z "$dispatch_id" ]] && note="ownership not checked"
  note_declarations "$type"
  check_declared_fields "$type" "$output_path" "$cwd" "$stop" || return 1
  check_declared_quotes "$type" "$source_path" "$cwd"
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

# print_failure_context RECORD: prints the model-facing JSON line for a fail
# record; prints nothing for any other record.
print_failure_context() {
  jq -c '
    select(.verdict == "fail")
    | {hookSpecificOutput:{hookEventName:"PostToolUse",
        additionalContext:("Dispatch output check failed (agent " + .agent_id
          + "): " + (.failed | join("; ")))}}' <<<"$1" 2>/dev/null
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
  local payload event id claim parked post stop record
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
  event="$(event_name "$payload")"

  claim="$PENDING/$id.claim.$$"
  claim_parked "$payload" "$id" "$claim" || return 0
  parked="$(cat "$claim")"
  rm -f "$claim"

  post="$payload"
  stop="$parked"
  if [[ "$event" == "SubagentStop" ]]; then
    post="$parked"
    stop="$payload"
  fi
  record="$(build_record "$id" "$post" "$stop")" || {
    fail_closed "bad payload" "bad payload" "$id"
    return 0
  }
  append_record "$record"
  [[ "$event" == "PostToolUse" ]] && print_failure_context "$record"
  return 0
}

main
exit 0
