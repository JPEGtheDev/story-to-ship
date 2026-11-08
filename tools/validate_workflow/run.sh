#!/bin/sh
# validate-workflow guard. Compares the head validate workflow
# and checks.list with the base and reports:
#   R1  a base step, covers path or proof entry that the head drops
#   R2  a pending entry whose reason lacks #<digits>
#   R3  a head step with no step entry, or a new head step lacking a proof entry
#       or carrying a pending entry
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
      else if ($1 == "proof") want = 6
      else want = 0
      if (want == 0) {
        problem = "unknown type"
      } else if (NF != want) {
        problem = "expected " want " fields"
      } else {
        for (i = 2; i <= NF && problem == ""; i++) {
          if ($i == "") problem = "empty field " i
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

# check_removal: R1 for base steps and for base covers and proof entries the head drops.
check_removal() {
  while IFS= read -r step; do
    if ! grep -Fxq -- "$step" "$TMP/head.steps"; then
      finding R1 "base step \"$step\" is absent from the head workflow"
    fi
  done < "$TMP/base.steps"

  while IFS="$TAB" read -r kind step detail; do
    grep -Fxq -- "$step" "$TMP/head.steps" || continue
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
    grep -Fxq -- "$step" "$TMP/head.steps" ||
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

if [ "$FINDINGS" -eq 0 ]; then
  echo "OK validate-workflow"
  exit 0
fi
echo "validate-workflow: $FINDINGS findings"
exit 1
