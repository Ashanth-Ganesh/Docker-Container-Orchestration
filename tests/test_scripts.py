import socket
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts import create_report, top_three, words


class WordCounterTests(unittest.TestCase):
    def test_contractions_and_curly_apostrophes(self):
        self.assertEqual(
            words("I'm, can't, don't; we’re, I'll, couldn't, it's, won't!", True),
            ["i", "am", "can", "not", "do", "not", "we", "are", "i", "will",
             "could", "not", "it", "is", "will", "not"],
        )

    def test_punctuation_case_and_ties(self):
        self.assertEqual(words("IF! if, you—You don't."), ["if", "if", "you", "you", "don't"])
        self.assertEqual(top_three(["b", "a", "b", "a", "c", "d"]), [("a", 2), ("b", 2), ("c", 1)])
        self.assertEqual(top_three([]), [])

    def test_report_uses_both_files_and_expands_song_frequency(self):
        with tempfile.TemporaryDirectory(dir=Path(__file__).resolve().parent) as folder:
            data = Path(folder)
            (data / "IF.txt").write_text("IF you, if YOU!", encoding="utf-8")
            (data / "AlwaysRememberUsThisWay.txt").write_text("I'm I'm can't don't", encoding="utf-8")
            with patch.object(socket, "gethostbyname", return_value="172.17.0.2"):
                report = create_report(data)
            for expected in (
                "IF.txt: 4", "AlwaysRememberUsThisWay.txt: 4", "Grand total: 8",
                "am: 2", "i: 2", "not: 2", "IP address (container): 172.17.0.2",
            ):
                self.assertIn(expected, report)

    def test_supplied_files(self):
        root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory(dir=root / "tests") as folder:
            data = Path(folder)
            (data / "IF.txt").write_bytes((root / "IF-1.txt").read_bytes())
            (data / "AlwaysRememberUsThisWay.txt").write_bytes((root / "AlwaysRememberUsThisWay-2.txt").read_bytes())
            with patch.object(socket, "gethostbyname", return_value="172.17.0.2"):
                report = create_report(data)
            self.assertIn("IF.txt: 287", report)
            self.assertIn("AlwaysRememberUsThisWay.txt: 223", report)
            self.assertIn("Grand total: 510", report)


if __name__ == "__main__":
    unittest.main()
