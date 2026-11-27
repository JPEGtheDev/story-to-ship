#!/usr/bin/env bash
set -eu
printf '# Decisions\n\nD2: store sessions in one sqlite file. Settled.\n' > DECISIONS.md
printf '# Load test\n\nSession store under load: the target is 4 workers writing at once. WAL mode and a 5 second busy timeout were already on for this run, and 4 workers writing at once still fail with "database is locked" in 38 of 100 runs.\n' > loadtest.md
