import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
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
    def test_default_output_dir_uses_sources_url_path_for_stable_url(self):
        request_file = Path("/repo/Запросы/2026-06-23_17-37-29_MSK.md")

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
        request_file = Path("/repo/Запросы/2026-06-23_17-37-29_MSK.md")

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

    def test_parse_args_allows_url_path_without_source_name(self):
        argv = [
            "archive-chatgpt-share.py",
            "https://chatgpt.com/share/example",
            "--request-file",
            "/repo/Запросы/2026-06-23_17-37-29_MSK.md",
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
            request_file = repo / "Запросы" / "2026-06-24_14-33-08_MSK.md"
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
            "- [Источник: Запуск долгоживущей цепочки](../Источники/URL/https/chatgpt.com/share/example/)",
            markdown,
        )
        self.assertIn(
            "- [Индекс источника](../Источники/URL/https/chatgpt.com/share/example/source-index.md)",
            markdown,
        )
        self.assertIn(
            "- [Отчёт об извлечении](../Источники/URL/https/chatgpt.com/share/example/extraction-report.md)",
            markdown,
        )
        self.assertEqual(markdown.count("source-index.md"), 1)


if __name__ == "__main__":
    unittest.main()
