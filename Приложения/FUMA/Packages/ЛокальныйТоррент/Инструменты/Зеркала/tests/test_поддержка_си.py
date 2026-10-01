import importlib.util
import json
from pathlib import Path
import sys
import subprocess
import tempfile
import unittest
from unittest import mock


корень_зеркал = Path(__file__).resolve().parents[1]
путь_инвентаризатора = (корень_зеркал / "Кандидат/Инструменты"
    / "fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py")
спецификация = importlib.util.spec_from_file_location("зеркальный_инвентаризатор", путь_инвентаризатора)
модуль = importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name] = модуль
спецификация.loader.exec_module(модуль)
from разбор_си import загрузить_библиотеку


class ТестыПоддержкиСи(unittest.TestCase):
    def test_НеПринимаетМакросЧужогоЗаголовкаДажеКакСистемного(сам):
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный)
            (каталог / "подмена.hpp").write_text("#define S_ISREG(тип) (тип)\n")
            корень = каталог / "проект"
            корень.mkdir()
            (корень / "мост.cpp").write_text('#include <подмена.hpp>\nint проверить(int тип) { return S_ISREG(тип); }\n')
            with сам.assertRaises(модуль.ОшибкаКонтракта):
                модуль.построить_инвентарь(корень, ["-isystem", str(каталог)])
    def test_ПринимаетДоказанноеРаскрытиеМакросаСистемногоКомплекта(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            (корень / "мост.cpp").write_text("#include <sys/stat.h>\nint проверить(int тип) { return S_ISREG(тип); }\n")
            сам.assertEqual(модуль.построить_инвентарь(корень,
                ["-isysroot", "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"])["объявления"], [])

    def test_НеПринимаетСобственнуюПодменуСистемногоМакроса(сам):
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            сам.проверить_текст("#define S_ISREG(тип) (тип)\nint проверить(int тип) { return S_ISREG(тип); }")

    def test_ПринимаетУдалённоеКопированиеРусскогоВладельца(сам):
        сам.assertEqual(сам.проверить_текст("struct Снимок { Снимок() {} ~Снимок() {} "
            "Снимок(Снимок const&) = delete; Снимок& operator=(Снимок const&) = delete; };"), [])

    def test_ОператорНеСкрываетСобственныеЛатинскиеИмена(сам):
        объявления = сам.проверить_текст("struct Снимок { int bad_field; "
            "Снимок& operator=(Снимок const& bad_parameter) { int bad_local=0; return *this; } };" )
        сам.assertEqual({запись["имя"] for запись in объявления},
                        {"bad_field", "bad_parameter", "bad_local"})

    def проверить_текст(сам, текст, расширение=".cpp"):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            (корень / ("мост" + расширение)).write_text(текст, encoding="utf-8")
            return модуль.построить_инвентарь(корень)["объявления"]

    def test_ВидитТипПолеФункциюПараметрИМестнуюПеременную(сам):
        объявления = сам.проверить_текст("struct BadType { int bad_field; };\n"
            "int bad_function(int bad_parameter) { int bad_local = bad_parameter; return bad_local; }\n")
        сам.assertEqual({запись["имя"] for запись in объявления},
            {"BadType", "bad_field", "bad_function", "bad_parameter", "bad_local"})
        сам.assertTrue(all(запись["язык"] == "cpp" for запись in объявления))

    def test_ПринимаетРусскиеИменаВЗаголовке(сам):
        сам.assertEqual(сам.проверить_текст("struct Данные { int счётчик; };\n"
            "int вычислить(int размер);\n", ".hpp"), [])

    def test_НеПринимаетПовреждённыйСинтаксис(сам):
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            сам.проверить_текст("int незавершённое( {\n")

    def test_НеПропускаетНеактивнуюВетку(сам):
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            сам.проверить_текст("#if 0\nint hidden_name;\n#endif\nint имя;\n")

    def test_НеПринимаетСимволическуюСсылкуНаИсходник(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            цель = корень / "данные.txt"
            цель.write_text("int hidden_name;\n", encoding="utf-8")
            (корень / "мост.cpp").symlink_to(цель)
            with сам.assertRaises(модуль.ОшибкаКонтракта):
                модуль.построить_инвентарь(корень)

    def test_ОтделяетВнешниеЗаголовкиОтСобственныхОбъявлений(сам):
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный)
            внешний = каталог / "external.hpp"
            внешний.write_text("struct ExternalType { int external_field; };\n", encoding="utf-8")
            корень = каталог / "проект"
            корень.mkdir()
            (корень / "мост.cpp").write_text(f'#include "{внешний}"\nExternalType собственное;\n', encoding="utf-8")
            сам.assertEqual(модуль.построить_инвентарь(корень)["объявления"], [])

    def test_НеНаследуетВнешниеИменаПосетителяПитона(сам):
        объявления = сам.проверить_текст("int __hidden__;\nint visit_Name();\n")
        сам.assertEqual({запись["имя"] for запись in объявления}, {"__hidden__", "visit_Name"})

    def test_НеПропускаетРасширеннуюЛатиницу(сам):
        объявления = сам.проверить_текст("int é;\n")
        сам.assertEqual({запись["имя"] for запись in объявления}, {"é"})

    def test_ОтклоняетМеткиПереходов(сам):
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            сам.проверить_текст("int вычислить() { goto bad_label; bad_label: return 0; }\n")

    def test_НеПропускаетСкрытуюВеткуПослеСклейкиСтрок(сам):
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            сам.проверить_текст("#i\\\nf 0\nint hidden_name;\n#en\\\ndif\nint имя;\n")

    def test_НеПропускаетСкрытуюВеткуПослеКомментария(сам):
        with сам.assertRaises(модуль.ОшибкаКонтракта):
            сам.проверить_текст("#/**/if 0\nint hidden_name;\n#/**/endif\nint имя;\n")

    def test_ОбнаруживаетПодменуИсходникаСсылкойВоВремяРазбора(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            файл = корень / "мост.cpp"
            файл.write_text("int hidden_name;\n", encoding="utf-8")
            цель = корень / "данные.txt"
            цель.write_bytes(файл.read_bytes())
            библиотека = загрузить_библиотеку()
            исходная = библиотека.clang_parseTranslationUnit2

            def подменить(*аргументы):
                файл.unlink()
                файл.symlink_to(цель)
                return исходная(*аргументы)

            with mock.patch.object(библиотека, "clang_parseTranslationUnit2", side_effect=подменить):
                with сам.assertRaises(модуль.ОшибкаКонтракта):
                    модуль.построить_инвентарь(корень)

    def test_НеПринимаетДругиеБайтыПриВозвратеИсходника(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            файл = корень / "мост.cpp"
            исходные = b"int hidden_name;\n" + "int имя;\n".encode("utf-8")
            другие = b"//x hidden_name;\n" + "int имя;\n".encode("utf-8")
            файл.write_bytes(исходные)
            библиотека = загрузить_библиотеку()
            исходная = библиотека.clang_parseTranslationUnit2

            def подменить(*аргументы):
                файл.write_bytes(другие)
                try:
                    return исходная(*аргументы)
                finally:
                    файл.write_bytes(исходные)

            with mock.patch.object(библиотека, "clang_parseTranslationUnit2", side_effect=подменить):
                try:
                    объявления = модуль.построить_инвентарь(корень)["объявления"]
                except модуль.ОшибкаКонтракта:
                    return
                сам.assertIn("hidden_name", {запись["имя"] for запись in объявления})

    def test_ПередаётПутьЗаголовковЧерезКоманднуюСтроку(сам):
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный)
            (каталог / "external.hpp").write_text("struct ExternalType {};\n", encoding="utf-8")
            корень = каталог / "проект"
            корень.mkdir()
            (корень / "мост.cpp").write_text("#include <external.hpp>\nExternalType bad_name;\n", encoding="utf-8")
            результат = subprocess.run([sys.executable, "-B", str(путь_инвентаризатора),
                "инвентаризировать", "--корень-репозитория", str(корень),
                f"--аргумент-компилятора-си=-I{каталог}"], capture_output=True, text=True)
            сам.assertEqual(результат.returncode, 0, результат.stderr)
            сам.assertEqual({запись["имя"] for запись in json.loads(результат.stdout)["объявления"]}, {"bad_name"})

    def test_ОтклоняетСобственныеВключенияНеизвестногоФормата(сам):
        for расширение in (".inc", ".inl", ".данные"):
            with сам.subTest(расширение=расширение), tempfile.TemporaryDirectory() as временный:
                корень = Path(временный)
                заголовок = корень / ("подробности" + расширение)
                заголовок.write_text("int hidden_name;\n", encoding="utf-8")
                (корень / "мост.cpp").write_text(f'#include "{заголовок.name}"\nint имя;\n', encoding="utf-8")
                with сам.assertRaises(модуль.ОшибкаКонтракта):
                    модуль.построить_инвентарь(корень)

    def test_НеДопускаетНепрозрачныйВводКомпилятора(сам):
        for аргументы in (("-include-pch", "скрытый.pch"), ("-fmodules",),
                          ("@скрытые-аргументы",), ("-Xclang", "-load", "скрытый.so")):
            with сам.subTest(аргументы=аргументы), tempfile.TemporaryDirectory() as временный:
                корень = Path(временный)
                (корень / "мост.cpp").write_text("int имя;\n", encoding="utf-8")
                with сам.assertRaisesRegex(модуль.ОшибкаКонтракта, "недопущенный аргумент компилятора"):
                    модуль.построить_инвентарь(корень, аргументы)

    def test_ПринимаетЯвныйСтандартСиПлюсПлюс(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный)
            (корень / "мост.cpp").write_text("int bad_name;\n", encoding="utf-8")
            объявления = модуль.построить_инвентарь(корень, ("-std=c++17",))["объявления"]
            сам.assertEqual({запись["имя"] for запись in объявления}, {"bad_name"})


if __name__ == "__main__":
    unittest.main()
