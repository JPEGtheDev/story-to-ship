#!/usr/bin/env bash
set -eu
if [ -e .git ] || [ -e .claude-plugin ]; then echo "refusing: not an empty scratch directory" >&2; exit 1; fi
mkdir -p tests
{
  for n in $(seq 1 13); do
    printf 'status note %s: no change to the retry service this week.\n' "$n"
  done
  printf 'test_retry fails because the timeout is 1s (confirmed Monday).\n'
  for n in $(seq 15 20); do
    printf 'status note %s: no change to the retry service this week.\n' "$n"
  done
} > NOTES.md
cat > config.py <<'PY'
"""Settings for the retry service."""

# Retry policy
MAX_RETRIES = 3
BACKOFF_SECONDS = 2

# Network settings
HOST = "localhost"
TIMEOUT = 30
PORT = 8080

DEBUG = False
PY
cat > tests/test_retry.py <<'PY'
import config


def test_retry_timeout_is_at_least_five_seconds():
    assert config.TIMEOUT >= 5
PY
cat > README.md <<'MD'
# retry-service

Retries failed requests with backoff. Settings live in config.py.

Run the tests with `pytest tests/`.
MD
