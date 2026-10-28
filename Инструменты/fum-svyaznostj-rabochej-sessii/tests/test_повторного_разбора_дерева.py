"""Повтор чистого разбора не заменяет новые внешние Git-наблюдения."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest
from unittest.mock import patch

КОРЕНЬ = Path(__file__).resolve().parents[3]
for пакет in ('fum-struktura-papok-zaprosov', 'fum-svyaznostj-rabochej-sessii'):
    sys.path.insert(0, str(КОРЕНЬ / 'Инструменты' / пакет / 'scripts'))

import независимый_журнал as журнал
import контракт_независимого_журнала as контракт

ПРИНЯТАЯ_ОСНОВА = '80c4ec0012a2a166d606d27ad762b6416b309e88'


def дерево(объект='1'):
    строки = [
        ('040000', 'tree', объект * 40, 'Журнал'),
        ('100644', 'blob', объект * 40, 'Журнал/README.md'),
    ]
    return b''.join((' '.join(строка[:3]) + '\t' + строка[3]).encode() + b'\0'
                    for строка in строки)


class ПовторныйРазборДерева(unittest.TestCase):
    def прочитать(self, коммит='a' * 40):
        return журнал._дерево_коммита(КОРЕНЬ, коммит)

    def вызов(self, коммит='a' * 40):
        return ((КОРЕНЬ, 'ls-tree', '-r', '-t', '-z', '--full-tree', коммит), {})

    def test_принятое_реальное_дерево_действительно_переиспользует_разбор(self):
        сырые = журнал._гит(КОРЕНЬ, 'ls-tree', '-r', '-t', '-z', '--full-tree', ПРИНЯТАЯ_ОСНОВА)
        with patch.object(журнал, '_гит', return_value=сырые) as гит, \
                patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
            with контракт.область_чистых_проверок():
                self.assertEqual(self.прочитать(), self.прочитать())
            self.assertEqual(структура.call_count, 1)
            self.assertEqual(гит.call_args_list, [self.вызов()] * 2)

    def test_равные_байты_разбираются_один_раз_при_двух_вызовах_Git(self):
        with patch.object(журнал, '_гит', return_value=дерево()) as гит, \
                patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
            with контракт.область_чистых_проверок():
                первый = self.прочитать()
                второй = self.прочитать('b' * 40)
            self.assertEqual(первый, второй)
            self.assertIsNot(первый, второй)
            self.assertEqual(структура.call_count, 1)
            self.assertEqual(гит.call_args_list, [self.вызов(), self.вызов('b' * 40)])

    def test_отказ_Git_после_успеха_сохраняет_исходное_исключение(self):
        ошибки = [ValueError('недоступный объект'), OSError('ошибка чтения'),
                  subprocess.TimeoutExpired('git', 1), KeyboardInterrupt()]
        for ошибка in ошибки:
            with self.subTest(тип=type(ошибка).__name__):
                with patch.object(журнал, '_гит', side_effect=[дерево(), ошибка]) as гит:
                    with контракт.область_чистых_проверок():
                        self.прочитать()
                        with self.assertRaises(type(ошибка)) as пойманная:
                            self.прочитать()
                    self.assertIs(пойманная.exception, ошибка)
                    self.assertEqual(гит.call_args_list, [self.вызов()] * 2)

    def test_изменённые_байты_того_же_OID_проходят_новый_разбор(self):
        with patch.object(журнал, '_гит', side_effect=[дерево(), дерево('2'), дерево('2')]) as гит, \
                patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
            with контракт.область_чистых_проверок():
                первый, второй, третий = (self.прочитать() for _ in range(3))
            self.assertNotEqual(первый, второй)
            self.assertEqual(второй, третий)
            self.assertEqual(структура.call_count, 2)
            self.assertEqual(гит.call_args_list, [self.вызов()] * 3)

    def test_повреждение_после_успеха_не_скрывается(self):
        плохие = [
            дерево() + дерево(),
            дерево() + ('040000 tree ' + '3' * 40 + '\tжурнал\0').encode(),
            дерево().replace(b'100644', b'100755'),
            b'bad\0',
            b'100644 blob ' + b'1' * 40 + b'\t\xff\0',
        ]
        for плохое in плохие:
            with self.subTest(байты=repr(плохое)[:70]):
                with patch.object(журнал, '_гит', return_value=плохое):
                    try:
                        self.прочитать()
                    except (ValueError, UnicodeDecodeError) as исходная:
                        ожидаемое = (type(исходная), исходная.args)
                    else:
                        self.fail('Фикстура должна отклоняться исходным разбором')
                with patch.object(журнал, '_гит', side_effect=[дерево(), плохое]) as гит:
                    with контракт.область_чистых_проверок():
                        self.прочитать()
                        with self.assertRaises(ожидаемое[0]) as пойманная:
                            self.прочитать()
                    self.assertEqual(пойманная.exception.args, ожидаемое[1])
                    self.assertEqual(гит.call_args_list, [self.вызов()] * 2)

    def test_ошибка_структуры_не_кэшируется(self):
        плохое = дерево().replace(b'100644', b'100755')
        with patch.object(журнал, '_гит', return_value=плохое) as гит, \
                patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
            with контракт.область_чистых_проверок():
                for _ in range(2):
                    with self.assertRaises(ValueError):
                        self.прочитать()
            self.assertEqual(структура.call_count, 2)
            self.assertEqual(гит.call_args_list, [self.вызов()] * 2)

    def test_мутация_выданного_словаря_не_меняет_следующий_результат(self):
        with patch.object(журнал, '_гит', return_value=дерево()) as гит, \
                patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
            with контракт.область_чистых_проверок():
                первый = self.прочитать()
                ожидаемое = dict(первый)
                первый.clear()
                второй = self.прочитать()
                второй['новая-запись'] = ('100644', 'blob', 'f' * 40)
                self.assertEqual(self.прочитать(), ожидаемое)
            self.assertEqual(структура.call_count, 1)
            self.assertEqual(гит.call_args_list, [self.вызов()] * 3)

    def test_новая_область_и_вызовы_вне_области_не_переиспользуют_старый_кэш(self):
        with patch.object(журнал, '_гит', return_value=дерево()) as гит, \
                patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
            self.прочитать(); self.прочитать()
            with контракт.область_чистых_проверок():
                self.прочитать(); self.прочитать()
            self.прочитать()
            with контракт.область_чистых_проверок():
                self.прочитать(); self.прочитать()
            self.assertEqual(структура.call_count, 5)
            self.assertEqual(гит.call_args_list, [self.вызов()] * 7)

    def test_вложенная_область_восстанавливает_внешнюю(self):
        with patch.object(журнал, '_гит', return_value=дерево()) as гит, \
                patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
            with контракт.область_чистых_проверок():
                self.прочитать(); self.прочитать()
                with контракт.область_чистых_проверок():
                    self.прочитать(); self.прочитать()
                self.прочитать()
            self.assertEqual(структура.call_count, 2)
            self.assertEqual(гит.call_args_list, [self.вызов()] * 5)

    def test_предел_байтов_и_числа_записей_возвращает_обычный_разбор(self):
        случаи = [('_ПРЕДЕЛ_СЫРОГО_ДЕРЕВА', len(дерево()) - 1, 2),
                  ('_ПРЕДЕЛ_СЫРОГО_ДЕРЕВА', len(дерево()), 1),
                  ('_ПРЕДЕЛ_ЗАПИСЕЙ_ДЕРЕВА', 1, 2),
                  ('_ПРЕДЕЛ_ЗАПИСЕЙ_ДЕРЕВА', 2, 1)]
        for имя, предел, число in случаи:
            with self.subTest(имя=имя, предел=предел):
                with patch.object(контракт, имя, предел, create=True), \
                        patch.object(журнал, '_гит', return_value=дерево()) as гит, \
                        patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
                    with контракт.область_чистых_проверок():
                        self.assertEqual(self.прочитать(), self.прочитать())
                    self.assertEqual(структура.call_count, число)
                    self.assertEqual(гит.call_args_list, [self.вызов()] * 2)

    def test_потоки_имеют_собственные_области(self):
        барьер = threading.Barrier(2)
        def работа():
            with контракт.область_чистых_проверок():
                первый = self.прочитать()
                барьер.wait(timeout=5)
                self.assertEqual(self.прочитать(), первый)
        with patch.object(журнал, '_гит', return_value=дерево()) as гит, \
                patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
            with ThreadPoolExecutor(max_workers=2) as пул:
                for будущее in [пул.submit(работа) for _ in range(2)]:
                    будущее.result(timeout=10)
            self.assertEqual(структура.call_count, 2)
            self.assertEqual(гит.call_args_list, [self.вызов()] * 4)

    def test_исключение_восстанавливает_внешнюю_область_и_не_оставляет_кэш(self):
        ошибка = ValueError('исходное исключение области')
        with patch.object(журнал, '_гит', return_value=дерево()) as гит, \
                patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
            with self.assertRaises(ValueError) as пойманная:
                with контракт.область_чистых_проверок():
                    self.прочитать()
                    try:
                        with контракт.область_чистых_проверок():
                            self.прочитать()
                            raise ошибка
                    except ValueError as внутренняя:
                        self.assertIs(внутренняя, ошибка)
                    self.прочитать()
                    raise ошибка
            self.assertIs(пойманная.exception, ошибка)
            self.прочитать()
            self.assertEqual(структура.call_count, 3)
            self.assertEqual(гит.call_args_list, [self.вызов()] * 4)

    def test_одинаковые_байты_с_другим_разборщиком_не_переиспользуются(self):
        первый = lambda сырые: {'путь': ('100644', 'blob', '1' * 40)}
        второй = lambda сырые: {'путь': ('100644', 'blob', '2' * 40)}
        with контракт.область_чистых_проверок():
            self.assertNotEqual(контракт.проверенный_разбор_дерева('данные'.encode(), первый),
                                контракт.проверенный_разбор_дерева('данные'.encode(), второй))

    def test_смена_дерева_и_обход_лимита_сохраняют_результаты(self):
        for среднее, число in ((дерево('2'), 3), (дерево('2') + b'\0', 2)):
            with self.subTest(среднее=среднее):
                with patch.object(контракт, '_ПРЕДЕЛ_СЫРОГО_ДЕРЕВА', len(дерево())), \
                        patch.object(журнал, '_гит', side_effect=[дерево(), среднее, дерево()]) as гит, \
                        patch.object(журнал, '_проверить_структуру', wraps=журнал._проверить_структуру) as структура:
                    with контракт.область_чистых_проверок():
                        первый, второй, третий = (self.прочитать() for _ in range(3))
                    self.assertEqual(первый, третий)
                    self.assertNotEqual(первый, второй)
                    self.assertEqual(структура.call_count, число)
                    self.assertEqual(гит.call_args_list, [self.вызов()] * 3)


class БезопасностьПрофиля(unittest.TestCase):
    def test_граница_сохраняет_декоратор_N7_и_точный_прежний_разбор(self):
        from профиль_повторного_разбора_дерева import граница_вариантов
        узел, хэши = граница_вариантов(ПРИНЯТАЯ_ОСНОВА)
        self.assertEqual(узел.name, '_дерево_коммита')
        self.assertEqual(len(хэши), 3)

    def test_выход_не_перезаписывает_файл_и_не_попадает_в_Git(self):
        from профиль_повторного_разбора_дерева import проверить_выход
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            файл = корень / 'существующий'; файл.write_bytes(b'original')
            with self.assertRaises(ValueError):
                проверить_выход(файл, корень / 'вход')
            self.assertEqual(файл.read_bytes(), b'original')
            for имя, голый in (('checkout', False), ('bare', True)):
                каталог = корень / имя; каталог.mkdir()
                if голый:
                    (каталог / 'HEAD').write_text('ref: refs/heads/main\n')
                    (каталог / 'objects').mkdir()
                else:
                    (каталог / '.git').mkdir()
                with self.assertRaises(ValueError):
                    проверить_выход(каталог / 'выход', корень / 'вход')
                self.assertFalse((каталог / 'выход').exists())

    def test_выход_не_совпадает_с_будущим_входом(self):
        from профиль_повторного_разбора_дерева import проверить_выход
        with tempfile.TemporaryDirectory() as временный:
            путь = Path(временный).resolve() / 'будущий'
            with self.assertRaisesRegex(ValueError, 'должны различаться'):
                проверить_выход(путь, путь)
            self.assertFalse(путь.exists())


if __name__ == '__main__':
    unittest.main()
