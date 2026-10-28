"""Один вызов переиспользует чистые значения, но заново проверяет живой слой."""
from contextlib import nullcontext
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_независимой_контрольной_точки as фикстура
import test_слияния_независимых_журналов as слияние
import контракт_независимого_журнала as контракт


class ЧистаяОбластьСверки(unittest.TestCase):
    def setUp(self):
        self.р = фикстура.РеальныйНезависимыйСоздатель()
        self.р.setUp()
        self.addCleanup(self.р.doCleanups)

    def вызов(self):
        return self.р.м.сверить_независимый_журнал(
            self.р.п, self.р.выбранный)

    def наблюдение(self, *, без_переиспользования=False):
        разбор = self.р.ж._разобрать_дерево_коммита
        путь = контракт.PurePosixPath
        процесс = subprocess.run
        argv = []

        def внешний(*args, **kwargs):
            команда = args[0] if args else kwargs['args']
            argv.append(tuple(str(x) for x in команда))
            return процесс(*args, **kwargs)

        область = (patch.object(контракт, 'область_чистых_проверок', nullcontext)
            if без_переиспользования else nullcontext())
        with область, patch.object(self.р.ж, '_разобрать_дерево_коммита',
                wraps=разбор) as разбирали, patch.object(контракт,
                'PurePosixPath', wraps=путь) as пути, \
                patch.object(subprocess, 'run', внешний):
            результат = self.вызов()
        return результат, argv, разбирали.call_count, пути.call_count

    def test_меньше_чистых_разборов_при_прежних_результате_и_argv(self):
        прежде = self.наблюдение(без_переиспользования=True)
        теперь = self.наблюдение()
        повтор = self.наблюдение()
        self.assertEqual(прежде[:2], теперь[:2])
        self.assertEqual(теперь, повтор)
        self.assertLess(теперь[3], прежде[3])
        self.assertLessEqual(теперь[2], прежде[2])
        self.assertIsNone(контракт._ЧИСТЫЕ_ПРОВЕРКИ.get())

    def отказ_после_первого_контракта(self, изменить, вернуть, *, прежний=False):
        команды = self.р.м.команды
        границ = []

        def граница(*args, **kwargs):
            результат = команды(*args, **kwargs)
            границ.append(True)
            изменить()
            return результат

        область = (patch.object(контракт, 'область_чистых_проверок', nullcontext)
            if прежний else nullcontext())
        try:
            with область, patch.object(self.р.м, 'команды', граница):
                with self.assertRaises(ValueError) as ошибка:
                    self.вызов()
            self.assertEqual([True], границ)
            self.assertIsNone(контракт._ЧИСТЫЕ_ПРОВЕРКИ.get())
            return type(ошибка.exception), ошибка.exception.args
        finally:
            вернуть()

    def test_смена_байтов_и_режима_после_прогрева_даёт_прежний_отказ(self):
        имя = next(n for n in self.р.прежние if n.endswith('/' + 'запрос.md'))
        файл = self.р.ф.корень / имя
        сырые = файл.read_bytes()
        режим = файл.stat().st_mode & 0o777
        варианты = (
            (lambda: файл.write_bytes(сырые + b'\n'), lambda: файл.write_bytes(сырые)),
            (lambda: файл.chmod(0o600), lambda: файл.chmod(режим)),
        )
        for изменить, вернуть in варианты:
            with self.subTest(режим=изменить):
                прежде = self.отказ_после_первого_контракта(изменить, вернуть, прежний=True)
                теперь = self.отказ_после_первого_контракта(изменить, вернуть)
                self.assertEqual(прежде, теперь)

    def test_другой_HEAD_с_тем_же_деревом_по_прежнему_отклоняется(self):
        # Именно merge-контракт повторно сверяет живых родителей.
        # Обычная сверка Журнала не заменяет общий HEAD-guard Creator.
        стенд = слияние.СлияниеНезависимыхЖурналов()
        self.addCleanup(стенд.doCleanups)
        self.р, _ = стенд.новая()
        гит = self.р.ф.гит
        прежний = гит('rev-parse', 'HEAD').strip()
        дерево = гит('rev-parse', 'HEAD^{tree}').strip()
        новый = гит('commit-tree', дерево, '-p', прежний,
            '-m', 'Открытая фикстура дрейфа HEAD при том же дереве').strip()

        def изменить():
            гит('update-ref', 'HEAD', новый, прежний)

        def вернуть():
            гит('update-ref', 'HEAD', прежний, новый)

        прежде = self.отказ_после_первого_контракта(изменить, вернуть, прежний=True)
        теперь = self.отказ_после_первого_контракта(изменить, вернуть)
        self.assertEqual(прежде, теперь)

    def test_исходное_исключение_и_внешняя_область_сохраняются(self):
        исходная = ValueError('Открытый отказ после первого контракта')
        with контракт.область_чистых_проверок():
            внешняя = контракт._ЧИСТЫЕ_ПРОВЕРКИ.get()
            with patch.object(self.р.м, 'команды', side_effect=исходная):
                with self.assertRaises(ValueError) as ошибка:
                    self.вызов()
            self.assertIs(исходная, ошибка.exception)
            self.assertIs(внешняя, контракт._ЧИСТЫЕ_ПРОВЕРКИ.get())
        self.assertIsNone(контракт._ЧИСТЫЕ_ПРОВЕРКИ.get())

    def test_прежний_маршрут_не_создаёт_новой_области(self):
        with patch.object(контракт, 'область_чистых_проверок',
                side_effect=AssertionError('Прежний маршрут не должен входить в область')):
            self.assertIsNone(self.р.м.сверить_независимый_журнал(
                {'схема': 'fum.создание-коммита.5'}, None))


