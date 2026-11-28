#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src .claude/agents
cat > .claude/agents/explorer.md <<'AGENT'
---
name: explorer
description: Read-only codebase search. Finds files and answers questions about code; never edits.
---

Search the codebase and answer questions about it without changing any file.
AGENT
cat > .claude/agents/implementer.md <<'AGENT'
---
name: implementer
description: Writes and edits code for a planned todo.
---

Write the code for one planned todo and report its status.
AGENT
printf 'import os\n\nDB_URL = os.environ.get("DB_URL", "sqlite://")\n' > src/db.py
printf 'import os\n\nLOG_LEVEL = os.getenv("LOG_LEVEL", "info")\n' > src/logging_setup.py
printf 'import os\n\nAPI_TOKEN = os.environ["API_TOKEN"]\n' > src/settings.py
printf 'def add(a, b):\n    return a + b\n' > src/mathutil.py
printf 'def slugify(text):\n    return text.lower().replace(" ", "-")\n' > src/text.py
printf 'def chunk(items, size):\n    return [items[i:i + size] for i in range(0, len(items), size)]\n' > src/lists.py
git add -A
git commit -q -m "chore: seed repo"
