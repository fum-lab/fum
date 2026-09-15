"""Закрытый синтаксис CJS и полный учёт связываний до допуска проекции."""

import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

путь = Path(__file__).resolve().parents[1] / "scripts" / "разбор_сценария.py"
спецификация = importlib.util.spec_from_file_location("разбор_сценария", путь)
модуль = importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name] = модуль
спецификация.loader.exec_module(модуль)

спецификация_учёта = importlib.util.spec_from_file_location("учёт_сценария", путь.with_name("перевести-объявления-кода.py"))
учёт = importlib.util.module_from_spec(спецификация_учёта)
sys.modules[спецификация_учёта.name] = учёт
спецификация_учёта.loader.exec_module(учёт)


class ПроверкаСценарияОтвета(unittest.TestCase):
    def имена(сам, текст):
        return {запись["имя"] for запись in модуль.разобрать(текст)["объявления"]}

    def test_все_формы_связываний_наблюдаются(сам):
        текст = '''"use strict";
const {test: проверить, вложенный: {badAlias}, ...badRest} = источник;
let [badArray, ...badTail] = источник;
async function badFunction({badParameter = (() => {const badInner = 1; return 1;})()}) {
    for (const [badLoop] of источник) { const значение = badLoop; }
    try { throw 1; } catch ({message: badCatch}) { return badCatch; }
}
const стрелка = async (badArrow = 1, ...badArgs) => badArrow;
const один = badSingle => ({badProperty: badSingle});
const выражение = function badNamed(badLocal) {return badLocal;};
const одно = 1, badSecond = 2;
const сокращение = {badShorthand};
'''
        сам.assertTrue({"badAlias", "badRest", "badArray", "badTail", "badFunction",
                        "badParameter", "badInner", "badLoop", "badCatch", "badArrow",
                        "badArgs", "badSingle", "badProperty", "badNamed", "badLocal",
                        "badSecond", "badShorthand"}
                       <= сам.имена(текст))

    def test_литералы_комментарии_и_деление_не_создают_объявлений(сам):
        текст = '''// const fakeComment = 1;
const строка = "function fakeString(fakeParameter) {}";
const выражение = /const fakeRegex = [\\/]/u;
const число = (6 + 2) / 4;
const результат = значение => значение / 2;
'''
        сам.assertFalse(any(имя.startswith("fake") for имя in сам.имена(текст)))

    def test_вложенные_параметры_и_поле_присваивания_наблюдаются(сам):
        сам.assertTrue({"badNested", "badAssigned"} <= сам.имена(
            'const результат = ([{поле: badNested = 1}]) => badNested; '
            'объект.badAssigned = 1;'))

    def test_неподдержанный_синтаксис_закрывается(сам):
        варианты = [
            'class Русский { hidden() {} }',
            'const объект = { hidden() { return 1; } };',
            'const объект = { get hidden() { return 1; } };',
            'const объект = { ["hidden"]: 1 };',
            'const объект = { "hidden": 1 };',
            'объект["hidden"] = 1;',
            'const стрелка = () => {hidden: 1;};',
            'const строка = `const hidden = 1;`;',
            'const \\u0068idden = 1;',
            'var hidden = 1;',
            'function* генератор(hidden) { yield hidden; }',
            'import hidden from "module";',
            'export const hidden = 1;',
            'with (объект) { hidden = 1; }',
            'const число = ;',
            'const число = 1; /* незакрытый',
        ]
        for текст in варианты:
            with сам.subTest(текст=текст):
                with сам.assertRaises(модуль.ОшибкаСценария):
                    модуль.разобрать(текст)

    def test_внешние_ключи_не_разрешают_латинское_связывание(сам):
        результат = модуль.разобрать('const status = 1; const ответ = {id:"ход",status:status,error:null,startedAt:null,completedAt:null,durationMs:null,items:[]};')
        записи = [з for з in результат["объявления"] if з["имя"] == "status"]
        сам.assertEqual([з["класс"] for з in записи], ["собственное", "внешнее"])
        сам.assertTrue(all(з["источник"] for з in записи if з["класс"] == "внешнее"))

    def test_внешний_ключ_требует_полной_формы_контракта(сам):
        результат = модуль.разобрать('const объект = {cmd:1};')
        сам.assertEqual(next(з["класс"] for з in результат["объявления"] if з["имя"] == "cmd"), "собственное")

    def test_неизвестный_корень_поля_не_выдаётся_за_среду_исполнения(сам):
        for текст, имя in (('получить().module.exports=1;', 'exports'), ('получить().process.exitCode=1;', 'exitCode')):
            with сам.subTest(текст=текст):
                результат = модуль.разобрать(текст)
                сам.assertEqual(next(з["класс"] for з in результат["объявления"] if з["имя"] == имя), "собственное")

    def test_опасные_левые_части_не_теряют_имена(сам):
        сам.assertIn("hidden", сам.имена('new Объект().hidden = 1;'))
        for текст in ('объект[("hidden")] = 1;', 'for (объект.hidden of записи) {}',
                      '([объект.hidden] = записи);', '({поле:объект.hidden} = запись);'):
            with сам.subTest(текст=текст):
                with сам.assertRaises(модуль.ОшибкаСценария):
                    модуль.разобрать(текст)

    def test_переименование_не_меняет_внешний_ключ(сам):
        текст = 'const status=1; const ответ={id:"ход",status:status,error:null,startedAt:null,completedAt:null,durationMs:null,items:[]};'
        новый, _, _ = учёт.замены_сценария(текст, {"status":"состояние"})
        сам.assertIn('status:состояние', новый)
        сам.assertIn('const состояние=1', новый)

    def test_переименование_различает_присваивание_переменной_и_поле(сам):
        текст = 'let length=0; length+=1; const число=строка.length;'
        новый, _, _ = учёт.замены_сценария(текст, {"length": "длина"})
        сам.assertEqual(новый, 'let длина=0; длина+=1; const число=строка.length;')
        with сам.assertRaises(учёт.ОшибкаКонтракта):
            учёт.замены_сценария('const объект={length:1}; const число=строка.length;', {"length": "длина"})

    def test_переименование_сокращённого_связывания_сохраняет_читаемый_ключ(сам):
        новый, _, _ = учёт.замены_сценария('const {test}=require("node:test"); test("имя",()=>{});', {"test": "проверить"})
        сам.assertEqual(новый, 'const {test:проверить}=require("node:test"); проверить("имя",()=>{});')
        with сам.assertRaises(учёт.ОшибкаКонтракта):
            учёт.замены_сценария('const объект={hidden:1}; const {hidden:значение}=объект;', {"hidden":"скрытое"})

    def test_позиции_сохраняются_и_исходник_не_исполняется(сам):
        результат = модуль.разобрать('"use strict";\nthrow new Error("Не исполнять");\nconst badName = 1;')
        запись = next(з for з in результат["объявления"] if з["имя"] == "badName")
        сам.assertEqual((запись["строка"], запись["столбец"]), (3, 7))

    def test_все_разделители_строк_завершают_комментарий(сам):
        for разделитель in ("\n", "\r", "\r\n", "\u2028", "\u2029"):
            with сам.subTest(разделитель=repr(разделитель)):
                сам.assertIn("hidden", сам.имена('const имя = 1; // текст' + разделитель + 'const hidden = 1;'))

    def test_перевод_строки_не_скрывает_метку_после_возврата(сам):
        for разделитель in ("\n", "\r", "\r\n", "\u2028", "\u2029", "/*\n*/"):
            with сам.subTest(разделитель=repr(разделитель)):
                with сам.assertRaises(модуль.ОшибкаСценария):
                    модуль.разобрать('function русская(){return' + разделитель + '{type:1};}')

    def test_координаты_строк_и_закрытые_продолжения_литералов(сам):
        результат = модуль.разобрать('const имя=1;\r\nconst hidden=2;')
        сам.assertEqual(next(з["строка"] for з in результат["объявления"] if з["имя"] == "hidden"), 2)
        for конец in ('\n', '\r', '\r\n', '\u2028', '\u2029'):
            with сам.subTest(конец=repr(конец)):
                with сам.assertRaises(модуль.ОшибкаСценария):
                    модуль.разобрать('const строка="а\\' + конец + 'б";')

    def test_пределы_закрываются_до_внешней_команды(сам):
        with сам.assertRaises(модуль.ОшибкаСценария):
            модуль.разобрать(" " * 262145)
        with сам.assertRaises(модуль.ОшибкаСценария):
            модуль.разобрать("const значение = " + "(" * 100 + "1" + ")" * 100 + ";")

    def test_конечные_пути_инвентаря_и_токеновый_перевод(сам):
        for имя in модуль.пути_сценариев:
            with tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                файл = корень / имя
                файл.parent.mkdir(parents=True)
                текст = 'const badName = "badName"; const результат = badName; // badName\n'
                файл.write_text(текст)
                сам.assertEqual({з["имя"] for з in учёт.построить_инвентарь(корень)["объявления"]}, {"badName"})
                новый, количества, имена = учёт.замены_сценария(текст, {"badName": "имя"})
                сам.assertEqual(новый, 'const имя = "badName"; const результат = имя; // badName\n')
                сам.assertEqual(количества, {"badName": 2})
                сам.assertIn("badName", имена)

    def test_неверный_путь_и_символический_предок_закрываются(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            файл = корень / "другой.cjs"
            файл.write_text("const имя = 1;")
            with сам.assertRaises(учёт.ОшибкаКонтракта):
                учёт.построить_инвентарь(корень)
            файл.unlink()
            (корень / "внешнее").mkdir()
            (корень / "Инструменты").symlink_to(корень / "внешнее", target_is_directory=True)
            with сам.assertRaises(учёт.ОшибкаКонтракта):
                учёт.построить_инвентарь(корень)


if __name__ == "__main__":
    unittest.main()
