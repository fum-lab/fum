"""Plain text источники не становятся активным Markdown памяти."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

СПЕЦИФИКАЦИЯ = importlib.util.spec_from_file_location("source_archive", Path(__file__).parents[1] / "scripts/source_archive.py")
МОДУЛЬ = importlib.util.module_from_spec(СПЕЦИФИКАЦИЯ)
sys.modules[СПЕЦИФИКАЦИЯ.name] = МОДУЛЬ
СПЕЦИФИКАЦИЯ.loader.exec_module(МОДУЛЬ)


class ТекстовыеИсточники(unittest.TestCase):
    def test_исходные_байты_и_дословная_область(self):
        исходник = b'[local](../missing.md)\n```\n<template>real data</template>\n'
        def транспорт(адрес, тело, заголовки):
            тело.write_bytes(исходник)
            заголовки.write_text('Content-Type: text/plain; charset=utf-8\n')
            return {"content_type": "text/plain; charset=utf-8", "http_code": "200", "url_effective": адрес}
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            МОДУЛЬ.build_snapshot(корень, 'https://example.org/preset', транспорт)
            self.assertEqual((корень / 'response.body.html').read_bytes(), исходник)
            извлечение = (корень / 'extracted-text.md').read_text()
            self.assertIn('````text\n' + исходник.decode() + '````', извлечение)
            МОДУЛЬ.validate_snapshot_manifest(корень)


if __name__ == '__main__':
    unittest.main()
