#!/usr/bin/env bash
set -eu
cat > cache-notes.md <<'EOF'
# Cache investigation log

## Option 1: no cache
- 2026-03-02: Measured the report endpoint with no caching. Each request recomputes totals.
- 2026-03-02: Benchmark run 1: p50 410 ms, p95 880 ms, 120 requests per second.
- 2026-03-03: Benchmark run 2 after warming the database: p50 395 ms, p95 850 ms.
- 2026-03-03: Database CPU sits near 70 percent at peak. Not sustainable if traffic doubles.

## Option 2: in-process cache
- 2026-03-05: Added a dictionary cache with a 60 second expiry inside the app process.
- 2026-03-05: Benchmark run 3: p50 38 ms, p95 95 ms, 900 requests per second.
- 2026-03-06: Each of the 4 app processes holds its own copy, so a value can be up to 60 seconds stale
  and differ between processes. The report data changes hourly, so this is acceptable.
- 2026-03-06: Memory per process grew by 40 MB. Within the 512 MB limit.
- 2026-03-09: Benchmark run 4 under a cold start: p50 410 ms for the first request only, then 38 ms.

## Option 3: Redis cache
- 2026-03-10: Stood up a Redis instance and pointed the app at it with the same 60 second expiry.
- 2026-03-11: Benchmark run 5: p50 52 ms, p95 120 ms, 850 requests per second.
- 2026-03-12: One shared copy, so all processes agree. Adds a network hop and a new service to run.
- 2026-03-13: Redis restarted once during testing and the app fell back to recomputing; p95 rose to 900 ms
  for 20 seconds. No failover is set up.
- 2026-03-16: Estimated cost of a managed Redis plan: 45 dollars per month plus on-call load.

| Option | p50 ms | p95 ms | req/s | New service |
|--------|--------|--------|-------|-------------|
| none | 395 | 850 | 120 | no |
| in-process | 38 | 95 | 900 | no |
| Redis | 52 | 120 | 850 | yes |

Decision needed by Friday: in-process or Redis. Recommend in-process.
EOF
