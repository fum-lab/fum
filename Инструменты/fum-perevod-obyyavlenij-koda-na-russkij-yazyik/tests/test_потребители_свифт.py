"""Материализовать только явно выбранные привязки Swift и сохранить wire keys."""

import copy
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import time
import tracemalloc
import unicodedata
import unittest
from unittest import mock

from test_аббревиатуры_контекста import учёт


def позиция(токен):
    return {поле: getattr(токен, поле) for поле in
            ("начало", "конец", "строка", "столбец", "экранирован")}


def запись_файла(путь, текст, объявления=(), употребления=()):
    return {"путь": путь, "ожидаемый_хэш": учёт.вычислить_хэш(текст.encode()),
            "объявления": list(объявления), "употребления": list(употребления)}


def объявление(токен, имя="переведённая", идентификатор="главное", вид="функция"):
    return {"идентификатор": идентификатор, "вид": вид, "старое_имя": токен.текст,
            "новое_имя": имя, "позиция": позиция(токен)}


def употребление(токен, идентификатор="главное"):
    return {"объявление": идентификатор, "позиция": позиция(токен)}


def пример():
    первый = '// Ё🙂é\r\nfunc old() { old() }\r\nfunc чужая(old: Int) { print(old) }\r\nlet текст = "old"\r\n// old\r\n'
    второй = 'let ответ = old()\r\nlet чужой = объект.old\r\n'
    токены = [т for т in учёт.токены_свифт(первый) if т.текст == "old"]
    потребители = [т for т in учёт.токены_свифт(второй) if т.текст == "old"]
    карта = {"версия_схемы": 2, "файлы": [
        запись_файла("а.swift", первый, [объявление(токены[0])], [употребление(токены[1])]),
        запись_файла("б.swift", второй, употребления=[употребление(потребители[0])])
    ]}
    return {"а.swift": первый, "б.swift": второй}, карта


