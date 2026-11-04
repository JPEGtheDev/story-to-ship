#!/bin/sh
# Fixture tests for page-edit.sh, the owner page editor, for its add-card, hide, status, ready-add and ready-remove
# ops: the usage errors (exit 2), the anchor rules, the card and context checks, the hide blocks, the status and
# Ready to merge rules, the non-ASCII check, the unreadable-file messages, the byte-identical failure path, the
# no-temp-file rule and the file mode kept by each edit. The real template (placeholders filled, two cards q7
# and q9, each with its context block) and small synthetic pages are the fixtures. No network.
# PAGE_EDIT=<path> substitutes another script (used to prove a test can fail).
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

PAGE_EDIT=${PAGE_EDIT:-$(dirname "$0")/../page-edit.sh}
TEMPLATE=$(dirname "$0")/../../references/owner-questions-template.html
TAB=$(printf '\t')
REAL_AWK=$(command -v awk) || exit 2
REAL_CP=$(command -v cp) || exit 2
REAL_MV=$(command -v mv) || exit 2

# One-line card and context HTML. The card holds one id attribute; its context block has id c-q8.
CARD8='<article class="q" id="q8"><div class="qhead"><a class="qid" href="#c-q8">Q8</a><span class="topic">Story: Topic &amp; more</span></div><p>Question?</p></article>'
CTX8='<div class="ctx" id="c-q8"><h3><a href="#q8">Q8</a> Story</h3><p>Context &amp; notes</p></div>'
CARD7='<article class="q" id="q7"><p>Again</p></article>'

# write_lines <file> <line>...: writes each argument as one line of the file.
write_lines() {
  _wl_file=$1
  shift
  printf '%s\n' "$@" > "$_wl_file" || exit 2
}

# new_case: a fresh directory for one case. The page sits in its own subdirectory so a listing of that
# subdirectory shows any temp file. Sets CASE_DIR, CASE_PAGE (the page file) and CASE_IN (the input file).
new_case() {
  CASE_DIR=$(mktemp -d "$TEST_TMP/case.XXXXXX") || exit 2
  mkdir "$CASE_DIR/page" || exit 2
  CASE_PAGE=$CASE_DIR/page/page.html
  CASE_IN=$CASE_DIR/in.txt
}

# run_edit <args...>: runs the editor with the arguments; sets RC and writes stdout and stderr to
# CASE_DIR/out and CASE_DIR/err.
run_edit() {
  RC=0
  sh "$PAGE_EDIT" "$@" > "$CASE_DIR/out" 2> "$CASE_DIR/err" || RC=$?
}

# assert_stdout <name> <expected text> <file>: the file holds the expected text and one newline after it,
# or nothing at all when the expected text is empty.
assert_stdout() {
  if [ -n "$2" ]; then
    printf '%s\n' "$2" > "$TEST_TMP/want-out.txt"
  else
    : > "$TEST_TMP/want-out.txt"
  fi
  assert_file_eq "$1" "$TEST_TMP/want-out.txt" "$3"
}

# expect_args <name> <exit> <stdout text> <args...>: runs the editor and checks the exit code, the exact stdout
# and an empty stderr.
expect_args() {
  _ea_name=$1
  _ea_rc=$2
  _ea_out=$3
  shift 3
  run_edit "$@"
  assert_exit "$_ea_name exit" "$_ea_rc" "$RC"
  assert_stdout "$_ea_name stdout" "$_ea_out" "$CASE_DIR/out"
  assert_empty "$_ea_name stderr" "$CASE_DIR/err"
}

# save_page: keeps a copy of the page for the byte-identity check.
save_page() {
  cat "$CASE_PAGE" > "$CASE_DIR/saved" || exit 2
}

# assert_unchanged <name>: the page is byte-identical to the saved copy.
assert_unchanged() {
  assert_file_eq "$1 page unchanged" "$CASE_DIR/saved" "$CASE_PAGE"
}

# expect_unchanged <name> <exit> <stdout text> <args...>: a failing run that must leave the page as it was.
expect_unchanged() {
  _eu_name=$1
  save_page
  expect_args "$@"
  assert_unchanged "$_eu_name"
}

# expect_usage <name> <args...>: runs the editor with the arguments; exit 2, nothing on stdout, usage on stderr,
# and the page untouched.
expect_usage() {
  _us_name=$1
  shift
  save_page
  run_edit "$@"
  assert_exit "$_us_name exit" 2 "$RC"
  assert_empty "$_us_name stdout" "$CASE_DIR/out"
  assert_nonempty "$_us_name usage on stderr" "$CASE_DIR/err"
  assert_unchanged "$_us_name"
}

# snapshot_dir <dir> <file>: writes the name of every entry in the directory, hidden ones included.
snapshot_dir() {
  printf '%s\n' "$1"/* "$1"/.[!.]* > "$2" || exit 2
}

# assert_listing_same <name> <listing before>: the page directory holds the entries listed before the run.
assert_listing_same() {
  snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-after"
  assert_file_eq "$1" "$2" "$CASE_DIR/listing-after"
}

# syn_q7: a small synthetic page with one card, q7, and no context block.
syn_q7() {
  write_lines "$CASE_PAGE" '<main>' '  <article class="q" id="q7">' '    <p>x</p>' '  </article>' '</main>'
}

# line_of <file> <text>: the number of the first line that holds the fixed text.
line_of() {
  grep -n -F -- "$2" "$1" | sed -n '1p' | sed 's/:.*//'
}

# insert_above <src> <dst> <line> <text>: writes src to dst with text as a new line above the given line.
insert_above() {
  { sed -n "1,$(($3 - 1))p" "$1"; printf '%s\n' "$4"; sed -n "$3,\$p" "$1"; } > "$2" || exit 2
}

# The template with every placeholder filled. The card number is left as @N@ so build_page can set it.
BASE=$TEST_TMP/base.html
sed -e 's/{{NUMBER}}/@N@/g' -e 's/{{[A-Z_]*}}/filled/g' "$TEMPLATE" > "$BASE" || exit 2

# The shape build_page relies on: the card runs lines 66-72 and the context block lines 84-87 of the template.
sed -n '66p;72p;84p;87p' "$BASE" > "$TEST_TMP/shape.txt" || exit 2
write_lines "$TEST_TMP/shape-want.txt" '    <article class="q" id="q@N@">' '    </article>' \
  '    <div class="ctx" id="c-q@N@">' '    </div>'
assert_file_eq "template shape: lines 66, 72, 84 and 87 are the card and context edges" \
  "$TEST_TMP/shape-want.txt" "$TEST_TMP/shape.txt"

# build_page <out> [id...]: the template with one card block and one context block per id, in the order given.
build_page() {
  _bp_out=$1
  shift
  {
    sed -n '1,65p' "$BASE"
    for _bp_id in "$@"; do sed -n '66,72p' "$BASE" | sed "s/@N@/$_bp_id/g"; done
    sed -n '73,83p' "$BASE"
    for _bp_id in "$@"; do sed -n '84,87p' "$BASE" | sed "s/@N@/$_bp_id/g"; done
    sed -n '88,89p' "$BASE"
  } > "$_bp_out" || exit 2
}

REAL=$TEST_TMP/real.html
build_page "$REAL" 7 9

