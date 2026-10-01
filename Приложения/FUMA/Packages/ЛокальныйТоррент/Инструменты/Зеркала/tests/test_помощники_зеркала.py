import importlib.machinery
import importlib.util
import json
from contextlib import contextmanager
from argparse import Namespace
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest import mock


зеркала = Path(__file__).resolve().parents[1]
путь_проектора = зеркала / "Кандидат/Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py"
спецификация = importlib.util.spec_from_file_location("проектор_помощники_зеркала", путь_проектора)
модуль = importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name] = модуль
спецификация.loader.exec_module(модуль)
манифест = json.loads((зеркала / "манифест-исходного-зеркала.json").read_text())
путь_зеркал = "Приложения/FUMA/Packages/ЛокальныйТоррент/Инструменты/Зеркала"


class ТестыЗакреплённыхПомощников(unittest.TestCase):
    def подготовить(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name).resolve()
        сам.зеркала = сам.корень / путь_зеркал
        сам.зеркала.mkdir(parents=True)
        shutil.copyfile(зеркала / "манифест-исходного-зеркала.json",
            сам.зеркала / "манифест-исходного-зеркала.json")
        for запись in манифест["файлы"]:
            цель = сам.корень / запись["путь_зеркала"]
            цель.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(зеркала.parents[5] / запись["путь_зеркала"], цель)
            цель.chmod(0o755 if запись["режим"] == "100755" else 0o644)
        сам.проектор = сам.зеркала / "Кандидат/Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py"
        сам.подмена_файла = mock.patch.object(модуль, "__file__", str(сам.проектор))
        сам.подмена_файла.start()
        сам.addCleanup(сам.подмена_файла.stop)
        сам.модули_до = dict(sys.modules)
        сам.пути_до = list(sys.path)
        сам.addCleanup(сам.восстановить_модули)

    def восстановить_модули(сам):
        состояние = getattr(модуль, "состояние_зеркальных_помощников", None)
        if состояние is not None:
            состояние["закрытая_копия"].cleanup()
        for имя in set(sys.modules) - set(сам.модули_до):
            if имя.startswith("fum_") or имя in (
                    "project_files", "request_folder_layout", "автор_коммита", "разбор_сценария",
                    "аббревиатуры_контекста", "безопасные_привязки_python"):
                del sys.modules[имя]
        for имя, прежний in сам.модули_до.items():
            if имя in sys.modules and sys.modules[имя] is not прежний:
                sys.modules[имя] = прежний
        sys.path[:] = сам.пути_до
        setattr(модуль, "состояние_зеркальных_помощников", None)
        for имя in ("_МОДУЛЬ_СТРУКТУРНОЙ_РАЗМЕТКИ", "_МОДУЛЬ_СВЯЗНОСТИ", "_МОДУЛЬ_ОБЪЯВЛЕНИЙ"):
            setattr(модуль, имя, None)

    def test_ПроверяетВсеТридцатьТриИсходникаИТочныйСостав(сам):
        сам.подготовить()
        снимок = модуль.проверить_исходное_зеркало(сам.корень)
        сам.assertEqual(set(снимок), {запись["исходный_путь"] for запись in манифест["файлы"]})
        файл = сам.корень / манифест["файлы"][-1]["путь_зеркала"]
        данные = файл.read_bytes()
        файл.write_bytes(данные + b" ")
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            модуль.проверить_исходное_зеркало(сам.корень)
        файл.write_bytes(данные)
        лишний = файл.parent / "чужой.py"
        лишний.write_text("")
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            модуль.проверить_исходное_зеркало(сам.корень)

    def test_ЗагружаетПроверенныеБайтыБезПовторногоЧтенияЗагрузчиком(сам):
        сам.подготовить()
        with mock.patch.object(importlib.machinery.SourceFileLoader, "exec_module",
                side_effect=AssertionError("Повторное чтение исходника загрузчиком запрещено")):
            помощники = модуль.подготовить_зеркальные_помощники()
        сам.assertEqual(len(помощники["модули"]), 9)
        структурный = модуль.модуль_структурной_разметки()
        сам.assertEqual(Path(структурный.__file__).read_bytes(),
            (зеркала.parents[5] / next(запись["путь_зеркала"] for запись in манифест["файлы"]
                if запись["исходный_путь"].endswith("pereimenovatj-fajl-s-obnovleniyem-ssyilok.py"))).read_bytes())
        сам.assertIs(структурный, sys.modules["fum_структурная_разметка_братиславской_проекции"])
        сам.assertIs(getattr(sys.modules["request_folder_layout"], "_LINK_TOOLS"), структурный)
        сам.assertEqual(sys.path, сам.пути_до)
        модуль.проверить_границу_зеркальных_помощников()

    def test_ОтклоняетЧужойИмпортИПодменуКешированногоМодуля(сам):
        сам.подготовить()
        with mock.patch.dict(sys.modules, {"project_files": object()}):
            with сам.assertRaises(модуль.ОшибкаКонтракта):
                модуль.подготовить_зеркальные_помощники()
        помощники = модуль.подготовить_зеркальные_помощники()
        with mock.patch.dict(sys.modules, {"project_files": object()}):
            with сам.assertRaises(модуль.ОшибкаКонтракта):
                модуль.модуль_структурной_разметки()
        сам.assertIs(помощники["модули"]["project_files"], sys.modules["project_files"])

    def test_ВыявляетИзменениеИсходникаПослеЗагрузки(сам):
        сам.подготовить()
        модуль.подготовить_зеркальные_помощники()
        файл = сам.корень / манифест["файлы"][-1]["путь_зеркала"]
        файл.write_bytes(файл.read_bytes() + b" ")
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            модуль.проверить_границу_зеркальных_помощников()

    def test_НеЧитаетИсходноеЗеркалоПовторноЧерезСамоотпечаток(сам):
        сам.подготовить()
        чтение = Path.read_bytes
        перечитаны = []
        def прочитать(путь):
            if путь.is_relative_to(сам.зеркала):
                перечитаны.append(путь)
                raise AssertionError("Небезопасное повторное чтение исходного зеркала")
            return чтение(путь)
        with mock.patch.object(Path, "read_bytes", прочитать):
            помощники = модуль.подготовить_зеркальные_помощники()
        сам.assertFalse(перечитаны)
        сам.assertFalse(Path(помощники["модули"]["project_files"].__file__).is_relative_to(сам.зеркала))

    def test_НеВыдаётПланПослеПозднегоОтказаГраницы(сам):
        сам.подготовить()
        @contextmanager
        def отказать(*аргументы, **именованные):
            yield ["преобразователь"], lambda: None
            raise модуль.ОшибкаКонтракта("поздний отказ границы")
        параметры = Namespace(корень_репозитория=str(сам.корень), контракт="контракт.json", команда="план")
        with mock.patch.object(модуль, "загрузить_политику", return_value={}), \
                mock.patch.object(модуль, "подготовить_изолированный_преобразователь", отказать), \
                mock.patch.object(модуль, "преобразователь_процесса"), \
                mock.patch.object(модуль, "построить_план", return_value={"состояние": "предлагаемый план"}), \
                mock.patch.object(модуль, "записать_машинные_данные") as вывод:
            сам.assertEqual(модуль.выполнить_команду(параметры), 2)
            вывод.assert_not_called()

    def test_ЗакрываетМодулиИНеСкрываетИсходнуюОшибкуОчисткой(сам):
        сам.подготовить()
        помощники = модуль.подготовить_зеркальные_помощники()
        копия = помощники["закрытая_копия"]
        сам.addCleanup(копия.cleanup)
        исходная = RuntimeError("исходная ошибка")
        with mock.patch.object(модуль, "построить_анализатор") as разбор, \
                mock.patch.object(модуль, "выполнить_команду", side_effect=исходная), \
                mock.patch.object(копия, "cleanup", side_effect=OSError("ошибка очистки")) as очистка:
            setattr(разбор.return_value.parse_args, "return_value", Namespace(профилировать=False))
            with сам.assertRaises(RuntimeError) as отказ:
                модуль.главная([])
            сам.assertIs(отказ.exception, исходная)
            очистка.assert_called_once()
        сам.assertIsNone(модуль.состояние_зеркальных_помощников)
        for имя in помощники["модули"]:
            сам.assertNotIn(имя, sys.modules)


if __name__ == "__main__":
    unittest.main()
