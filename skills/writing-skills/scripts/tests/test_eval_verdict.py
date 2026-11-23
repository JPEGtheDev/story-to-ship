import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest

MODULE_PATH = os.path.join(os.path.dirname(__file__), "..", "eval_verdict.py")


def _load():
    """Load eval_verdict by file path at call time; None while the module is missing."""
    if not os.path.exists(MODULE_PATH):
        return None
    spec = importlib.util.spec_from_file_location("eval_verdict", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _stage_verdict(stage, ref_pass, ref_n, cand_pass, cand_n):
    module = _load()
    return None if module is None else module.stage_verdict(stage, ref_pass, ref_n, cand_pass, cand_n)


def _p(ref_pass, ref_n, cand_pass, cand_n):
    module = _load()
    return None if module is None else module.fisher_one_sided(ref_pass, ref_n, cand_pass, cand_n)


def _confirm_verdict(fresh_pass, fresh_n, ref_pass, ref_n):
    module = _load()
    fn = getattr(module, "confirm_verdict", None)
    return None if fn is None else fn(fresh_pass, fresh_n, ref_pass, ref_n)


def _read_run_records(path):
    module = _load()
    fn = getattr(module, "read_run_records", None)
    return None if fn is None else fn(path)


def _cache_key(case_hash, plugin_commit, model_id, judge_model_id, claude_code_version):
    module = _load()
    fn = getattr(module, "cache_key", None)
    return None if fn is None else fn(case_hash, plugin_commit, model_id, judge_model_id, claude_code_version)


class StageVerdictTest(unittest.TestCase):
    def test_StageVerdict_Stage5TwoOfFiveAgainst30Of30_ReturnsLoss(self):
        # Arrange
        stage, ref, cand = 5, (30, 30), (2, 5)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        # Assert
        self.assertEqual("LOSS", verdict)

    def test_FisherOneSided_TwoOfFiveAgainst30Of30_ReturnsP0001528(self):
        # Arrange / Act
        p = _p(30, 30, 2, 5)
        # Assert
        self.assertIsNotNone(p)
        self.assertAlmostEqual(0.001528, p, places=6)

    def test_StageVerdict_Stage5ThreeOfFiveAgainst30Of30_ReturnsNext(self):
        # Arrange / Act
        verdict = _stage_verdict(5, 30, 30, 3, 5)
        p = _p(30, 30, 3, 5)
        # Assert
        self.assertEqual("NEXT", verdict)
        self.assertAlmostEqual(0.016807, p, places=6)

    def test_StageVerdict_Stage15TwelveOfFifteenAgainst30Of30_ReturnsLoss(self):
        # Arrange / Act
        verdict = _stage_verdict(15, 30, 30, 12, 15)
        p = _p(30, 30, 12, 15)
        # Assert
        self.assertEqual("LOSS", verdict)
        self.assertAlmostEqual(0.032065, p, places=6)

    def test_StageVerdict_Stage15FifteenOfFifteenAgainst30Of30_ReturnsHold(self):
        # Arrange / Act
        verdict = _stage_verdict(15, 30, 30, 15, 15)
        # Assert
        self.assertEqual("HOLD", verdict)

    def test_StageVerdict_Stage1513Of15Against30Of30_ReturnsNext(self):
        # Arrange
        stage, ref, cand = 15, (30, 30), (13, 15)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        p = _p(*ref, *cand)
        # Assert
        self.assertEqual("NEXT", verdict)
        self.assertAlmostEqual(0.106061, p, places=6)

    def test_StageVerdict_Stage1514Of15Against30Of30_ReturnsNext(self):
        # Arrange
        stage, ref, cand = 15, (30, 30), (14, 15)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        p = _p(*ref, *cand)
        # Assert
        self.assertEqual("NEXT", verdict)
        self.assertAlmostEqual(0.333333, p, places=6)

    def test_StageVerdict_Stage1513Of15Against27Of30_ReturnsNext(self):
        # Arrange
        stage, ref, cand = 15, (27, 30), (13, 15)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        # Assert
        self.assertEqual("NEXT", verdict)

    def test_StageVerdict_Stage1514Of15Against27Of30_ReturnsHold(self):
        # Arrange
        stage, ref, cand = 15, (27, 30), (14, 15)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        # Assert
        self.assertEqual("HOLD", verdict)

    def test_StageVerdict_Stage3025Of30Against30Of30_ReturnsLoss(self):
        # Arrange
        stage, ref, cand = 30, (30, 30), (25, 30)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        p = _p(*ref, *cand)
        # Assert
        self.assertEqual("LOSS", verdict)
        self.assertAlmostEqual(0.026093, p, places=6)

    def test_StageVerdict_Stage3026Of30Against30Of30_ReturnsHold(self):
        # Arrange
        stage, ref, cand = 30, (30, 30), (26, 30)
        # Act
        verdict = _stage_verdict(stage, *ref, *cand)
        p = _p(*ref, *cand)
        # Assert
        self.assertEqual("HOLD", verdict)
        self.assertAlmostEqual(0.0562, p, places=4)


class ConfirmVerdictTest(unittest.TestCase):
    def test_ConfirmVerdict_Fresh26Of30Against30Of30PAboveZeroPointZeroFive_ReturnsHold(self):
        # Arrange: fresh 26/30 against reference 30/30 gives exact one-sided p = 0.0562
        fresh, ref = (26, 30), (30, 30)
        # Act
        verdict = _confirm_verdict(*fresh, *ref)
        # Assert
        self.assertEqual("HOLD", verdict)

    def test_ConfirmVerdict_Fresh0Of30Against30Of30PBelowZeroPointZeroFive_ReturnsLoss(self):
        # Arrange: fresh 0/30 against reference 30/30 gives one-sided p far below 0.05
        fresh, ref = (0, 30), (30, 30)
        # Act
        verdict = _confirm_verdict(*fresh, *ref)
        # Assert
        self.assertEqual("LOSS", verdict)


class ReadRunRecordsTest(unittest.TestCase):
    def test_ReadRunRecords_FiveRecordsOneWithError_ReturnsFourKeptAndOneDropped(self):
        # Arrange
        records = [
            {"case": "a", "pass": True, "error": None},
            {"case": "b", "pass": False, "error": None},
            {"case": "c", "pass": True, "error": "timeout"},
            {"case": "d", "pass": True, "error": None},
            {"case": "e", "pass": True, "error": None},
        ]
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "run.json")
            with open(path, "w") as handle:
                json.dump(records, handle)
            # Act
            result = _read_run_records(path)
        # Assert
        self.assertIsNotNone(result)
        kept, dropped = result
        self.assertEqual(4, len(kept))
        self.assertEqual(1, dropped)


