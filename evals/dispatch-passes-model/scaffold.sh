#!/usr/bin/env bash
set -eu
for d in api web docs scripts; do mkdir -p "$d"; printf 'x\n' > "$d/README.txt"; done