# ---- add-card on the real template ----

new_case
cat "$REAL" > "$CASE_PAGE"
N7=$(line_of "$REAL" 'id="q7">')
insert_above "$REAL" "$CASE_DIR/want.html" "$N7" "    $CARD8"
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
expect_args "add-card real template" 0 'OK add-card: q8 before q7' add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card real template: card directly above q7 with its indent, rest byte-identical" \
  "$CASE_DIR/want.html" "$CASE_PAGE"
assert_listing_same "add-card real template: no temp file left beside the page" "$CASE_DIR/listing-before"

new_case
cat "$REAL" > "$CASE_PAGE"
N7=$(line_of "$REAL" 'id="q7">')
N7C=$(line_of "$REAL" 'id="c-q7">')
insert_above "$REAL" "$CASE_DIR/step.html" "$N7" "    $CARD8"
insert_above "$CASE_DIR/step.html" "$CASE_DIR/want.html" "$((N7C + 1))" "    $CTX8"
write_lines "$CASE_IN" 'before=q7' "card=$CARD8" "context=$CTX8"
expect_args "add-card real template with context" 0 'OK add-card: q8 before q7 and context' \
  add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card real template: context directly above c-q7, card above q7" \
  "$CASE_DIR/want.html" "$CASE_PAGE"

# ---- hide on the real template ----

new_case
cat "$REAL" > "$CASE_PAGE"
build_page "$CASE_DIR/want.html" 9
write_lines "$CASE_IN" 'hide=q7'
expect_args "hide q7 real template" 0 'OK hide: q7' hide "$CASE_PAGE" "$CASE_IN"
assert_file_eq "hide q7 real template: card and context blocks gone, q9 untouched" \
  "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
cat "$REAL" > "$CASE_PAGE"
build_page "$CASE_DIR/want.html"
write_lines "$CASE_IN" 'hide=q7' 'hide=q9'
expect_args "hide q7 and q9 real template" 0 'OK hide: q7
OK hide: q9' hide "$CASE_PAGE" "$CASE_IN"
assert_file_eq "hide q7 and q9 real template: both cards and contexts gone" \
  "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
cat "$REAL" > "$CASE_PAGE"
build_page "$CASE_DIR/want.html"
write_lines "$CASE_IN" 'hide=q9' 'hide=q7'
expect_args "hide q9 then q7 real template" 0 'OK hide: q9
OK hide: q7' hide "$CASE_PAGE" "$CASE_IN"
assert_file_eq "hide q9 then q7 real template: output follows input order" \
  "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
cat "$REAL" > "$CASE_PAGE"
build_page "$CASE_DIR/want.html" 9
write_lines "$CASE_IN" 'hide=q7' 'hide=q7'
expect_args "hide q7 twice" 0 'OK hide: q7' hide "$CASE_PAGE" "$CASE_IN"
assert_file_eq "hide q7 twice: removed once" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
cat "$REAL" > "$CASE_PAGE"
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
write_lines "$CASE_IN" 'hide=q7' 'hide=q99'
save_page
run_edit hide "$CASE_PAGE" "$CASE_IN"
assert_exit "hide q7 with failing q99 exit" 1 "$RC"
assert_grep "hide q7 with failing q99 reports the anchor" '^FAIL hide: anchor q99 not found$' "$CASE_DIR/out"
assert_empty "hide q7 with failing q99 stderr" "$CASE_DIR/err"
assert_unchanged "hide q7 with failing q99: nothing removed"
assert_listing_same "hide with a failing id: no temp file left" "$CASE_DIR/listing-before"

# ---- add-card: anchor rules on synthetic pages ----

new_case
write_lines "$CASE_PAGE" '<main>' '  <p>nothing here</p>' '</main>'
write_lines "$CASE_IN" 'before=q99' "card=$CARD8"
expect_unchanged "add-card missing anchor" 1 'FAIL add-card: anchor q99 not found' add-card "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p id="q7">a</p>' '  <p id="q7">b</p>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
expect_unchanged "add-card repeated anchor" 1 'FAIL add-card: anchor q7 repeated' add-card "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p data-id="q7">a</p>' '  <a href="#q7">b</a>' '  <div id="c-q7">c</div>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
expect_unchanged "add-card data-id, href and c- anchors not counted" 1 'FAIL add-card: anchor q7 not found' \
  add-card "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p id="q70">a</p>' '  <p id="q7">b</p>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
write_lines "$CASE_DIR/want.html" '<main>' '  <p id="q70">a</p>' "  $CARD8" '  <p id="q7">b</p>' '</main>'
expect_args "add-card q70 is not q7" 0 'OK add-card: q8 before q7' add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card q70 is not q7: card above the q7 line" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p data-id="q7">a</p>' '  <p id="q7">b</p>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
write_lines "$CASE_DIR/want.html" '<main>' '  <p data-id="q7">a</p>' "  $CARD8" '  <p id="q7">b</p>' '</main>'
expect_args "add-card data-id plus one id is not repeated" 0 'OK add-card: q8 before q7' \
  add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card data-id plus one id: card above the id line" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
write_lines "$CASE_PAGE" '<main>' '  <a href="#q8">x</a>' '  <p data-id="q8">y</p>' '  <p id="q7">a</p>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
write_lines "$CASE_DIR/want.html" '<main>' '  <a href="#q8">x</a>' '  <p data-id="q8">y</p>' "  $CARD8" '  <p id="q7">a</p>' '</main>'
expect_args "add-card href and data-id do not hold the new id" 0 'OK add-card: q8 before q7' \
  add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card href and data-id: card above q7" "$CASE_DIR/want.html" "$CASE_PAGE"

# The anchor boundary: the character before id is not a letter, digit, underscore or hyphen. A double quote, the
# start of the line and a tab all sit before a match; a letter, digit or underscore before id does not match.

new_case
write_lines "$CASE_PAGE" '<main>' '  <p class="a"id="q7">a</p>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
write_lines "$CASE_DIR/want.html" '<main>' "  $CARD8" '  <p class="a"id="q7">a</p>' '</main>'
expect_args "add-card double quote before id matches" 0 'OK add-card: q8 before q7' add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card double quote before id: card above that line" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
write_lines "$CASE_PAGE" '<main>' '  <article class="q"id="q7">' '    <p>x</p>' '  </article>' '  <div class="ctx" id="c-q7">' \
  '    <p>y</p>' '  </div>' '  <p>keep</p>' '</main>'
write_lines "$CASE_IN" 'hide=q7'
write_lines "$CASE_DIR/want.html" '<main>' '  <p>keep</p>' '</main>'
expect_args "hide double quote before id matches" 0 'OK hide: q7' hide "$CASE_PAGE" "$CASE_IN"
assert_file_eq "hide double quote before id: card and context blocks gone" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
write_lines "$CASE_PAGE" '<main>' 'id="q7">a</p>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
write_lines "$CASE_DIR/want.html" '<main>' "$CARD8" 'id="q7">a</p>' '</main>'
expect_args "add-card id at column 0 matches" 0 'OK add-card: q8 before q7' add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card id at column 0: card above that line" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
write_lines "$CASE_PAGE" '<main>' "  <p${TAB}id=\"q7\">a</p>" '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
write_lines "$CASE_DIR/want.html" '<main>' "  $CARD8" "  <p${TAB}id=\"q7\">a</p>" '</main>'
expect_args "add-card tab before id matches" 0 'OK add-card: q8 before q7' add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card tab before id: card above that line with its indent" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p xid="q7">a</p>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
expect_unchanged "add-card letter before id does not match" 1 'FAIL add-card: anchor q7 not found' \
  add-card "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p 9id="q7">a</p>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
