import importlib.util
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
    def test_код_переадресации_очищается_из_location_и_отчёта(сам):
        адрес = "https://example.org/article?error=cookies_not_supported&code=private-redirect&section=abstract"
        заголовки = source_archive.redact_headers("Location: " + адрес + "\r\nContent-Type: text/html\r\n")
        сам.assertNotIn("private-redirect", заголовки)
        сам.assertIn("section=abstract", заголовки)
        сам.assertEqual(source_archive.redact_headers(заголовки), заголовки)
        with tempfile.TemporaryDirectory() as каталог:
            путь = Path(каталог) / "extraction-report.md"
            source_archive.write_report(путь, "https://example.org/article", {"url_effective": адрес}, [], 0, [])
            текст = путь.read_text()
            сам.assertNotIn("private-redirect", текст)
            сам.assertIn("section=abstract", текст)
        фрагмент = source_archive.redact_headers("Location: https://example.org/callback#code=private-fragment\r\n")
        сам.assertNotIn("private-fragment", фрагмент)
        свёрнуто = source_archive.redact_headers("Location: https://example.org/callback?view=full\r\n code=private-folded\r\n")
        сам.assertNotIn("private-folded", свёрнуто)
        сам.assertIn("view=full", свёрнуто)

    def test_служебные_заголовки_обоих_архиваторов_очищаются(сам):
        спецификация = importlib.util.spec_from_file_location(
            "архиватор_для_проверки_заголовков", SCRIPTS_DIR / "archive-chatgpt-share.py"
        )
        архиватор = importlib.util.module_from_spec(спецификация)
        спецификация.loader.exec_module(архиватор)
        for очистить in (source_archive.redact_headers, архиватор.redact_headers):
            for имя in (
                "CF-Ray", "X-Request-ID", "Request-Context", "X-MS-Middleware-Request-ID",
                "X-B3-TraceId", "X-GitHub-Request-Id", "X-VCAP-Request-ID",
                "Traceparent", "Tracestate", "X-NXID", "X-Amz-Cf-Id",
                "X-Amzn-RequestId", "X-Amzn-Trace-Id", "X-Fastly-Request-ID",
                "X-Guploader-Uploadid", "X-Trans-Id", "X-Cloud-Trace-Context",
                "X-Timer", "X-Shred", "Server-Timing", "Report-To", "Reporting-Endpoints",
            ):
                with сам.subTest(вход=очистить.__module__, заголовок=имя):
                    сырьё = (
                        "HTTP/2 200\r\n"
                        f"{имя.swapcase()}: private-fum-fixture\r\n"
                        "\tprivate-fum-continuation\r\n"
                        "Set-Cookie: private-fum-cookie\r\n"
                        " private-fum-cookie-continuation\r\n"
                        "Content-Type: text/html\r\n"
                        "Content-Language: ru\r\n"
                        "Last-Modified: Mon, 07 Sep 2026 12:00:00 GMT\r\n"
                    )
                    результат = очистить(сырьё)
                    сам.assertNotIn("private-fum-", результат)
                    сам.assertIn(f"{имя.lower()}: [REDACTED: response trace identifier]\n", результат)
                    сам.assertIn("set-cookie: [REDACTED: response cookie]\n", результат)
                    сам.assertIn("Content-Type: text/html\r\n", результат)
                    сам.assertIn("Content-Language: ru\r\n", результат)
                    сам.assertIn("Last-Modified: Mon, 07 Sep 2026 12:00:00 GMT\r\n", результат)
                    сам.assertEqual(очистить(результат), результат)

    def test_геометаданные_и_устройство_запроса_удаляются_из_заголовков(сам):
        сырьё = (
            "HTTP/2 200\r\n"
            "X-Request-Geoip-Country-Code: synthetic-private-region\r\n"
            "\tprivate-continuation\r\n"
            "X-Request-Detected-Device: synthetic-private-device\r\n"
            "Content-Type: text/html\r\n"
        )
        итог = source_archive.redact_headers(сырьё)
        сам.assertNotIn("private", итог)
        сам.assertIn("x-request-geoip-country-code: [REDACTED: request metadata]", итог)
        сам.assertIn("x-request-detected-device: [REDACTED: request metadata]", итог)
        сам.assertIn("Content-Type: text/html", итог)
        сам.assertEqual(source_archive.redact_headers(итог), итог)

    def test_метаданные_маршрута_ответа_очищаются_адресно(сам):
        соседи = (
            "Content-Type: text/html; charset=utf-8\r\n"
            "Content-Language: ru\r\n"
            "Last-Modified: Mon, 07 Sep 2026 12:00:00 GMT\r\n"
            "X-Served-By-Example: public-example-node\r\n"
            "X-GitHub-Edge-Region-Example: public-example-region\r\n"
            "X-Public-Note: public-value\r\n"
            " public-folded-space\r\n"
            "\tpublic-folded-tab\r\n"
        )
        for имя in ("X-Served-By", "X-GitHub-Edge-Region"):
            with сам.subTest(заголовок=имя):
                сырьё = (
                    "HTTP/2 200\r\n"
                    f"{имя.swapcase()}: synthetic-private-first-a, synthetic-private-first-b\r\n"
                    " synthetic-private-folded-space\r\n"
                    "\tsynthetic-private-folded-tab\r\n"
                    f"{имя.upper()}: synthetic-private-second-a, synthetic-private-second-b\r\n"
                    + соседи
                )
                итог = source_archive.redact_headers(сырьё)
                сам.assertEqual(
                    итог,
                    "HTTP/2 200\r\n"
                    + f"{имя.lower()}: [REDACTED: request metadata]\n" * 2
                    + соседи,
                )
                сам.assertNotIn("synthetic-private-", итог)
                сам.assertEqual(source_archive.redact_headers(итог), итог)

    def test_метаданные_маршрута_не_изменяют_сырые_байты_разметки(сам):
        тело = (
            b"<!doctype html>\r\n<title>Fixture</title>\r\n"
            b"<p>byte:\xff public text</p> \t\r\n"
            b"<div>Public text</div>  \n \t\r\n"
        )

        def транспорт(адрес, путь_тела, путь_заголовков):
            путь_тела.write_bytes(тело)
            путь_заголовков.write_text(
                "HTTP/2 200\r\n"
                "X-Served-By: synthetic-private-node-a, synthetic-private-node-b\r\n"
                " synthetic-private-folded-space\r\n"
                "X-GitHub-Edge-Region: synthetic-private-region-a, synthetic-private-region-b\r\n"
                "\tsynthetic-private-folded-tab\r\n"
                "Content-Type: text/html; charset=utf-8\r\n"
                "Content-Language: ru\r\n",
                encoding="utf-8",
            )
            return {
                "transport": "синтетическая фикстура",
                "url_effective": адрес,
                "http_code": "200",
                "content_type": "text/html",
                "size_download": str(len(тело)),
            }

        with tempfile.TemporaryDirectory() as каталог:
            каталог = Path(каталог)
            source_archive.build_snapshot(
                каталог, "https://fixture.invalid/route-metadata", транспорт,
            )
            сам.assertEqual((каталог / "response.body.html").read_bytes(), тело)
            заголовки = (каталог / "response.headers.txt").read_text(encoding="utf-8")
            сам.assertEqual(
                заголовки,
                "HTTP/2 200\n"
                "x-served-by: [REDACTED: request metadata]\n"
                "x-github-edge-region: [REDACTED: request metadata]\n"
                "Content-Type: text/html; charset=utf-8\n"
                "Content-Language: ru\n",
            )
            сам.assertNotIn("synthetic-private-", заголовки)
            отчёт = (каталог / "extraction-report.md").read_text(encoding="utf-8")
            сам.assertIn("X-GitHub-Edge-Region", отчёт)
            сам.assertIn("X-Served-By", отчёт)

    def test_служебный_идентификатор_cf_ray_редактируется(self):
        сырьё = (
            "HTTP/2 200\r\n"
            "Content-Type: text/html\r\n"
            "CF-Ray: trace-identifier-VNO\r\n"
        )

        очищенное = source_archive.redact_headers(сырьё)

        self.assertNotIn("trace-identifier-VNO", очищенное)
        self.assertIn(
            "cf-ray: [REDACTED: response trace identifier]\n",
            очищенное,
        )

    def test_адресный_профиль_заголовков_имеет_явный_выход_и_обратное_чтение(сам):
        import hashlib as хэширование
        профиль = Path(__file__).with_name("профиль_очистки_заголовков.py")
        сам.assertTrue(профиль.is_file(), "Отсутствует адресный профиль заголовков")
        соседи = (
            "Content-Type: text/html; charset=utf-8\r\n"
            "Content-Language: ru\r\n"
            "Last-Modified: Mon, 07 Sep 2026 12:00:00 GMT\r\n"
            "X-Served-By-Example: public-example-node\r\n"
            "X-GitHub-Edge-Region-Example: public-example-region\r\n"
            "X-Public-Note: public-value\r\n"
            " public-folded-space\r\n"
            "\tpublic-folded-tab\r\n"
        )
        фикстуры = []
        for имя in ("X-Served-By", "X-GitHub-Edge-Region"):
            сырьё = (
                "HTTP/2 200\r\n"
                f"{имя.swapcase()}: synthetic-private-first-a, synthetic-private-first-b\r\n"
                " synthetic-private-folded-space\r\n"
                "\tsynthetic-private-folded-tab\r\n"
                f"{имя.upper()}: synthetic-private-second-a, synthetic-private-second-b\r\n"
                + соседи
            )
            ожидание = "HTTP/2 200\r\n" + f"{имя.lower()}: [REDACTED: request metadata]\n" * 2 + соседи
            фикстуры.append({"имя": имя, "вход_байт": len(сырьё.encode("utf-8")),
                "вход_хэш": хэширование.sha256(сырьё.encode("utf-8")).hexdigest(),
                "ожидание_байт": len(ожидание.encode("utf-8")),
                "ожидание_хэш": хэширование.sha256(ожидание.encode("utf-8")).hexdigest()})
        код = {имя: хэширование.sha256((REPO_ROOT / имя).read_bytes()).hexdigest() for имя in (
            "Инструменты/fum-materialyi-zaprosov/scripts/source_archive.py",
            "Инструменты/fum-materialyi-zaprosov/tests/профиль_очистки_заголовков.py",
            "Инструменты/fum-snimki-indeksa/scripts/профиль.py",
        )}
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный).resolve()
            for фаза in ("до", "после"):
                with сам.subTest(фаза=фаза):
                    выход = каталог / (фаза + ".json")
                    процесс = subprocess.run([sys.executable, "-B", str(профиль), "--фаза", фаза,
                        "--выход", str(выход)], cwd=каталог, text=True, stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE, check=False)
                    сам.assertEqual(процесс.returncode, 0, процесс.stderr)
                    данные = выход.read_bytes()
                    отчёт = json.loads(данные)
                    чтение = json.loads(процесс.stdout)
                    сам.assertEqual(отчёт["схема"], "fum.профиль-очистки-заголовков.1")
                    сам.assertEqual(отчёт["фаза"], фаза)
                    сам.assertEqual(чтение["схема"], "fum.чтение-профиля-заголовков.1")
                    сам.assertEqual(чтение["фаза"], фаза)
                    сам.assertTrue(чтение["прочитано_обратно"])
                    сам.assertEqual(чтение["хэш_результата"], хэширование.sha256(данные).hexdigest())
                    сам.assertEqual(чтение["байт_результата"], len(данные))
                    сам.assertEqual(отчёт["код_до"], код)
                    сам.assertEqual(отчёт["код_после"], код)
                    сам.assertEqual(чтение["код_после_чтения"], код)
                    сам.assertEqual(отчёт["фикстуры_до"], фикстуры)
                    сам.assertEqual(отчёт["фикстуры_после"], фикстуры)
                    сам.assertEqual(отчёт["счётчики"], {"повторы": 7, "фикстур": 2, "стадий": 14,
                        "вызовов_на_фикстуру_в_стадии": 1000, "вызовов_сырья": 14000,
                        "вызовов_ожиданий": 14000, "вызовов_измерено": 28000})
                    сам.assertEqual(чтение["счётчики"], отчёт["счётчики"])
                    сам.assertEqual(отчёт["проверка_до"], отчёт["проверка_после"])
                    сам.assertIs(type(отчёт["проверка_до"]["корректная_очистка"]), bool)
                    if фаза == "после":
                        сам.assertTrue(отчёт["проверка_до"]["корректная_очистка"])
                        сам.assertTrue(отчёт["проверка_до"]["идемпотентность"])
                    сам.assertEqual(len(отчёт["измерения"]), 14)
                    for имя in ("Очистка сырых синтетических заголовков", "Повторная очистка ожидаемых заголовков"):
                        сам.assertEqual(sum(запись["стадия"] == имя for запись in отчёт["измерения"]), 7)
                    for запись in отчёт["измерения"]:
                        сам.assertIs(type(запись["длительность_наносекунды"]), int)
                        сам.assertGreaterEqual(запись["длительность_наносекунды"], 0)
                        сам.assertEqual(запись["исход"], "успех")
                    сам.assertEqual(выход.read_bytes(), данные)
                    for маркер in (b"/Users/", b"/private/", b"/tmp/", b"file://", b"synthetic-private-"):
                        сам.assertNotIn(маркер, данные + процесс.stdout.encode("utf-8"))
            for аргументы in (["--фаза", "до"], ["--фаза", "до", "--выход", "относительный.json"]):
                отказ = subprocess.run([sys.executable, "-B", str(профиль), *аргументы], cwd=каталог,
                    text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
                сам.assertNotEqual(отказ.returncode, 0)
                сам.assertFalse((каталог / "относительный.json").exists())
            сам.assertEqual(sorted(путь.name for путь in каталог.iterdir()), ["до.json", "после.json"])

    def test_default_url_output_is_shared_at_repository_root(self):
        request_file = Path(
            "/repo/Журнал/2026-07-21_10-36-18_MSK_архивировать-источник/запрос.md"
        )

        output_dir = source_archive.default_output_dir(
            request_file,
            "https://example.com/articles/fum",
        )

        self.assertEqual(
            output_dir,
            Path("/repo/Источники/URL/https/example.com/articles/fum"),
        )

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
            request_file = (
                repo
                / "Журнал"
                / "2026-07-21_10-36-18_MSK_архивировать-источник"
                / "запрос.md"
            )
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
            request_file = (
                Path(tmp)
                / "Журнал"
                / "2026-07-21_10-36-18_MSK_архивировать-источник"
                / "запрос.md"
            )

            with self.assertRaisesRegex(ValueError, "request file"):
                source_archive.archive_url(
                    "https://example.com/material.html",
                    request_file,
                    transport=mock.Mock(),
                )

    def test_existing_legacy_request_path_is_rejected_before_transport(self):
        with tempfile.TemporaryDirectory() as tmp:
            request_file = Path(tmp) / "Запросы" / "legacy.md"
            request_file.parent.mkdir()
            request_file.write_text("# Запрос\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "Журнал"):
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
            request_file = (
                repo
                / "Журнал"
                / "2026-07-21_10-36-18_MSK_архивировать-источник"
                / "запрос.md"
            )
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
            source_path = "../../Источники/URL/https/fixture.invalid/articles/fum"
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
