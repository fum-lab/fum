"""Адресная миграция пути сохраняет сырые снимки и дословный текст."""
import importlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parents[1] / "scripts"))
import source_archive


class ПереносСнимков(unittest.TestCase):
    def подготовить(сам, корень):
        модуль = importlib.import_module("перенести_снимки")
        старый = корень / "Источники/URL/https/example.org/.gitmodules"
        старый.mkdir(parents=True)
        def транспорт(адрес, тело, заголовки):
            тело.write_bytes(b'raw bytes\r\n')
            заголовки.write_text('Content-Type: text/plain\n')
            return {"content_type": "text/plain", "http_code": "200", "url_effective": адрес}
        source_archive.build_snapshot(старый, 'https://example.org/.gitmodules', транспорт)
        запрос = корень / 'Журнал/2026-09-12_00-00-00_MSK_перенести-снимок/запрос.md'
        запрос.parent.mkdir(parents=True)
        ссылка = '../../' + (старый.relative_to(корень) / 'source-index.md').as_posix()
        запрос.write_text('# Запрос\n\n## Текст запроса\n\n[дословно](' + ссылка + ')\n\n## Источники\n\n[живой](' + ссылка + ')\n')
        манифест = корень / 'манифест.json'
        манифест.write_text(json.dumps({'источники': [{'путь': (старый.relative_to(корень) / 'response.body.html').as_posix(), 'url': 'https://example.org/.gitmodules'}]}, ensure_ascii=False) + '\n')
        вход = {'каталоги': [старый.relative_to(корень).as_posix()], 'markdown': [запрос.relative_to(корень).as_posix()], 'манифесты': ['манифест.json']}
        return модуль, старый, запрос, манифест, вход

    def test_план_перенос_и_защищённые_байты(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог); модуль, старый, запрос, манифест, вход = сам.подготовить(корень)
            байты = {п.name: п.read_bytes() for п in старый.iterdir()}
            план = модуль.построить_план(корень, вход)
            сам.assertEqual(план, модуль.построить_план(корень, вход))
            сам.assertTrue(старый.exists())
            модуль.применить(корень, вход, план)
            новый = source_archive.url_output_dir(корень, 'https://example.org/.gitmodules')
            сам.assertFalse(старый.exists())
            сам.assertEqual(байты, {п.name: п.read_bytes() for п in новый.iterdir()})
            сам.assertIn('[дословно](../../Источники/URL/https/example.org/.gitmodules/source-index.md)', запрос.read_text())
            сам.assertIn('[живой](../../Источники/URL/https/example.org/gitmodules-fe7afb5c9c916e52/source-index.md)', запрос.read_text())
            данные = json.loads(манифест.read_text())['источники'][0]
            сам.assertEqual(данные['url'], 'https://example.org/.gitmodules')
            сам.assertTrue((корень / данные['путь']).is_file())
            source_archive.validate_snapshot_manifest(новый)

    def test_изменившийся_вход_не_переносится(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог); модуль, старый, запрос, манифест, вход = сам.подготовить(корень)
            план = модуль.построить_план(корень, вход)
            запрос.write_text(запрос.read_text() + '\nПоздняя правка.\n')
            with сам.assertRaises(ValueError):
                модуль.применить(корень, вход, план)
            сам.assertTrue(старый.is_dir())

    def test_коллизия_и_symlink_отклоняются(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог); модуль, старый, запрос, манифест, вход = сам.подготовить(корень)
            новый = source_archive.url_output_dir(корень, 'https://example.org/.gitmodules')
            новый.mkdir()
            with сам.assertRaises(ValueError):
                модуль.построить_план(корень, вход)
            новый.rmdir()
            (старый / 'подмена').symlink_to(запрос)
            with сам.assertRaises(ValueError):
                модуль.построить_план(корень, вход)


if __name__ == '__main__':
    unittest.main()
