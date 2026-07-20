"""Stratified candidate selector for the evaluation-evidence-gate audit runner.

Given the turns produced by audit_extract (each a dict with at least
turn_id and turn_type), select a stratified candidate subset for human
labeling: hit a per-stratum floor, then top up to a total target, both
deterministically (pure sort on turn_id, no randomness).

Note: forcing inclusion of every would-block turn requires judge verdicts
and belongs to a later P2-run step -- that is out of scope here; this
module only stratifies by turn_type over the raw extracted turns.

Usage: python3 audit_sample.py <path-to-turns.jsonl>
Writes the selected turns as JSONL to stdout.
"""

import json
import sys

from contracts import TURN_TYPES


def sample_turns(turns, target_total=30, per_stratum_floor=8):
    """Select a stratified, deterministic subset of turns.

    1. Group turns by turn_type. Within each stratum, order candidates by
       turn_id (string sort).
    2. From each stratum take the first min(per_stratum_floor, len(stratum)).
    3. If the combined count < target_total, top up: from all
       not-yet-selected turns across every stratum, ordered by turn_id, add
       until the count reaches target_total or no candidates remain.
    4. Return the selected turns ordered by turn_id.
    5. If the total number of input turns is < target_total, return all of
       them (cannot reach the target) -- no crash, no error.
    """
    if len(turns) < target_total:
        return sorted(turns, key=lambda t: t["turn_id"])

    strata = {turn_type: [] for turn_type in TURN_TYPES}
    for turn in turns:
        strata.setdefault(turn["turn_type"], []).append(turn)
    for stratum_turns in strata.values():
        stratum_turns.sort(key=lambda t: t["turn_id"])

    selected_ids = set()
    selected = []
    for turn_type in strata:
        for turn in strata[turn_type][:per_stratum_floor]:
            selected.append(turn)
            selected_ids.add(turn["turn_id"])

    if len(selected) < target_total:
        remaining = sorted(
            (t for t in turns if t["turn_id"] not in selected_ids),
            key=lambda t: t["turn_id"],
        )
        for turn in remaining:
            if len(selected) >= target_total:
                break
            selected.append(turn)
            selected_ids.add(turn["turn_id"])

    return sorted(selected, key=lambda t: t["turn_id"])


def main():
    if len(sys.argv) != 2:
        sys.stderr.write("usage: audit_sample.py <path-to-turns.jsonl>\n")
        return 1
    turns = []
    with open(sys.argv[1], "r", encoding="ascii") as f:
        for raw_line in f:
            if not raw_line.strip():
                continue
            turns.append(json.loads(raw_line))
    for turn in sample_turns(turns):
        sys.stdout.write(json.dumps(turn) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
