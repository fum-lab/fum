"""Чистые проверки повторяются в новой области, ошибки и живые данные не кэшируются."""
from concurrent.futures import ThreadPoolExecutor
from contextlib import nullcontext
from pathlib import Path
import builtins
import sys
import tempfile
import threading
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import контракт_независимого_журнала as контракт
import связность_независимого_журнала as связь


def область():
    # Прежняя версия тоже исполняется: RED показывает лишнюю работу, а не ImportError.
    return getattr(контракт, 'область_чистых_проверок', nullcontext)()


class ЧистыеПроверкиМетаданных(unittest.TestCase):
    def счётчик_путей(self):
        прежний = контракт.PurePosixPath
        вызовы = []
        def разобрать(значение):
            вызовы.append(значение)
            return прежний(значение)
        return вызовы, patch.object(контракт, 'PurePosixPath', разобрать)

    def test_один_разбор_каждого_повторного_пути_в_области(self):
        вызовы, счётчик = self.счётчик_путей()
        with счётчик, область():
            for _ in range(4):
                контракт.путь(значение='Журнал/пример/запрос.md')
                контракт.путь(значение='Журнал/пример/отчёт.md')
        self.assertEqual(вызовы, ['Журнал/пример/запрос.md', 'Журнал/пример/отчёт.md'])

    def test_повторная_строка_не_повторяет_посимвольный_цикл(self):
        прежний = builtins.ord
        вызовы = []
        def код(знак):
            вызовы.append(знак)
            return прежний(знак)
        значение = 'метаданные' * 50
        with patch.object(builtins, 'ord', код), область():
            for _ in range(4):
                контракт.строка(значение=значение)
        self.assertEqual(len(вызовы), 2 * len(значение))

    def test_новая_вложенная_и_внешняя_проверки_остаются_свежими(self):
        вызовы, счётчик = self.счётчик_путей()
        with счётчик:
            with область():
                контракт.путь('пример'); контракт.путь('пример')
                with область():
                    контракт.путь('пример'); контракт.путь('пример')
                контракт.путь('пример')
            with область():
                контракт.путь('пример')
            контракт.путь('пример'); контракт.путь('пример')
        self.assertEqual(вызовы, ['пример'] * 5)

    def test_лимит_не_вызывает_неограниченного_накопления(self):
        вызовы, счётчик = self.счётчик_путей()
        with patch.object(контракт, '_ПРЕДЕЛ_ЧИСТЫХ_ЗНАЧЕНИЙ', 2, create=True), счётчик, область():
            for имя in ('а', 'б', 'в', 'а', 'б', 'в'):
                контракт.путь(имя)
        self.assertEqual(вызовы, ['а', 'б', 'в', 'в'])

    def test_ошибка_пути_не_сохраняется_как_успех(self):
        вызовы, счётчик = self.счётчик_путей()
        ошибки = []
        with счётчик, область():
            for _ in range(2):
                try:
                    контракт.путь('а//б')
                except ValueError as ошибка:
                    ошибки.append(ошибка)
            контракт.путь('а/б'); контракт.путь('а/б')
        self.assertEqual([str(о) for о in ошибки], ['неверный относительный путь'] * 2)
        self.assertIsNot(ошибки[0], ошибки[1])
        self.assertEqual(вызовы, ['а//б', 'а//б', 'а/б'])

    def test_интерфейс_типы_и_границы_UTF8_сохранены(self):
        class Нехешируемый:
            def __hash__(self):
                raise AssertionError('Неверный тип не должен попадать в кэш')
        class Подкласс(str):
            pass
        with область():
            for значение in (None, False, 0, [], {}, Нехешируемый(), Подкласс('а')):
                for функция in (контракт.строка, контракт.путь):
                    with self.assertRaisesRegex(ValueError, '^неверная строка метаданных$'):
                        функция(значение=значение)
            for значение in ('а' * 512, 'a' * 1024, '🚀' * 256, 'а\u0085б', 'а\u2028б'):
                self.assertIsNone(контракт.строка(значение=значение))
            for значение in ('', 'а' * 513, 'a' * 1025, '🚀' * 257, 'а\nб', 'а\x7fб'):
                with self.assertRaisesRegex(ValueError, '^неверная строка метаданных$'):
                    контракт.строка(значение=значение)
            for значение in ('пример', 'а/б', '.'):
                self.assertIsNone(контракт.путь(значение=значение))
            абсолютный = (Path(tempfile.gettempdir()) / 'пример').as_posix()
            for значение in (абсолютный, 'а//б', 'а/./б', 'а/../б', 'а/', 'а' + chr(92) + 'б', 'а' + chr(58) + 'б'):
                with self.assertRaisesRegex(ValueError, '^неверный относительный путь$'):
                    контракт.путь(значение=значение)

    def test_все_кодовые_точки_Unicode_сохраняют_исходный_контракт(self):
        with область():
            for код in range(0x110000):
                значение = chr(код)
                if 0xD800 <= код <= 0xDFFF:
                    with self.assertRaises(UnicodeEncodeError):
                        контракт.строка(значение)
                elif код < 32 or код == 127:
                    with self.assertRaisesRegex(ValueError, '^неверная строка метаданных$'):
                        контракт.строка(значение)
                else:
                    self.assertIsNone(контракт.строка(значение))

    def test_две_одновременные_области_не_делят_кэш(self):
        вызовы, счётчик = self.счётчик_путей()
        барьер = threading.Barrier(2, timeout=5)
        def работник():
            with область():
                контракт.путь('одинаковый-путь')
                барьер.wait()
                контракт.путь('одинаковый-путь')
        with счётчик, ThreadPoolExecutor(max_workers=2) as исполнители:
            задания = [исполнители.submit(работник) for _ in range(2)]
            for задание in задания:
                задание.result(timeout=10)
        self.assertEqual(вызовы, ['одинаковый-путь'] * 2)

    def test_производственный_proof_создаёт_область_и_возвращает_исходную_ошибку(self):
        исходная = ValueError('адресный отказ до чтения живого слоя')
        def первый_барьер(*args):
            контракт.путь('пример'); контракт.путь('пример')
            raise исходная
        вызовы, счётчик = self.счётчик_путей()
        with счётчик, patch.object(связь, 'сверить_привязку', первый_барьер):
            try:
                связь.доказательство_слоя({'привязка_журнала': {}})
            except ValueError as ошибка:
                self.assertIs(ошибка, исходная)
            else:
                self.fail('Исходный отказ потерян')
            контракт.путь('пример'); контракт.путь('пример')
        self.assertEqual(вызовы, ['пример'] * 3)


