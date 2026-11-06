#!/usr/bin/env bash
set -eu
mkdir -p docs
printf '# Setup\n\nRun npm install -g tool to set up.\n' > docs/setup.md
printf '# Changelog\n\n## 2.3.0\n\n- Added the export command.\n' > docs/changelog.md
printf '# Config\n\nretries: 3\n\nThe text says 5 retries are the default.\n' > docs/config.md
cat > plan.md <<'PLAN'
# Plan: docs fixes

Todo 1: fix the three review findings in the docs
loop: single -- reason: prose-only change to docs
Files:
  - Modify: docs/setup.md
  - Modify: docs/changelog.md
  - Modify: docs/config.md
Depends on: none
PLAN
cat > implementer-result.md <<'RESULT'
STATUS: DONE_WITH_CONCERNS
Changed: docs/setup.md, docs/changelog.md, docs/config.md
Summary: edited the three files; the review has findings to address.
RESULT
cat > review-output.md <<'REVIEW'
Stage 1 review: FAIL
1. The setup guide still tells the reader to run npm install -g.
2. The changelog entry for 2.3.0 is missing the date.
3. The example config sets retries to 3 but the text says 5.
REVIEW
