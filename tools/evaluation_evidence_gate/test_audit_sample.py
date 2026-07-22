import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import contracts
import audit_sample


def make_turn(turn_id, turn_type):
    """Build a minimal turn dict shaped like audit_extract output."""
    return {"turn_id": turn_id, "turn_type": turn_type}


def build_even_turns():
    """40 turns: 10 in each of the 4 TURN_TYPES strata, turn_ids zero-padded
    per stratum so string sort matches intended order."""
    turns = []
    for stratum in contracts.TURN_TYPES:
        for i in range(10):
            turns.append(make_turn(f"sess-{stratum}#{i:02d}", stratum))
    return turns


def build_skewed_turns():
    """Skewed distribution: 'question' stratum has only 2 turns; the other
    three strata have 15 each (total 47), so top-up has plenty to draw from."""
    turns = []
    for stratum in contracts.TURN_TYPES:
        count = 2 if stratum == "question" else 15
        for i in range(count):
            turns.append(make_turn(f"sess-{stratum}#{i:02d}", stratum))
    return turns


def build_short_turns():
    """12 turns total (fewer than target_total=30), spread across strata."""
    turns = []
    types = list(contracts.TURN_TYPES)
    for i in range(12):
        stratum = types[i % len(types)]
        turns.append(make_turn(f"sess-{stratum}#{i:02d}", stratum))
    return turns


class SampleTurnsEvenDistributionTest(unittest.TestCase):
    def test_every_stratum_contributes_floor_count(self):
        turns = build_even_turns()
        selected = audit_sample.sample_turns(turns)
        counts = {}
        for turn in selected:
            counts[turn["turn_type"]] = counts.get(turn["turn_type"], 0) + 1
        for stratum in contracts.TURN_TYPES:
            self.assertEqual(counts.get(stratum, 0), 8)

    def test_total_is_32(self):
        turns = build_even_turns()
        selected = audit_sample.sample_turns(turns)
        self.assertEqual(len(selected), 32)

    def test_floor_selects_the_first_n_turn_ids_not_last_n(self):
        # Pins WHICH turns the floor selects, not just how many: with 10 turns
        # per stratum and floor=8, the first 8 by turn_id (#00..#07) must be
        # chosen. Guards against a first-N -> last-N (or reversed-sort) drift
        # that count-only assertions cannot catch.
        turns = build_even_turns()
        selected = audit_sample.sample_turns(turns)
        for stratum in contracts.TURN_TYPES:
            ids = sorted(
                t["turn_id"] for t in selected if t["turn_type"] == stratum
            )
            expected = [f"sess-{stratum}#{i:02d}" for i in range(8)]
            self.assertEqual(ids, expected)
        self.assertGreaterEqual(len(selected), 30)

    def test_result_ordered_by_turn_id(self):
        turns = build_even_turns()
        selected = audit_sample.sample_turns(turns)
        ids = [t["turn_id"] for t in selected]
        self.assertEqual(ids, sorted(ids))


class SampleTurnsDeterminismTest(unittest.TestCase):
    def test_repeated_calls_return_identical_sequence(self):
        turns = build_even_turns()
        first = [t["turn_id"] for t in audit_sample.sample_turns(turns)]
        second = [t["turn_id"] for t in audit_sample.sample_turns(turns)]
        self.assertEqual(first, second)

    def test_repeated_calls_on_skewed_input_are_identical(self):
        turns = build_skewed_turns()
        first = [t["turn_id"] for t in audit_sample.sample_turns(turns)]
        second = [t["turn_id"] for t in audit_sample.sample_turns(turns)]
        self.assertEqual(first, second)


class SampleTurnsSkewedDistributionTest(unittest.TestCase):
    def test_small_stratum_fully_included(self):
        turns = build_skewed_turns()
        selected = audit_sample.sample_turns(turns)
        question_ids = {t["turn_id"] for t in turns if t["turn_type"] == "question"}
        selected_question_ids = {
            t["turn_id"] for t in selected if t["turn_type"] == "question"
        }
        self.assertEqual(selected_question_ids, question_ids)
        self.assertEqual(len(selected_question_ids), 2)

    def test_total_reaches_target_via_topup(self):
        turns = build_skewed_turns()
        selected = audit_sample.sample_turns(turns)
        self.assertGreaterEqual(len(selected), 30)


class SampleTurnsShortInputTest(unittest.TestCase):
    def test_returns_all_when_fewer_than_target(self):
        turns = build_short_turns()
        selected = audit_sample.sample_turns(turns)
        self.assertEqual(len(selected), 12)
        self.assertEqual(
            {t["turn_id"] for t in selected}, {t["turn_id"] for t in turns}
        )


class SampleTurnsIntegrityTest(unittest.TestCase):
    def test_no_fabricated_turns_and_unique_ids(self):
        turns = build_even_turns()
        selected = audit_sample.sample_turns(turns)
        input_ids = {t["turn_id"] for t in turns}
        selected_ids = [t["turn_id"] for t in selected]
        for turn_id in selected_ids:
            self.assertIn(turn_id, input_ids)
        self.assertEqual(len(selected_ids), len(set(selected_ids)))

    def test_no_fabricated_turns_on_skewed_input(self):
        turns = build_skewed_turns()
        selected = audit_sample.sample_turns(turns)
        input_ids = {t["turn_id"] for t in turns}
        selected_ids = [t["turn_id"] for t in selected]
        for turn_id in selected_ids:
            self.assertIn(turn_id, input_ids)
        self.assertEqual(len(selected_ids), len(set(selected_ids)))


if __name__ == "__main__":
    unittest.main()