expect_unchanged "add-card digit before id does not match" 1 'FAIL add-card: anchor q7 not found' \
  add-card "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p my_id="q7">a</p>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
expect_unchanged "add-card underscore before id does not match" 1 'FAIL add-card: anchor q7 not found' \
  add-card "$CASE_PAGE" "$CASE_IN"

# ---- add-card: card and context checks ----

new_case
write_lines "$CASE_PAGE" '<main>' '  <p id="q7">a</p>' '  <p id="q9">b</p>' '</main>'
write_lines "$CASE_IN" 'before=q9' "card=$CARD7"
expect_unchanged "add-card existing card id" 1 'FAIL add-card: id q7 already on the page' add-card "$CASE_PAGE" "$CASE_IN"

new_case
syn_q7
write_lines "$CASE_IN" 'before=q7' 'card=<article class="q"><p>x</p></article>'
expect_unchanged "add-card card without id" 1 'FAIL add-card: card has no id' add-card "$CASE_PAGE" "$CASE_IN"

new_case
syn_q7
write_lines "$CASE_IN" 'before=q7' 'card=<article class="q" id="q8"><p id="q9">x</p></article>'
expect_unchanged "add-card card with two ids" 1 'FAIL add-card: card has more than one id' add-card "$CASE_PAGE" "$CASE_IN"

new_case
syn_q7
write_lines "$CASE_IN" "card=$CARD8"
expect_unchanged "add-card missing key before" 1 'FAIL add-card: missing key before' add-card "$CASE_PAGE" "$CASE_IN"

new_case
syn_q7
write_lines "$CASE_IN" 'before=q7'
expect_unchanged "add-card missing key card" 1 'FAIL add-card: missing key card' add-card "$CASE_PAGE" "$CASE_IN"

new_case
syn_q7
write_lines "$CASE_IN" 'before=q7' "card=$CARD8" "context=$CTX8"
expect_unchanged "add-card context anchor c-q7 missing" 1 'FAIL add-card: anchor c-q7 not found' \
  add-card "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p id="q7">a</p>' '  <div id="c-q7">x</div>' '  <div id="c-q7">y</div>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8" "context=$CTX8"
expect_unchanged "add-card context anchor c-q7 repeated" 1 'FAIL add-card: anchor c-q7 repeated' \
  add-card "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p id="q7">a</p>' '  <div id="c-q7">x</div>' '  <div id="c-q8">z</div>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8" "context=$CTX8"
expect_unchanged "add-card context id already on the page" 1 'FAIL add-card: id c-q8 already on the page' \
  add-card "$CASE_PAGE" "$CASE_IN"

# The context html's own id, when it differs from c-<card id>: checked against the page like the card id.
CTX_ZZ='<div class="ctx" id="c-zz"><p>Context &amp; notes</p></div>'
CTX_NOID='<div class="ctx"><p>Context &amp; notes</p></div>'

new_case
write_lines "$CASE_PAGE" '<main>' '  <p id="q7">a</p>' '  <div id="c-q7">x</div>' '  <div id="c-zz">z</div>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8" "context=$CTX_ZZ"
expect_unchanged "add-card context own id already on the page" 1 'FAIL add-card: id c-zz already on the page' \
  add-card "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p id="q7">a</p>' '  <div id="c-q7">x</div>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8" "context=$CTX_ZZ"
write_lines "$CASE_DIR/want.html" '<main>' "  $CARD8" '  <p id="q7">a</p>' "  $CTX_ZZ" '  <div id="c-q7">x</div>' '</main>'
expect_args "add-card context own id not on the page" 0 'OK add-card: q8 before q7 and context' \
  add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card context own id not on the page: context above c-q7" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p id="q7">a</p>' '  <div id="c-q7">x</div>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8" "context=$CTX_NOID"
write_lines "$CASE_DIR/want.html" '<main>' "  $CARD8" '  <p id="q7">a</p>' "  $CTX_NOID" '  <div id="c-q7">x</div>' '</main>'
expect_args "add-card context without an id is accepted" 0 'OK add-card: q8 before q7 and context' \
  add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card context without an id: context above c-q7" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
write_lines "$CASE_PAGE" '<main>' '  <article class="q" id="q7">' '    <div id="c-q7">x</div>' '  </article>' '</main>'
write_lines "$CASE_IN" 'before=q7' "card=$CARD8" "context=$CTX8"
cat "$CASE_PAGE" > "$CASE_DIR/orig.html"
insert_above "$CASE_DIR/orig.html" "$CASE_DIR/step.html" 2 "  $CARD8"
insert_above "$CASE_DIR/step.html" "$CASE_DIR/want.html" 4 "    $CTX8"
expect_args "add-card context at its own indent" 0 'OK add-card: q8 before q7 and context' \
  add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card context at its own indent: card at q7 indent, context at c-q7 indent" \
  "$CASE_DIR/want.html" "$CASE_PAGE"

# ---- add-card: non-ASCII input (page unchanged) and a tab (allowed) ----

new_case
syn_q7
printf 'before=q7\ncard=<article class="q" id="q8"><p>caf\303\251</p></article>\n' > "$CASE_IN"
expect_unchanged "add-card UTF-8 byte" 1 'FAIL add-card: input has a non-ASCII character' \
  add-card "$CASE_PAGE" "$CASE_IN"

new_case
syn_q7
printf 'before=q7\ncard=<article class="q" id="q8"><p>caf\351</p></article>\n' > "$CASE_IN"
expect_unchanged "add-card stray byte 351" 1 'FAIL add-card: input has a non-ASCII character' \
  add-card "$CASE_PAGE" "$CASE_IN"

new_case
syn_q7
printf 'before=q7\ncard=<article class="q" id="q8"><p>x</p></article>\r\n' > "$CASE_IN"
expect_unchanged "add-card carriage return byte" 1 'FAIL add-card: input has a non-ASCII character' \
  add-card "$CASE_PAGE" "$CASE_IN"

new_case
syn_q7
write_lines "$CASE_IN" 'before=q7' "card=<article class=\"q\" id=\"q8\">${TAB}<p>x</p></article>"
cat "$CASE_PAGE" > "$CASE_DIR/orig.html"
insert_above "$CASE_DIR/orig.html" "$CASE_DIR/want.html" 2 "  <article class=\"q\" id=\"q8\">${TAB}<p>x</p></article>"
expect_args "add-card tab in the card is allowed" 0 'OK add-card: q8 before q7' add-card "$CASE_PAGE" "$CASE_IN"
assert_file_eq "add-card tab in the card: card above q7" "$CASE_DIR/want.html" "$CASE_PAGE"

# ---- add-card: the success path leaves no temp file ----

new_case
syn_q7
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
run_edit add-card "$CASE_PAGE" "$CASE_IN"
assert_listing_same "add-card success: no temp file left beside the page" "$CASE_DIR/listing-before"

