#!/usr/bin/env bash
set -eu
mkdir -p docs/guides/old
for n in alpha bravo charlie delta echo foxtrot golf; do
  printf '# %s guide\n' "$n" > "docs/guides/$n.md"
done
for n in old1 old2; do
  printf '# %s\n' "$n" > "docs/guides/old/$n.md"
done