class ГраницаПарногоПрофиля(unittest.TestCase):
    ОСНОВА = 'c18ce285bafe5589fb5f006dfdd4342838905138'

    def test_изменение_разрешённого_Markdown_при_том_же_status_заметно(self):
        import профиль_чистой_области_сверки as профиль
        with фикстура.репозиторий() as ф:
            корень = ф.root.resolve()
            файл = корень / 'снимок.md'
            файл.write_text('Принятая запись.\n')
            файл.chmod(0o644)
            ф.git('add', 'снимок.md')
            ф.git('commit', '-qm', 'Открытая фикстура изменяемой цели')
            файл.write_text('Первое изменение.\n')
            параметры = {'разрешённые_цели': ['снимок.md'], 'источники': []}
            with patch.object(профиль, 'КОРЕНЬ', корень):
                до = профиль.снимок(параметры)
                файл.write_text('Второе изменение.\n')
                после = профиль.снимок(параметры)
                self.assertEqual(до['status_sha256'], после['status_sha256'])
                self.assertNotEqual(до['разрешённые_цели'], после['разрешённые_цели'])
                файл.chmod(0o600)
                режим = профиль.снимок(параметры)
                self.assertNotEqual(после['разрешённые_цели'], режим['разрешённые_цели'])

    def test_единственная_область_разрешена_при_прежнем_AST(self):
        import профиль_чистой_области_сверки as профиль
        функция, отпечатки = профиль.граница_вариантов(self.ОСНОВА)
        self.assertEqual('сверить_независимый_журнал', функция.name)
        self.assertEqual({профиль.КОНТРАКТ, профиль.СВЯЗЬ,
            профиль.ЖУРНАЛ, профиль.СОЗДАТЕЛЬ}, set(отпечатки))

    def test_дополнительная_дельта_создателя_или_зависимости_отклоняется(self):
        import профиль_чистой_области_сверки as профиль
        прочитать = Path.read_bytes
        for имя in (профиль.СОЗДАТЕЛЬ, профиль.КОНТРАКТ):
            with self.subTest(путь=имя):
                def подмена(путь):
                    сырые = прочитать(путь)
                    if путь == профиль.КОРЕНЬ / имя:
                        return сырые + '\nлишняя_дельта_профиля = 1\n'.encode()
                    return сырые
                with patch.object(Path, 'read_bytes', подмена), \
                        self.assertRaisesRegex(ValueError, 'изменён|Изменена'):
                    профиль.граница_вариантов(self.ОСНОВА)


if __name__ == '__main__':
    unittest.main()