# ---- add-card and hide: page file mode ----

# mode_of <file>: the first ten characters of the file's ls -l line, such as -rw-r--r--.
mode_of() {
  ls -l "$1" | awk '{print substr($1,1,10)}'
}

# assert_mode <name> <expected mode> <file>: the file's mode string is the expected one.
assert_mode() {
  _am_got=$(mode_of "$3") || exit 2
  if [ "$_am_got" = "$2" ]; then
    pass_case "$1"
  else
    fail_case "$1" "expected mode $2 got $_am_got"
  fi
}

new_case
syn_q7
chmod 644 "$CASE_PAGE" || exit 2
assert_mode "add-card mode 644 before the edit" '-rw-r--r--' "$CASE_PAGE"
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
expect_args "add-card keeps mode 644 page" 0 'OK add-card: q8 before q7' add-card "$CASE_PAGE" "$CASE_IN"
assert_mode "add-card keeps mode 644" '-rw-r--r--' "$CASE_PAGE"

new_case
cat "$REAL" > "$CASE_PAGE"
chmod 644 "$CASE_PAGE" || exit 2
assert_mode "hide mode 644 before the edit" '-rw-r--r--' "$CASE_PAGE"
write_lines "$CASE_IN" 'hide=q7'
expect_args "hide keeps mode 644 page" 0 'OK hide: q7' hide "$CASE_PAGE" "$CASE_IN"
assert_mode "hide keeps mode 644" '-rw-r--r--' "$CASE_PAGE"

new_case
syn_q7
chmod 600 "$CASE_PAGE" || exit 2
assert_mode "add-card mode 600 before the edit" '-rw-------' "$CASE_PAGE"
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
expect_args "add-card keeps mode 600 page" 0 'OK add-card: q8 before q7' add-card "$CASE_PAGE" "$CASE_IN"
assert_mode "add-card keeps mode 600" '-rw-------' "$CASE_PAGE"

# ---- hide: anchor and block rules on synthetic pages ----

new_case
syn_q7
write_lines "$CASE_IN" 'hide=q99'
expect_unchanged "hide missing anchor" 1 'FAIL hide: anchor q99 not found' hide "$CASE_PAGE" "$CASE_IN"

new_case
syn_q7
write_lines "$CASE_IN" 'hide=q7'
expect_unchanged "hide card without context block" 1 'FAIL hide: anchor c-q7 not found' hide "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p id="q7">a</p>' '  <p id="q7">b</p>' '  <div id="c-q7">c</div>' '</main>'
write_lines "$CASE_IN" 'hide=q7'
expect_unchanged "hide repeated anchor" 1 'FAIL hide: anchor q7 repeated' hide "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p data-id="q7">a</p>' '  <a href="#q7">b</a>' '  <div id="c-q7">c</div>' '</main>'
write_lines "$CASE_IN" 'hide=q7'
expect_unchanged "hide data-id and href not counted" 1 'FAIL hide: anchor q7 not found' hide "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <article class="q" id="q7">' '    <div class="qhead">' '      <a href="#c-q7">Q7</a>' \
  '    </div>' '    <p>x</p>' '  </article>' '  <div class="ctx" id="c-q7">' '    <div class="inner">' '      <p>y</p>' \
  '    </div>' '  </div>' '  <p>keep</p>' '</main>'
write_lines "$CASE_IN" 'hide=q7'
write_lines "$CASE_DIR/want.html" '<main>' '  <p>keep</p>' '</main>'
expect_args "hide nested closing tags at deeper indent" 0 'OK hide: q7' hide "$CASE_PAGE" "$CASE_IN"
assert_file_eq "hide nested closing tags: both blocks end at their own closing line" \
  "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
write_lines "$CASE_PAGE" '<main>' '  <article class="q" id="q7"><p>x</p></article>' \
  '  <div class="ctx" id="c-q7"><p>y</p></div>' '  <p>keep</p>' '</main>'
write_lines "$CASE_IN" 'hide=q7'
write_lines "$CASE_DIR/want.html" '<main>' '  <p>keep</p>' '</main>'
expect_args "hide single-line blocks" 0 'OK hide: q7' hide "$CASE_PAGE" "$CASE_IN"
assert_file_eq "hide single-line blocks: both lines gone" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
cat "$REAL" > "$CASE_PAGE"
write_lines "$CASE_IN" 'hide=q7' 'hide=q99'
expect_unchanged "hide failing id among several removes nothing" 1 'FAIL hide: anchor q99 not found' \
  hide "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p>nothing here</p>' '</main>'
: > "$CASE_IN"
expect_unchanged "hide no hide key" 1 'FAIL hide: missing key hide' hide "$CASE_PAGE" "$CASE_IN"

# ---- hide: non-ASCII input (page unchanged) ----

new_case
cat "$REAL" > "$CASE_PAGE"
printf 'hide=q7\303\251\n' > "$CASE_IN"
expect_unchanged "hide UTF-8 byte" 1 'FAIL hide: input has a non-ASCII character' hide "$CASE_PAGE" "$CASE_IN"

new_case
cat "$REAL" > "$CASE_PAGE"
printf 'hide=q7\351\n' > "$CASE_IN"
expect_unchanged "hide stray byte 351" 1 'FAIL hide: input has a non-ASCII character' hide "$CASE_PAGE" "$CASE_IN"

new_case
cat "$REAL" > "$CASE_PAGE"
printf 'hide=q7\177\n' > "$CASE_IN"
expect_unchanged "hide DEL byte" 1 'FAIL hide: input has a non-ASCII character' hide "$CASE_PAGE" "$CASE_IN"

# ---- usage errors (exit 2, usage on stderr, nothing on stdout) ----

new_case
syn_q7
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
expect_usage "usage no arguments"
expect_usage "usage one argument" add-card
expect_usage "usage two arguments" add-card "$CASE_PAGE"
expect_usage "usage four arguments" add-card "$CASE_PAGE" "$CASE_IN" extra
expect_usage "usage hide with two arguments" hide "$CASE_PAGE"
expect_usage "usage unknown op" bogus "$CASE_PAGE" "$CASE_IN"
expect_usage "usage unknown op frobnicate" frobnicate "$CASE_PAGE" "$CASE_IN"

# ---- unreadable page or input ----

new_case
syn_q7
write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
expect_args "add-card page missing" 1 "FAIL add-card: cannot read $CASE_DIR/missing.html" \
  add-card "$CASE_DIR/missing.html" "$CASE_IN"
expect_args "add-card page is a directory" 1 "FAIL add-card: cannot read $CASE_DIR/page" \
  add-card "$CASE_DIR/page" "$CASE_IN"
expect_args "add-card input is a directory" 1 "FAIL add-card: cannot read $CASE_DIR/page" \
  add-card "$CASE_PAGE" "$CASE_DIR/page"
expect_args "hide page is a directory" 1 "FAIL hide: cannot read $CASE_DIR/page" hide "$CASE_DIR/page" "$CASE_IN"
expect_args "hide input missing" 1 "FAIL hide: cannot read $CASE_DIR/missing.txt" \
  hide "$CASE_PAGE" "$CASE_DIR/missing.txt"

# ---- status, ready-add and ready-remove: shared fixtures ----

