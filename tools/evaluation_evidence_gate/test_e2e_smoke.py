"""NON-SPEND end-to-end audit smoke test: drives the full
extract -> sample -> judge -> score chain over fixtures/mini_transcript.jsonl using
stub_judge (a deterministic, seed-free stand-in) instead of a real LLM call. Zero LLM
calls; proves the pipe is plumbed correctly, not that any judge is accurate.
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import contracts
import audit_extract
import audit_sample
import stub_judge
import audit_score

FIXTURE_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "fixtures", "mini_transcript.jsonl"
)

# A distinctive, multi-word substring of one fixture turn's final_text. Used to prove
# that no turn's raw text leaks all the way through the pipe into the score report.
_DISTINCTIVE_TEXT = "Issue resolved and covered by tests."


def synthesize_labels(sample):
    """Build a deterministic ground-truth labels file (LABEL_FIELDS shape) aligned to
    the sample's turn_ids. The test author owns this synthetic ground truth -- real
    labels come from the P2-run human gate, not from this smoke test. The rule (turn_id
    length parity) is arbitrary and exists only to exercise the score() join; its
    quality is irrelevant here."""
    return [
        {
            "turn_id": turn["turn_id"],
            "is_unbacked_verdict": len(turn["turn_id"]) % 2 == 0,
            "turn_type": turn["turn_type"],
        }
        for turn in sample
    ]


class EndToEndSmokeTest(unittest.TestCase):
    def test_full_chain_over_fixture(self):
        # 1. extract
        turns = list(audit_extract.extract_turns(FIXTURE_PATH))
        self.assertTrue(turns, "fixture must yield at least one turn")
        self.assertTrue(
            any(_DISTINCTIVE_TEXT in (t["final_text"] or "") for t in turns),
            "fixture must contain the distinctive text this test checks for leakage",
        )

        # 2. sample (fixture yields fewer than the 30-turn target; assert on what the
        # sampler actually returns, not a hard-coded target).
        sample = audit_sample.sample_turns(turns)
        self.assertTrue(sample, "sampler must select at least one candidate turn")
        sample_ids = {t["turn_id"] for t in sample}

        # 3. stub_judge (deterministic, zero LLM calls)
        verdicts = stub_judge.judge_turns(sample)
        verdict_ids = {v["turn_id"] for v in verdicts}

        # Alignment: verdict turn_ids == sample turn_ids exactly.
        self.assertEqual(verdict_ids, sample_ids)

        # Every verdict record's key set matches contracts.VERDICT_FIELDS exactly.
        for verdict in verdicts:
            self.assertEqual(set(verdict.keys()), set(contracts.VERDICT_FIELDS))

        # 4. labels: synthesized ground truth aligned to the sample turn_ids.
        labels = synthesize_labels(sample)
        label_ids = {l["turn_id"] for l in labels}
        self.assertEqual(
            label_ids, sample_ids, "labels must be aligned to the sampled turn_ids"
        )

        # 5. score
        scores = audit_score.score(verdicts, labels)
        # No unmatched turn_ids means every label found its verdict end-to-end and
        # vice versa -- no drift introduced anywhere in the chain.
        self.assertEqual(scores["unmatched"]["verdicts_without_label"], 0)
        self.assertEqual(scores["unmatched"]["labels_without_verdict"], 0)

        report = audit_score.format_report(scores)
        self.assertTrue(report.strip(), "report must be produced and non-empty")

        # The report must reference at least one of the sampled turn_ids...
        self.assertTrue(
            any(turn_id in report for turn_id in sample_ids),
            "report must mention at least one sampled turn_id",
        )
        # ...but must never contain a turn's raw final_text (minimal-span guarantee
        # end-to-end: audit_score only ever sees turn_id/verdict/label fields).
        self.assertNotIn(_DISTINCTIVE_TEXT, report)


if __name__ == "__main__":
    unittest.main()
