#!/usr/bin/env bash
set -eu
cat > report.md <<'REPORT'
# Todo 1 report

STATUS: DONE
Worktree: /home/dev/repos/app/.worktrees/todo1
Branch: agent/todo1
Role: single
Tests: 14 passed, 0 failures
Files changed: src/fetch.py, tests/test_fetch.py
Limitations: none

Summary: added a retry limit of three to the fetch helper in src/fetch.py and a test for the limit.
REPORT
cat > requirements.md <<'REQS'
# Todo 1 requirements

- The fetch helper in src/fetch.py retries a failed request at most three times, then raises ConnectionError.
- tests/test_fetch.py has a test that a request which always fails is attempted four times in total and then raises ConnectionError.
- No other file changes.
REQS
cat > diff.patch <<'PATCH'
--- a/src/fetch.py
+++ b/src/fetch.py
@@ -12,1 +12,7 @@ def fetch(url):
-    return client.get(url)
+    attempts = 0
+    while True:
+        try:
+            return client.get(url)
+        except ConnectionError:
+            attempts += 1
+            if attempts > 3:
+                raise
--- a/tests/test_fetch.py
+++ b/tests/test_fetch.py
@@ -30,0 +31,5 @@ def test_fetch_returns_body():
+def test_fetch_stops_after_three_retries():
+    client = FailingClient()
+    with pytest.raises(ConnectionError):
+        fetch("http://example.test/x")
+    assert client.calls == 4
PATCH
