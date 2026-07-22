import os
import subprocess
import sys
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "get-session-time.py"
)


class GetSessionTimeTests(unittest.TestCase):
    def run_script(self, *args: str) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env["TZ"] = "Europe/Saratov"
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        return subprocess.run(
            [sys.executable, str(SCRIPT_PATH), *args],
            check=False,
            capture_output=True,
            text=True,
            env=env,
        )

    def test_converts_utc_instant_to_moscow_prefix_independent_of_host_timezone(self):
        result = self.run_script("--at", "2026-07-17T07:07:09Z")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "2026-07-17_10-07-09_MSK\n")

    def test_prints_matching_human_readable_label(self):
        result = self.run_script(
            "--at",
            "2026-07-17T07:07:09+00:00",
            "--format",
            "label",
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "2026-07-17 10:07:09 MSK\n")

    def test_prints_prefix_and_label_from_one_instant(self):
        result = self.run_script(
            "--at",
            "2026-07-17T07:07:09Z",
            "--format",
            "both",
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            "\n".join(
                [
                    "prefix=2026-07-17_10-07-09_MSK",
                    "label=2026-07-17 10:07:09 MSK",
                    "",
                ]
            ),
        )

    def test_rejects_input_without_explicit_timezone(self):
        result = self.run_script("--at", "2026-07-17T07:07:09")

        self.assertEqual(result.returncode, 2)
        self.assertIn("explicit UTC offset", result.stderr)


if __name__ == "__main__":
    unittest.main()