# replace_line <src> <dst> <line> <text>: writes src to dst with the given line replaced by text.
replace_line() {
  { sed -n "1,$(($3 - 1))p" "$1"; printf '%s\n' "$4"; sed -n "$(($3 + 1)),\$p" "$1"; } > "$2" || exit 2
}

# The real template with the older Ready to merge entry given pr 130 (the placeholder value is "filled").
READY130=$TEST_TMP/ready130.html
sed 's/data-pr="filled"/data-pr="130"/' "$REAL" > "$READY130" || exit 2
N_READY=$(line_of "$REAL" 'id="ready">')
N_UL=$((N_READY + 1))
N_LI=$((N_READY + 2))
write_lines "$TEST_TMP/ul-want.txt" '    <ul>'
sed -n "${N_UL}p" "$REAL" > "$TEST_TMP/ul-got.txt" || exit 2
assert_file_eq "ready list: the ul line sits right after the ready heading" "$TEST_TMP/ul-want.txt" "$TEST_TMP/ul-got.txt"

ENTRY131='<a href="https://example.test/pull/131">Repo PR 131</a> (427): Summary &amp; notes'
LI131="      <li data-pr=\"131\">$ENTRY131</li>"

# ---- status on the real template ----

new_case
cat "$REAL" > "$CASE_PAGE"
N_W=$(line_of "$REAL" 'data-status="Working"')
replace_line "$REAL" "$CASE_DIR/want.html" "$N_W" '    <p class="meta" data-status="Working">Working: Two runners on 427</p>'
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
write_lines "$CASE_IN" 'status=Working' 'text=Two runners on 427'
expect_args "status Working real template" 0 'OK status: Working' status "$CASE_PAGE" "$CASE_IN"
assert_file_eq "status Working: only the Working line changes" "$CASE_DIR/want.html" "$CASE_PAGE"
assert_listing_same "status Working: no temp file left beside the page" "$CASE_DIR/listing-before"

new_case
cat "$REAL" > "$CASE_PAGE"
N_N=$(line_of "$REAL" 'data-status="Needs you"')
replace_line "$REAL" "$CASE_DIR/want.html" "$N_N" '    <p class="meta" data-status="Needs you">Needs you: Owner answer for Q7</p>'
write_lines "$CASE_IN" 'status=Needs you' 'text=Owner answer for Q7'
expect_args "status Needs you real template" 0 'OK status: Needs you' status "$CASE_PAGE" "$CASE_IN"
assert_file_eq "status Needs you: label with a space, Working line untouched" "$CASE_DIR/want.html" "$CASE_PAGE"

# ---- status: anchor rules and failures on synthetic pages ----

new_case
write_lines "$CASE_PAGE" '<main>' '  <p data-status="Working">Working: a</p>' '</main>'
write_lines "$CASE_IN" 'status=Needs you' 'text=x'
expect_unchanged "status label missing" 1 'FAIL status: label Needs you not found' status "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p data-status="Working">Working: a</p>' '  <p data-status="Working">Working: b</p>' '</main>'
write_lines "$CASE_IN" 'status=Working' 'text=c'
expect_unchanged "status label repeated" 1 'FAIL status: label Working repeated' status "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p data-status="Working">Working: a' '</main>'
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
write_lines "$CASE_IN" 'status=Working' 'text=b'
expect_unchanged "status line has no closing tag" 1 'FAIL status: label Working has no closing tag on its line' \
  status "$CASE_PAGE" "$CASE_IN"
assert_listing_same "status line has no closing tag: no temp file left beside the page" "$CASE_DIR/listing-before"

new_case
write_lines "$CASE_PAGE" '<main>' '  data-status="Working">Working: a</p>' '</main>'
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
write_lines "$CASE_IN" 'status=Working' 'text=b'
expect_unchanged "status line has no opening tag before the attribute" 1 \
  'FAIL status: label Working has no closing tag on its line' status "$CASE_PAGE" "$CASE_IN"
assert_listing_same "status line has no opening tag: no temp file left beside the page" "$CASE_DIR/listing-before"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p data-status="Working" x' '</main>'
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
write_lines "$CASE_IN" 'status=Working' 'text=b'
expect_unchanged "status line has no closing angle bracket after the attribute" 1 \
  'FAIL status: label Working has no closing tag on its line' status "$CASE_PAGE" "$CASE_IN"
assert_listing_same "status line has no closing angle bracket: no temp file left beside the page" "$CASE_DIR/listing-before"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p data-status="Working">Working: a</p>' '</main>'
write_lines "$CASE_IN" 'status=Work' 'text=b'
expect_unchanged "status label is a prefix of the attribute value" 1 'FAIL status: label Work not found' \
  status "$CASE_PAGE" "$CASE_IN"

for _st_pre in x x- x_ 1; do
  new_case
  write_lines "$CASE_PAGE" '<main>' "  <p ${_st_pre}data-status=\"Working\">Working: a</p>" '</main>'
  write_lines "$CASE_IN" 'status=Working' 'text=b'
  expect_unchanged "status boundary: char before data-status is $_st_pre" 1 \
    'FAIL status: label Working not found' status "$CASE_PAGE" "$CASE_IN"
done

new_case
cat "$REAL" > "$CASE_PAGE"
write_lines "$CASE_IN" 'status=Working'
expect_unchanged "status without text" 1 'FAIL status: missing key text' status "$CASE_PAGE" "$CASE_IN"

new_case
cat "$REAL" > "$CASE_PAGE"
write_lines "$CASE_IN" 'status=Working' 'text='
expect_unchanged "status with empty text" 1 'FAIL status: missing key text' status "$CASE_PAGE" "$CASE_IN"

new_case
cat "$REAL" > "$CASE_PAGE"
write_lines "$CASE_IN" 'text=x'
expect_unchanged "status without status label" 1 'FAIL status: missing key status' status "$CASE_PAGE" "$CASE_IN"

new_case
cat "$REAL" > "$CASE_PAGE"
write_lines "$CASE_IN" 'status=' 'text=x'
expect_unchanged "status with empty label" 1 'FAIL status: missing key status' status "$CASE_PAGE" "$CASE_IN"

new_case
cat "$REAL" > "$CASE_PAGE"
printf 'status=Working\ntext=Two\303\251\n' > "$CASE_IN"
expect_unchanged "status UTF-8 text" 1 'FAIL status: input has a non-ASCII character' status "$CASE_PAGE" "$CASE_IN"

new_case
cat "$REAL" > "$CASE_PAGE"
printf 'status=Working\ntext=x\351\n' > "$CASE_IN"
expect_unchanged "status stray byte 351" 1 'FAIL status: input has a non-ASCII character' status "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p data-status="Working">Working: a</p>' '</main>'
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
write_lines "$CASE_IN" 'status=Needs you' 'text=x'
expect_unchanged "status failure leaves no temp file" 1 'FAIL status: label Needs you not found' \
  status "$CASE_PAGE" "$CASE_IN"
assert_listing_same "status failure: no temp file left beside the page" "$CASE_DIR/listing-before"

# ---- ready-add on the real template ----

