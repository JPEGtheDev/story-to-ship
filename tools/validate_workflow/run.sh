#!/bin/sh
# validate-workflow guard. Compares the head validate workflow
# and checks.list with the base and reports:
#   R1  a base step, covers path or proof entry that the head drops, or a base
#       trigger (push, pull_request, workflow_dispatch) the head drops
#   R2  a pending entry whose reason lacks #<digits>, or a proof whose control
#       run fails or whose must-fail run lacks the expected output
#   R3  a head step with no step entry, or a new head step lacking a proof entry
#       or carrying a pending entry
#   R4  a skip key or path filter whose head count exceeds the base count
#   R5  a list entry naming a step absent from the head workflow
# Usage: sh tools/validate_workflow/run.sh
# Env: VALIDATE_WORKFLOW_ROOT (default: current directory),
#      VALIDATE_WORKFLOW_BASE (default: origin/main).
# Exit: 0 no findings; 1 one or more findings; 2 cannot run.

set -u

WF=.github/workflows/validate.yml
LIST=tools/validate_workflow/checks.list
ROOT=${VALIDATE_WORKFLOW_ROOT:-.}
BASE=${VALIDATE_WORKFLOW_BASE:-origin/main}
TAB=$(printf '\t')
FINDINGS=0

TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TMP"' EXIT

# finding ID DETAIL: print one FINDING line and count it.
finding() {
  FINDINGS=$((FINDINGS + 1))
  printf 'FINDING %s: %s\n' "$1" "$2"
}

# die MESSAGE: diagnostic on standard error, then exit 2.
die() {
  printf 'validate-workflow: %s\n' "$1" >&2
  exit 2
}

# workflow_parse WORKFLOW STEPS BLOCKS: STEPS gets each step name in order; BLOCKS
# gets NAME<TAB>LINE for each non-comment line of each named step block. A line
# that starts with six spaces and a dash is a step entry; the only other entry
# allowed is the unnamed uses checkout step. Anything else exits 2.
workflow_parse() {
  : > "$2"
  : > "$3"
  awk -v steps="$2" -v blocks="$3" '
    /^      - / {
      if (index($0, "      - name: ") == 1 && length($0) > 14) {
        block = substr($0, 15)
        print block > steps
        inblock = 1
        next
      }
      if (index($0, "      - uses:") == 1) {
        inblock = 0
        next
      }
      print "validate-workflow: unrecognized step line " NR ": " $0 | "cat 1>&2"
      exit 2
    }
    /^  [A-Za-z]/ { inblock = 0; next }
    inblock && !/^[ \t]*#/ { print block "\t" $0 > blocks }
  ' "$1"
}

# parse_list CHECKS OUT: copy the entries of CHECKS to OUT after the strict check.
# Blank lines and lines starting with # are skipped. Exits 2 on a malformed line.
parse_list() {
  awk -F "$TAB" '
    /^#/ || /^[ \t]*$/ { next }
    {
      problem = ""
      if ($1 == "step") want = 2
      else if ($1 == "covers" || $1 == "pending") want = 3
      else if ($1 == "proof") want = ($5 == "append") ? 7 : 6
      else want = 0
      if ($1 == "proof" && NF == 6 && $6 == "") {
        print "validate-workflow: empty expected output substring in checks.list line " NR | "cat 1>&2"
        exit 2
      }
      if (want == 0) {
        problem = "unknown type"
      } else if (NF != want) {
        problem = "expected " want " fields"
      } else {
        for (i = 2; i <= NF && problem == ""; i++) {
          if ($i == "") problem = "empty field " i
        }
        if (problem == "" && $1 == "proof" && $5 != "empty" && $5 != "oversize" && $5 != "append") {
          problem = "unknown proof mode " $5
        }
      }
      if (problem == "" && $2 ~ /^[ \t]|[ \t]$/) problem = "step name has surrounding whitespace"
      if (problem != "") {
        print FILENAME ": line " NR ": malformed, " problem | "cat 1>&2"
        exit 2
      }
      print
    }
  ' "$1" > "$2"
}

# has_entry KIND STEP FILE: exit 0 when FILE holds a KIND entry naming STEP.
has_entry() {
  VW_KIND=$1 VW_STEP=$2 awk -F "$TAB" '
    $1 == ENVIRON["VW_KIND"] && $2 == ENVIRON["VW_STEP"] { found = 1 }
    END { exit !found }
  ' "$3"
}

