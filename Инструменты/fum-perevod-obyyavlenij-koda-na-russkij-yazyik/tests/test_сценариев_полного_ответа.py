"""Два точных компонента потока; побитовый синтаксис не скрывает объявлений."""
from pathlib import Path
import unittest

from test_сценарий_ответа import модуль, учёт

КОРЕНЬ = Path(__file__).resolve().parents[3]
ПУТИ = ('Инструменты/fum-svyaznostj-rabochej-sessii/scripts/мост_полного_ответа_узла.cjs',
        'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/хэш_полного_ответа_узла.cjs')


class ПолныйСценарий(unittest.TestCase):
    def test_точные_пути_и_полное_чтение(сам):
        for путь in ПУТИ:
            сам.assertIn(путь, модуль.пути_сценариев)
            текст = (КОРЕНЬ / путь).read_text()
            сам.assertEqual(учёт.объявления_сценария(текст, путь), [])
        with сам.assertRaises(учёт.ОшибкаКонтракта):
            учёт.объявления_сценария('const x = 1;', 'произвольный.cjs')

    def test_побитовые_операторы_сохраняют_связывания(сам):
        текст = 'const badValue = (1 << 2) | (4 & 7) ^ (8 >>> 1); let badOther = ~badValue >> 1;'
        результат = модуль.разобрать(текст)['объявления']
        сам.assertEqual({э['имя'] for э in результат if э['класс'] == 'собственное'}, {'badValue', 'badOther'})
        for путь in ПУТИ:
            сам.assertTrue(учёт.объявления_сценария(текст, путь))

    def test_новые_поля_внешнего_интерфейса_узко_отделены(сам):
        текст = 'const команда = {cmd: "", workdir: "", tty: false, yield_time_ms: 1, max_output_tokens: 1}; const отпечаток = {байты: 1, sha256: ""}; const сосед = {tty: false};'
        результат = модуль.разобрать(текст)['объявления']
        поля = [э for э in результат if э['вид'] == 'поле']
        сам.assertEqual([э['класс'] for э in поля if э['имя'] == 'tty'], ['внешнее', 'собственное'])
        сам.assertEqual([э['класс'] for э in поля if э['имя'] == 'sha256'], ['внешнее'])

    def test_неизвестная_конструкция_не_исполняется(сам):
        for текст in ('const x = `template`;', 'class Hidden {}', 'let value = 1; value &&= 2;'):
            with сам.subTest(текст=текст), сам.assertRaises(модуль.ОшибкаСценария):
                модуль.разобрать(текст)


if __name__ == '__main__':
    unittest.main()
