"""Проверка поздней очистки снимков без сетевого доступа и реальных секретов."""

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


СКРИПТ = Path(__file__).resolve().parents[1] / "scripts" / "очистить_сохранённые_снимки.py"
ОПИСАНИЕ = importlib.util.spec_from_file_location("fum_очистка_снимков", СКРИПТ)
ОЧИСТКА = importlib.util.module_from_spec(ОПИСАНИЕ)
ОПИСАНИЕ.loader.exec_module(ОЧИСТКА)


class ПроверкиОчисткиСнимков(unittest.TestCase):
    def test_отчёт_без_иных_изменений_тоже_входит_в_план(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            снимок = корень / "Источники/URL/https/example.org/article"
            снимок.mkdir(parents=True)
            тело = снимок / "response.body.html"
            отчёт = снимок / "extraction-report.md"
            тело.write_text("<p>Открытая статья</p>")
            отчёт.write_text("- Effective URL: https://example.org/article?code=private-only-report\n")
            путь = отчёт.relative_to(корень).as_posix()
            итог = ОЧИСТКА._преобразования(корень, [тело.relative_to(корень).as_posix(), путь])
            сам.assertIn(путь, итог)
            сам.assertNotIn(b"private-only-report", итог[путь])

    def test_старый_отчёт_дополняется_новой_редакцией_и_скрывает_код(сам):
        старое = (
            "- Effective URL: https://example.org/article?code=private-redirect&view=full\n"
            "## Редакции перед сохранением\n\n"
            "- Повторная очистка сохранённого снимка: удалены известные служебные идентификаторы запроса, nonce и локальные метаданные без нового сетевого захвата.\n"
        ).encode()
        новое = ОЧИСТКА._отчёт_с_поздней_очисткой(старое)
        сам.assertNotIn(b"private-redirect", новое)
        сам.assertIn(b"view=full", новое)
        сам.assertIn("телеметрия", новое.decode())
        сам.assertEqual(новое, ОЧИСТКА._отчёт_с_поздней_очисткой(новое))

    def test_специализированный_отчёт_получает_отдельную_позднюю_пометку(сам):
        исходное = b'# Existing report\n\nLegacy capture.\n'
        новое = ОЧИСТКА._отчёт_с_поздней_очисткой(исходное)
        сам.assertIn('## Поздняя очистка', новое.decode())
        сам.assertEqual(новое, ОЧИСТКА._отчёт_с_поздней_очисткой(новое))

    def test_html_и_производные_слои_диалога_очищаются_без_сетевого_захвата(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            обычный = корень / "Источники/URL/https/example.org/page"
            диалог = корень / "Источники/URL/https/chatgpt.com/share/example"
            обычный.mkdir(parents=True)
            диалог.mkdir(parents=True)
            файлы = {
                обычный / "response.body.html": '<script>{"visitorData":"synthetic-private-visitor"}</script><p>Открытый текст</p>',
                обычный / "response.headers.txt": 'HTTP/2 200\nX-NXID: synthetic-private-id\n',
                обычный / "extraction-report.md": '## Редакции перед сохранением\n\n- Прежняя очистка.\n',
                диалог / "chatgpt-share.html": '<meta name="dd-trace-id" content="synthetic-private-trace"><script nonce="synthetic-private-nonce">{"authStatus":"ok","cspScriptNonce":"synthetic-private-nonce"}</script><p>Диалог</p>',
                диалог / "chatgpt-share.initial-state.json": json.dumps({"cspScriptNonce": "synthetic-private-nonce"}),
                диалог / "chatgpt-share.decoded-data.json": json.dumps({"root": {"dd": {"traceId": "synthetic-private-trace"}}}),
                диалог / "chatgpt-share.script-03.txt": '"cspScriptNonce":"synthetic-private-nonce","visitorData":"synthetic-private-orphan"',
                диалог / "chatgpt-share.react-router-stream.txt": 'trace=synthetic-private-trace,"cspNonce":"synthetic-private-stream"',
                диалог / "extraction-report.md": '## Редакции перед сохранением\n\n- Прежняя очистка.\n',
            }
            пути = []
            for путь, текст in файлы.items():
                путь.write_text(текст)
                пути.append(путь.relative_to(корень).as_posix())
            итог = ОЧИСТКА._преобразования(корень, пути)
            сам.assertEqual(len(итог), len(файлы))
            сам.assertTrue(all(b"synthetic-private" not in данные for данные in итог.values()))
            сам.assertIn("Открытый текст", итог[пути[0]].decode())
            сам.assertIn("Диалог", итог[(диалог / "chatgpt-share.html").relative_to(корень).as_posix()].decode())
            for путь, данные in итог.items():
                (корень / путь).write_bytes(данные)
            сам.assertEqual(ОЧИСТКА._преобразования(корень, пути), {})
