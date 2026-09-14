"""Реальные сигнатуры сохраняют объявления при уточнении лексических ролей."""

from collections import Counter
from pathlib import Path
import tempfile
import unittest

from test_аббревиатуры_контекста import учёт


примеры = {
    "атрибут": 'let действие = { @Sendable (hidden: Int) in hidden }',
    "захваты": 'let действие = { [safe = 1, unsafe = 2] in safe + unsafe }',
    "экранирование": 'let действие = { (`consuming`: Int) in `consuming` }',
    "проекция": '''import SwiftUI
func принять(_ действие: (Binding<Int>) -> Void) {}
принять { $source in _ = source }
''',
    "метки": '''func взвесить(for signal: String) { _ = signal }
func разместить(in directory: String) { _ = directory }
''',
    "себя": '''import Foundation
final class Пример: NSObject {
  func выполнить() {
    let действие = { [weak self] in
      guard let self, self.description.isEmpty else { return }
    }
    действие()
    let второе = { [weak self] in
      guard let self, let url = URL(string: self.description) else { return }
      _ = url
    }
    второе()
  }
}
''',
}


class ПроверкиСигнатурСвифт(unittest.TestCase):
    def имена(сам, текст):
        with tempfile.TemporaryDirectory() as папка:
            файл = Path(папка) / "пример.swift"
            файл.write_text(текст, encoding="utf-8")
            return Counter(з.имя for з in учёт.объявления_свифт(файл, "пример.swift"))

    def test_атрибут_не_скрывает_параметр(сам):
        сам.assertEqual(Counter({"hidden": 1}), сам.имена(примеры["атрибут"]))

    def test_захваты_не_становятся_модификаторами_по_одному_имени(сам):
        сам.assertEqual(Counter({"safe": 1, "unsafe": 1}), сам.имена(примеры["захваты"]))
        сам.assertEqual(Counter({"hidden": 1}), сам.имена(
            'let действие = { [unowned(safe) объект] hidden in hidden }'))

    def test_экранированное_имя_не_становится_модификатором(сам):
        сам.assertEqual(Counter({"consuming": 1}), сам.имена(примеры["экранирование"]))

    def test_проецируемый_параметр_сохраняет_своё_имя(сам):
        сам.assertEqual(Counter({"source": 1}), сам.имена(примеры["проекция"]))

    def test_ключевые_слова_в_роли_меток_не_теряются(сам):
        сам.assertEqual(Counter({"for": 1, "signal": 1, "in": 1, "directory": 1}),
                        сам.имена(примеры["метки"]))

    def test_краткое_связывание_себя_не_захватывает_следующее_выражение(сам):
        сам.assertEqual(Counter({"url": 1}), сам.имена(примеры["себя"]))

    def test_неоднозначный_модификатор_не_переводится_как_имя(сам):
        текст = ('struct Т {}\nfunc принять(_ значение: consuming Т) {}\n'
                 'let действие = { (`consuming`: Int) in `consuming` }')
        with сам.assertRaises(учёт.ОшибкаКонтракта):
            учёт.замены_свифт(текст, {"consuming": "имя"})
        with сам.assertRaises(учёт.ОшибкаКонтракта):
            учёт.замены_свифт(
                'let действие = { [safe = 1, unowned(safe) объект] in safe }',
                {"safe": "безопасный"})

    def test_экранированное_имя_переводится_с_сохранением_кавычек(сам):
        текст = примеры["экранирование"]
        результат, количества, _ = учёт.замены_свифт(текст, {"consuming": "значение"})
        сам.assertEqual('let действие = { (`значение`: Int) in `значение` }', результат)
        сам.assertEqual({"consuming": 2}, количества)


if __name__ == "__main__":
    unittest.main()
