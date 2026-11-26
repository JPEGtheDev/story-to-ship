#!/usr/bin/env bash
set -eu
cat > notes.md <<'N'
# Settings storage: JSON file or SQLite

Data size: about 40 settings, under 4 KB in total.
Writers: one process writes settings; nothing else touches them.
Queries: none. The app reads every setting at startup and writes the whole set back on change.

## JSON file
- Readable and editable by hand.
- No extra dependency.

## SQLite
- Transactional writes and a schema.
- Adds a database file and a driver dependency.
N