class ПроверкиПотребителейСвифт(unittest.TestCase):
    def подготовить(сам, корень, исходники, карта):
        for имя, текст in исходники.items():
            файл = корень / имя
            файл.parent.mkdir(parents=True, exist_ok=True)
            файл.write_bytes(текст.encode())
        путь = корень / "карта.json"
        путь.write_text(json.dumps(карта, ensure_ascii=False), encoding="utf-8")
        return учёт.подготовить_изменения(корень, учёт.прочитать_карту(путь))

    def test_внутренние_и_межфайловые_выборы_сохраняют_чужие_токены(сам):
        исходники, карта = пример()
        with tempfile.TemporaryDirectory() as папка:
            корень = Path(папка)
            (корень / "а.swift").write_bytes(исходники["а.swift"].encode())
            (корень / "а.swift").chmod(0o640)
            изменения = сам.подготовить(корень, исходники, карта)
            сам.assertEqual(2, len(изменения))
            сам.assertEqual(исходники["а.swift"].replace('func old() { old() }',
                'func переведённая() { переведённая() }'), изменения[0].новый_текст)
            сам.assertEqual(исходники["б.swift"].replace('ответ = old()',
                'ответ = переведённая()'), изменения[1].новый_текст)
            сам.assertEqual(2, учёт.описание_плана(изменения, "план")["версия_схемы"])
            for имя, текст in исходники.items():
                сам.assertEqual(текст.encode(), (корень / имя).read_bytes())
            учёт.атомарно_применить(изменения)
            сам.assertEqual(0o640, stat.S_IMODE((корень / "а.swift").stat().st_mode))
            сам.assertIn(b"\r\n", (корень / "а.swift").read_bytes())

    def test_одно_старое_имя_различает_две_привязки(сам):
        исходники, карта = пример()
        токены = [т for т in учёт.токены_свифт(исходники["а.swift"]) if т.текст == "old"]
        карта["файлы"][0]["объявления"].append(объявление(токены[2], "местный", "тень", "параметр"))
        карта["файлы"][0]["употребления"].append(употребление(токены[3], "тень"))
        with tempfile.TemporaryDirectory() as папка:
            изменения = сам.подготовить(Path(папка), исходники, карта)
            сам.assertIn('чужая(местный: Int) { print(местный) }', изменения[0].новый_текст)
            сам.assertIn('func переведённая() { переведённая() }', изменения[0].новый_текст)
            сам.assertEqual(4, len(учёт.описание_плана(изменения, "план")["файлы"][0]["замены"]))

    def test_обратные_кавычки_сохраняются(сам):
        текст = 'func `old`() { `old`() }\n'
        токены = [т for т in учёт.токены_свифт(текст) if т.текст == "old"]
        карта = {"версия_схемы": 2, "файлы": [запись_файла("а.swift", текст,
            [объявление(токены[0])], [употребление(токены[1])])]}
        with tempfile.TemporaryDirectory() as папка:
            сам.assertEqual('func `переведённая`() { `переведённая`() }\n',
                сам.подготовить(Path(папка), {"а.swift": текст}, карта)[0].новый_текст)

    def test_повреждения_отказывают_до_записи_и_не_меняют_гит(сам):
        исходники, исходная = пример()
        варианты = []
        for поле, значение in [("начало", True), ("конец", 1.0), ("строка", 0),
                               ("столбец", 99), ("экранирован", 0)]:
            карта = copy.deepcopy(исходная)
            карта["файлы"][1]["употребления"][0]["позиция"][поле] = значение
            варианты.append(карта)
        for поле, значение in [("объявление", "неизвестное"), ("лишнее", 1)]:
            карта = copy.deepcopy(исходная)
            карта["файлы"][1]["употребления"][0][поле] = значение
            варианты.append(карта)
        for поле, значение in [("ожидаемый_хэш", "sha256:" + "0" * 64), ("путь", "../снаружи.swift")]:
            карта = copy.deepcopy(исходная); карта["файлы"][1][поле] = значение; варианты.append(карта)
        карта = copy.deepcopy(исходная); карта["файлы"][1]["употребления"] *= 2; варианты.append(карта)
        карта = copy.deepcopy(исходная); карта["файлы"] *= 2; варианты.append(карта)
        карта = copy.deepcopy(исходная); карта["файлы"][0]["объявления"] *= 2; варианты.append(карта)
        карта = copy.deepcopy(исходная); карта["файлы"][0]["объявления"][0]["вид"] = "свойство"; варианты.append(карта)
        карта = copy.deepcopy(исходная); карта["версия_схемы"] = True; варианты.append(карта)
        for карта in варианты:
            with сам.subTest(карта=карта), tempfile.TemporaryDirectory() as папка:
                корень = Path(папка)
                subprocess.run(["git", "init", "-q", str(корень)], check=True)
                subprocess.run(["git", "-C", str(корень), "-c", "user.name=Тест", "-c", "user.email=test@local",
                                "commit", "--allow-empty", "-qm", "Начало"], check=True)
                голова = subprocess.check_output(["git", "-C", str(корень), "rev-parse", "HEAD"])
                индекс = (корень / ".git/index").read_bytes() if (корень / ".git/index").exists() else None
                with сам.assertRaises(учёт.ОшибкаКонтракта):
                    сам.подготовить(корень, исходники, карта)
                сам.assertEqual(голова, subprocess.check_output(["git", "-C", str(корень), "rev-parse", "HEAD"]))
                сам.assertEqual(индекс, (корень / ".git/index").read_bytes() if (корень / ".git/index").exists() else None)
                for имя, текст in исходники.items(): сам.assertEqual(текст.encode(), (корень / имя).read_bytes())

    def test_чужое_объявление_строка_и_часть_токена_не_становятся_употреблением(сам):
        исходники, исходная = пример()
        текст = исходники["а.swift"]
        тень = [т for т in учёт.токены_свифт(текст) if т.текст == "old"][2]
        варианты = [позиция(тень), {**исходная["файлы"][0]["употребления"][0]["позиция"], "конец": 28},
                    {"начало": текст.index('"old"') + 1, "конец": текст.index('"old"') + 4,
                     "строка": 4, "столбец": 14, "экранирован": False}]
        for локатор in варианты:
            карта = copy.deepcopy(исходная)
            карта["файлы"][0]["употребления"] = [{"объявление": "главное", "позиция": локатор}]
            with сам.subTest(локатор=локатор), tempfile.TemporaryDirectory() as папка:
                with сам.assertRaises(учёт.ОшибкаКонтракта): сам.подготовить(Path(папка), исходники, карта)

    def test_коллизия_в_потребителе_и_символическая_ссылка_отказывают(сам):
        исходники, карта = пример()
        исходники["б.swift"] += 'let переведённая = 1\n'
        карта["файлы"][1]["ожидаемый_хэш"] = учёт.вычислить_хэш(исходники["б.swift"].encode())
        with tempfile.TemporaryDirectory() as папка:
            with сам.assertRaises(учёт.ОшибкаКонтракта): сам.подготовить(Path(папка), исходники, карта)
        исходники, карта = пример()
        with tempfile.TemporaryDirectory() as папка:
            корень = Path(папка)
            сам.подготовить(корень, исходники, карта)
            (корень / "б.swift").unlink()
            (корень / "б.swift").symlink_to(корень / "а.swift")
            with сам.assertRaises(учёт.ОшибкаКонтракта):
                учёт.подготовить_изменения(корень, учёт.прочитать_карту(корень / "карта.json"))

    def test_поздний_дрейф_последнего_файла_сохраняет_первый(сам):
        исходники, карта = пример()
        with tempfile.TemporaryDirectory() as папка:
            корень = Path(папка); изменения = сам.подготовить(корень, исходники, карта)
            (корень / "б.swift").write_bytes(b"// drift\n")
            with сам.assertRaises(учёт.ОшибкаКонтракта): учёт.атомарно_применить(изменения)
            сам.assertEqual(исходники["а.swift"].encode(), (корень / "а.swift").read_bytes())
            сам.assertEqual(b"// drift\n", (корень / "б.swift").read_bytes())
            сам.assertEqual([], list(корень.glob(".*.swift.*")))

    def test_одна_токенизация_каждого_источника(сам):
        исходники, карта = пример()
        with tempfile.TemporaryDirectory() as папка, mock.patch.object(учёт, "токены_свифт", wraps=учёт.токены_свифт) as разбор:
            сам.подготовить(Path(папка), исходники, карта)
            сам.assertEqual(2, разбор.call_count)

    def test_байтовые_и_двухбайтовые_позиции_не_заменяют_символьные(сам):
        исходники, исходная = пример()
        локатор = исходная["файлы"][0]["объявления"][0]["позиция"]
        префикс = исходники["а.swift"][:локатор["начало"]]
        for начало in (len(префикс.encode("utf-8")), len(префикс.encode("utf-16-le")) // 2):
            карта = copy.deepcopy(исходная)
            карта["файлы"][0]["объявления"][0]["позиция"].update(начало=начало, конец=начало + 3)
            with сам.subTest(начало=начало), tempfile.TemporaryDirectory() as папка, сам.assertRaises(учёт.ОшибкаКонтракта):
                сам.подготовить(Path(папка), исходники, карта)

    def test_поздние_режим_и_ссылка_отказывают_до_первой_замены(сам):
        исходники, карта = пример()
        for причина in ("режим", "ссылка"):
            with сам.subTest(причина=причина), tempfile.TemporaryDirectory() as папка:
                корень = Path(папка); изменения = сам.подготовить(корень, исходники, карта)
                последний = корень / "б.swift"
                if причина == "режим": последний.chmod(0o600)
                else:
                    последний.unlink(); последний.symlink_to(корень / "а.swift")
                with сам.assertRaises(учёт.ОшибкаКонтракта): учёт.атомарно_применить(изменения)
                сам.assertEqual(исходники["а.swift"].encode(), (корень / "а.swift").read_bytes())
                сам.assertEqual([], list(корень.glob(".*.swift.*")))

    def test_сырые_строки_и_регулярные_выражения_закрывают_новую_карту(сам):
        for выражение in ['#"префикс " old " суффикс"#', '/old/', '#/old/#']:
            текст = 'func old() {}\nlet строка = ' + выражение + '\n'
            токен = учёт.токены_свифт(текст)[1]
            карта = {"версия_схемы": 2, "файлы": [запись_файла("а.swift", текст, [объявление(токен)])]}
            with сам.subTest(выражение=выражение), tempfile.TemporaryDirectory() as папка:
                with сам.assertRaises(учёт.ОшибкаКонтракта): сам.подготовить(Path(папка), {"а.swift": текст}, карта)

    def test_прежний_потребитель_без_объявления_по_прежнему_отказывает(сам):
        with tempfile.TemporaryDirectory() as папка:
            корень = Path(папка); текст = 'old()\n'; (корень / "а.swift").write_text(текст)
            with сам.assertRaisesRegex(учёт.ОшибкаКонтракта, "не являются объявлениями"):
                учёт.подготовить_изменения(корень, [учёт.ЗаписьКарты("а.swift", учёт.вычислить_хэш(текст.encode()), {"old": "переведённая"})])

    def test_служебные_ключи_не_становятся_употреблением_собственного_типа(сам):
        текст = 'struct Запись: Swift.Codable { let хэш: Swift.String\n enum CodingKeys: Swift.String, Swift.CodingKey { case хэш = "sha256" } }\nstruct CodingKeys {}\n'
        токены = [т for т in учёт.токены_свифт(текст) if т.текст == "CodingKeys"]
        карта = {"версия_схемы": 2, "файлы": [запись_файла("а.swift", текст,
            [объявление(токены[1], "СобственныеКлючи", вид="тип")], [употребление(токены[0])])]}
        with tempfile.TemporaryDirectory() as папка, сам.assertRaises(учёт.ОшибкаКонтракта):
            сам.подготовить(Path(папка), {"а.swift": текст}, карта)

    def test_собственный_одноимённый_тип_выбирается_отдельно_от_служебных_ключей(сам):
        текст = 'struct Запись: Swift.Codable { let хэш: Swift.String\n enum CodingKeys: Swift.String, Swift.CodingKey { case хэш = "sha256" } }\nstruct CodingKeys {}\nlet объект = CodingKeys()\n'
        токены = [т for т in учёт.токены_свифт(текст) if т.текст == "CodingKeys"]
        карта = {"версия_схемы": 2, "файлы": [запись_файла("а.swift", текст,
            [объявление(токены[1], "СобственныеКлючи", вид="тип")], [употребление(токены[2])])]}
        with tempfile.TemporaryDirectory() as папка:
            корень = Path(папка)
            изменения = сам.подготовить(корень, {"а.swift": текст}, карта)
            сам.assertIn('enum CodingKeys: Swift.String, Swift.CodingKey { case хэш = "sha256" }', изменения[0].новый_текст)
            сам.assertIn('struct СобственныеКлючи {}\nlet объект = СобственныеКлючи()', изменения[0].новый_текст)
            with сам.assertRaises(учёт.ОшибкаКонтракта):
                учёт.подготовить_изменения(корень, [учёт.ЗаписьКарты("а.swift", учёт.вычислить_хэш(текст.encode()), {"CodingKeys": "СобственныеКлючи"})])

    def test_экранированный_многострочный_разделитель_не_открывает_употребление(сам):
        текст = 'func old() {}\nlet строка = """\nначало \\""" old() \\""" конец\n"""\n'
        токены = [т for т in учёт.токены_свифт(текст) if т.текст == "old"]
        сам.assertEqual(2, len(токены))  # Контрпример для прежнего ограниченного lexer.
        карта = {"версия_схемы": 2, "файлы": [запись_файла("а.swift", текст,
            [объявление(токены[0])], [употребление(токены[1])])]}
        with tempfile.TemporaryDirectory() as папка, сам.assertRaises(учёт.ОшибкаКонтракта):
            сам.подготовить(Path(папка), {"а.swift": текст}, карта)

    def test_вложенная_строка_интерполяции_не_открывает_употребление(сам):
        текст = 'func old() {}\nlet строка = "\\(String("old"))"\n'
        токены = [т for т in учёт.токены_свифт(текст) if т.текст == "old"]
        сам.assertEqual(2, len(токены))
        карта = {"версия_схемы": 2, "файлы": [запись_файла("а.swift", текст,
            [объявление(токены[0])], [употребление(токены[1])])]}
        with tempfile.TemporaryDirectory() as папка, сам.assertRaises(учёт.ОшибкаКонтракта):
            сам.подготовить(Path(папка), {"а.swift": текст}, карта)

    def test_регулярное_выражение_после_перевода_строки_закрывает_карту(сам):
        текст = 'func old() {}\nold()\n/old/\n'
        токены = [т for т in учёт.токены_свифт(текст) if т.текст == "old"]
        карта = {"версия_схемы": 2, "файлы": [запись_файла("а.swift", текст,
            [объявление(токены[0])], [употребление(токены[-1])])]}
        with tempfile.TemporaryDirectory() as папка, сам.assertRaises(учёт.ОшибкаКонтракта):
            сам.подготовить(Path(папка), {"а.swift": текст}, карта)

    def test_регулярное_выражение_после_контекстного_слова_закрывает_карту(сам):
        текст = 'func old() {}\nfunc функция() async { let выражение = await /old/ }\n'
        токены = [т for т in учёт.токены_свифт(текст) if т.текст == "old"]
        карта = {"версия_схемы": 2, "файлы": [запись_файла("а.swift", текст,
            [объявление(токены[0])], [употребление(токены[1])])]}
        with tempfile.TemporaryDirectory() as папка, сам.assertRaises(учёт.ОшибкаКонтракта):
            сам.подготовить(Path(папка), {"а.swift": текст}, карта)


class ПроверкиКлючейКодирования(unittest.TestCase):
    def инвентарь(сам, текст):
        with tempfile.TemporaryDirectory() as папка:
            файл = Path(папка) / "а.swift"; файл.write_text(текст, encoding="utf-8")
            return учёт.объявления_свифт(файл, "а.swift")

    def test_квалифицированные_ключи_не_являются_собственным_типом(сам):
        for протокол in ("Codable", "Encodable", "Decodable"):
            текст = 'struct Запись: Swift.' + протокол + ' { let хэш: Swift.String\n enum CodingKeys: Swift.String, Swift.CodingKey { case хэш = "sha256" } }\n'
            сам.assertEqual([], сам.инвентарь(текст))

    def test_прежние_неквалифицированные_ключи_сохраняют_классификацию(сам):
        текст = 'struct Запись: Codable { let хэш: String\n enum CodingKeys: String, CodingKey { case old = "sha256" } }\n'
        сам.assertEqual({"CodingKeys", "old"}, {з.имя for з in сам.инвентарь(текст)})

    def test_массивы_и_необязательные_типы_покрывают_несколько_свойств(сам):
        текст = 'public struct Запись: Swift.Codable, Swift.Sendable {\n let хэш: Swift.String\n var элементы: [Элемент]?\n private enum CodingKeys: Swift.String, Swift.CodingKey { case хэш = "sha256", элементы = "items" }\n}\n'
        сам.assertEqual([], сам.инвентарь(текст))

    def test_межфайловая_тень_модуля_закрывает_новый_профиль(сам):
        текст = 'struct Запись: Swift.Codable { let хэш: Swift.String\n enum CodingKeys: Swift.String, Swift.CodingKey { case хэш = "sha256" } }\n'
        for тень in ('typealias Swift = Подмена', 'func функция<Swift>() {}', 'func функция(Swift: Int) {}'):
            with сам.subTest(тень=тень), tempfile.TemporaryDirectory() as папка:
                корень = Path(папка); (корень / "а.swift").write_text(текст, encoding="utf-8")
                (корень / "б.swift").write_text(тень, encoding="utf-8")
                with сам.assertRaises(учёт.ОшибкаКонтракта): учёт.объявления_свифт(корень / "а.swift", "а.swift")

    def test_тени_и_неподдержанные_квалифицированные_формы_отказывают(сам):
        хороший = 'struct Запись: Swift.Codable { let хэш: Swift.String\n enum CodingKeys: Swift.String, Swift.CodingKey { case хэш = "sha256" } }\n'
        варианты = ['typealias Swift = Подмена\n' + хороший, 'struct Swift {}\n' + хороший,
                    хороший.replace('case хэш = "sha256"', 'case хэш'),
                    хороший.replace('case хэш', 'case old'), хороший.replace('Swift.String, Swift.CodingKey', 'String, CodingKey'),
                    хороший.replace('case хэш = "sha256"', 'case хэш = "sha256"; case хэш = "другое"'),
                    хороший.replace('case хэш = "sha256"', 'case хэш = "sha256"; func метод() {}'),
                    хороший.replace('let хэш: Swift.String', 'let хэш: Swift.String, второй: Swift.String'),
                    хороший.replace('case хэш = "sha256"', ', хэш = "sha256"'),
                    '@ДобавитьПоле ' + хороший, хороший.replace('let хэш', '@Обёртка let хэш'),
                    хороший.replace('case хэш = "sha256"', 'case хэш = "sha256",, хэш = "другое"'),
                    хороший.replace('case хэш = "sha256"', 'case хэш = "sha256",'),
                    хороший.replace('let хэш: Swift.String', 'let хэш: Swift.String = "значение"'),
                    хороший.replace('let хэш: Swift.String', 'var хэш: Swift.String { "значение" }'),
                    хороший.replace('let хэш: Swift.String', 'let хэш: Swift.String\n let второй: Swift.String')]
        for текст in варианты:
            with сам.subTest(текст=текст), сам.assertRaises(учёт.ОшибкаКонтракта): сам.инвентарь(текст)


def измерить(выход):
    """Одинаковые два источника, 1/10 uses; счётчик разбора отдельно от времени."""
    первый = 'func old() {}\n'
    второй = ('let значение = old()\n' * 1000)
    токен = учёт.токены_свифт(первый)[1]
    употребления = [т for т in учёт.токены_свифт(второй) if т.текст == "old"]
    результаты = []
    with tempfile.TemporaryDirectory() as папка:
        корень = Path(папка)
        for кратность in (1, 10):
            карта = {"версия_схемы": 2, "файлы": [запись_файла("а.swift", первый, [объявление(токен)]),
                запись_файла("б.swift", второй, употребления=[употребление(т) for т in употребления[:кратность]])]}
            проверка = ПроверкиПотребителейСвифт()
            проверка.подготовить(корень, {"а.swift": первый, "б.swift": второй}, карта)
            учёт.подготовить_изменения(корень, учёт.прочитать_карту(корень / "карта.json"))
            for повтор in range(3):
                tracemalloc.start(); начало = time.perf_counter_ns()
                with mock.patch.object(учёт, "токены_свифт", wraps=учёт.токены_свифт) as разбор:
                    изменения = учёт.подготовить_изменения(корень, учёт.прочитать_карту(корень / "карта.json"))
                длительность = time.perf_counter_ns() - начало
                _, пик = tracemalloc.get_traced_memory(); tracemalloc.stop()
                if разбор.call_count != 2: raise AssertionError("Повторная токенизация")
                результаты.append({"употреблений": кратность, "повтор": повтор, "длительность_нс": длительность,
                                   "пик_памяти_байты": пик, "токенизаций": разбор.call_count,
                                   "замен": sum(len(и.выбранные_позиции) for и in изменения)})
    источник = Path(учёт.__file__)
    Path(выход).write_text(json.dumps({"схема": "fum.профиль-употреблений-свифт.1", "измерения": результаты,
        "исходники": {"а.swift": учёт.вычислить_хэш(первый.encode()), "б.swift": учёт.вычислить_хэш(второй.encode())},
        "автоматизация_sha256": hashlib.sha256(источник.read_bytes()).hexdigest(),
        "граница": "Два одинаковых источника. Прогрев и подготовка файлов исключены; чтение карты, SHA, разбор и план включены. Скорость полного процесса не измерена."}, ensure_ascii=False, indent=2) + '\n', encoding="utf-8")


def сравнить_наследование(корпус, коммит, выход):
    """Сравнить классификаторы на полном неизменном Git-корпусе и контуре C."""
    корпус = Path(корпус).resolve()
    репозиторий = Path(__file__).resolve().parents[3]
    относительный = Path(учёт.__file__).resolve().relative_to(репозиторий)
    записи = subprocess.check_output(["git", "-C", str(репозиторий), "ls-tree", "-r", "-z", коммит]).split(b"\0")
    манифест = []
    for запись in filter(None, записи):
        метаданные, путь = запись.split(b"\t", 1)
        режим, вид, объект = метаданные.decode().split()
        манифест.append((путь.decode("utf-8"), режим, вид, объект))

    def проверить_корпус():
        ожидаемые = set()
        for путь, режим, вид, объект in манифест:
            файл = корпус / путь
            if вид == "commit":
                if режим != "160000": raise AssertionError("Неизвестный gitlink")
                continue  # Внешние submodule не входят в Git-байты C.
            ожидаемые.add(путь)
            if режим == "120000":
                if not файл.is_symlink(): raise AssertionError("Потеря symlink: " + путь)
                данные = os.readlink(файл).encode("utf-8")
            else:
                if файл.is_symlink() or not файл.is_file(): raise AssertionError("Потеря Git-файла: " + путь)
                данные = файл.read_bytes()
                if bool(файл.stat().st_mode & 0o111) != (режим == "100755"):
                    raise AssertionError("Изменён executable mode: " + путь)
            наблюдаемый = hashlib.sha1(b"blob " + str(len(данные)).encode() + b"\0" + данные).hexdigest()
            if наблюдаемый != объект: raise AssertionError("Изменены Git-байты: " + путь)
        реальные = [п.relative_to(корпус).as_posix() for п in корпус.rglob("*") if п.is_file() or п.is_symlink()]
        # APFS возвращает NFD имён. Это только проверка состава, байты не нормализуются.
        наблюдаемые_имена = [unicodedata.normalize("NFC", п) for п in реальные]
        ожидаемые_имена = [unicodedata.normalize("NFC", п) for п in ожидаемые]
        if (len(set(наблюдаемые_имена)) != len(реальные) or len(set(ожидаемые_имена)) != len(ожидаемые)
                or set(наблюдаемые_имена) != set(ожидаемые_имена)):
            raise AssertionError("Лишние, пропущенные или Unicode-коллизии имён корпуса C")

    проверить_корпус()
    исполнение = r'''
import hashlib,json,sys,types
from pathlib import Path
корпус,источник,канонический=map(Path,sys.argv[1:4])
байты=источник.read_bytes()
модуль=types.ModuleType("проверяемый_переводчик")
модуль.__file__=str(канонический)
sys.modules[модуль.__name__]=модуль
exec(compile(байты,str(канонический),"exec"),модуль.__dict__)
инвентарь=модуль.построить_инвентарь(корпус)
модули={}
for имя,значение in tuple(sys.modules.items()):
    путь=getattr(значение,"__file__",None)
    if not путь: continue
    путь=Path(путь).resolve()
    if путь.is_relative_to(корпус):
        модули[имя]={"путь":путь.relative_to(корпус).as_posix(),"sha256":hashlib.sha256(путь.read_bytes()).hexdigest()}
    elif not путь.is_relative_to(Path(sys.base_prefix).resolve()):
        raise AssertionError("Импорт за пределами C и стандартной библиотеки: "+имя)
if not {"разбор_сценария","аббревиатуры_контекста","безопасные_привязки_python"}.issubset(модули):
    raise AssertionError("Неполный импорт принимающего контура C")
модули.pop("проверяемый_переводчик",None)
print(json.dumps({"инвентарь":инвентарь,"модули":модули,"исходник_sha256":hashlib.sha256(байты).hexdigest()},ensure_ascii=False))
'''
    with tempfile.TemporaryDirectory() as папка:
        новый = Path(папка) / "новый.py"
        новый.write_bytes(Path(учёт.__file__).read_bytes())
        результаты = []
        for источник in (корпус / относительный, новый):
            запуск = subprocess.run([sys.executable, "-I", "-S", "-B", "-c", исполнение,
                str(корпус), str(источник), str(корпус / относительный)],
                cwd=корпус, capture_output=True, timeout=180, check=True)
            if запуск.stderr: raise AssertionError("Неожиданный stderr классификатора")
            результаты.append(json.loads(запуск.stdout))
    проверить_корпус()
    старый, новый = результаты
    if старый["модули"] != новый["модули"]: raise AssertionError("Разные транзитивные зависимости")
    if старый["инвентарь"] != новый["инвентарь"]: raise AssertionError("Изменён полный упорядоченный инвентарь C")
    ключи = []
    for результат in результаты:
        ключи.append([з for з in результат["инвентарь"]["объявления"]
                      if з["язык"] == "swift" and з["вид"] == "тип" and з["имя"] == "CodingKeys"])
    if len(ключи[0]) != 300 or ключи[0] != ключи[1]: raise AssertionError("Изменены 300 прежних CodingKeys")
    снимок = относительный.parents[1] / "остаток-объявлений-кода.json"
    сводка = учёт.сводка_снимка(новый["инвентарь"])
    данные = {"схема": "fum.наследование-инвентаря-свифт.1", "коммит_корпуса": коммит,
        "дерево_корпуса": subprocess.check_output(["git", "-C", str(репозиторий), "rev-parse", коммит + "^{tree}"]).decode().strip(),
        "манифест_sha256": hashlib.sha256(json.dumps(манифест, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest(),
        "файлов_корпуса": sum(з[2] == "blob" for з in манифест), "контур": старый["модули"],
        "старый_исходник_sha256": старый["исходник_sha256"], "новый_исходник_sha256": новый["исходник_sha256"],
        "инвентарь": сводка, "полный_упорядоченный_инвентарь_совпадает": True,
        "CodingKeys": {"записей": len(ключи[0]), "файлов": len({з["путь"] for з in ключи[0]}),
            "точные_записи_совпадают": True, "sha256": hashlib.sha256(учёт.канонический_текст(ключи[0]).encode()).hexdigest()},
        "существующий_снимок": {"sha256": hashlib.sha256((корпус / снимок).read_bytes()).hexdigest(),
            "значение": json.loads((корпус / снимок).read_text()), "совпадает_с_корпусом": json.loads((корпус / снимок).read_text()) == сводка},
        "граница": "Полный Git-корпус C проверен по blob OID и executable mode до и после. Два свежих Python -I -S -B; одинаковый контур C. Снимок не обновлён; текущий checkout, V2 и новые DTO этим сравнением не принимаются."}
    Path(выход).write_text(json.dumps(данные, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--профиль": измерить(sys.argv[2])
    elif len(sys.argv) == 5 and sys.argv[1] == "--наследование": сравнить_наследование(*sys.argv[2:])
    else: unittest.main()
