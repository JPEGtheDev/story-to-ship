#!/usr/bin/env bash
# Guard test for agents/story-coordinator.md: the template must carry the
# runner reload rule as one bullet line (a line that starts with "- ").
#
# The template path comes from STORY_COORDINATOR_TEMPLATE. When that variable
# is unset, the template is agents/story-coordinator.md under the repository
# root, two directories above this script's directory.
#
# Check: the rule sentence, matched as a fixed string, appears on exactly one
# line that starts with "- ". A missing template file fails the check.

set -u

SENTENCE="A runner's reload text may name a role skill (running-a-sprint); the runner ignores that name, never loads any role skill, and reloads the other skills the rules above name."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${STORY_COORDINATOR_TEMPLATE:-$SCRIPT_DIR/../../agents/story-coordinator.md}"

# Arrange
# The template path and the rule sentence are set above.

# Act
if [[ ! -f "$TEMPLATE" ]]; then
  echo "FAIL: story-coordinator template not found at $TEMPLATE"
  exit 1
fi
count="$(grep -F -- "$SENTENCE" "$TEMPLATE" | grep -c '^- ')"

# Assert
if [[ "$count" -eq 1 ]]; then
  echo "PASS: story-coordinator template rule"
  exit 0
fi
echo "FAIL: expected the runner reload rule on exactly one '- ' bullet line of $TEMPLATE, found $count"
exit 1