class ВыходПрофиля(unittest.TestCase):
    def test_выход_не_перезаписывает_существующее_и_не_попадает_в_Git(self):
        from профиль_чистых_проверок_метаданных import проверить_выход
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            существующий = корень / 'существующий'
            существующий.write_bytes(b'original')
            with self.assertRaises(ValueError):
                проверить_выход(существующий, корень / 'вход')
            self.assertEqual(существующий.read_bytes(), b'original')
            for имя, bare in (('checkout', False), ('bare', True)):
                каталог = корень / имя; каталог.mkdir()
                if bare:
                    (каталог / 'HEAD').write_text('ref: refs/heads/main\n')
                    (каталог / 'objects').mkdir()
                else:
                    (каталог / '.git').mkdir()
                with self.assertRaises(ValueError):
                    проверить_выход(каталог / 'выход', корень / 'вход')
                self.assertFalse((каталог / 'выход').exists())

    def test_выход_не_совпадает_с_будущим_входом(self):
        from профиль_чистых_проверок_метаданных import проверить_выход
        with tempfile.TemporaryDirectory() as временный:
            путь = Path(временный).resolve() / 'ещё-не-создан'
            with self.assertRaisesRegex(ValueError, 'должны различаться'):
                проверить_выход(путь, путь)
            self.assertFalse(путь.exists())


if __name__ == '__main__':
    unittest.main()
