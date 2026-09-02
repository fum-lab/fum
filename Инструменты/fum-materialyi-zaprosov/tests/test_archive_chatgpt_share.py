import importlib.util
import io
import json
import tempfile
import unittest
from contextlib import ExitStack, redirect_stderr
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "archive-chatgpt-share.py"
)

spec = importlib.util.spec_from_file_location("archive_chatgpt_share", SCRIPT_PATH)
archive_chatgpt_share = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(archive_chatgpt_share)


class ArchiveChatgptShareTests(unittest.TestCase):
    def fake_atomic_directory_exchange(self, first: Path, second: Path) -> bool:
        old_snapshot = second.with_name(f".{second.name}.old-fixture")
        self.assertFalse(old_snapshot.exists())
        first.replace(old_snapshot)
        second.replace(first)
        old_snapshot.replace(second)
        return True

    def run_archive_fixture(
        self,
        *,
        request_file: Path,
        output_dir: Path,
        html: str,
        decoded: object | None = None,
    ) -> int:
        args = SimpleNamespace(
            url="https://chatgpt.com/share/example",
            request_file=request_file,
            output_dir=output_dir,
            source_name=None,
        )

        def fake_run_curl(url: str, html_path: Path, headers_path: Path):
            self.assertEqual(url, args.url)
            html_path.write_text(html, encoding="utf-8")
            headers_path.write_text(
                "HTTP/2 200\ncontent-type: text/html\n",
                encoding="utf-8",
            )
            return {
                "url_effective": url,
                "http_code": "200",
                "content_type": "text/html",
                "size_download": str(len(html.encode("utf-8"))),
            }

        with ExitStack() as stack:
            stack.enter_context(
                mock.patch.object(
                    archive_chatgpt_share,
                    "parse_args",
                    return_value=args,
                )
            )
            stack.enter_context(
                mock.patch.object(
                    archive_chatgpt_share,
                    "run_curl",
                    side_effect=fake_run_curl,
                )
            )
            stack.enter_context(
                mock.patch.object(
                    archive_chatgpt_share,
                    "try_atomic_directory_exchange",
                    side_effect=self.fake_atomic_directory_exchange,
                )
            )
            if decoded is not None:
                stack.enter_context(
                    mock.patch.object(
                        archive_chatgpt_share,
                        "decode_react_router_table",
                        return_value=decoded,
                    )
                )
            return archive_chatgpt_share.main()

    def full_snapshot_fixture(self) -> tuple[str, dict[str, object]]:
        stream_script = (
            "window.__reactRouterContext.streamController.enqueue("
            + json.dumps("[{}]")
            + ");"
        )
        html = (
            "<html><body>"
            '<script>{"authStatus":"ok","cfConnectingIp":"127.0.0.1"}</script>'
            f"<script>{stream_script}</script>"
            "<p>Полный снимок</p>"
            "</body></html>"
        )
        decoded = {
            "loaderData": {
                "routes/share.$shareId.($action)": {
                    "serverResponse": {
                        "data": {
                            "title": "Полный снимок",
                            "conversation_id": "conversation-1",
                            "linear_conversation": [
                                {
                                    "id": "node-1",
                                    "parent": None,
                                    "message": {
                                        "author": {"role": "user"},
                                        "content": {
                                            "content_type": "text",
                                            "parts": ["Содержательное сообщение."],
                                        },
                                    },
                                }
                            ],
                        }
                    }
                }
            }
        }
        return html, decoded

    def snapshot_bytes(self, directory: Path) -> dict[str, bytes]:
        return {
            path.relative_to(directory).as_posix(): path.read_bytes()
            for path in directory.rglob("*")
            if path.is_file()
        }

    def test_default_output_dir_uses_sources_url_path_for_stable_url(self):
        request_file = Path(
            "/repo/Журнал/2026-06-23_17-37-29_MSK_архивировать-чат/запрос.md"
        )

        output_dir = archive_chatgpt_share.default_output_dir(
            request_file,
            "https://chatgpt.com/share/6a3a5b33-0658-83eb-a491-8e5a7fef6f54",
        )

        self.assertEqual(
            output_dir,
            Path(
                "/repo/Источники/URL/https/chatgpt.com/share/"
                "6a3a5b33-0658-83eb-a491-8e5a7fef6f54"
            ),
        )

    def test_default_output_dir_keeps_query_variants_separate(self):
        request_file = Path(
            "/repo/Журнал/2026-06-23_17-37-29_MSK_архивировать-чат/запрос.md"
        )

        first = archive_chatgpt_share.default_output_dir(
            request_file,
            "https://example.com/search?q=FUM",
        )
        second = archive_chatgpt_share.default_output_dir(
            request_file,
            "https://example.com/search?q=other",
        )

        self.assertNotEqual(first, second)
        self.assertEqual(first.parent, Path("/repo/Источники/URL/https/example.com/search"))
        self.assertNotIn("FUM", first.as_posix())
        self.assertRegex(first.name, r"^_query-[0-9a-f]{16}$")

    def test_default_output_dir_keeps_normalized_path_collisions_separate(self):
        request_file = Path(
            "/repo/Журнал/2026-06-23_17-37-29_MSK_архивировать-чат/запрос.md"
        )

        first = archive_chatgpt_share.default_output_dir(
            request_file,
            "https://chatgpt.com/share/a:b",
        )
        second = archive_chatgpt_share.default_output_dir(
            request_file,
            "https://chatgpt.com/share/a-b",
        )

        self.assertNotEqual(first, second)

    def test_default_output_dir_rejects_non_http_url(self):
        request_file = Path(
            "/repo/Журнал/2026-06-23_17-37-29_MSK_архивировать-чат/запрос.md"
        )

        with self.assertRaisesRegex(ValueError, "HTTP or HTTPS"):
            archive_chatgpt_share.default_output_dir(
                request_file,
                "file://localhost/private/material.html",
            )

    def test_non_url_fallback_is_owned_by_request_folder(self):
        request_file = Path(
            "/repo/Журнал/2026-06-23_17-37-29_MSK_архивировать-чат/запрос.md"
        )

        output_dir = archive_chatgpt_share.default_output_dir(
            request_file,
            "not-a-url",
            "Сырой экспорт",
        )

        self.assertEqual(
            output_dir,
            Path(
                "/repo/Журнал/2026-06-23_17-37-29_MSK_архивировать-чат/"
                "материалы/источники/Сырой-экспорт"
            ),
        )

    def test_main_rejects_unsafe_url_even_with_explicit_output_dir(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            request_file = (
                root
                / "Журнал"
                / "2026-06-23_17-37-29_MSK_архивировать-чат"
                / "запрос.md"
            )
            request_file.parent.mkdir(parents=True)
            request_file.write_text("# Запрос\n", encoding="utf-8")
            args = SimpleNamespace(
                url="https://user:secret@chatgpt.com/share/example",
                request_file=request_file,
                output_dir=root / "source",
                source_name=None,
            )

            with mock.patch.object(
                archive_chatgpt_share,
                "parse_args",
                return_value=args,
            ):
                with mock.patch.object(
                    archive_chatgpt_share,
                    "run_curl",
                    side_effect=AssertionError("transport must not run"),
                ):
                    with self.assertRaisesRegex(ValueError, "userinfo"):
                        archive_chatgpt_share.main()

    def test_main_rejects_missing_request_file_before_capture(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            args = SimpleNamespace(
                url="https://chatgpt.com/share/example",
                request_file=root / "missing.md",
                output_dir=root / "source",
                source_name=None,
            )

            with mock.patch.object(
                archive_chatgpt_share,
                "parse_args",
                return_value=args,
            ):
                with mock.patch.object(
                    archive_chatgpt_share,
                    "run_curl",
                    side_effect=AssertionError("transport must not run"),
                ):
                    with self.assertRaisesRegex(ValueError, "request file"):
                        archive_chatgpt_share.main()

    def test_existing_legacy_request_path_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            request_file = Path(tmp) / "Запросы" / "legacy.md"
            request_file.parent.mkdir()
            request_file.write_text("# Запрос\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "Журнал"):
                archive_chatgpt_share.validate_request_file(request_file)

    def test_cli_reports_runtime_error_without_traceback(self):
        stderr = io.StringIO()
        with mock.patch.object(
            archive_chatgpt_share,
            "main",
            side_effect=RuntimeError("curl capture failed with exit code 22"),
        ):
            with redirect_stderr(stderr):
                result = archive_chatgpt_share.cli()

        self.assertEqual(result, 1)
        self.assertIn("curl capture failed with exit code 22", stderr.getvalue())
        self.assertNotIn("Traceback", stderr.getvalue())

    def test_parse_args_allows_url_path_without_source_name(self):
        argv = [
            "archive-chatgpt-share.py",
            "https://chatgpt.com/share/example",
            "--request-file",
            "/repo/Журнал/2026-06-23_17-37-29_MSK_архивировать-чат/запрос.md",
        ]

        with mock.patch("sys.argv", argv):
            args = archive_chatgpt_share.parse_args()

        self.assertIsNone(args.output_dir)
        self.assertIsNone(args.source_name)

    def test_redact_headers_removes_set_cookie_values(self):
        raw = (
            "HTTP/2 200\r\n"
            "content-type: text/html\r\n"
            "Set-Cookie: session=secret; HttpOnly\r\n"
            "set-cookie: another=secret\r\n"
        )

        redacted = archive_chatgpt_share.redact_headers(raw)

        self.assertNotIn("session=secret", redacted)
        self.assertNotIn("another=secret", redacted)
        self.assertEqual(redacted.count("[REDACTED: response cookie]"), 2)
        self.assertIn("content-type: text/html", redacted)

    def test_existing_snapshot_must_belong_to_exact_source_url(self):
        with tempfile.TemporaryDirectory() as tmp:
            output_dir = Path(tmp) / "source"
            output_dir.mkdir()
            (output_dir / "source-url.txt").write_text(
                "https://chatgpt.com/share/different\n",
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "belongs to a different URL"):
                archive_chatgpt_share.ensure_destination_matches_url(
                    output_dir,
                    "https://chatgpt.com/share/example",
                )

    def test_external_title_is_escaped_when_request_is_linked(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            request_file = (
                repo
                / "Журнал"
                / "2026-06-23_17-37-29_MSK_архивировать-чат"
                / "запрос.md"
            )
            output_dir = repo / "Источники" / "source"
            request_file.parent.mkdir(parents=True)
            output_dir.mkdir(parents=True)
            request_file.write_text("# Запрос\n", encoding="utf-8")

            archive_chatgpt_share.link_source_in_request_file(
                request_file,
                output_dir,
                "X](https://attacker.invalid)[Y",
            )

            markdown = request_file.read_text(encoding="utf-8")

        self.assertIn(r"Источник: X\](https://attacker.invalid)\[Y", markdown)
        self.assertNotRegex(markdown, r"(?<!\\)\]\(https://attacker\.invalid")

    def test_redact_initial_state_removes_local_request_metadata_recursively(self):
        state = {
            "cfConnectingIp": "127.0.0.1",
            "nested": {
                "userAgent": "secret-agent",
                "keep": "public value",
                "id": "ua-sensitive-id",
            },
            "statsigPayload": json.dumps(
                {
                    "user": {"country": "RU", "stableID": "stable-secret"},
                    "feature": "visible",
                }
            ),
        }

        redacted = archive_chatgpt_share.redact_initial_state(state)

        self.assertEqual(redacted["cfConnectingIp"], archive_chatgpt_share.REDACTION)
        self.assertEqual(redacted["nested"]["userAgent"], archive_chatgpt_share.REDACTION)
        self.assertEqual(redacted["nested"]["id"], archive_chatgpt_share.REDACTION)
        self.assertEqual(redacted["nested"]["keep"], "public value")

        statsig = json.loads(redacted["statsigPayload"])
        self.assertEqual(statsig["user"]["country"], archive_chatgpt_share.REDACTION)
        self.assertEqual(statsig["user"]["stableID"], archive_chatgpt_share.REDACTION)
        self.assertEqual(statsig["feature"], "visible")

    def test_redact_initial_state_removes_decoded_request_metadata(self):
        decoded = {
            "node_id": "node-1",
            "metadata": {
                "request_id": "wfr_019ef3de600371ae98c98e1105e2192a",
                "async_source": (
                    "saserver-switzerlandnorth-prod.fck9d:"
                    "bon-user-NiAAil3YY6CORHPNoPrMjgxk-9010db44:EU"
                ),
                "keep": "public value",
            },
            "messages": [
                {
                    "request_id": "9010db44-dc61-4ded-bc46-3a1385bc14eb",
                    "text": "Содержательный текст диалога.",
                }
            ],
        }

        redacted = archive_chatgpt_share.redact_initial_state(decoded)

        self.assertEqual(redacted["node_id"], "node-1")
        self.assertEqual(redacted["metadata"]["request_id"], archive_chatgpt_share.REDACTION)
        self.assertEqual(redacted["metadata"]["async_source"], archive_chatgpt_share.REDACTION)
        self.assertEqual(redacted["metadata"]["keep"], "public value")
        self.assertEqual(redacted["messages"][0]["request_id"], archive_chatgpt_share.REDACTION)
        self.assertEqual(redacted["messages"][0]["text"], "Содержательный текст диалога.")

    def test_sanitize_html_redacts_bootstrap_state_inside_script(self):
        html = (
            "<html><body>"
            '<script>{"authStatus":"ok","cfConnectingIp":"127.0.0.1"}</script>'
            "</body></html>"
        )
        scripts = archive_chatgpt_share.collect_scripts(html)

        sanitized_html, initial_state = archive_chatgpt_share.sanitize_html(html, scripts)

        self.assertEqual(initial_state["cfConnectingIp"], archive_chatgpt_share.REDACTION)
        self.assertNotIn("127.0.0.1", sanitized_html)
        self.assertIn(archive_chatgpt_share.REDACTION, sanitized_html)

    def test_extract_stream_parts_decodes_enqueued_json_strings(self):
        scripts = [
            'window.__reactRouterContext.streamController.enqueue("[{\\"value\\":1}]");'
            'window.__reactRouterContext.streamController.enqueue("{\\"tail\\":true}");'
        ]

        parts = archive_chatgpt_share.extract_stream_parts(scripts)

        self.assertEqual(parts, ['[{"value":1}]', '{"tail":true}'])

    def test_decode_react_router_table_resolves_references_and_cycles(self):
        stream = json.dumps([{"root": 1, "loop": 2}, "value", 2])

        decoded = archive_chatgpt_share.decode_react_router_table(stream)

        self.assertEqual(decoded["root"], "value")
        self.assertEqual(decoded["loop"], "$CYCLE:2")

    def test_extract_messages_returns_linear_dialog_text(self):
        decoded = {
            "loaderData": {
                "routes/share.$shareId.($action)": {
                    "serverResponse": {
                        "data": {
                            "title": "Example",
                            "conversation_id": "conv-1",
                            "linear_conversation": [
                                {
                                    "id": "node-1",
                                    "parent": None,
                                    "message": {
                                        "author": {"role": "user"},
                                        "content": {
                                            "content_type": "text",
                                            "parts": ["Hello", "world"],
                                        },
                                        "create_time": 1_700_000_000,
                                    },
                                },
                                {"id": "empty", "message": {"content": {"parts": []}}},
                            ],
                        }
                    }
                }
            }
        }

        extracted = archive_chatgpt_share.extract_messages(decoded)

        self.assertEqual(extracted["title"], "Example")
        self.assertEqual(extracted["conversation_id"], "conv-1")
        self.assertEqual(extracted["message_count"], 1)
        self.assertEqual(extracted["messages"][0]["role"], "user")
        self.assertEqual(extracted["messages"][0]["text"], "Hello\nworld")
        self.assertTrue(
            extracted["messages"][0]["create_time_utc"].startswith("2023-11-14T")
        )

    def test_formatted_messages_markdown_name_uses_dialog_title(self):
        messages_data = {"title": "Запуск долгоживущей цепочки"}

        name = archive_chatgpt_share.formatted_messages_markdown_name(messages_data)

        self.assertEqual(name, "запуск-долгоживущей-цепочки.md")

    def test_write_messages_markdown_uses_readable_dialog_title_and_roles(self):
        messages_data = {
            "title": "Запуск долгоживущей цепочки",
            "message_count": 2,
            "messages": [
                {
                    "role": "user",
                    "create_time_utc": "2026-06-23T09:11:59+00:00",
                    "text": "Какой из агентов запустил наиболее долгоживущую цепочку?",
                },
                {
                    "role": "assistant",
                    "create_time_utc": "2026-06-23T09:13:43+00:00",
                    "text": "Не хватает исходных данных.",
                },
            ],
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "запуск-долгоживущей-цепочки.md"

            archive_chatgpt_share.write_messages_markdown(
                path,
                "https://chatgpt.com/share/example",
                messages_data,
            )

            markdown = path.read_text(encoding="utf-8")

        self.assertTrue(markdown.startswith("# Запуск долгоживущей цепочки\n"))
        self.assertIn("Полный структурный слой: [chatgpt-share.messages.json](chatgpt-share.messages.json)", markdown)
        self.assertIn("## Диалог", markdown)
        self.assertIn(
            "<!-- FUM-CHATGPT-SHARE-VERBATIM:BEGIN -->",
            markdown,
        )
        self.assertIn(
            "<!-- FUM-CHATGPT-SHARE-VERBATIM:END -->",
            markdown,
        )
        self.assertLess(
            markdown.index("<!-- FUM-CHATGPT-SHARE-VERBATIM:BEGIN -->"),
            markdown.index("### 1. Пользователь"),
        )
        self.assertLess(
            markdown.index("### 2. Ассистент"),
            markdown.index("<!-- FUM-CHATGPT-SHARE-VERBATIM:END -->"),
        )
        self.assertIn("### 1. Пользователь", markdown)
        self.assertIn("### 2. Ассистент", markdown)
        self.assertNotIn("## Сообщение 1: user", markdown)
        self.assertNotIn("Время UTC", markdown)
        self.assertNotIn("Исходная роль", markdown)

    def test_write_messages_markdown_omits_service_messages_and_formats_obsidian_math(self):
        messages_data = {
            "title": "Формулы и служебный слой",
            "message_count": 4,
            "messages": [
                {
                    "role": "user",
                    "text": "Теперь по этим формулам можно вычислять веса агентов.",
                },
                {
                    "role": "tool",
                    "text": "The output of this plugin was redacted.",
                },
                {
                    "role": "assistant",
                    "text": '{"search_query":[{"q":"FUM"}],"response_length":"short"}',
                },
                {
                    "role": "assistant",
                    "text": (
                        "Итоговый вес можно записать так:\n\n"
                        "\\[\n"
                        "W_i=\\alpha Q_i+\\beta T_i\n"
                        "\\]\n\n"
                        "Лидирует агент с максимальным \\(W_i\\). "
                        "\ue200cite\ue202turn1search0\ue201"
                    ),
                },
            ],
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "формулы-и-служебный-слой.md"

            archive_chatgpt_share.write_messages_markdown(
                path,
                "https://chatgpt.com/share/example",
                messages_data,
            )

            markdown = path.read_text(encoding="utf-8")

        self.assertIn("$$\nW_i=\\alpha Q_i+\\beta T_i\n$$", markdown)
        self.assertIn("максимальным $W_i$", markdown)
        self.assertNotIn("\\[", markdown)
        self.assertNotIn("\\]", markdown)
        self.assertNotIn("\\(", markdown)
        self.assertNotIn("\\)", markdown)
        self.assertNotIn("Служебный вывод инструмента", markdown)
        self.assertNotIn("The output of this plugin was redacted.", markdown)
        self.assertNotIn("search_query", markdown)
        self.assertNotIn("\ue200cite", markdown)

    def test_write_source_index_links_readable_markdown_and_report(self):
        messages_data = {
            "title": "Запуск долгоживущей цепочки",
            "message_count": 2,
        }

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "source-index.md"

            archive_chatgpt_share.write_source_index(
                path,
                "https://chatgpt.com/share/example",
                [
                    "chatgpt-share.messages.json",
                    "extraction-report.md",
                    "запуск-долгоживущей-цепочки.md",
                ],
                messages_data,
            )

            markdown = path.read_text(encoding="utf-8")

        self.assertTrue(markdown.startswith("# Источник: Запуск долгоживущей цепочки\n"))
        self.assertIn("Исходный URL: <https://chatgpt.com/share/example>", markdown)
        self.assertIn(
            "- [Оформленный диалог](запуск-долгоживущей-цепочки.md)",
            markdown,
        )
        self.assertIn("- [Отчёт об извлечении](extraction-report.md)", markdown)
        self.assertIn(
            "- [Структурный слой сообщений](chatgpt-share.messages.json)",
            markdown,
        )

    def test_link_source_in_request_file_adds_material_links_once(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            request_file = (
                repo
                / "Журнал"
                / "2026-06-24_14-33-08_MSK_архивировать-чат"
                / "запрос.md"
            )
            output_dir = (
                repo
                / "Источники"
                / "URL"
                / "https"
                / "chatgpt.com"
                / "share"
                / "example"
            )
            request_file.parent.mkdir(parents=True)
            output_dir.mkdir(parents=True)
            request_file.write_text(
                "# Исходный запрос 2026-06-24 14:33:08 MSK\n\n"
                "## Текст запроса\n\n"
                "> пример\n",
                encoding="utf-8",
            )

            archive_chatgpt_share.link_source_in_request_file(
                request_file,
                output_dir,
                "Запуск долгоживущей цепочки",
            )
            archive_chatgpt_share.link_source_in_request_file(
                request_file,
                output_dir,
                "Запуск долгоживущей цепочки",
            )

            markdown = request_file.read_text(encoding="utf-8")

        self.assertIn("## Прикрепляемые материалы", markdown)
        self.assertIn(
            "- [Источник: Запуск долгоживущей цепочки](../../Источники/URL/https/chatgpt.com/share/example/)",
            markdown,
        )
        self.assertIn(
            "- [Индекс источника](../../Источники/URL/https/chatgpt.com/share/example/source-index.md)",
            markdown,
        )
        self.assertIn(
            "- [Отчёт об извлечении](../../Источники/URL/https/chatgpt.com/share/example/extraction-report.md)",
            markdown,
        )
        self.assertEqual(markdown.count("source-index.md"), 1)

    def test_full_snapshot_then_partial_snapshot_replaces_managed_files_exactly(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            request_file = (
                repo
                / "Журнал"
                / "2026-06-23_17-37-29_MSK_архивировать-чат"
                / "запрос.md"
            )
            output_dir = repo / "Источники" / "source"
            request_file.parent.mkdir(parents=True)
            request_file.write_text("# Запрос\n", encoding="utf-8")
            full_html, decoded = self.full_snapshot_fixture()

            self.run_archive_fixture(
                request_file=request_file,
                output_dir=output_dir,
                html=full_html,
                decoded=decoded,
            )

            old_structural_files = {
                "chatgpt-share.initial-state.json",
                "chatgpt-share.decoded-data.json",
                "chatgpt-share.messages.json",
                "полный-снимок.md",
            }
            old_script_files = {
                path.name for path in output_dir.glob("chatgpt-share.script-*.txt")
            }
            self.assertTrue(old_structural_files <= {path.name for path in output_dir.iterdir()})
            self.assertTrue(old_script_files)

            self.run_archive_fixture(
                request_file=request_file,
                output_dir=output_dir,
                html="<html><body><p>Неполный снимок</p></body></html>",
            )

            manifest_path = output_dir / "snapshot-manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            actual_files = {
                path.relative_to(output_dir).as_posix()
                for path in output_dir.rglob("*")
                if path.is_file()
            }
            self.assertEqual(
                manifest["schema"],
                "fum.request-materials.snapshot-manifest.v1",
            )
            self.assertEqual(actual_files, set(manifest["managed_files"]))
            self.assertTrue(old_structural_files.isdisjoint(actual_files))
            self.assertTrue(old_script_files.isdisjoint(actual_files))

            index = (output_dir / "source-index.md").read_text(encoding="utf-8")
            report = (output_dir / "extraction-report.md").read_text(encoding="utf-8")
            for old_name in old_structural_files | old_script_files:
                self.assertNotIn(old_name, index)
                self.assertNotIn(old_name, report)

    def test_failed_rearchive_keeps_canonical_snapshot_byte_for_byte(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            request_file = (
                repo
                / "Журнал"
                / "2026-06-23_17-37-29_MSK_архивировать-чат"
                / "запрос.md"
            )
            output_dir = repo / "Источники" / "source"
            request_file.parent.mkdir(parents=True)
            request_file.write_text("# Запрос\n", encoding="utf-8")
            full_html, decoded = self.full_snapshot_fixture()

            self.run_archive_fixture(
                request_file=request_file,
                output_dir=output_dir,
                html=full_html,
                decoded=decoded,
            )
            canonical_before = self.snapshot_bytes(output_dir)

            def fail_report(*args, **kwargs):
                self.assertEqual(
                    self.snapshot_bytes(output_dir),
                    canonical_before,
                )
                raise RuntimeError("fixture: report generation failed")

            with mock.patch.object(
                archive_chatgpt_share,
                "write_report",
                side_effect=fail_report,
            ):
                with self.assertRaisesRegex(
                    RuntimeError,
                    "report generation failed",
                ):
                    self.run_archive_fixture(
                        request_file=request_file,
                        output_dir=output_dir,
                        html="<html><body><p>Новый ответ</p></body></html>",
                    )

            self.assertEqual(self.snapshot_bytes(output_dir), canonical_before)
            self.assertEqual(
                list(output_dir.parent.glob(f".{output_dir.name}.staging-*")),
                [],
            )

    def test_rearchive_fails_closed_when_atomic_directory_exchange_is_unavailable(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            output_dir = root / "source"
            staging_dir = root / ".source.staging-fixture"
            output_dir.mkdir()
            staging_dir.mkdir()
            (output_dir / "old-a.txt").write_text("old a\n", encoding="utf-8")
            (output_dir / "old-b.txt").write_text("old b\n", encoding="utf-8")
            (staging_dir / "new.txt").write_text("new\n", encoding="utf-8")
            canonical_before = self.snapshot_bytes(output_dir)
            staging_before = self.snapshot_bytes(staging_dir)

            with mock.patch.object(
                archive_chatgpt_share,
                "try_atomic_directory_exchange",
                return_value=False,
            ):
                with self.assertRaisesRegex(
                    RuntimeError,
                    "atomic directory exchange is unavailable",
                ):
                    archive_chatgpt_share.install_snapshot(
                        staging_dir,
                        output_dir,
                    )

            self.assertEqual(self.snapshot_bytes(output_dir), canonical_before)
            self.assertEqual(self.snapshot_bytes(staging_dir), staging_before)
            self.assertEqual(list(root.glob(".source.backup-*")), [])

    def test_request_link_failure_after_commit_is_reported_as_warning(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            request_file = (
                repo
                / "Журнал"
                / "2026-06-23_17-37-29_MSK_архивировать-чат"
                / "запрос.md"
            )
            output_dir = repo / "Источники" / "source"
            request_file.parent.mkdir(parents=True)
            request_file.write_text("# Запрос\n", encoding="utf-8")
            full_html, decoded = self.full_snapshot_fixture()
            stderr = io.StringIO()

            with mock.patch.object(
                archive_chatgpt_share,
                "link_source_in_request_file",
                side_effect=OSError("fixture: request file is unavailable"),
            ):
                with redirect_stderr(stderr):
                    result = self.run_archive_fixture(
                        request_file=request_file,
                        output_dir=output_dir,
                        html=full_html,
                        decoded=decoded,
                    )

            self.assertEqual(result, 0)
            archive_chatgpt_share.validate_snapshot_manifest(output_dir)
            self.assertIn("snapshot was saved", stderr.getvalue())
            self.assertIn("request file was not linked", stderr.getvalue())

    def test_request_file_update_is_atomic_when_replace_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            request_file = (
                repo
                / "Журнал"
                / "2026-06-23_17-37-29_MSK_архивировать-чат"
                / "запрос.md"
            )
            output_dir = repo / "Источники" / "source"
            request_file.parent.mkdir(parents=True)
            output_dir.mkdir(parents=True)
            original = "# Исходный запрос\n\nИсходное содержимое.\n"
            request_file.write_text(original, encoding="utf-8")

            with mock.patch.object(
                archive_chatgpt_share.os,
                "replace",
                side_effect=OSError("fixture: replace failed"),
            ):
                with self.assertRaisesRegex(OSError, "replace failed"):
                    archive_chatgpt_share.link_source_in_request_file(
                        request_file,
                        output_dir,
                        "Источник",
                    )

            self.assertEqual(request_file.read_text(encoding="utf-8"), original)
            self.assertEqual(
                list(request_file.parent.glob(f".{request_file.name}.tmp-*")),
                [],
            )

    def test_post_commit_staging_residue_is_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            request_file = (
                repo
                / "Журнал"
                / "2026-06-23_17-37-29_MSK_архивировать-чат"
                / "запрос.md"
            )
            output_dir = repo / "Источники" / "source"
            request_file.parent.mkdir(parents=True)
            request_file.write_text("# Запрос\n", encoding="utf-8")
            full_html, decoded = self.full_snapshot_fixture()
            self.run_archive_fixture(
                request_file=request_file,
                output_dir=output_dir,
                html=full_html,
                decoded=decoded,
            )
            real_temporary_directory = tempfile.TemporaryDirectory

            class LeakyTemporaryDirectory:
                def __init__(self, *args, **kwargs):
                    self.path = Path(
                        tempfile.mkdtemp(
                            prefix=kwargs.get("prefix"),
                            dir=kwargs.get("dir"),
                        )
                    )

                def __enter__(self):
                    return str(self.path)

                def __exit__(self, exc_type, exc_value, traceback):
                    return False

            def temporary_directory_factory(*args, **kwargs):
                prefix = kwargs.get("prefix", "")
                if prefix.startswith(f".{output_dir.name}.staging-"):
                    return LeakyTemporaryDirectory(*args, **kwargs)
                return real_temporary_directory(*args, **kwargs)

            stderr = io.StringIO()
            with mock.patch.object(
                archive_chatgpt_share.tempfile,
                "TemporaryDirectory",
                side_effect=temporary_directory_factory,
            ):
                with redirect_stderr(stderr):
                    self.run_archive_fixture(
                        request_file=request_file,
                        output_dir=output_dir,
                        html="<html><body><p>Неполный снимок</p></body></html>",
                    )

            residues = list(output_dir.parent.glob(f".{output_dir.name}.staging-*"))
            self.assertEqual(len(residues), 1)
            self.assertIn("old snapshot remains in staging", stderr.getvalue())
            archive_chatgpt_share.validate_snapshot_manifest(output_dir)


if __name__ == "__main__":
    unittest.main()
