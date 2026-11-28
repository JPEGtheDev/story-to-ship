#!/usr/bin/env bash
set -eu
if [ -e .git ] || [ -e .claude-plugin ]; then echo "refusing: not an empty scratch directory" >&2; exit 1; fi
mkdir -p src
cat > app.log <<'LOG'
02:00:00 INFO startup complete
02:00:05 INFO GET /api/health 200
02:02:00 INFO GET /api/users 200
02:04:00 INFO GET /api/health 200
02:05:30 INFO GET /api/orders 200
02:06:10 INFO GET /api/users 200
02:07:45 INFO GET /api/health 200
02:08:20 INFO GET /api/orders 200
02:09:00 INFO GET /api/users 200
02:10:03 ERROR GET /api/export 500
02:10:41 ERROR GET /api/export 500
02:11:17 ERROR GET /api/export 500
02:12:00 INFO GET /api/health 200
02:13:25 INFO GET /api/users 200
02:15:00 INFO GET /api/orders 200
02:16:40 INFO GET /api/health 200
02:18:05 INFO GET /api/users 200
02:20:00 INFO GET /api/health 200
02:22:30 INFO GET /api/orders 200
02:25:00 INFO GET /api/users 200
02:27:15 INFO GET /api/health 200
02:29:50 INFO GET /api/orders 200
02:32:10 INFO GET /api/users 200
02:35:00 INFO GET /api/health 200
02:38:45 INFO GET /api/orders 200
02:42:00 INFO GET /api/users 200
02:46:30 INFO GET /api/health 200
02:51:05 INFO GET /api/orders 200
02:58:20 INFO GET /api/users 200
03:00:00 INFO GET /api/health 200
LOG
cat > src/export.py <<'PY'
import csv
import io

HEADER = ["id", "name", "amount"]


def build_export_csv(rows):
    """Return the export rows as CSV text."""
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(HEADER)
    for row in rows:
        writer.writerow([row["id"], row["name"], row["amount"]])
    buffer.seek(0)
    return buffer.read()
PY
cat > README.md <<'MD'
# orders-service

Serves the orders API. app.log holds the request log for the service.
src/export.py builds the CSV export returned by GET /api/export.
MD
