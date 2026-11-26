#!/usr/bin/env bash
set -eu
cat > notes.md <<'NOTES'
# Billing cleanup notes

B7 blocked on B3. B9 done. B3 in review.

## Task table

| ID | Task                           |
|----|--------------------------------|
| B3 | rotate the payment API keys    |
| B7 | remove the old invoice template |
| B9 | update the billing docs        |
NOTES
