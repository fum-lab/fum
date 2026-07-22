import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[3]
FUM_ENTRY = REPO_ROOT / "fum"
FIXTURES = Path(__file__).resolve().parent / "fixtures" / "simple-html"
FIXTURE_URL = "https://fixture.invalid/articles/fum"
MANIFEST_SCHEMA = "fum.request-materials.snapshot-manifest.v1"
SCRIPTS_DIR = REPO_ROOT / "Инструменты" / "fum-materialyi-zaprosov" / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

import source_archive  # noqa: E402


class SourceArchiveCoreTests(unittest.TestCase):
    def test_query_and_fragment_values_are_not_exposed_in_output_path(self):
        output_dir = source_archive.url_output_dir(
            Path("/repo"),
            "https://example.com/search?token=super-secret#private-anchor",
        )

        rendered = output_dir.as_posix()
        self.assertNotIn("super-secret", rendered)
        self.assertNotIn("private-anchor", rendered)
        self.assertRegex(output_dir.parts[-2], r"^_query-[0-9a-f]{16}$")
        self.assertRegex(output_dir.parts[-1], r"^_fragment-[0-9a-f]{16}$")

    def test_normalized_path_segments_cannot_alias_distinct_urls(self):
        first = source_archive.url_output_dir(
            Path("/repo"),
            "https://example.com/articles/a:b",
        )
        second = source_archive.url_output_dir(
            Path("/repo"),
            "https://example.com/articles/a-b",
        )

        self.assertNotEqual(first, second)

    def test_existing_snapshot_must_belong_to_exact_source_url(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            request_file = repo / "Запросы" / "request.md"
            request_file.parent.mkdir(parents=True)
            request_file.write_text("# Запрос\n", encoding="utf-8")
            url = "https://example.com/articles/fum"
            output_dir = source_archive.default_output_dir(request_file, url)
            output_dir.mkdir(parents=True)
            (output_dir / "source-url.txt").write_text(
                "https://different.example/articles/fum\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "belongs to a different URL"):
                source_archive.ensure_destination_matches_url(output_dir, url)

    def test_non_http_url_is_rejected_before_transport(self):
        with self.assertRaisesRegex(ValueError, "HTTP or HTTPS"):
            source_archive.url_output_dir(
                Path("/repo"),
                "file://localhost/private/material.html",
            )

    def test_url_userinfo_is_rejected_before_transport(self):
        with self.assertRaisesRegex(ValueError, "userinfo"):
            source_archive.url_output_dir(
                Path("/repo"),
                "https://user:secret@example.com/material.html",
            )

    def test_request_file_must_exist_before_archive(self):
        with tempfile.TemporaryDirectory() as tmp:
            request_file = Path(tmp) / "Запросы" / "missing.md"

            with self.assertRaisesRegex(ValueError, "request file"):
                source_archive.archive_url(
                    "https://example.com/material.html",
                    request_file,
                    transport=mock.Mock(),
                )

    def test_curl_failure_is_reported_without_echoing_the_source_url(self):
        url = "https://example.com/material.html?token=private"
        error = subprocess.CalledProcessError(
            22,
            ["curl"],
            stderr="fixture curl failure",
        )
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with mock.patch.object(
                source_archive.subprocess,
                "run",
                side_effect=error,
            ):
                with self.assertRaisesRegex(RuntimeError, "curl capture failed") as caught:
                    source_archive.run_curl(
                        url,
                        root / "body",
                        root / "headers",
                    )

        self.assertNotIn(url, str(caught.exception))

    def test_external_title_is_escaped_before_markdown_insertion(self):
        title = "X](https://attacker.invalid)[Y\nNext"

        escaped = source_archive.markdown_text(title)

        self.assertEqual(
            escaped,
            r"X\](https://attacker.invalid)\[Y Next",
        )
        self.assertNotRegex(escaped, r"(?<!\\)\]\(")

    def test_raw_html_bytes_are_preserved_in_snapshot(self):
        raw_html = b"<!doctype html><title>Fixture</title><p>byte:\xff</p>\n"

        def transport(url: str, body_path: Path, headers_path: Path):
            body_path.write_bytes(raw_html)
            headers_path.write_text(
                "HTTP/1.1 200 OK\nContent-Type: text/html\n",
                encoding="utf-8",
            )
            return {
                "transport": "fixture",
                "url_effective": url,
                "http_code": "200",
                "content_type": "text/html",
                "size_download": str(len(raw_html)),
            }

        with tempfile.TemporaryDirectory() as tmp:
            staging_dir = Path(tmp)
            source_archive.build_snapshot(
                staging_dir,
                "https://example.com/material.html",
                transport,
            )

            stored = (staging_dir / "response.body.html").read_bytes()

        self.assertEqual(stored, raw_html)


class SourceArchiveCliAcceptanceTests(unittest.TestCase):
    maxDiff = None

    def run_fum(
        self,
        *,
        request_file: Path,
        fixture_version: str,
        failpoint: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        environment["FUM_SOURCE_ARCHIVE_TEST_FIXTURE_DIR"] = str(
            FIXTURES / fixture_version
        )
        if failpoint is None:
            environment.pop("FUM_SOURCE_ARCHIVE_TEST_FAILPOINT", None)
        else:
            environment["FUM_SOURCE_ARCHIVE_TEST_FAILPOINT"] = failpoint
        return subprocess.run(
            [
                str(FUM_ENTRY),
                "source",
                "archive",
                FIXTURE_URL,
                "--request",
                str(request_file),
            ],
            cwd=REPO_ROOT,
            env=environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def snapshot_bytes(self, directory: Path) -> dict[str, bytes]:
        return {
            path.relative_to(directory).as_posix(): path.read_bytes()
            for path in directory.rglob("*")
            if path.is_file()
        }

    def assert_exact_manifest(
        self,
        output_dir: Path,
        expected_files: list[str],
    ) -> None:
        manifest = json.loads(
            (output_dir / "snapshot-manifest.json").read_text(encoding="utf-8")
        )
        self.assertEqual(
            manifest,
            {
                "schema": MANIFEST_SCHEMA,
                "managed_files": expected_files,
            },
        )
        actual_files = sorted(
            path.relative_to(output_dir).as_posix()
            for path in output_dir.rglob("*")
            if path.is_file()
        )
        self.assertEqual(actual_files, expected_files)

    def test_common_cli_archives_rearchives_and_preserves_previous_snapshot_on_failure(
        self,
    ):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            request_file = repo / "Запросы" / "request.md"
            request_file.parent.mkdir(parents=True)
            request_file.write_text(
                "# Исходный запрос\n\nИсходное содержимое.\n",
                encoding="utf-8",
            )
            output_dir = (
                repo
                / "Источники"
                / "URL"
                / "https"
                / "fixture.invalid"
                / "articles"
                / "fum"
            )

            first = self.run_fum(
                request_file=request_file,
                fixture_version="v1",
            )
            self.assertEqual(first.returncode, 0, first.stderr)
            self.assertEqual(
                (output_dir / "source-url.txt").read_text(encoding="utf-8"),
                FIXTURE_URL + "\n",
            )
            self.assert_exact_manifest(
                output_dir,
                [
                    "extracted-text.md",
                    "extraction-report.md",
                    "response.body.html",
                    "response.headers.txt",
                    "snapshot-manifest.json",
                    "source-index.md",
                    "source-url.txt",
                    "structured-data.json",
                ],
            )
            structured_data = json.loads(
                (output_dir / "structured-data.json").read_text(encoding="utf-8")
            )
            self.assertEqual(structured_data["@type"], "Article")
            self.assertEqual(
                structured_data["headline"],
                "Первый снимок архиватора FUM",
            )
            extracted_text = (output_dir / "extracted-text.md").read_text(
                encoding="utf-8"
            )
            self.assertIn("# Извлечённый текст", extracted_text)
            self.assertIn("Первый снимок архиватора FUM", extracted_text)
            self.assertIn("Версия v1 проверяет извлечение текста", extracted_text)
            headers = (output_dir / "response.headers.txt").read_text(encoding="utf-8")
            self.assertIn("set-cookie: [REDACTED: response cookie]", headers)
            published_snapshot = b"\n".join(self.snapshot_bytes(output_dir).values())
            self.assertNotIn(b"fum-fixture-secret", published_snapshot)

            request_text = request_file.read_text(encoding="utf-8")
            source_path = "../Источники/URL/https/fixture.invalid/articles/fum"
            self.assertEqual(request_text.count("## Прикрепляемые материалы"), 1)
            self.assertEqual(request_text.count(f"({source_path}/)"), 1)
            self.assertEqual(request_text.count(f"({source_path}/source-index.md)"), 1)
            self.assertEqual(
                request_text.count(f"({source_path}/extraction-report.md)"),
                1,
            )

            second = self.run_fum(
                request_file=request_file,
                fixture_version="v2",
            )
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assert_exact_manifest(
                output_dir,
                [
                    "extracted-text.md",
                    "extraction-report.md",
                    "response.body.html",
                    "response.headers.txt",
                    "snapshot-manifest.json",
                    "source-index.md",
                    "source-url.txt",
                ],
            )
            self.assertFalse((output_dir / "structured-data.json").exists())
            self.assertIn(
                "Второй снимок архиватора FUM",
                (output_dir / "extracted-text.md").read_text(encoding="utf-8"),
            )
            request_after_repeat = request_file.read_text(encoding="utf-8")
            self.assertEqual(request_after_repeat, request_text)
            articles_dir = output_dir.parent
            self.assertEqual(
                sorted(path.name for path in articles_dir.iterdir()),
                ["fum"],
            )

            snapshot_before_failure = self.snapshot_bytes(output_dir)
            failed = self.run_fum(
                request_file=request_file,
                fixture_version="v1",
                failpoint="after-build",
            )
            self.assertNotEqual(failed.returncode, 0)
            self.assertIn("test failpoint after-build", failed.stderr)
            self.assertEqual(
                self.snapshot_bytes(output_dir),
                snapshot_before_failure,
            )
            self.assertEqual(
                list(articles_dir.glob(".fum.staging-*")),
                [],
            )
            self.assertEqual(
                request_file.read_text(encoding="utf-8"),
                request_after_repeat,
            )


if __name__ == "__main__":
    unittest.main()
