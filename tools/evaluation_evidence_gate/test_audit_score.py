import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import contracts
import audit_score


def make_verdict(turn_id, verdict_present, backed):
    """Build a verdict dict shaped by contracts.VERDICT_FIELDS."""
    return {"turn_id": turn_id, "verdict_present": verdict_present, "backed": backed}


def make_label(turn_id, is_unbacked_verdict, turn_type):
    """Build a label dict shaped by contracts.LABEL_FIELDS."""
    return {
        "turn_id": turn_id,
        "is_unbacked_verdict": is_unbacked_verdict,
        "turn_type": turn_type,
    }


def build_crafted_dataset():
    """Crafted verdicts + labels with known TP/FP/FN/TN across three strata,
    plus one verdict-only and one label-only turn_id for unmatched coverage.

    Stratum completion_claim (TP=1, FP=1, FN=1, TN=1):
      t1: predicted positive (present=T, backed=F), gt positive  -> TP
      t2: predicted positive (present=T, backed=F), gt negative  -> FP
      t3: not predicted (present=F),                gt positive  -> FN
      t4: not predicted (present=T, backed=T),       gt negative -> TN

    Stratum hand_off (TP=0, FP=0, FN=1) -- zero predicted positives:
      t5: not predicted (present=F), gt positive  -> FN
      t6: not predicted (present=F, backed=T), gt negative -> TN

    Stratum question (TP=0, FP=1, FN=0) -- zero ground-truth positives:
      t7: predicted positive (present=T, backed=F), gt negative -> FP
      t8: not predicted (present=F), gt negative -> TN

    Overall (across t1..t8): TP=1, FP=2, FN=2 -> precision=recall=1/3.
    """
    verdicts = [
        make_verdict("t1", True, False),
        make_verdict("t2", True, False),
        make_verdict("t3", False, False),
        make_verdict("t4", True, True),
        make_verdict("t5", False, False),
        make_verdict("t6", False, True),
        make_verdict("t7", True, False),
        make_verdict("t8", False, False),
        make_verdict("t_verdict_only", True, False),
    ]
    labels = [
        make_label("t1", True, "completion_claim"),
        make_label("t2", False, "completion_claim"),
        make_label("t3", True, "completion_claim"),
        make_label("t4", False, "completion_claim"),
        make_label("t5", True, "hand_off"),
        make_label("t6", False, "hand_off"),
        make_label("t7", False, "question"),
        make_label("t8", False, "question"),
        make_label("t_label_only", True, "other"),
    ]
    return verdicts, labels


class ScorePerStratumTest(unittest.TestCase):
    def test_completion_claim_stratum_exact_counts_and_metrics(self):
        verdicts, labels = build_crafted_dataset()
        scores = audit_score.score(verdicts, labels)
        block = scores["by_turn_type"]["completion_claim"]
        self.assertEqual(block["tp"], 1)
        self.assertEqual(block["fp"], 1)
        self.assertEqual(block["fn"], 1)
        self.assertAlmostEqual(block["precision"], 0.5)
        self.assertAlmostEqual(block["recall"], 0.5)

    def test_hand_off_stratum_zero_predicted_positives(self):
        verdicts, labels = build_crafted_dataset()
        scores = audit_score.score(verdicts, labels)
        block = scores["by_turn_type"]["hand_off"]
        self.assertEqual(block["tp"], 0)
        self.assertEqual(block["fp"], 0)
        self.assertEqual(block["fn"], 1)
        self.assertEqual(block["precision"], "n/a (no predicted positives)")
        self.assertAlmostEqual(block["recall"], 0.0)

    def test_question_stratum_zero_ground_truth_positives(self):
        verdicts, labels = build_crafted_dataset()
        scores = audit_score.score(verdicts, labels)
        block = scores["by_turn_type"]["question"]
        self.assertEqual(block["tp"], 0)
        self.assertEqual(block["fp"], 1)
        self.assertEqual(block["fn"], 0)
        self.assertAlmostEqual(block["precision"], 0.0)
        self.assertEqual(block["recall"], "n/a (no ground-truth positives)")

    def test_stratum_with_no_matched_turns_is_absent(self):
        # 'other' only appears via the unmatched label t_label_only, which is
        # never joined to a verdict, so it must not produce a by_turn_type
        # entry at all.
        verdicts, labels = build_crafted_dataset()
        scores = audit_score.score(verdicts, labels)
        self.assertNotIn("other", scores["by_turn_type"])


