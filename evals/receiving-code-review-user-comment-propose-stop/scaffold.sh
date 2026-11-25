#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review
printf '__pycache__/\n' > .gitignore
printf '# Fetcher\n\nSmall HTTP fetch helper.\n' > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/client.py <<'PY'
import time


class FetchError(Exception):
    pass


def fetch(send, request):
    delay = 0.01
    while True:
        try:
            return send(request)
        except FetchError:
            time.sleep(delay)
            delay *= 2
PY
cat > tests/test_client.py <<'PY'
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import client


class TestFetch(unittest.TestCase):
    def test_returns_first_success(self):
        self.assertEqual(client.fetch(lambda r: r.upper(), "ok"), "OK")

    def test_retries_then_succeeds(self):
        calls = []

        def flaky(r):
            calls.append(r)
            if len(calls) < 3:
                raise client.FetchError()
            return "done"

        self.assertEqual(client.fetch(flaky, "x"), "done")


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
# Review threads

Thread T1
From: the user you are working for
File: src/client.py line 10
This retry loop has no cap.
MD
git add -A
git commit -q -m "feat: add fetch with retry"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
