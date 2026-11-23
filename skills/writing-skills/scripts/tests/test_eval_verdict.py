import importlib.util
import os
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


if __name__ == "__main__":
    unittest.main()
