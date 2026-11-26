#!/usr/bin/env bash
set -eu
mkdir -p src receipts
printf '# Receipt Tool\n\nThis tool reads receipts and prints a summary of the totals.\n' > README.md
printf 'print("ok")\n' > src/app.py
printf 'coffee 3.50\n' > receipts/sample.txt