new_case
cat "$READY130" > "$CASE_PAGE"
insert_above "$READY130" "$CASE_DIR/want.html" "$N_LI" "$LI131"
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
write_lines "$CASE_IN" 'pr=131' "entry=$ENTRY131"
expect_args "ready-add 131 above the older entry" 0 'OK ready-add: 131' ready-add "$CASE_PAGE" "$CASE_IN"
assert_file_eq "ready-add 131: new li first in the list, indent two more than the ul" "$CASE_DIR/want.html" "$CASE_PAGE"
assert_listing_same "ready-add 131: no temp file left beside the page" "$CASE_DIR/listing-before"

new_case
sed "${N_LI}d" "$REAL" > "$CASE_PAGE" || exit 2
cat "$CASE_PAGE" > "$CASE_DIR/empty.html"
insert_above "$CASE_DIR/empty.html" "$CASE_DIR/want.html" "$N_LI" "$LI131"
write_lines "$CASE_IN" 'pr=131' "entry=$ENTRY131"
expect_args "ready-add into an empty list" 0 'OK ready-add: 131' ready-add "$CASE_PAGE" "$CASE_IN"
assert_file_eq "ready-add into an empty list: li directly below the ul line" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
cat "$READY130" > "$CASE_PAGE"
cat "$READY130" > "$CASE_DIR/orig.html"
write_lines "$CASE_IN" 'pr=131' "entry=$ENTRY131"
expect_args "ready-add 131 before its removal" 0 'OK ready-add: 131' ready-add "$CASE_PAGE" "$CASE_IN"
write_lines "$CASE_IN" 'pr=131'
expect_args "ready-remove 131 again" 0 'OK ready-remove: 131' ready-remove "$CASE_PAGE" "$CASE_IN"
assert_file_eq "ready-remove 131 again: page byte-identical to the page before the add" "$CASE_DIR/orig.html" "$CASE_PAGE"

new_case
cat "$READY130" > "$CASE_PAGE"
grep -v 'data-pr="130"' "$READY130" > "$CASE_DIR/want.html" || exit 2
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
write_lines "$CASE_IN" 'pr=130'
expect_args "ready-remove the older entry 130" 0 'OK ready-remove: 130' ready-remove "$CASE_PAGE" "$CASE_IN"
assert_file_eq "ready-remove 130: its li line gone, rest byte-identical" "$CASE_DIR/want.html" "$CASE_PAGE"
assert_listing_same "ready-remove 130: no temp file left beside the page" "$CASE_DIR/listing-before"

# ---- ready-add: failures on the real template ----

new_case
cat "$READY130" > "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=130' "entry=$ENTRY131"
expect_unchanged "ready-add pr already listed" 1 'FAIL ready-add: pr 130 already listed' ready-add "$CASE_PAGE" "$CASE_IN"

for _ra_pr in abc 13x ''; do
  new_case
  cat "$READY130" > "$CASE_PAGE"
  write_lines "$CASE_IN" "pr=$_ra_pr" "entry=$ENTRY131"
  expect_unchanged "ready-add pr not a number: [$_ra_pr]" 1 'FAIL ready-add: pr must be a number' \
    ready-add "$CASE_PAGE" "$CASE_IN"
done

new_case
cat "$READY130" > "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=131'
expect_unchanged "ready-add without entry" 1 'FAIL ready-add: missing key entry' ready-add "$CASE_PAGE" "$CASE_IN"

new_case
cat "$READY130" > "$CASE_PAGE"
printf 'pr=131\nentry=Caf\303\251\n' > "$CASE_IN"
expect_unchanged "ready-add UTF-8 entry" 1 'FAIL ready-add: input has a non-ASCII character' ready-add "$CASE_PAGE" "$CASE_IN"

new_case
cat "$READY130" > "$CASE_PAGE"
printf 'pr=131\nentry=x\351\n' > "$CASE_IN"
expect_unchanged "ready-add stray byte 351" 1 'FAIL ready-add: input has a non-ASCII character' ready-add "$CASE_PAGE" "$CASE_IN"

new_case
cat "$READY130" > "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=130' "entry=$ENTRY131"
snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
save_page
run_edit ready-add "$CASE_PAGE" "$CASE_IN"
assert_exit "ready-add failure exit" 1 "$RC"
assert_listing_same "ready-add failure: no temp file left beside the page" "$CASE_DIR/listing-before"

# ---- ready-add: the pr boundary and the ready anchor on synthetic pages ----

for _ra_pre in x x- x_ 1; do
  new_case
  write_lines "$CASE_PAGE" '<main>' '  <h2 id="ready">Ready to merge</h2>' '  <ul>' "    <li ${_ra_pre}data-pr=\"131\">old</li>" '  </ul>' '</main>'
  write_lines "$CASE_DIR/want.html" '<main>' '  <h2 id="ready">Ready to merge</h2>' '  <ul>' '    <li data-pr="131">Entry</li>' \
    "    <li ${_ra_pre}data-pr=\"131\">old</li>" '  </ul>' '</main>'
  write_lines "$CASE_IN" 'pr=131' 'entry=Entry'
  expect_args "ready-add 131 beside a non-matching data-pr: char before is $_ra_pre" 0 'OK ready-add: 131' \
    ready-add "$CASE_PAGE" "$CASE_IN"
  assert_file_eq "ready-add 131 beside $_ra_pre data-pr: inserted under the ul" "$CASE_DIR/want.html" "$CASE_PAGE"
done

new_case
write_lines "$CASE_PAGE" '<main>' '  <h2 id="ready">Ready to merge</h2>' '  <ul>' '    <li data-pr="1310">old</li>' '  </ul>' '</main>'
write_lines "$CASE_DIR/want.html" '<main>' '  <h2 id="ready">Ready to merge</h2>' '  <ul>' '    <li data-pr="131">Entry</li>' \
  '    <li data-pr="1310">old</li>' '  </ul>' '</main>'
write_lines "$CASE_IN" 'pr=131' 'entry=Entry'
expect_args "ready-add 131 with data-pr 1310 on the page" 0 'OK ready-add: 131' ready-add "$CASE_PAGE" "$CASE_IN"
assert_file_eq "ready-add 131: data-pr=\"1310\" is another pr" "$CASE_DIR/want.html" "$CASE_PAGE"

new_case
write_lines "$CASE_PAGE" '<main>' '  <p>nothing here</p>' '</main>'
write_lines "$CASE_IN" 'pr=131' 'entry=Entry'
expect_unchanged "ready-add anchor ready missing" 1 'FAIL ready-add: anchor ready not found' ready-add "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <h2 data-id="ready">Ready</h2>' '  <ul>' '  </ul>' '</main>'
write_lines "$CASE_IN" 'pr=131' 'entry=Entry'
expect_unchanged "ready-add data-id is not the anchor" 1 'FAIL ready-add: anchor ready not found' \
  ready-add "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <h2 id="ready">Ready</h2>' '  <h2 id="ready">Ready again</h2>' '  <ul>' '  </ul>' '</main>'
write_lines "$CASE_IN" 'pr=131' 'entry=Entry'
expect_unchanged "ready-add anchor ready repeated" 1 'FAIL ready-add: anchor ready repeated' ready-add "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <ul>' '    <li>old</li>' '  </ul>' '  <h2 id="ready">Ready to merge</h2>' '</main>'
write_lines "$CASE_IN" 'pr=131' 'entry=Entry'
expect_unchanged "ready-add no list after the anchor" 1 'FAIL ready-add: no list after anchor ready' \
  ready-add "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <ul>' '    <li>old</li>' '  </ul>' '  <h2 id="ready">Ready to merge</h2>' '  <ul>' '  </ul>' '</main>'