class CliTest(unittest.TestCase):
    def test_Cli_BadStageArgument_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            run_file = os.path.join(tmp, "run.json")
            with open(run_file, "w") as handle:
                handle.write("{}")

            # Act
            result = subprocess.run(
                [sys.executable, MODULE_PATH, "--stage", "7", run_file],
                capture_output=True,
                text=True,
            )

        # Assert
        self.assertEqual(2, result.returncode)

    def test_Cli_MissingRunFile_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            missing_file = os.path.join(tmp, "absent.json")

            # Act
            result = subprocess.run(
                [sys.executable, MODULE_PATH, "--stage", "5", missing_file],
                capture_output=True,
                text=True,
            )

        # Assert
        self.assertEqual(2, result.returncode)

    def test_Cli_MalformedJsonRunFile_ExitsTwo(self):
        # Arrange
        with tempfile.TemporaryDirectory() as tmp:
            run_file = os.path.join(tmp, "run.json")
            with open(run_file, "w") as handle:
                handle.write("{not json")

            # Act
            result = subprocess.run(
                [sys.executable, MODULE_PATH, "--stage", "5", run_file],
                capture_output=True,
                text=True,
            )

        # Assert
        self.assertEqual(2, result.returncode)


class CacheKeyTest(unittest.TestCase):
    def test_CacheKey_ModelIdChanges_ReturnsDifferentKey(self):
        # Arrange
        others = ("case-hash", "plugin-commit", "judge-model", "1.0.0")
        # Act
        key_a = _cache_key(others[0], others[1], "model-a", others[2], others[3])
        key_b = _cache_key(others[0], others[1], "model-b", others[2], others[3])
        # Assert
        self.assertIsNotNone(key_a)
        self.assertNotEqual(key_a, key_b)


if __name__ == "__main__":
    unittest.main()
