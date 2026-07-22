"""Regression test: the production JSONL readers inside audit_sample.main,
audit_score.main, and stub_judge.main must accept UTF-8 input -- the system
that produces their input data emits UTF-8, and only files WE author are
guaranteed ASCII. Exercises each module's real file-read path via subprocess
(not a direct function call) so an open(..., encoding="ascii") mismatch
actually raises UnicodeDecodeError the way it would in production.
"""

import json
import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

TOOL_DIR = os.path.dirname(os.path.abspath(__file__))


def _write_utf8_jsonl(records):
    """Write records to a new temp .jsonl file, UTF-8 encoded, with
    ensure_ascii=False so a non-ASCII value lands as a raw multi-byte
    UTF-8 sequence on disk (not a \\uXXXX escape, which would be pure
    ASCII and would not reproduce an ascii-decode crash). Returns the
    path; caller must remove it."""
    fd, path = tempfile.mkstemp(suffix=".jsonl")
    os.close(fd)
    with open(path, "w", encoding="utf-8") as f:
        for record in records:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    return path


class ReadersRawUtf8JsonlLineTest(unittest.TestCase):
    """Each production reader's main() CLI path must not crash on a raw
    (non-escaped) non-ASCII byte in its input JSONL."""

    def test_Readers_RawUtf8JsonlLine_DoNotCrash(self):
        # Arrange: one record per module shape, each carrying a genuine
        # non-ASCII character (an em-dash, U+2014) in a string field.
        turn = {
            "turn_id": "t1",
            "turn_type": "completion_claim",
            "final_text": "resolved—done",
        }
        verdict = {
            "turn_id": "t1",
            "verdict_present": True,
            "backed": False,
            "note": "context—here",
        }
        label = {
            "turn_id": "t1",
            "is_unbacked_verdict": True,
            "turn_type": "completion_claim",
        }

        # (module filename, list of record-lists -- one record-list per
        # positional argv file the module's main() expects)
        cases = [
            ("audit_sample.py", [[turn]]),
            ("stub_judge.py", [[turn]]),
            ("audit_score.py", [[verdict], [label]]),
        ]

        for module_name, file_record_lists in cases:
            with self.subTest(module=module_name):
                module_path = os.path.join(TOOL_DIR, module_name)
                temp_paths = [_write_utf8_jsonl(records) for records in file_record_lists]
                try:
                    # Act
                    result = subprocess.run(
                        [sys.executable, module_path] + temp_paths,
                        capture_output=True,
                        text=True,
                    )
                    # Assert
                    self.assertEqual(
                        result.returncode,
                        0,
                        msg=f"{module_name} crashed on UTF-8 input; stderr:\n{result.stderr}",
                    )
                    self.assertNotIn("UnicodeDecodeError", result.stderr)
                finally:
                    for path in temp_paths:
                        os.remove(path)


if __name__ == "__main__":
    unittest.main()
