"""Точные границы публичных шаблонов адресов и настоящих локальных путей."""
import importlib.util
import json
import os
from pathlib import Path
import sys
import unittest
from unittest import mock

корень = Path(__file__).resolve().parents[3]
выбранный = os.environ.get("FUM_CHECKED_CODE_ROOT")
if выбранный is not None:
    if not выбранный or not Path(выбранный).is_absolute():
        raise ValueError("нужен явный абсолютный корень проверяемой реализации")
    корень = Path(выбранный)
сценарии = корень / "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts"
sys.path.insert(0, str(сценарии))
import path_forms

описание = importlib.util.spec_from_file_location(
    "сканер_шаблонов_адресов", сценарии / "proveritj-mashinno-lokaljnyiye-puti.py")
сканер = importlib.util.module_from_spec(описание)
sys.modules[описание.name] = сканер
описание.loader.exec_module(сканер)


class ШаблоныАдресов(unittest.TestCase):
    def test_публичные_шаблоны_сохраняют_полные_границы(сам):
        for адрес in (
            "https://api.github.com/repos/fum-lab/fum/issues/1/labels{/name}",
            "https://api.github.com/users/example/following{/other_user}",
            "https://api.github.com/users/example/gists{/gist_id}",
            "https://api.github.com/users/example/starred{/owner}{/repo}",
            "https://api.github.com/users/example/events{/privacy}",
            "HTTP://example.test:443/a{/_x2}{/Y}",
            "https://user%40name@example.test/a{/id}",
            "https://exa%6Dple.test/a{/id}",
            "https://пример.рф/a{/id}",
        ):
            with сам.subTest(адрес=адрес):
                текст = 'начало "' + адрес + '" конец'
                сам.assertEqual(path_forms.detect_path_forms(текст), ())
                формы = path_forms.detect_path_forms(текст, include_web_urls=True)
                сам.assertEqual(len(формы), 1)
                форма = формы[0]
                сам.assertEqual((форма.start, форма.end, форма.kind, форма.value),
                                 (8, 8 + len(адрес), "web-url", адрес))
                сам.assertEqual(текст[форма.start:форма.end], адрес)

    def test_неполный_или_неподдержанный_хвост_не_маскируется(сам):
        основа = "https://example.test/a"
        for хвост in (
            "{/good}{/bad", "{/good}{/bad*}", "{/good}{/9bad}",
            "{/good}{/имя}", "{/good}{?query}", "{/good}tail",
            "{/good}{/bad}}", "{/good}/suffix", "{/good}?q=x",
            "{/good}#fragment",
            "{/good}"
            "{/Users/example}",
        ):
            with сам.subTest(хвост=хвост):
                формы = path_forms.detect_path_forms(основа + хвост, include_web_urls=True)
                сам.assertEqual(формы[0].value, основа)
                сам.assertIn("/good", [форма.value for форма in формы[1:]])
                сам.assertEqual(формы[0].end, len(основа))

    def test_неверный_адрес_не_поглощает_шаблон(сам):
        for основа in ("https:///", "https://:443/a",
                       "https://example.test:bad/a", "https://example.test:70000/a",
                       "https://bad|host/a", "https://bad%ZZhost/a",
                       "https://bad%/a", "https://bad%2/a",
                       "https://bad^host/a", "https://bad" + chr(96) + "host/a",
                       "https://bad\\host/a", "https://bad" + chr(0) + "host/a"):
            with сам.subTest(основа=основа):
                формы = path_forms.detect_path_forms(основа + "{/good}", include_web_urls=True)
                сам.assertEqual((формы[0].value, формы[0].end), (основа, len(основа)))
                сам.assertIn("/good", [форма.value for форма in формы[1:]])

    def test_файл_и_иная_схема_сохраняют_прежние_границы(сам):
        for основа, вид in (("file:///srv/a", "file-uri"),
                            ("ssh://example.test/a", "web-url")):
            with сам.subTest(основа=основа):
                формы = path_forms.detect_path_forms(основа + "{/id}", include_web_urls=True)
                сам.assertEqual((формы[0].kind, формы[0].value), (вид, основа))
                сам.assertIn("/id", [форма.value for форма in формы[1:]])

    def test_соседний_локальный_путь_сохраняется(сам):
        адрес = "https://example.test/a{/id}"
        for разделитель in ('"', "'", " ", "\n"):
            with сам.subTest(разделитель=разделитель):
                текст = адрес + разделитель + "/srv/private"
                формы = path_forms.detect_path_forms(текст, include_web_urls=True)
                сам.assertEqual([(форма.kind, форма.value) for форма in формы],
                                 [("web-url", адрес), ("posix-absolute", "/srv/private")])
                сам.assertEqual([форма.value for форма in path_forms.detect_path_forms(текст)],
                                 ["/srv/private"])
        текст = '"' + адрес + '"/Users/example/private'
        сам.assertEqual([(форма.kind, форма.value) for форма in path_forms.detect_path_forms(текст)],
                         [("posix-user-home", "/Users/example/private")])

        текст = "`" + адрес + "`/Users/example/private"
        формы = path_forms.detect_path_forms(текст, include_web_urls=True)
        основа = "https://example.test/a"
        сам.assertEqual((формы[0].value, формы[0].end), (основа, 1 + len(основа)))
        сам.assertIn("/id", [форма.value for форма in формы[1:]])

    def test_отдельный_шаблон_остаётся_кандидатом_пути(сам):
        сам.assertEqual([форма.value for форма in path_forms.detect_path_forms("{/other_user}")],
                         ["/other_user"])

    def test_сканер_обычного_документа_не_даёт_исключения_настоящему_пути(сам):
        запись = {"following_url": "https://api.github.com/users/example/following{/other_user}",
                  "gists_url": "https://api.github.com/users/example/gists{/gist_id}",
                  "starred_url": "https://api.github.com/users/example/starred{/owner}{/repo}",
                  "events_url": "https://api.github.com/users/example/events{/privacy}"}
        сам.assertEqual(сканер.scan_text("Документация/пример.json", json.dumps(запись)), [])
        запись["body"] = "/custom/private/checkout"
        находки = сканер.scan_text("Документация/пример.json", json.dumps(запись))
        сам.assertEqual([находка.category for находка in находки], ["error.posix-absolute"])

    def test_обычный_адрес_не_разбирает_хвост_или_узел(сам):
        with mock.patch.object(path_forms.re, "fullmatch", side_effect=AssertionError("лишний разбор")), \
                mock.patch.object(path_forms, "urlsplit", side_effect=AssertionError("лишний authority")):
            сам.assertEqual(path_forms.detect_path_forms("https://example.test/a/b"), ())


if __name__ == "__main__":
    unittest.main()