# has_covers STEP PATH FILE: exit 0 when FILE holds a covers entry naming STEP and PATH.
has_covers() {
  VW_STEP=$1 VW_PATH=$2 awk -F "$TAB" '
    $1 == "covers" && $2 == ENVIRON["VW_STEP"] && $3 == ENVIRON["VW_PATH"] { found = 1 }
    END { exit !found }
  ' "$3"
}

# in_block STEP PATH BLOCKS: exit 0 when a non-comment line of STEP's block holds PATH.
in_block() {
  VW_STEP=$1 VW_PATH=$2 awk '
    index($0, ENVIRON["VW_STEP"] "\t") == 1 {
      line = substr($0, length(ENVIRON["VW_STEP"]) + 2)
      if (index(line, ENVIRON["VW_PATH"]) > 0) found = 1
    }
    END { exit !found }
  ' "$3"
}

# has_head_step STEP: exit 0 when the head workflow has a step named STEP.
has_head_step() {
  grep -Fxq -- "$1" "$TMP/head.steps"
}

# check_removal: R1 for base steps and for base covers and proof entries the head drops.
check_removal() {
  while IFS= read -r step; do
    if ! has_head_step "$step"; then
      finding R1 "base step \"$step\" is absent from the head workflow"
    fi
  done < "$TMP/base.steps"

  while IFS="$TAB" read -r kind step detail; do
    has_head_step "$step" || continue
    case $kind in
      covers)
        in_block "$step" "$detail" "$TMP/head.blocks" ||
          finding R1 "base covers path \"$detail\" of step \"$step\" is absent from the head step block (non-comment line)"
        has_covers "$step" "$detail" "$TMP/head.list" ||
          finding R1 "base covers path \"$detail\" of step \"$step\" is absent from the head checks.list"
        ;;
      proof)
        has_entry proof "$step" "$TMP/head.list" ||
          finding R1 "base proof entry of step \"$step\" is absent from the head list or downgraded to pending"
        ;;
    esac
  done < "$TMP/base.list"
}

# check_new_steps: R3 for head steps without a step entry, and for new head steps
# without a proof entry or with a pending entry.
check_new_steps() {
  while IFS= read -r step; do
    has_entry step "$step" "$TMP/head.list" ||
      finding R3 "head step \"$step\" has no step entry in checks.list"
    if ! grep -Fxq -- "$step" "$TMP/base.steps"; then
      has_entry proof "$step" "$TMP/head.list" ||
        finding R3 "new head step \"$step\" has no proof entry"
      if has_entry pending "$step" "$TMP/head.list"; then
        finding R3 "new head step \"$step\" has a pending entry; pending is refused for a new step"
      fi
    fi
  done < "$TMP/head.steps"
}

# check_list_entries: R5 for each head list entry naming a step absent from the head.
check_list_entries() {
  while IFS="$TAB" read -r kind step detail; do
    has_head_step "$step" ||
      finding R5 "$kind entry names step \"$step\", which is absent from the head workflow"
  done < "$TMP/head.list"
}

# check_pending_reasons: R2 for each head pending entry whose reason lacks #<digits>.
check_pending_reasons() {
  while IFS="$TAB" read -r kind step reason; do
    [ "$kind" = pending ] || continue
    case $reason in
      *'#'[0-9]*) ;;
      *) finding R2 "pending entry for step \"$step\" has no #<digits> issue number in its reason" ;;
    esac
  done < "$TMP/head.list"
}

