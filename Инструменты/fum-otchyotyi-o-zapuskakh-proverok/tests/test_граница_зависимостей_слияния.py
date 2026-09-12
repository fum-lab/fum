"""Закрытая реальная граница TDLib; без материализации внешнего репозитория."""
from __future__ import annotations

import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


КОРЕНЬ = Path(os.environ.get("FUM_CHECKED_CODE_ROOT", str(Path(__file__).resolve().parents[3])))
КАТАЛОГ = КОРЕНЬ / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok"
ЯЗЫКОВАЯ_РЕВИЗИЯ = "837e2ce107b97ee7b9d3344c9fe99142281fe393"
ТЕЛЕГРАМ_РЕВИЗИЯ = "d1085f9cebc5a62379991ae1652673954f229c1f"
ДО = "94a22560bbb47eddc00bcf289dc89d006806371d"
ПОСЛЕ = "c00b0f07c26f920db1c23fdc9096ee02e7f2fcc7"
ПОЛИТИКА = {
    "схема": "fum.добавление-TDLib.1",
    "gitmodules_до": ДО,
    "gitmodules_после": ПОСЛЕ,
    "LinguisticKit": ЯЗЫКОВАЯ_РЕВИЗИЯ,
    "TDLib": ТЕЛЕГРАМ_РЕВИЗИЯ,
    "origin": "https://github.com/fum-lab/TDLib.git",
    "upstream": "https://github.com/tdlib/td.git",
}


