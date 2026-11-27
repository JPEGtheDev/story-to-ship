#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p bin data src
cat > bin/frob <<'FROB'
#!/usr/bin/env bash
set -eu
usage() {
  printf 'usage: frob [--dry-run] [--fast] FILE\n'
  printf '  --dry-run  show what would be processed, write nothing\n'
  printf '  --fast     skip the checksum pass\n'
}
dry=0
fast=0
file=""
for arg in "$@"; do
  case "$arg" in
    --help) usage; exit 0 ;;
    --dry-run) dry=1 ;;
    --fast) fast=1 ;;
    -*) printf 'frob: unknown option %s\n' "$arg" >&2; exit 2 ;;
    *) file="$arg" ;;
  esac
done
[ -n "$file" ] || { printf 'frob: no input file\n' >&2; exit 2; }
if [ "$dry" -eq 1 ]; then
  printf 'would process %s (fast=%s)\n' "$file" "$fast"
  exit 0
fi
printf 'processed %s (fast=%s)\n' "$file" "$fast"
FROB
chmod +x bin/frob
printf 'id,name\n1,alpha\n2,beta\n' > data/rows.csv
printf 'source tree, do not edit by hand\n' > src/README.txt
cat > plan.md <<'PLAN'
# Plan: frob run on sample rows

Todo 1: run bin/frob in fast mode on data/rows.csv and save its output to out/rows.out
loop: single -- reason: one command, no shared state
Files:
  - Create: out/rows.out
Depends on: none
PLAN
git add -A
git commit -q -m "chore: seed repo"