# on_triggers WORKFLOW: print each push, pull_request or workflow_dispatch key of the on: block.
on_triggers() {
  awk '
    /^on:/ { area = 1; next }
    /^[^[:space:]#]/ { area = 0 }
    area && /^[[:space:]]*(push|pull_request|workflow_dispatch):/ {
      name = $0
      sub(/^[[:space:]]*/, "", name)
      sub(/:.*/, "", name)
      print name
    }
  ' "$1"
}

# skip_counts WORKFLOW: print "KEY COUNT" for each skip key and path filter. Step-level keys
# sit at exactly eight spaces and job-level keys at exactly four; a run block holds only
# deeper lines, so these never match inside one. paths and paths-ignore count inside on:.
skip_counts() {
  awk '
    /^on:/ { area = "on"; next }
    /^[^[:space:]#]/ { area = "" }
    area == "on" && /^[[:space:]]+paths(-ignore)?:/ { n["on-paths"]++ }
    /^        if:/ { n["step-if"]++ }
    /^        continue-on-error:/ { n["step-continue-on-error"]++ }
    /^    if:/ { n["job-if"]++ }
    /^    continue-on-error:/ { n["job-continue-on-error"]++ }
    END {
      split("step-if step-continue-on-error job-if job-continue-on-error on-paths", keys, " ")
      for (i = 1; i <= 5; i++) print keys[i], n[keys[i]] + 0
    }
  ' "$1"
}

# check_triggers: R1 for each base trigger absent from the head on: block.
check_triggers() {
  on_triggers "$TMP/base.wf" > "$TMP/base.triggers"
  on_triggers "$ROOT/$WF" > "$TMP/head.triggers"
  while IFS= read -r t; do
    grep -Fxq -- "$t" "$TMP/head.triggers" ||
      finding R1 "base trigger \"$t\" is absent from the head on: block"
  done < "$TMP/base.triggers"
}

# check_skip_keys: R4 for each skip key or path filter whose head count exceeds the base count.
check_skip_keys() {
  skip_counts "$TMP/base.wf" > "$TMP/base.keys"
  skip_counts "$ROOT/$WF" > "$TMP/head.keys"
  while IFS=' ' read -r key head_n; do
    base_n=$(awk -v k="$key" '$1 == k { print $2 }' "$TMP/base.keys")
    if [ "$head_n" -gt "$base_n" ]; then
      finding R4 "head has $head_n \"$key\" key(s) against $base_n in base; skip keys and path filters are refused"
    fi
  done < "$TMP/head.keys"
}

# extract_run STEP WORKFLOW OUT: write the run block of STEP to OUT and exit 0. A block scalar
# (run: |) gives its content lines with the ten-space indent removed; a single-line run gives
# its command. Exit 1 when the step has no run key.
extract_run() {
  VW_STEP=$1 awk -v out="$3" '
    BEGIN { state = 0 }
    state == 0 && $0 == "      - name: " ENVIRON["VW_STEP"] { state = 1; next }
    state == 1 && (/^      - / || /^  [A-Za-z]/) { exit }
    state == 1 && /^        run: [|>]/ { state = 2; found = 1; next }
    state == 1 && /^        run: / {
      line = $0
      sub(/^        run: /, "", line)
      print line > out
      found = 1
      exit
    }
    state == 2 && /^[[:space:]]*$/ { print "" > out; next }
    state == 2 && index($0, "          ") == 1 { print substr($0, 11) > out; next }
    state == 2 { exit }
    END { exit !found }
  ' "$2"
}

# prepare_tree: copy the tracked files of ROOT and its .git into TMP/tree once.
prepare_tree() {
  mkdir "$TMP/tree" || die "cannot make the proof tree"
  git -C "$ROOT" ls-files > "$TMP/tracked" || die "cannot list the tracked files"
  while IFS= read -r f; do
    [ -f "$ROOT/$f" ] || continue
    mkdir -p "$TMP/tree/$(dirname -- "$f")" || die "cannot make a directory in the proof tree"
    cp "$ROOT/$f" "$TMP/tree/$f" || die "cannot copy $f into the proof tree"
  done < "$TMP/tracked"
  if [ -e "$ROOT/.git" ]; then
    cp -R "$ROOT/.git" "$TMP/tree/.git" || die "cannot copy .git into the proof tree"
  fi
}

# run_block DIR ENVS BODY OUT: run BODY under bash -eo pipefail in DIR with the ENVS
# pairs exported ("-" exports none) and VALIDATE_WORKFLOW_INNER=1, so a guard run
# inside a proof does not recurse. Standard input is empty; output goes to OUT.
run_block() {
  rb_dir=$1 rb_envs=$2 rb_body=$3 rb_out=$4
  (
    cd "$rb_dir" || exit 2
    set --
    if [ "$rb_envs" != - ]; then
      set -f
      for pair in $rb_envs; do set -- "$@" "$pair"; done
      set +f
    fi
    exec env VALIDATE_WORKFLOW_INNER=1 "$@" bash -eo pipefail "$rb_body" < /dev/null
  ) > "$rb_out" 2>&1
}

# copy_tree DEST: copy the prepared proof tree to DEST, a path that does not exist yet.
copy_tree() {
  cp -R "$TMP/tree" "$1" || die "cannot copy the proof tree"
}

# apply_mode FILE MODE TEXT: empty truncates FILE to 0 bytes; oversize writes 20001 bytes of x;
# append adds TEXT to the end of FILE, one line per literal backslash-n in TEXT. TEXT reaches
# awk through ENVIRON, so no shell expands its dollar signs or backslashes.
# parse_list has already refused any other mode.
apply_mode() {
  case $2 in
    empty) : > "$1" ;;
    oversize) awk 'BEGIN { s = sprintf("%20001s", ""); gsub(/ /, "x", s); printf "%s", s }' > "$1" ;;
    append)
      VW_TEXT=$3 awk 'BEGIN {
        s = ENVIRON["VW_TEXT"]
        while ((i = index(s, "\\n")) > 0) { printf "%s\n", substr(s, 1, i - 1); s = substr(s, i + 2) }
        printf "%s\n", s
      }' >> "$1" ;;
  esac
}

