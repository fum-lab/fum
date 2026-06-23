import importlib.util
import io
import json
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
    def test_default_output_dir_uses_sources_folder_with_source_name(self):
        request_file = Path("/repo/Запросы/2026-06-23_17-37-29_MSK.md")

        output_dir = archive_chatgpt_share.default_output_dir(
            request_file,
            "расшаренный чат ChatGPT: запуск долгоживущей цепочки",
        )

        self.assertEqual(
            output_dir,
            Path(
                "/repo/Источники/"
                "2026-06-23_17-37-29_MSK_"
                "расшаренный-чат-ChatGPT-запуск-долгоживущей-цепочки"
            ),
        )

    def test_parse_args_requires_source_name_without_output_dir(self):
        argv = [
            "archive-chatgpt-share.py",
            "https://chatgpt.com/share/example",
            "--request-file",
            "/repo/Запросы/2026-06-23_17-37-29_MSK.md",
        ]

        with (
            mock.patch("sys.argv", argv),
            mock.patch("sys.stderr", io.StringIO()),
            self.assertRaises(SystemExit) as raised,
        ):
            archive_chatgpt_share.parse_args()

        self.assertNotEqual(raised.exception.code, 0)

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


if __name__ == "__main__":
    unittest.main()
