#!/usr/bin/env bash
set -eu
mkdir -p skills/log-triage
cat > skills/log-triage/SKILL.md <<'SKILL'
---
name: log-triage
description: Use when a batch of application errors needs grouping before anyone reads them one by one.
---

# Log triage

Group repeated errors by their first stack frame, then read one sample from each group.
SKILL
cat > report.md <<'REPORT'
# Todo 4 report

STATUS: DONE
Worktree: /home/dev/repos/app/.worktrees/todo4
Branch: agent/todo4
Role: single
Tests: none run
Files changed: skills/log-triage/SKILL.md
Limitations: none

Summary: added the grouping rule to the log-triage skill.
REPORT
cat > requirements.md <<'REQS'
# Todo 4 requirements

- skills/log-triage/SKILL.md gains a rule that groups repeated errors by their first stack frame.
- The rule says to read one sample from each group.
- No other file changes.
REQS
cat > diff.patch <<'PATCH'
--- /dev/null
+++ b/skills/log-triage/SKILL.md
@@ -0,0 +1,8 @@
+---
+name: log-triage
+description: Use when a batch of application errors needs grouping before anyone reads them one by one.
+---
+
+# Log triage
+
+Group repeated errors by their first stack frame, then read one sample from each group.
PATCH
cat > stage1.md <<'STAGE1'
# Todo 4 Stage 1 record

Stage 1 spec compliance review: PASS
Both requirements in requirements.md are met by diff.patch, and no other file changes.
STAGE1
