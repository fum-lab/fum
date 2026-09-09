import hashlib
import json
import os
from pathlib import Path
import tempfile
import subprocess
import sys
import unittest
from unittest import mock

from test_братиславская_проекция_памяти import модуль


class ПроверкаКэшаПреобразователя(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name)
        сам.кэш = сам.корень / "кэш"
        сам.кэш.mkdir(mode=0o700)
        сам.ключ = "a" * 64
        сам.секрет = b"a" * 32
        сам.продукт = сам.корень / "сборка"
        сам.продукт.mkdir()
        for имя in ("preobrazovatj-nazvaniya", "libLinguisticKit.dylib"):
            путь = сам.продукт / имя
            путь.write_bytes((имя + "\n").encode())
            путь.chmod(0o755)
        сам.собрать = mock.Mock(return_value=[str(сам.продукт / "preobrazovatj-nazvaniya")])

    def получить(сам, ключ=None):
        return модуль.получить_проверенную_среду(
            сам.кэш, сам.секрет, ключ or сам.ключ, сам.собрать,
        )

    def test_между_двумя_подготовками_строится_один_раз(сам):
        первый = сам.получить()
        второй = сам.получить()
        сам.assertEqual(первый, второй)
        сам.assertEqual(set(первый), {"preobrazovatj-nazvaniya", "libLinguisticKit.dylib"})
        сам.assertEqual(сам.собрать.call_count, 1)

    def test_ключ_инвалидируется_каждым_влияющим_входом(сам):
        сведения = {имя: "исходное" for имя in (
            "дерево_обёртки", "дерево_зависимости", "ревизия_зависимости",
            "конфигурация", "аргументы", "компилятор", "версия_swift",
            "сведения_цели", "sdk", "архитектура", "система", "окружение",
        )}
        исходный = модуль.ключ_повторной_сборки(сведения)
        сам.assertEqual(исходный, модуль.ключ_повторной_сборки(dict(reversed(list(сведения.items())))))
        for поле in сведения:
            with сам.subTest(поле=поле):
                изменённые = {**сведения, поле: "другое"}
                сам.assertNotEqual(исходный, модуль.ключ_повторной_сборки(изменённые))
        сам.получить(исходный)
        сам.получить(модуль.ключ_повторной_сборки({**сведения, "компилятор": "другой"}))
        сам.assertEqual(сам.собрать.call_count, 2)

    def test_подмена_файла_манифеста_режима_или_набора_закрывает_повтор(сам):
        for случай in ("продукт", "библиотека", "манифест", "режим", "лишний", "ссылка", "нет_манифеста"):
            with сам.subTest(случай=случай):
                ключ = hashlib.sha256(случай.encode()).hexdigest()
                сам.получить(ключ)
                каталог = сам.кэш / ключ
                продукт = каталог / "preobrazovatj-nazvaniya"
                манифест = каталог / "манифест.json"
                if случай == "продукт":
                    продукт.write_bytes(b"foreign")
                elif случай == "библиотека":
                    (каталог / "libLinguisticKit.dylib").write_bytes(b"foreign")
                elif случай == "манифест":
                    манифест.write_text("{}", encoding="utf-8")
                elif случай == "режим":
                    продукт.chmod(0o644)
                elif случай == "лишний":
                    (каталог / "дополнение").write_bytes(b"extra")
                elif случай == "ссылка":
                    продукт.unlink()
                    продукт.symlink_to(сам.продукт / "preobrazovatj-nazvaniya")
                else:
                    манифест.unlink()
                до = сам.собрать.call_count
                with сам.assertRaises(модуль.ОшибкаКонтракта):
                    сам.получить(ключ)
                сам.assertEqual(сам.собрать.call_count, до)

    def test_согласованная_подмена_байтов_и_хэша_без_доверенного_ключа_отклоняется(сам):
        сам.получить()
        каталог = сам.кэш / сам.ключ
        продукт = каталог / "preobrazovatj-nazvaniya"
        продукт.write_bytes(b"foreign")
        манифест = каталог / "манифест.json"
        данные = json.loads(манифест.read_bytes())
        данные["содержимое"]["файлы"][продукт.name] = модуль.хэш_байтов(b"foreign")
        манифест.write_bytes(модуль.канонические_байты(данные))
        with сам.assertRaisesRegex(модуль.ОшибкаКонтракта, "подпись"):
            сам.получить()

    def test_незавершённая_запись_не_становится_исполняемой(сам):
        (сам.кэш / ".partial.чужой").mkdir()
        сам.собрать.side_effect = RuntimeError("оборванная сборка")
        with сам.assertRaisesRegex(RuntimeError, "оборванная"):
            сам.получить()
        сам.assertFalse((сам.кэш / сам.ключ).exists())
        сам.собрать.side_effect = None
        сам.assertIn("preobrazovatj-nazvaniya", сам.получить())

    def test_неполная_среда_исполнения_не_публикуется(сам):
        (сам.продукт / "libLinguisticKit.dylib").unlink()
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            сам.получить()
        сам.assertFalse((сам.кэш / сам.ключ).exists())

    def test_возвращённый_снимок_не_меняется_при_поздней_подмене_кэша(сам):
        снимок = сам.получить()
        (сам.кэш / сам.ключ / "preobrazovatj-nazvaniya").write_bytes(b"foreign")
        сам.assertEqual(снимок["preobrazovatj-nazvaniya"], b"preobrazovatj-nazvaniya\n")

    def test_нельзя_выбрать_внешний_путь_ключом(сам):
        for ключ in ("../путь", "A" * 64, "a" * 63, "/внешний"):
            with сам.subTest(ключ=ключ), сам.assertRaises(модуль.ОшибкаКонтракта):
                сам.получить(ключ)
        сам.собрать.assert_not_called()

    def test_ключ_доверия_сохраняется_и_не_восстанавливается_поверх_кэша(сам):
        гит = сам.корень / "гит"
        гит.mkdir()
        with mock.patch.object(модуль, "путь_квитанции_установки", return_value=гит / "квитанция"):
            первый_кэш, первый_ключ = модуль.подготовить_локальный_кэш(сам.корень)
            второй_кэш, второй_ключ = модуль.подготовить_локальный_кэш(сам.корень)
            сам.assertEqual((первый_кэш, первый_ключ), (второй_кэш, второй_ключ))
            сам.assertEqual(len(первый_ключ), 32)
            (гит / ".fum-swift-trust-v1" / "ключ").unlink()
            with сам.assertRaises(модуль.ОшибкаКонтракта):
                модуль.подготовить_локальный_кэш(сам.корень)


    def test_подготовители_не_отклоняют_доверие_опубликованное_между_чтениями(сам):
        гит = сам.корень / "гит"
        гит.mkdir()
        доверие = гит / ".fum-swift-trust-v1"
        исходная_проверка = модуль.os.path.lexists
        второй_результат = None
        внедрено = False

        def проверить_с_публикацией(путь):
            nonlocal второй_результат, внедрено
            результат = исходная_проверка(путь)
            if Path(путь) == доверие and not результат and not внедрено:
                внедрено = True
                # Первый уже прочитал отсутствие. Второй полностью публикует доверие и кэш.
                второй_результат = модуль.подготовить_локальный_кэш(сам.корень)
            return результат

        with mock.patch.object(модуль, "путь_квитанции_установки", return_value=гит / "квитанция"):
            with mock.patch.object(модуль.os.path, "lexists", side_effect=проверить_с_публикацией):
                первый_результат = модуль.подготовить_локальный_кэш(сам.корень)
        сам.assertTrue(внедрено)
        сам.assertEqual(первый_результат, второй_результат)
        сам.assertEqual((доверие / "ключ").read_bytes(), второй_результат[1])

    def test_подготовители_не_восстанавливают_доверие_при_настоящем_осиротевшем_кэше(сам):
        гит = сам.корень / "гит"
        гит.mkdir()
        кэш = гит / ".fum-swift-runtime-v1"
        кэш.mkdir(mode=0o700)
        остаток = кэш / "сохранить"
        остаток.write_bytes(b"untrusted")
        with mock.patch.object(модуль, "путь_квитанции_установки", return_value=гит / "квитанция"):
            with сам.assertRaisesRegex(модуль.ОшибкаКонтракта, "без доверенного ключа"):
                модуль.подготовить_локальный_кэш(сам.корень)
        сам.assertFalse((гит / ".fum-swift-trust-v1").exists())
        сам.assertEqual(остаток.read_bytes(), b"untrusted")


    def test_исполнение_не_наследует_инъекцию_динамического_загрузчика(сам):
        with mock.patch.dict(модуль.os.environ, {"PATH": "foreign", "DYLD_INSERT_LIBRARIES": "foreign", "LD_PRELOAD": "foreign"}):
            окружение = модуль.окружение_инструментария()
        сам.assertEqual(окружение["PATH"], os.defpath)
        сам.assertTrue(all(Path(путь).is_absolute() for путь in окружение["PATH"].split(os.pathsep)))
        сам.assertNotIn("DYLD_INSERT_LIBRARIES", окружение)
        сам.assertNotIn("LD_PRELOAD", окружение)
        сам.assertNotIn("SWIFT_EXEC", окружение)

    def test_производственный_ключ_учитывает_байты_драйвера(сам):
        инструмент = сам.корень / "swift"
        компилятор = сам.корень / "swiftc"
        пакеты = сам.корень / "swift-package"
        компоновщик = сам.корень / "ld"
        драйвер_компоновки = сам.корень / "clang"
        for путь in (инструмент, компилятор, пакеты, компоновщик, драйвер_компоновки):
            путь.write_bytes(b"version-one")

        def выполнить(команда, **параметры):
            if "--find" in команда:
                ответ = str(сам.корень / команда[-1])
            elif "--show-sdk-path" in команда:
                ответ = str(сам.корень)
            else:
                ответ = "stable-version"
            return subprocess.CompletedProcess(команда, 0, ответ, "")

        with mock.patch.object(модуль.subprocess, "run", side_effect=выполнить), mock.patch.object(
            модуль, "выполнить_команду_контроля_версий", return_value="tree"
        ):
            до, команда = модуль.сведения_для_повторной_сборки(сам.корень, "HEAD", {})
            инструмент.write_bytes(b"version-two")
            после, _ = модуль.сведения_для_повторной_сборки(сам.корень, "HEAD", {})
            компоновщик.write_bytes(b"linker-two")
            после_компоновщика, _ = модуль.сведения_для_повторной_сборки(сам.корень, "HEAD", {})
        сам.assertEqual(команда, str(инструмент))
        сам.assertNotEqual(модуль.ключ_повторной_сборки(до), модуль.ключ_повторной_сборки(после))
        сам.assertNotEqual(модуль.ключ_повторной_сборки(после), модуль.ключ_повторной_сборки(после_компоновщика))

    def test_строгая_маска_не_ослабляет_точные_режимы(сам):
        гит = сам.корень / "гит"
        гит.mkdir()
        прежняя = os.umask(0o777)
        try:
            with mock.patch.object(модуль, "путь_квитанции_установки", return_value=гит / "квитанция"):
                кэш, секрет = модуль.подготовить_локальный_кэш(сам.корень)
                модуль.получить_проверенную_среду(кэш, секрет, сам.ключ, сам.собрать)
        finally:
            os.umask(прежняя)

    def test_отказ_записи_не_оставляет_готового_поколения(сам):
        исходная = модуль.записать_обычный_файл
        for номер_отказа in (1, 2, 3):
            счётчик = 0

            def записать(*аргументы):
                nonlocal счётчик
                счётчик += 1
                if счётчик == номер_отказа:
                    raise OSError("ENOSPC fixture")
                исходная(*аргументы)

            with сам.subTest(номер=номер_отказа), mock.patch.object(модуль, "записать_обычный_файл", side_effect=записать):
                with сам.assertRaises(OSError):
                    сам.получить()
                сам.assertFalse((сам.кэш / сам.ключ).exists())

    def test_конкурентный_победитель_проверяется_после_гонки(сам):
        исходная = модуль.атомарно_переименовать_без_замены
        внутри = False

        def перенести(источник, цель):
            nonlocal внутри
            if not внутри:
                внутри = True
                сам.получить()
            исходная(источник, цель)

        with mock.patch.object(модуль, "атомарно_переименовать_без_замены", side_effect=перенести):
            сам.assertIn("preobrazovatj-nazvaniya", сам.получить())
        сам.assertEqual(сам.собрать.call_count, 2)

    def test_снимок_сборки_учитывает_реальные_байты_после_архивирования(сам):
        исходный = модуль.отпечаток_исходников_сборки(сам.продукт)
        путь = сам.продукт / "preobrazovatj-nazvaniya"
        путь.write_bytes(b"export-subst changes bytes despite same tree")
        сам.assertNotEqual(исходный, модуль.отпечаток_исходников_сборки(сам.продукт))

    def test_канал_вместо_файла_не_блокирует_проверку(сам):
        канал = сам.корень / "канал"
        os.mkfifo(канал)
        код = (
            "import importlib.util,pathlib;"
            f"спецификация=importlib.util.spec_from_file_location('проверка',{модуль.__file__!r});"
            "модуль=importlib.util.module_from_spec(спецификация);спецификация.loader.exec_module(модуль);"
            f"\ntry: модуль.прочитать_точный_обычный_файл(pathlib.Path({str(канал)!r}),'канал')"
            "\nexcept модуль.ОшибкаКонтракта: pass"
            "\nelse: raise AssertionError('канал принят')"
        )
        subprocess.run([sys.executable, "-c", код], check=True, timeout=3)