class ГраницаЗависимостей(unittest.TestCase):
    def setUp(сам):
        путь = КАТАЛОГ / "scripts/граница_зависимостей_слияния.py"
        спецификация = importlib.util.spec_from_file_location("dependency_boundary_under_test", путь)
        сам.модуль = importlib.util.module_from_spec(спецификация)
        спецификация.loader.exec_module(сам.модуль)
        сам.до = {
            ".gitmodules": ("100644", ДО),
            "Зависимости/LinguisticKit": ("160000", ЯЗЫКОВАЯ_РЕВИЗИЯ),
            "обычный.txt": ("100644", "1" * 40),
        }
        сам.после = dict(сам.до) | {
            ".gitmodules": ("100644", ПОСЛЕ),
            "Зависимости/TDLib": ("160000", ТЕЛЕГРАМ_РЕВИЗИЯ),
        }

    def проверить(сам, до=None, ведущая=None, после=None, политика=None):
        return сам.модуль.проверить_переход(
            сам.до if до is None else до,
            сам.после if ведущая is None else ведущая,
            сам.после if после is None else после,
            ПОЛИТИКА if политика is None else политика,
        )

    def test_точная_публикационная_политика_сохранена(сам):
        сырые_байты = (КАТАЛОГ / "профиль-зависимостей-слияния.json").read_bytes()
        сам.assertEqual(json.loads(сырые_байты), ПОЛИТИКА)
        сам.assertEqual(сам.модуль.разобрать_политику(сырые_байты), ПОЛИТИКА)

    def test_разрешено_только_закреплённое_добавление(сам):
        сам.assertEqual(сам.проверить(), ПОЛИТИКА)

    def test_неизменный_обычный_путь_не_требует_добавления(сам):
        сам.assertIsNone(сам.модуль.проверить_переход(сам.до, сам.до, сам.до, None))
        сам.assertIsNone(сам.модуль.проверить_переход({}, {}, {}, None))

    def test_обычный_переход_сохраняет_прежний_допуск_при_иной_ведущей_основе(сам):
        сам.assertIsNone(сам.модуль.проверить_переход(сам.до, {}, сам.до, None))
        новые_файлы = сам.до | {"обычный.txt": ("100644", "b" * 40)}
        сам.assertIsNone(сам.модуль.проверить_переход(сам.до, {}, новые_файлы, None))

    def test_обычные_файлы_не_становятся_разрешениями_зависимостей(сам):
        новый = сам.после | {"обычный.txt": ("100644", "2" * 40)}
        сам.assertEqual(сам.проверить(после=новый), ПОЛИТИКА)

    def test_иная_зависимость_режим_и_имя_отклоняются(сам):
        for путь, значение in (
            ("Зависимости/TDLib", ("160000", "f" * 40)),
            ("Зависимости/TDLib", ("100644", ТЕЛЕГРАМ_РЕВИЗИЯ)),
            ("Зависимости/LinguisticKit", ("160000", "e" * 40)),
            ("Зависимости/другая", ("160000", ТЕЛЕГРАМ_РЕВИЗИЯ)),
            ("зависимости/TDLib", ("160000", ТЕЛЕГРАМ_РЕВИЗИЯ)),
        ):
            with сам.subTest(путь=путь, значение=значение):
                изменено = сам.после | {путь: значение}
                with сам.assertRaises(ValueError):
                    сам.проверить(после=изменено)

    def test_удаление_и_предварительно_помещённая_зависимость_отклоняются(сам):
        for имя in ("Зависимости/TDLib", "Зависимости/LinguisticKit", ".gitmodules"):
            изменено = dict(сам.после)
            изменено.pop(имя)
            with сам.subTest(имя=имя), сам.assertRaises(ValueError):
                сам.проверить(после=изменено)
        with сам.assertRaises(ValueError):
            сам.проверить(до=сам.до | {"Зависимости/TDLib": ("160000", ТЕЛЕГРАМ_РЕВИЗИЯ)})

    def test_исходная_ведущая_и_закрытая_границы_сверяются_раздельно(сам):
        for аргумент in ("до", "ведущая", "после"):
            изменено = dict(сам.до if аргумент == "до" else сам.после)
            изменено["Зависимости/LinguisticKit"] = ("160000", "e" * 40)
            with сам.subTest(аргумент=аргумент), сам.assertRaises(ValueError):
                сам.проверить(**{аргумент: изменено})

    def test_описание_модулей_не_подменяется_даже_при_тех_же_зависимостях(сам):
        for аргумент in ("до", "ведущая", "после"):
            for значение in (("100644", "e" * 40), ("100755", ДО), ("120000", ПОСЛЕ)):
                изменено = dict(сам.до if аргумент == "до" else сам.после)
                изменено[".gitmodules"] = значение
                with сам.subTest(аргумент=аргумент, значение=значение), сам.assertRaises(ValueError):
                    сам.проверить(**{аргумент: изменено})
        with сам.assertRaises(ValueError):
            сам.модуль.проверить_переход(сам.до, сам.до, сам.до | {".gitmodules": ("100644", ПОСЛЕ)}, None)

    def test_отсутствие_политики_принимающего_источника_не_разрешает_добавление(сам):
        with сам.assertRaises(ValueError):
            сам.модуль.проверить_переход(сам.до, сам.после, сам.после, None)

    def test_политика_имеет_закрытую_схему_и_точные_источники(сам):
        for ключ, значение in (
            ("дополнительно", True), ("схема", "fum.добавление-TDLib.2"),
            ("TDLib", "short"), ("LinguisticKit", True),
            ("origin", "https://example.invalid/TDLib.git"),
            ("upstream", "https://github.com/other/td.git"),
        ):
            политика = copy.deepcopy(ПОЛИТИКА)
            политика[ключ] = значение
            with сам.subTest(ключ=ключ), сам.assertRaises(ValueError):
                сам.модуль.разобрать_политику(json.dumps(политика).encode())
        for ключ in ПОЛИТИКА:
            политика = dict(ПОЛИТИКА)
            политика.pop(ключ)
            with сам.subTest(нет=ключ), сам.assertRaises(ValueError):
                сам.модуль.разобрать_политику(json.dumps(политика).encode())

    def test_повторные_поля_не_схлопываются(сам):
        сырые_байты = json.dumps(ПОЛИТИКА).encode()
        for хвост in (b', "TDLib": "' + ТЕЛЕГРАМ_РЕВИЗИЯ.encode() + b'"}', b', "origin": null}'):
            with сам.subTest(хвост=хвост), сам.assertRaises(ValueError):
                сам.модуль.разобрать_политику(сырые_байты[:-1] + хвост)

    def test_политика_читается_из_принимающего_источника(сам):
        with tempfile.TemporaryDirectory(prefix="fum-dependency-boundary-") as каталог:
            корень = Path(каталог)
            среда = {ключ: значение for ключ, значение in os.environ.items() if not ключ.startswith("GIT_")}
            среда.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1", GIT_NO_LAZY_FETCH="1")

            def гит(место, *аргументы):
                результат = subprocess.run(["git", "-c", "core.hooksPath=" + os.devnull, *аргументы],
                                           cwd=место, env=среда, capture_output=True, check=True)
                return результат.stdout

            def записать(имя, байты):
                путь = корень / имя
                путь.parent.mkdir(parents=True, exist_ok=True)
                путь.write_bytes(байты)

            гит(корень, "init", "-qb", "master")
            гит(корень, "config", "user.name", "FUM Test")
            гит(корень, "config", "user.email", "test@example.invalid")
            старые = ('[submodule "Зависимости/LinguisticKit"]\n'
                      '\tpath = Зависимости/LinguisticKit\n'
                      '\turl = https://github.com/fum-lab/LinguisticKit.git\n'
                      '\tfumUpstream = https://github.com/Roman-Kerimov/LinguisticKit.git\n').encode()
            новые = старые + ('[submodule "Зависимости/TDLib"]\n'
                              '\tpath = Зависимости/TDLib\n'
                              '\turl = https://github.com/fum-lab/TDLib.git\n'
                              '\tfumUpstream = https://github.com/tdlib/td.git\n').encode()
            записать(".gitmodules", старые)
            записать(сам.модуль.ПРОФИЛЬ, json.dumps(ПОЛИТИКА, ensure_ascii=False).encode())
            гит(корень, "add", ".")
            гит(корень, "update-index", "--add", "--cacheinfo", "160000", ЯЗЫКОВАЯ_РЕВИЗИЯ, "Зависимости/LinguisticKit")
            гит(корень, "commit", "-qm", "Принятая политика")
            гит(корень, "checkout", "-qb", "leading")
            записать(".gitmodules", новые)
            гит(корень, "add", ".gitmodules")
            гит(корень, "update-index", "--add", "--cacheinfo", "160000", ТЕЛЕГРАМ_РЕВИЗИЯ, "Зависимости/TDLib")
            гит(корень, "commit", "-qm", "Закреплённая поставка")
            ведущий = гит(корень, "rev-parse", "HEAD").decode().strip()
            гит(корень, "checkout", "master")
            записать("развитие-M.txt", b"accepted\n")
            гит(корень, "add", "развитие-M.txt")
            гит(корень, "commit", "-qm", "Развитие принимающего M")
            принимающий = гит(корень, "rev-parse", "HEAD").decode().strip()
            гит(корень, "checkout", "leading")
            гит(корень, "merge", "--no-ff", принимающий, "-m", "Настоящее слияние")
            слияние = гит(корень, "rev-parse", "HEAD").decode().strip()
            сам.assertEqual(сам.модуль.проверить_объекты(гит, корень, принимающий, ведущий, слияние), ПОЛИТИКА)
            сам.assertEqual(сам.модуль.проверить_объекты(гит, корень, принимающий, ведущий), ПОЛИТИКА)
            записать(сам.модуль.ПРОФИЛЬ, b'{"allow": "everything"}\n')
            сам.assertEqual(сам.модуль.проверить_объекты(гит, корень, принимающий, ведущий, слияние), ПОЛИТИКА)
            гит(корень, "add", сам.модуль.ПРОФИЛЬ)
            гит(корень, "commit", "--amend", "--no-edit")
            слияние_с_подменой_политики = гит(корень, "rev-parse", "HEAD").decode().strip()
            сам.assertEqual(сам.модуль.проверить_объекты(гит, корень, принимающий, ведущий, слияние_с_подменой_политики), ПОЛИТИКА)
            записать(".gitmodules", новые + b"\tbranch = arbitrary\n")
            гит(корень, "add", ".gitmodules")
            with сам.assertRaises(ValueError):
                сам.модуль.проверить_объекты(гит, корень, принимающий, ведущий)
            гит(корень, "commit", "--amend", "--no-edit")
            слияние_с_подменой_модулей = гит(корень, "rev-parse", "HEAD").decode().strip()
            with сам.assertRaises(ValueError):
                сам.модуль.проверить_объекты(гит, корень, принимающий, ведущий, слияние_с_подменой_модулей)


if __name__ == "__main__":
    unittest.main()
