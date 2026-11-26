#!/usr/bin/env bash
set -eu

cat > plan.md <<'EOF'
# Cleanup plan

Step 1: rename the helper module utils.py to helpers.py
Step 2: remove the legacy/ folder (old importers, 3 files)
Step 3: update the README to describe the new layout
EOF

printf 'def slugify(text):\n    return text.lower()\n' > utils.py
printf '# Project\n\nSmall utilities and legacy importers.\n' > README.md

mkdir -p legacy
printf 'def import_csv(path):\n    return []\n' > legacy/csv_importer.py
printf 'def import_xml(path):\n    return []\n' > legacy/xml_importer.py
printf 'def import_json(path):\n    return []\n' > legacy/json_importer.py
