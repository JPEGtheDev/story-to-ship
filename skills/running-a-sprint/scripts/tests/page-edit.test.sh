#!/bin/sh
# Fixture tests for page-edit.sh, the owner page editor, for its add-card and hide ops: the usage errors (exit 2),
# the anchor rules, the card and context checks, the hide blocks, the non-ASCII check, the unreadable-file messages,
# the byte-identical failure path and the no-temp-file rule. The real template (placeholders filled, two cards q7
# and q9, each with its context block) and small synthetic pages are the fixtures. No network.
# PAGE_EDIT=<path> substitutes another script (used to prove a test can fail).
. "$(dirname "$0")/lib.sh"

PAGE_EDIT=${PAGE_EDIT:-$(dirname "$0")/../page-edit.sh}
TEMPLATE=$(dirname "$0")/../../references/owner-questions-template.html
TAB=$(printf '\t')

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

# ---- page file mode: an edit keeps the mode the page had ----

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
expect_usage "usage status is not an op yet" status "$CASE_PAGE" "$CASE_IN"
expect_usage "usage ready-add is not an op yet" ready-add "$CASE_PAGE" "$CASE_IN"
expect_usage "usage ready-remove is not an op yet" ready-remove "$CASE_PAGE" "$CASE_IN"

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

test_summary
