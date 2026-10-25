import importlib.util
import pathlib
import sys
import json
import hashlib
import tempfile
import subprocess
import unittest

ПУТЬ = pathlib.Path(__file__).with_name("архив_форков.py")
спека = importlib.util.spec_from_file_location("архив_форков", ПУТЬ)
модуль = importlib.util.module_from_spec(спека)
sys.modules[спека.name] = модуль
спека.loader.exec_module(модуль)


class ПроверкиГраницы(unittest.TestCase):
    def setUp(сам):
        сам.имя = "fum-lab/fum-yadro"
        сам.метаданные = {
            "full_name": сам.имя, "id": 123, "node_id": "R_test",
            "fork": True, "parent": {"full_name": "fum-lab/fum"},
            "source": {"full_name": "fum-lab/fum"},
            "permissions": {"admin": True}, "has_discussions": False,
            "has_pages": False, "forks_count": 0,
        }

    def test_точный_ролевой_форк(сам):
        сам.assertEqual(модуль.проверить_репозиторий(сам.имя, сам.метаданные), 123)

    def test_основной_и_зависимости_не_удаляются(сам):
        for имя in ["fum-lab/fum", "fum-lab/LinguisticKit", "fum-lab/libtorrent", "other/fum-yadro"]:
            with сам.subTest(имя=имя), сам.assertRaises(ValueError):
                модуль.проверить_репозиторий(имя, {**сам.метаданные, "full_name": имя})

    def test_чужой_родитель_и_отсутствие_прав(сам):
        for правка in [{"parent": {"full_name": "other/fum"}}, {"permissions": {"admin": False}}, {"fork": False}]:
            with сам.subTest(правка=правка), сам.assertRaises(ValueError):
                модуль.проверить_репозиторий(сам.имя, {**сам.метаданные, **правка})

    def test_изменившаяся_идентичность(сам):
        with сам.assertRaises(ValueError):
            модуль.проверить_перед_удалением(
                сам.имя, сам.метаданные, {**сам.метаданные, "id": 124},
                {"refs/heads/master": "a" * 40}, {"refs/heads/master": "a" * 40}, True)

    def test_изменившаяся_ветка(сам):
        with сам.assertRaises(ValueError):
            модуль.проверить_перед_удалением(
                сам.имя, сам.метаданные, сам.метаданные,
                {"refs/heads/master": "a" * 40}, {"refs/heads/master": "b" * 40}, True)

    def test_неполный_архив(сам):
        with сам.assertRaises(ValueError):
            модуль.проверить_перед_удалением(
                сам.имя, сам.метаданные, сам.метаданные, {}, {}, False)

    def test_неподдержанные_обсуждения_блокируют(сам):
        with сам.assertRaises(ValueError):
            модуль.проверить_репозиторий(сам.имя, {**сам.метаданные, "has_discussions": True})

    def test_пустые_и_неоднозначные_ссылки_блокируют(сам):
        for данные in ["", "abc\trefs/heads/master\n", "a"*40+"\trefs/heads/master\n"+"b"*40+"\trefs/heads/master\n"]:
            with сам.subTest(данные=данные), сам.assertRaises(ValueError):
                модуль.разобрать_ссылки(данные)

    def test_ссылки_не_путают_порядок(сам):
        данные = "b"*40+"\trefs/tags/v1\n"+"a"*40+"\trefs/heads/master\n"
        сам.assertEqual(len(модуль.разобрать_ссылки(данные)), 2)

    def test_положительный_допуск(сам):
        ссылки = {"refs/heads/master": "a"*40}
        модуль.проверить_перед_удалением(сам.имя, сам.метаданные, сам.метаданные, ссылки, ссылки, True)

    def test_новая_редакция_метаданных(сам):
        ссылки = {"refs/heads/master": "a"*40}
        with сам.assertRaises(ValueError):
            модуль.проверить_перед_удалением(сам.имя, сам.метаданные,
                {**сам.метаданные, "description": "новая работа"}, ссылки, ссылки, True)

    def test_запрет_повторного_удаления_после_неизвестного_исхода(сам):
        сам.проверить_жизненный_цикл(отказ=True)

    def test_удаление_и_подтверждение_по_точному_имени(сам):
        сам.проверить_жизненный_цикл(отказ=False)

    def проверить_жизненный_цикл(сам, отказ):
        with tempfile.TemporaryDirectory() as временный:
            каталог = pathlib.Path(временный) / "fum-yadro"
            каталог.mkdir()
            модуль.сохранить_данные(каталог / "репозиторий.json", сам.метаданные)
            for имя in ("issues", "pulls", "comments", "review-comments", "releases", "deployments", "labels", "milestones"):
                модуль.сохранить_данные(каталог / (имя + ".json"), [])
            модуль.сохранить_данные(каталог / "готовность.json", {
                "схема": "fum.архив-ролевого-форка.1", "имя": сам.имя,
                "ссылки": {"refs/heads/master": "a"*40},
                "снимки": {п.name: hashlib.sha256(п.read_bytes()).hexdigest() for п in каталог.glob("*.json")}})
            архив = object.__new__(модуль.Архив)
            архив.каталог = pathlib.Path(временный)
            вызовы = []
            архив.запрос = lambda к, имя, суффикс="", много=False: ({"total_count": 0} if суффикс.startswith("/actions/") else [] if суффикс else сам.метаданные if имя == сам.имя else {"full_name": имя})
            архив.получить_ссылки = lambda к, адрес: {"refs/heads/master": "a"*40}
            def выполнить(к, аргументы, допустимый_отказ=False):
                вызовы.append(аргументы)
                if аргументы[:3] == ["gh", "repo", "delete"]:
                    сам.assertTrue((каталог / "намерение-удаления.json").exists())
                    сам.assertEqual(аргументы, ["gh", "repo", "delete", сам.имя, "--yes"])
                    сам.assertTrue(any("lfs" in вызов for вызов in вызовы))
                    сам.assertTrue(any("ls-remote" in вызов for вызов in вызовы))
                    return subprocess.CompletedProcess(аргументы, 1 if отказ else 0,
                        b"", b"")
                if "show-ref" in аргументы:
                    return subprocess.CompletedProcess(аргументы, 0, ("a"*40+" refs/heads/master\n").encode(), b"")
                if "ls-remote" in аргументы:
                    return subprocess.CompletedProcess(аргументы, 128, b"", b"Repository not found")
                if аргументы[:2] == ["gh", "api"]:
                    return subprocess.CompletedProcess(аргументы, 1, b"", b"HTTP 404")
                return subprocess.CompletedProcess(аргументы, 0, b"", b"")
            архив.выполнить = выполнить
            if отказ:
                with сам.assertRaises(RuntimeError): архив.удалить(сам.имя)
            else:
                сам.assertTrue(архив.удалить(сам.имя)["удалён"])
            до = len(вызовы)
            with сам.assertRaises(ValueError): архив.удалить(сам.имя)
            сам.assertEqual(до, len(вызовы))


if __name__ == "__main__":
    unittest.main()