class ScoreOverallTest(unittest.TestCase):
    def test_overall_aggregates_across_all_matched_strata(self):
        verdicts, labels = build_crafted_dataset()
        scores = audit_score.score(verdicts, labels)
        overall = scores["overall"]
        self.assertEqual(overall["tp"], 1)
        self.assertEqual(overall["fp"], 2)
        self.assertEqual(overall["fn"], 2)
        self.assertAlmostEqual(overall["precision"], 1 / 3)
        self.assertAlmostEqual(overall["recall"], 1 / 3)


class ScoreJoinTest(unittest.TestCase):
    def test_unmatched_turn_ids_counted_not_scored(self):
        verdicts, labels = build_crafted_dataset()
        scores = audit_score.score(verdicts, labels)
        self.assertEqual(scores["unmatched"]["verdicts_without_label"], 1)
        self.assertEqual(scores["unmatched"]["labels_without_verdict"], 1)
        # The unmatched turn_ids must not leak into any scored counts: total
        # matched-and-classified turns across overall is tp+fp+fn+(TNs not
        # tracked) -- specifically neither t_verdict_only nor t_label_only
        # can be responsible for the overall tp/fp/fn totals already pinned
        # above (1/2/2), which only add up correctly if both are excluded.
        overall = scores["overall"]
        self.assertEqual(overall["tp"] + overall["fp"] + overall["fn"], 5)

    def test_only_turn_ids_present_in_both_sides_are_scored(self):
        verdicts = [make_verdict("only_v", True, False)]
        labels = [make_label("only_l", True, "question")]
        scores = audit_score.score(verdicts, labels)
        self.assertEqual(scores["unmatched"]["verdicts_without_label"], 1)
        self.assertEqual(scores["unmatched"]["labels_without_verdict"], 1)
        self.assertEqual(scores["by_turn_type"], {})
        self.assertEqual(scores["overall"]["tp"], 0)
        self.assertEqual(scores["overall"]["fp"], 0)
        self.assertEqual(scores["overall"]["fn"], 0)


class FormatReportTest(unittest.TestCase):
    def test_report_contains_disagreement_turn_ids_and_metric_labels(self):
        verdicts, labels = build_crafted_dataset()
        scores = audit_score.score(verdicts, labels)
        report = audit_score.format_report(scores)
        # Known FP turn_id in completion_claim.
        self.assertIn("t2", report)
        # Known FN turn_id in completion_claim.
        self.assertIn("t3", report)
        self.assertIn("precision", report)
        self.assertIn("recall", report)
        self.assertIn("tp", report)
        self.assertIn("fp", report)
        self.assertIn("fn", report)

    def test_report_has_no_overlong_lines(self):
        verdicts, labels = build_crafted_dataset()
        scores = audit_score.score(verdicts, labels)
        report = audit_score.format_report(scores)
        for line in report.splitlines():
            self.assertLessEqual(len(line), 200)

    def test_report_does_not_leak_message_text_field(self):
        verdicts, labels = build_crafted_dataset()
        scores = audit_score.score(verdicts, labels)
        report = audit_score.format_report(scores)
        self.assertNotIn("final_text", report)


class ValidateFieldsTest(unittest.TestCase):
    def test_verdict_missing_field_raises_with_turn_id_and_field(self):
        verdict = make_verdict("t1", True, False)
        del verdict["backed"]
        labels = [make_label("t1", True, "completion_claim")]
        with self.assertRaises(ValueError) as cm:
            audit_score.score([verdict], labels)
        message = str(cm.exception)
        self.assertIn("t1", message)
        self.assertIn("backed", message)

    def test_label_missing_field_raises_with_turn_id_and_field(self):
        verdicts = [make_verdict("t1", True, False)]
        label = make_label("t1", True, "completion_claim")
        del label["turn_type"]
        with self.assertRaises(ValueError) as cm:
            audit_score.score(verdicts, [label])
        message = str(cm.exception)
        self.assertIn("t1", message)
        self.assertIn("turn_type", message)


class UseContractsFieldsTest(unittest.TestCase):
    def test_verdict_and_label_helpers_match_contract_fields(self):
        verdict = make_verdict("t1", True, False)
        label = make_label("t1", True, "completion_claim")
        self.assertEqual(set(verdict.keys()), set(contracts.VERDICT_FIELDS))
        self.assertEqual(set(label.keys()), set(contracts.LABEL_FIELDS))


if __name__ == "__main__":
    unittest.main()
