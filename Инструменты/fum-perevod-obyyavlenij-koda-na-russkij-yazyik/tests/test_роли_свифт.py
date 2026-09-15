"""Различать объявления Swift, обращения и тела управляющих конструкций."""

from pathlib import Path
import tempfile
import unittest

from test_аббревиатуры_контекста import учёт


class ПроверкиРолейСвифт(unittest.TestCase):
    def имена(сам, текст):
        with tempfile.TemporaryDirectory() as папка:
            файл = Path(папка) / "пример.swift"
            файл.write_text(текст, encoding="utf-8")
            return {з.имя for з in учёт.объявления_свифт(файл, "пример.swift")}

    def test_ветви_и_вызовы_не_являются_объявлениями(сам):
        for текст in [
            'func русская(_ значение: String) -> Int { switch значение { case "да": return 1; default: return 0 } }',
            'guard case .объект(let поля) = узел, Set(поля.keys) == ключи else { return }',
            'let действие = { строки.append(строки.count)\nfor имя in имена {} }',
            'let действие = { try работа()\nfor имя in имена {} }',
        ]:
            with сам.subTest(текст=текст):
                сам.assertEqual(set(), сам.имена(текст))

    def test_реальные_параметры_замыкания_и_цикла_сохраняются(сам):
        сам.assertEqual({"hidden", "local"}, сам.имена(
            'let обработка = { (hidden: Int) -> Int in let local = hidden; return local }'))
        сам.assertEqual({"append", "return", "hidden", "count"}, сам.имена(
            'enum Вид { case append }; let `return` = 1; for hidden in значения { let count = hidden }'))
        сам.assertEqual({"first", "second"}, сам.имена('for (first, second) in пары {}'))

    def test_варианты_перечисления_ограничены_его_телом(сам):
        сам.assertEqual({"one", "two"}, сам.имена(
            'enum Вид { case one, two; func имя() { switch self { case .one: return; default: return } } }'))

    def test_захваты_и_варианты_после_явного_значения_не_теряются(сам):
        сам.assertEqual({"hidden"}, сам.имена('let обработка = { [weak self] hidden in hidden }'))
        сам.assertEqual({"captured", "hidden"}, сам.имена(
            'let обработка = { [captured = источник] hidden in hidden }'))
        сам.assertEqual({"hidden"}, сам.имена('enum Вид: Int { case первый = 1, hidden = 2 }'))
        сам.assertEqual({"hidden"}, сам.имена(
            'let обработка = { (hidden: Int) throws(Ошибка) -> Int in hidden }'))
        сам.assertEqual({"hidden"}, сам.имена('for await hidden in поток {}'))
        сам.assertEqual({"hidden"}, сам.имена('for try await hidden in поток {}'))

    def test_явные_строковые_токены_сохраняют_границы_и_не_считают_комментарии(сам):
        текст = '// "ложная"\nlet строка = "настоящая" /* "ложная" */\n'
        токены = учёт.токены_свифт(текст, со_строками=True)
        строки = [т for т in токены if т.вид == "строка"]
        сам.assertEqual(['"настоящая"'], [т.текст for т in строки])
        сам.assertEqual('"настоящая"', текст[строки[0].начало:строки[0].конец])


if __name__ == "__main__":
    unittest.main()
