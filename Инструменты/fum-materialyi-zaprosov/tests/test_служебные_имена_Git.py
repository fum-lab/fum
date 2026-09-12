"""URL-снимок должен сохранять байты и образовывать допустимое дерево Git."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

КАТАЛОГ = Path(__file__).parents[1] / "scripts"
sys.path.insert(0, str(КАТАЛОГ))
import source_archive

СПЕЦИФИКАЦИЯ = importlib.util.spec_from_file_location("архиватор_чата", КАТАЛОГ / "archive-chatgpt-share.py")
АРХИВАТОР = importlib.util.module_from_spec(СПЕЦИФИКАЦИЯ)
СПЕЦИФИКАЦИЯ.loader.exec_module(АРХИВАТОР)
ОПАСНЫЕ = (".gitmodules", ".GITMODULES", "%2Egitmodules", ".gitmodules.",
           "gitmod~1", "GITMOD~4", "gi7eba~1", "gi7eb~12", "~1234567",
           ".gitattributes", "GITATT~2", "gi7d29~1", ".git", ".GiT.", "git~1")


class СлужебныеИменаGit(unittest.TestCase):
    def test_оба_входа_кодируют_конечный_и_промежуточный_сегмент(сам):
        for модуль in (source_archive, АРХИВАТОР):
            for имя in ОПАСНЫЕ:
                with сам.subTest(вход=модуль.__name__, имя=имя):
                    сегмент = модуль.source_path_segment(имя)
                    сам.assertNotEqual(сегмент.casefold().rstrip(" ."), имя.casefold().rstrip(" ."))
                    for хвост in ((), ("child",)):
                        адрес = "https://example.org/root/" + "/".join((имя, *хвост))
                        путь = модуль.url_output_dir(Path("."), адрес)
                        сам.assertIn(сегмент, путь.parts)
                        сам.assertEqual(путь, модуль.url_output_dir(Path("."), адрес))
        сам.assertEqual(source_archive.source_path_segment(".gitmodules"), "gitmodules-fe7afb5c9c916e52")

    def test_обычные_имена_не_меняются(сам):
        for имя in (".github", ".gitignore", ".gitmodules.txt", "gitmod~5", "gi7eba~0", "README.md", "имя-с-ё"):
            сам.assertEqual(source_archive.source_path_segment(имя), имя)

    def test_повтор_байты_коллизия_и_строгое_дерево(сам):
        исходник = b'[submodule "x"]\n\tpath = x\n\turl = https://example.org/x.git\n'
        def транспорт(адрес, тело, заголовки):
            тело.write_bytes(исходник)
            заголовки.write_text("Content-Type: text/plain\n")
            return {"content_type": "text/plain", "http_code": "200", "url_effective": адрес}
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            запрос = корень / "Журнал/2026-09-12_00-00-00_MSK_архивировать-снимок/запрос.md"
            запрос.parent.mkdir(parents=True)
            запрос.write_text("# Снимок\n\n## Текст запроса\n\nАрхивировать.\n\n## Источники\n")
            subprocess.run(["git", "init", "-q", str(корень)], check=True)
            for номер, имя in enumerate(ОПАСНЫЕ):
                адрес = f"https://example.org/{номер}/{имя}"
                for повтор in range(2):
                    результат = source_archive.archive_url(адрес, запрос, transport=транспорт)
                    сам.assertEqual((результат.output_dir / "response.body.html").read_bytes(), исходник)
                    сам.assertEqual((результат.output_dir / "source-url.txt").read_text().strip(), адрес)
                    source_archive.validate_snapshot_manifest(результат.output_dir)
                подмена = результат.output_dir / "source-url.txt"
                подмена.write_text("https://different.example/source\n")
                with сам.assertRaisesRegex(ValueError, "different URL"):
                    source_archive.archive_url(адрес, запрос, transport=транспорт)
                подмена.write_text(адрес + "\n")
            subprocess.run(["git", "-C", str(корень), "add", "."], check=True, capture_output=True)
            дерево = subprocess.check_output(["git", "-C", str(корень), "write-tree"], text=True).strip()
            итог = subprocess.run(["git", "-C", str(корень), "fsck", "--strict", "--no-reflogs", дерево], capture_output=True, text=True)
            сам.assertEqual(итог.returncode, 0, итог.stdout + итог.stderr)


if __name__ == "__main__":
    unittest.main()
