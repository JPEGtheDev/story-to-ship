#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review
: > src/__init__.py
printf "# Demo\n" > README.md
cat > src/export.py <<'PY'
import time


def export_rows(rows):
    """Return CSV text for rows (lists of values)."""
    lines = []
    for row in rows:
        lines.append(",".join(str(v) for v in row))
    return "\n".join(lines) + "\n"


def send_with_retry(send, attempts=3, sleep=time.sleep):
    """Call send() until it succeeds or attempts run out; re-raise the last error."""
    for attempt in range(attempts):
        try:
            return send()
        except OSError:
            if attempt == attempts - 1:
                raise
            sleep(5)
PY
cat > tests/test_export.py <<'PY'
import unittest

from src.export import export_rows, send_with_retry


class ExportTest(unittest.TestCase):
    def test_rows_without_header(self):
        self.assertEqual(export_rows([[1, 2]]), "1,2\n")

    def test_retry_succeeds_after_one_failure(self):
        calls = []

        def send():
            calls.append(1)
            if len(calls) == 1:
                raise OSError("down")
            return "ok"

        self.assertEqual(send_with_retry(send, sleep=lambda s: None), "ok")


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/export.py <<'PY'
import time


def export_rows(rows, header=None):
    """Return CSV text for rows (lists of values). An optional header row comes first."""
    lines = []
    if header is not None:
        lines.append(",".join(str(h) for h in header))
    for row in rows:
        lines.append(",".join(str(v) for v in row))
    return "\n".join(lines) + "\n"


def send_with_retry(send, attempts=3, sleep=time.sleep):
    """Call send() until it succeeds or attempts run out; re-raise the last error."""
    for attempt in range(attempts):
        try:
            return send()
        except OSError:
            if attempt == attempts - 1:
                raise
            sleep(5)
PY
cat > tests/test_export.py <<'PY'
import unittest

from src.export import export_rows, send_with_retry


class ExportTest(unittest.TestCase):
    def test_rows_without_header(self):
        self.assertEqual(export_rows([[1, 2]]), "1,2\n")

    def test_header_comes_first(self):
        self.assertEqual(export_rows([[1, 2]], header=["a", "b"]), "a,b\n1,2\n")

    def test_retry_succeeds_after_one_failure(self):
        calls = []

        def send():
            calls.append(1)
            if len(calls) == 1:
                raise OSError("down")
            return "ok"

        self.assertEqual(send_with_retry(send, sleep=lambda s: None), "ok")


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/export.py, send_with_retry()

The delay between retries is hard-coded in send_with_retry(). It has nothing to do with the header row this PR adds, and nothing is broken by it today. I noticed it while reading the file.
MD
git add -A
git commit -q -m "feat: add optional header row to the CSV export"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