write_lines "$CASE_DIR/want.html" '<main>' '  <ul>' '    <li>old</li>' '  </ul>' '  <h2 id="ready">Ready to merge</h2>' '  <ul>' \
  '    <li data-pr="131">Entry</li>' '  </ul>' '</main>'
write_lines "$CASE_IN" 'pr=131' 'entry=Entry'
expect_args "ready-add uses the first ul after the anchor" 0 'OK ready-add: 131' ready-add "$CASE_PAGE" "$CASE_IN"
assert_file_eq "ready-add: the li goes under the ul after the anchor, not the one before" "$CASE_DIR/want.html" "$CASE_PAGE"

# ---- ready-remove: the pr rules and the block rule ----

for _rr_pre in x x- x_ 1; do
  new_case
  write_lines "$CASE_PAGE" '<main>' '  <ul>' "    <li ${_rr_pre}data-pr=\"131\">old</li>" '  </ul>' '</main>'
  cat "$CASE_PAGE" > "$CASE_DIR/saved"
  write_lines "$CASE_IN" 'pr=131'
  expect_args "ready-remove 131 beside a non-matching data-pr: char before is $_rr_pre" 1 \
    'FAIL ready-remove: pr 131 not found' ready-remove "$CASE_PAGE" "$CASE_IN"
  assert_unchanged "ready-remove boundary $_rr_pre: page unchanged"
done

new_case
write_lines "$CASE_PAGE" '<main>' '  <ul>' '    <li data-pr="1310">old</li>' '  </ul>' '</main>'
save_page
write_lines "$CASE_IN" 'pr=131'
expect_args "ready-remove 131 with only data-pr 1310 listed" 1 'FAIL ready-remove: pr 131 not found' \
  ready-remove "$CASE_PAGE" "$CASE_IN"
assert_unchanged "ready-remove 131 with only 1310: page unchanged"

new_case
write_lines "$CASE_PAGE" '<main>' '  <ul>' '    <li data-pr="131">a</li>' '    <li data-pr="131">b</li>' '  </ul>' '</main>'
save_page
write_lines "$CASE_IN" 'pr=131'
expect_args "ready-remove pr repeated" 1 'FAIL ready-remove: pr 131 repeated' ready-remove "$CASE_PAGE" "$CASE_IN"
assert_unchanged "ready-remove pr repeated: page unchanged"

new_case
cat "$READY130" > "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=131'
expect_unchanged "ready-remove pr absent" 1 'FAIL ready-remove: pr 131 not found' ready-remove "$CASE_PAGE" "$CASE_IN"

new_case
cat "$READY130" > "$CASE_PAGE"
: > "$CASE_IN"
expect_unchanged "ready-remove without pr" 1 'FAIL ready-remove: missing key pr' ready-remove "$CASE_PAGE" "$CASE_IN"

for _rr_pr in abc 13x ''; do
  new_case
  cat "$READY130" > "$CASE_PAGE"
  write_lines "$CASE_IN" "pr=$_rr_pr"
  expect_unchanged "ready-remove pr not a number: [$_rr_pr]" 1 'FAIL ready-remove: pr must be a number' \
    ready-remove "$CASE_PAGE" "$CASE_IN"
done

new_case
cat "$READY130" > "$CASE_PAGE"
printf 'pr=131\303\251\n' > "$CASE_IN"
expect_unchanged "ready-remove UTF-8 pr" 1 'FAIL ready-remove: input has a non-ASCII character' ready-remove "$CASE_PAGE" "$CASE_IN"

new_case
cat "$READY130" > "$CASE_PAGE"
printf 'pr=131\351\n' > "$CASE_IN"
expect_unchanged "ready-remove stray byte 351" 1 'FAIL ready-remove: input has a non-ASCII character' ready-remove "$CASE_PAGE" "$CASE_IN"

new_case
write_lines "$CASE_PAGE" '<main>' '  <h2 id="ready">Ready to merge</h2>' '  <ul>' '    <li data-pr="131">' '      <li>' \
  '      </li>' '    </li>' '    <li data-pr="130">Older</li>' '  </ul>' '</main>'
write_lines "$CASE_DIR/want.html" '<main>' '  <h2 id="ready">Ready to merge</h2>' '  <ul>' '    <li data-pr="130">Older</li>' '  </ul>' '</main>'
write_lines "$CASE_IN" 'pr=131'
expect_args "ready-remove a multi-line li whole" 0 'OK ready-remove: 131' ready-remove "$CASE_PAGE" "$CASE_IN"
assert_file_eq "ready-remove 131: block ends at its own closing tag, nested closing tag at deeper indent ignored" \
  "$CASE_DIR/want.html" "$CASE_PAGE"

# ---- every op: a failure after the temp file exists leaves no temp file ----

# stub_tool <tool> <real path> <case pattern>: writes CASE_DIR/bin/<tool>, a stand-in that exits 1 when its arguments
# ("$*") match the case pattern (a glob with no spaces) and otherwise runs the real tool.
# The single-quoted lines are stub source text, so their $ must stay unexpanded.
# shellcheck disable=SC2016
stub_tool() {
  mkdir -p "$CASE_DIR/bin" || exit 2
  printf '%s\n' '#!/bin/sh' 'case "$*" in' "  $3) exit 1 ;;" 'esac' "exec \"$2\" \"\$@\"" > "$CASE_DIR/bin/$1" || exit 2
  chmod +x "$CASE_DIR/bin/$1" || exit 2
}

# op_case <op>: a fresh case holding the page and the input that the op edits.
op_case() {
  new_case
  case "$1" in
    add-card)
      cat "$REAL" > "$CASE_PAGE"
      write_lines "$CASE_IN" 'before=q7' "card=$CARD8"
      ;;
    hide)
      cat "$REAL" > "$CASE_PAGE"
      write_lines "$CASE_IN" 'hide=q7'
      ;;
    status)
      cat "$REAL" > "$CASE_PAGE"
      write_lines "$CASE_IN" 'status=Working' 'text=Two runners on 427'
      ;;
    ready-add)
      cat "$READY130" > "$CASE_PAGE"
      write_lines "$CASE_IN" 'pr=131' "entry=$ENTRY131"
      ;;
    ready-remove)
      cat "$READY130" > "$CASE_PAGE"
      write_lines "$CASE_IN" 'pr=130'
      ;;
  esac
}

# expect_temp_gone <name> <op> <reason>: runs the op with the case's stubs first on PATH. The run exits 1 with the one
# FAIL line, leaves the page byte-identical and leaves no temp file beside the page.
expect_temp_gone() {
  snapshot_dir "$CASE_DIR/page" "$CASE_DIR/listing-before"
  save_page
  RC=0
  PATH="$CASE_DIR/bin:$PATH" sh "$PAGE_EDIT" "$2" "$CASE_PAGE" "$CASE_IN" > "$CASE_DIR/out" 2> "$CASE_DIR/err" || RC=$?
  assert_exit "$1 exit" 1 "$RC"
  assert_stdout "$1 stdout" "FAIL $2: $3" "$CASE_DIR/out"
  assert_empty "$1 stderr" "$CASE_DIR/err"
  assert_unchanged "$1"
  assert_listing_same "$1: no temp file left beside the page" "$CASE_DIR/listing-before"
}

