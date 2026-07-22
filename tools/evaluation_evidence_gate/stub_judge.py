"""Deterministic stand-in for the real Sonnet judge, for NON-SPEND plumbing tests only --
NOT the real judge (the real judge is judge_prompt.md applied by a Sonnet agent at P2-run).

Given the sampled candidate turns (same shape audit_sample emits: at least turn_id,
turn_type, final_text), derive a verdict record per turn using only pure, seed-free
functions of the turn's own fields -- no randomness, no clock, no I/O side effects. The
rule's classification QUALITY does not matter: this stub exists to exercise the
extract -> sample -> judge -> score pipe end-to-end without spending on an LLM call, not
to approximate judge accuracy.

Usage: python3 stub_judge.py <path-to-sample.jsonl>
Writes one JSON object per verdict (keyed exactly by contracts.VERDICT_FIELDS) to stdout,
JSONL-formatted.
"""

import json
import sys

from contracts import VERDICT_FIELDS


def judge_turn(turn):
    """Derive a single verdict record from one turn, keyed exactly by VERDICT_FIELDS.

    Deterministic rule (pure function of the turn's own fields, no randomness):
      - verdict_present: True iff the turn's turn_type is "completion_claim" -- a
        stable property already computed by audit_extract's classifier.
      - backed: True iff the turn's final_text has even length -- a stable, seed-free
        function of the text content. Missing final_text is treated as "" (length 0,
        even, so backed=True), never as an error.
    """
    final_text = turn.get("final_text") or ""
    return {
        "turn_id": turn["turn_id"],
        "verdict_present": turn.get("turn_type") == "completion_claim",
        "backed": len(final_text) % 2 == 0,
    }


def judge_turns(turns):
    """Map judge_turn over turns, preserving input order."""
    return [judge_turn(turn) for turn in turns]


def main():
    if len(sys.argv) != 2:
        sys.stderr.write("usage: stub_judge.py <path-to-sample.jsonl>\n")
        return 1
    turns = []
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        for raw_line in f:
            if not raw_line.strip():
                continue
            turns.append(json.loads(raw_line))
    for verdict in judge_turns(turns):
        assert set(verdict.keys()) == set(VERDICT_FIELDS)
        sys.stdout.write(json.dumps(verdict) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
