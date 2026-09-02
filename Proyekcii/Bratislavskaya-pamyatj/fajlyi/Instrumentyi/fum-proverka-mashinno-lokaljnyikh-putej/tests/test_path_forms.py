import sys
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1] / "scripts"
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

from path_forms import detect_path_forms


class PathFormsTests(unittest.TestCase):
    def assert_kinds(self, text: str, *expected: str) -> None:
        self.assertEqual(
            tuple(form.kind for form in detect_path_forms(text)),
            expected,
        )

    def test_detects_supported_local_path_forms(self) -> None:
        cases = {
            "/Users/example/work/FUM": "posix-user-home",
            "/home/example/work/FUM": "posix-user-home",
            "/srv/fum/runtime/config.json": "posix-absolute",
            "/custom/private/checkout": "posix-absolute",
            "`/custom/private/checkout`": "posix-absolute",
            "``/custom/private/checkout``": "posix-absolute",
            ">/custom/private/checkout": "posix-absolute",
            r"C:\Users\Example\work\FUM": "windows-drive",
            "D:/work/FUM/config.json": "windows-drive",
            "C:\\": "windows-drive",
            "D:/": "windows-drive",
            r"\\server\share\FUM\config.json": "windows-unc",
            r"\\?\UNC\server\share\project": "windows-unc",
            "//server/share/project": "windows-unc",
            "file:///Users/example/work/FUM": "file-uri",
            "file://server/share/FUM": "file-uri",
            "~/work/FUM": "home-expansion",
            "~alice/project": "home-expansion",
            "~alice": "home-expansion",
            "~": "home-expansion",
            "$HOME/work/FUM": "home-expansion",
            "$HOME": "home-expansion",
            "${HOME}/work/FUM": "home-expansion",
            "${HOME}": "home-expansion",
            r"$env:USERPROFILE\project": "home-expansion",
            r"${env:USERPROFILE}\work": "home-expansion",
            "$Env:HOME": "home-expansion",
            "$(HOME)/work": "home-expansion",
            r"%USERPROFILE%\work\FUM": "home-expansion",
            "%HOMEPATH%": "home-expansion",
            "let source = #filePath": "compiler-file-path",
        }

        for text, expected in cases.items():
            with self.subTest(text=text):
                self.assert_kinds(text, expected)

    def test_deduplicates_overlapping_file_uri_and_posix_matches(self) -> None:
        self.assert_kinds(
            "open file:///Users/example/work/FUM",
            "file-uri",
        )

    def test_web_urls_are_typed_but_not_local_path_forms(self) -> None:
        forms = detect_path_forms(
            "https://example.test/a/b ssh://git@example.test/repo",
            include_web_urls=True,
        )

        self.assertEqual(tuple(form.kind for form in forms), ("web-url", "web-url"))
        self.assertEqual(
            detect_path_forms(
                "https://example.test/a/b ssh://git@example.test/repo"
            ),
            (),
        )

    def test_relative_paths_file_id_and_non_path_slashes_are_ignored(self) -> None:
        for text in (
            "README.md",
            "../README.md",
            "refs/heads/master",
            "let source = #fileID",
            "x / y",
            "команда /hooks",
            "арифметика 10/2",
            "приближение~value",
            "regex-boundary ~-",
            "ограда ~~~",
            "current /= part",
            "`render`/projection-профиль",
            "``render``/projection-профиль",
            "Проекты/<имя>/README.md",
            "$HOMEMADE/value",
            r"${env:OTHER}\work",
            "$(OTHER)/work",
            "// однострочный комментарий",
            "//server",
            r"\\?\UNC\server",
            r"\\?\OTHER\server\share",
            "C:",
            "https://example.test/a/b",
            "mailto:user@example.test",
        ):
            with self.subTest(text=text):
                self.assertEqual(detect_path_forms(text), ())

    def test_returns_source_spans_without_rewriting_the_input(self) -> None:
        text = "prefix /Users/example/work suffix"

        form = detect_path_forms(text)[0]

        self.assertEqual(text[form.start : form.end], "/Users/example/work")
        self.assertEqual(form.kind, "posix-user-home")


if __name__ == "__main__":
    unittest.main()