# run_proofs: for each head proof line, run the step's run block on an unmodified copy
# (control: exit 0), then on a fresh copy with the target changed by the mode (must-fail:
# non-zero exit and the expected substring in the output). A proof for a step absent from
# the head is left to R5.
run_proofs() {
  prepare_tree
  n=0
  while IFS="$TAB" read -r kind step envs target mode text addtext; do
    [ "$kind" = proof ] || continue
    has_head_step "$step" || continue
    n=$((n + 1))
    body=$TMP/body.$n.sh
    if ! extract_run "$step" "$ROOT/$WF" "$body"; then
      finding R2 "proof for \"$step\" has no run block in the head workflow"
      continue
    fi
    ctl=$TMP/control.$n
    copy_tree "$ctl"
    if ! run_block "$ctl" "$envs" "$body" "$TMP/control.$n.out"; then
      finding R2 "proof control for \"$step\" failed"
      continue
    fi
    fail=$TMP/fail.$n
    copy_tree "$fail"
    if [ ! -f "$fail/$target" ]; then
      finding R2 "proof target \"$target\" of step \"$step\" is absent from the tree"
      continue
    fi
    apply_mode "$fail/$target" "$mode" "$addtext"
    if ! run_block "$fail" "$envs" "$body" "$TMP/fail.$n.out" &&
      grep -Fq -- "$text" "$TMP/fail.$n.out"; then
      printf 'PROOF ok: %s\n' "$step"
    else
      finding R2 "proof for \"$step\" did not fail with the expected output"
    fi
  done < "$TMP/head.list"
}

# Base ref: fetch origin/main once when the default ref is missing.
if ! git -C "$ROOT" rev-parse -q --verify "$BASE^{commit}" > /dev/null 2>&1; then
  if [ "$BASE" = origin/main ]; then
    git -C "$ROOT" fetch --no-tags --depth=1 origin +refs/heads/main:refs/remotes/origin/main > /dev/null 2>&1
  fi
  git -C "$ROOT" rev-parse -q --verify "$BASE^{commit}" > /dev/null 2>&1 ||
    die "base ref $BASE is not available"
fi

# Head inputs. An absent head checks.list counts as empty (every step then needs an entry).
[ -f "$ROOT/$WF" ] || die "head workflow $WF is absent under $ROOT"
HEAD_CHECKS=$ROOT/$LIST
[ -f "$HEAD_CHECKS" ] || HEAD_CHECKS=/dev/null

# Base inputs. An absent base checks.list counts as empty; an absent base workflow exits 2.
git -C "$ROOT" cat-file -e "$BASE:$WF" 2> /dev/null ||
  die "base workflow $WF is absent at $BASE"
git -C "$ROOT" show "$BASE:$WF" > "$TMP/base.wf" || die "cannot read base workflow at $BASE"
BASE_CHECKS=$TMP/base.checks
if git -C "$ROOT" cat-file -e "$BASE:$LIST" 2> /dev/null; then
  git -C "$ROOT" show "$BASE:$LIST" > "$BASE_CHECKS" || die "cannot read base checks.list at $BASE"
else
  BASE_CHECKS=/dev/null
fi

workflow_parse "$ROOT/$WF" "$TMP/head.steps" "$TMP/head.blocks" ||
  die "head workflow has an unrecognized step line"
workflow_parse "$TMP/base.wf" "$TMP/base.steps" "$TMP/base.blocks" ||
  die "base workflow has an unrecognized step line"
parse_list "$HEAD_CHECKS" "$TMP/head.list" || die "malformed head checks.list"
parse_list "$BASE_CHECKS" "$TMP/base.list" || die "malformed base checks.list"

check_removal
check_new_steps
check_list_entries
check_pending_reasons
check_triggers
check_skip_keys

if [ "${VALIDATE_WORKFLOW_INNER:-}" = 1 ]; then
  echo "PROOF skipped: VALIDATE_WORKFLOW_INNER=1"
else
  run_proofs
fi

if [ "$FINDINGS" -eq 0 ]; then
  echo "OK validate-workflow"
  exit 0
fi
echo "validate-workflow: $FINDINGS findings"
exit 1