for _pt_op in add-card hide status ready-add ready-remove; do
  case "$_pt_op" in
    add-card) _pt_awk='*n1*' ;;
    status) _pt_awk='*open_end*' ;;
    ready-add) _pt_awk='*ENTRY_HTML*' ;;
    *) _pt_awk='*RANGES*' ;;
  esac
  op_case "$_pt_op"
  stub_tool cp "$REAL_CP" '-p*'
  expect_temp_gone "$_pt_op: mode copy fails after the temp file exists" "$_pt_op" "cannot copy the mode of $CASE_PAGE"
  op_case "$_pt_op"
  stub_tool awk "$REAL_AWK" "$_pt_awk"
  expect_temp_gone "$_pt_op: awk write fails after the temp file exists" "$_pt_op" \
    "cannot write a temp file beside $CASE_PAGE"
  op_case "$_pt_op"
  stub_tool mv "$REAL_MV" '*'
  expect_temp_gone "$_pt_op: move over the page fails after the temp file exists" "$_pt_op" "cannot write $CASE_PAGE"
done

# ---- status, ready-add and ready-remove: unreadable page or input ----

new_case
cat "$REAL" > "$CASE_PAGE"
write_lines "$CASE_IN" 'status=Working' 'text=x'
expect_args "status page missing" 1 "FAIL status: cannot read $CASE_DIR/missing.html" \
  status "$CASE_DIR/missing.html" "$CASE_IN"
expect_args "status page is a directory" 1 "FAIL status: cannot read $CASE_DIR/page" \
  status "$CASE_DIR/page" "$CASE_IN"
expect_args "status input missing" 1 "FAIL status: cannot read $CASE_DIR/missing.txt" \
  status "$CASE_PAGE" "$CASE_DIR/missing.txt"
expect_args "status input is a directory" 1 "FAIL status: cannot read $CASE_DIR/page" \
  status "$CASE_PAGE" "$CASE_DIR/page"

new_case
cat "$READY130" > "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=131' "entry=$ENTRY131"
expect_args "ready-add page missing" 1 "FAIL ready-add: cannot read $CASE_DIR/missing.html" \
  ready-add "$CASE_DIR/missing.html" "$CASE_IN"
expect_args "ready-add page is a directory" 1 "FAIL ready-add: cannot read $CASE_DIR/page" \
  ready-add "$CASE_DIR/page" "$CASE_IN"
expect_args "ready-add input missing" 1 "FAIL ready-add: cannot read $CASE_DIR/missing.txt" \
  ready-add "$CASE_PAGE" "$CASE_DIR/missing.txt"
expect_args "ready-add input is a directory" 1 "FAIL ready-add: cannot read $CASE_DIR/page" \
  ready-add "$CASE_PAGE" "$CASE_DIR/page"

new_case
cat "$READY130" > "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=130'
expect_args "ready-remove page missing" 1 "FAIL ready-remove: cannot read $CASE_DIR/missing.html" \
  ready-remove "$CASE_DIR/missing.html" "$CASE_IN"
expect_args "ready-remove page is a directory" 1 "FAIL ready-remove: cannot read $CASE_DIR/page" \
  ready-remove "$CASE_DIR/page" "$CASE_IN"
expect_args "ready-remove input missing" 1 "FAIL ready-remove: cannot read $CASE_DIR/missing.txt" \
  ready-remove "$CASE_PAGE" "$CASE_DIR/missing.txt"
expect_args "ready-remove input is a directory" 1 "FAIL ready-remove: cannot read $CASE_DIR/page" \
  ready-remove "$CASE_PAGE" "$CASE_DIR/page"

# ---- status, ready-add and ready-remove: missing keys ----

new_case
cat "$READY130" > "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=131'
expect_unchanged "ready-add without entry key" 1 'FAIL ready-add: missing key entry' ready-add "$CASE_PAGE" "$CASE_IN"

# ---- status, ready-add and ready-remove: page file mode ----

new_case
cat "$REAL" > "$CASE_PAGE"
chmod 644 "$CASE_PAGE" || exit 2
assert_mode "status mode 644 before the edit" '-rw-r--r--' "$CASE_PAGE"
write_lines "$CASE_IN" 'status=Needs you' 'text=Owner answer'
expect_args "status keeps mode 644 page" 0 'OK status: Needs you' status "$CASE_PAGE" "$CASE_IN"
assert_mode "status keeps mode 644" '-rw-r--r--' "$CASE_PAGE"

new_case
cat "$REAL" > "$CASE_PAGE"
chmod 600 "$CASE_PAGE" || exit 2
assert_mode "status mode 600 before the edit" '-rw-------' "$CASE_PAGE"
write_lines "$CASE_IN" 'status=Needs you' 'text=Owner answer'
expect_args "status keeps mode 600 page" 0 'OK status: Needs you' status "$CASE_PAGE" "$CASE_IN"
assert_mode "status keeps mode 600" '-rw-------' "$CASE_PAGE"

new_case
cat "$READY130" > "$CASE_PAGE"
chmod 644 "$CASE_PAGE" || exit 2
assert_mode "ready-add mode 644 before the edit" '-rw-r--r--' "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=131' "entry=$ENTRY131"
expect_args "ready-add keeps mode 644 page" 0 'OK ready-add: 131' ready-add "$CASE_PAGE" "$CASE_IN"
assert_mode "ready-add keeps mode 644" '-rw-r--r--' "$CASE_PAGE"

new_case
cat "$READY130" > "$CASE_PAGE"
chmod 600 "$CASE_PAGE" || exit 2
assert_mode "ready-add mode 600 before the edit" '-rw-------' "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=131' "entry=$ENTRY131"
expect_args "ready-add keeps mode 600 page" 0 'OK ready-add: 131' ready-add "$CASE_PAGE" "$CASE_IN"
assert_mode "ready-add keeps mode 600" '-rw-------' "$CASE_PAGE"

new_case
cat "$READY130" > "$CASE_PAGE"
chmod 644 "$CASE_PAGE" || exit 2
assert_mode "ready-remove mode 644 before the edit" '-rw-r--r--' "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=130'
expect_args "ready-remove keeps mode 644 page" 0 'OK ready-remove: 130' ready-remove "$CASE_PAGE" "$CASE_IN"
assert_mode "ready-remove keeps mode 644" '-rw-r--r--' "$CASE_PAGE"

new_case
cat "$READY130" > "$CASE_PAGE"
chmod 600 "$CASE_PAGE" || exit 2
assert_mode "ready-remove mode 600 before the edit" '-rw-------' "$CASE_PAGE"
write_lines "$CASE_IN" 'pr=130'
expect_args "ready-remove keeps mode 600 page" 0 'OK ready-remove: 130' ready-remove "$CASE_PAGE" "$CASE_IN"
assert_mode "ready-remove keeps mode 600" '-rw-------' "$CASE_PAGE"

test_summary
