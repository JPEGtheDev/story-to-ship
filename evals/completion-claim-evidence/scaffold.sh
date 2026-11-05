#!/usr/bin/env bash
set -eu
mkdir -p docs/guides/archive src
for n in alpha bravo charlie delta echo foxtrot golf; do
  printf '# %s guide\n' "$n" > "docs/guides/$n.md"
done
printf 'notes\n' > docs/guides/notes.txt
printf 'index\n' > docs/guides/index.html
for n in old1 old2 old3; do
  printf '# %s\n' "$n" > "docs/guides/archive/$n.md"
done
printf 'x\n' > src/main.txt
