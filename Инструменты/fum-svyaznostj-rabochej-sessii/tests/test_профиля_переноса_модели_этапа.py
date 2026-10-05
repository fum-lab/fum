"""Проверки достоверности профиля; runtime переноса остаётся прежним."""
import copy
import importlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
профиль = importlib.import_module('профиль_переноса_модели_этапа')
СКРИПТ = Path(профиль.__file__).resolve()


class ЗапрещённоеИнструментирование:
    def object(сам, *аргументы, **параметры):
        raise AssertionError('Профильная подмена вошла в чистый замер')


class ДостоверностьПрофиля(unittest.TestCase):
    def test_чистый_замер_не_устанавливает_счётчики(сам):
        for вариант in ('A', 'B'):
            with сам.subTest(вариант=вариант), patch.object(профиль, 'patch', ЗапрещённоеИнструментирование()):
                итог = профиль.измерить(64*1024, вариант, режим='замер')
                сам.assertEqual('замер', итог['режим'])
                сам.assertIsNone(итог['счётчики'])
                сам.assertGreater(итог['полное_время_нс'], 0)
                сам.assertTrue(итог['исход']['совпадает_с_независимым_полным_импортом'])
                сам.assertTrue(итог['исход']['старые_байты_неизменны'])

    def test_отдельный_счётчик_имеет_тот_же_полный_исход(сам):
        исходы = []
        for вариант in ('A', 'B'):
            замер = профиль.измерить(64*1024, вариант, режим='замер')
            счётчик = профиль.измерить(64*1024, вариант, режим='счётчики')
            сам.assertIsNone(счётчик['полное_время_нс'])
            сам.assertGreater(счётчик['счётчики']['разобрано_строк_JSONL'], 0)
            сам.assertEqual(замер['исход'], счётчик['исход'])
            исходы.append(замер['исход'])
        сам.assertEqual(*исходы)

    def test_любой_занятый_выход_отклоняется_до_работников(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            файл = корень/'файл'; файл.write_bytes('сохранено'.encode())
            папка = корень/'папка'; папка.mkdir()
            ссылка = корень/'ссылка'; ссылка.symlink_to(файл)
            висячая = корень/'висячая'; висячая.symlink_to(корень/'нет')
            очередь = корень/'очередь'; os.mkfifo(очередь)
            for выход in (файл, папка, ссылка, висячая, очередь):
                до = выход.lstat()
                with сам.subTest(тип=выход.name), patch.object(sys, 'argv', [str(СКРИПТ), '--выход', str(выход)]), \
                        patch.object(профиль.subprocess, 'run', side_effect=AssertionError('Запущен работник')) as запуск, \
                        patch.object(sys, 'stderr', io.StringIO()):
                    with сам.assertRaises(SystemExit) as отказ:
                        профиль.главная()
                    сам.assertEqual(2, отказ.exception.code)
                    запуск.assert_not_called()
                после = выход.lstat()
                сам.assertEqual((до.st_ino, до.st_mode, до.st_size, до.st_mtime_ns),
                    (после.st_ino, после.st_mode, после.st_size, после.st_mtime_ns))
            сам.assertEqual('сохранено'.encode(), файл.read_bytes())
            сам.assertEqual(str(корень/'нет'), os.readlink(висячая))

    def test_оптимизация_отклоняется_до_сценария_в_обоих_процессах(сам):
        оболочка = '''import runpy, subprocess, sys
def запрет(*аргументы, **параметры):
    raise RuntimeError("Обнаружен эффект до отказа оптимизации")
subprocess.run = запрет
sys.argv = sys.argv[1:]
runpy.run_path(sys.argv[0], run_name="__main__")
'''
        режимы = [(['-O'], None), (['-OO'], None), ([], '1'), ([], '2')]
        with tempfile.TemporaryDirectory() as каталог:
            for флаги, среда in режимы:
                for вариант in (None, 'A', 'B'):
                    окружение = dict(os.environ)
                    окружение.pop('PYTHONOPTIMIZE', None)
                    if среда is not None:
                        окружение['PYTHONOPTIMIZE'] = среда
                    выход = Path(каталог)/'результат.json'
                    аргументы = ['--выход', str(выход)] if вариант is None else ['--работник', вариант, '--размер', '65536']
                    with сам.subTest(флаги=флаги, среда=среда, вариант=вариант):
                        итог = subprocess.run([sys.executable, '-B', *флаги, '-c', оболочка, str(СКРИПТ), *аргументы],
                            env=окружение, capture_output=True, timeout=20)
                        сам.assertEqual(2, итог.returncode, итог.stderr.decode())
                        сам.assertIn('оптимиза', итог.stderr.decode().lower())
                        сам.assertNotIn('Обнаружен эффект', итог.stderr.decode())
                        сам.assertEqual(b'', итог.stdout)
                        сам.assertFalse(os.path.lexists(выход))

    def test_неверные_выдачи_работника_не_становятся_замерами(сам):
        исходный = профиль.измерить(64*1024, 'A', режим='замер')
        изменения = [({'полное_время_нс': 0}), ({'полное_время_нс': True}),
            ({'полное_время_нс': float('nan')}), ({'режим': 'счётчики'}),
            ({'вариант': 'B'}), ({'новое_неизвестное_поле': True})]
        for добавка in изменения:
            сдвиг = {**copy.deepcopy(исходный), **добавка}
            with сам.subTest(изменение=list(добавка)), сам.assertRaises(ValueError):
                профиль.проверить_выдачу(сдвиг, 64*1024, 'A', 'замер')
        счётчик = профиль.измерить(64*1024, 'A', режим='счётчики')
        счётчик['полное_время_нс'] = 1
        with сам.assertRaises(ValueError):
            профиль.проверить_выдачу(счётчик, 64*1024, 'A', 'счётчики')

    def test_различие_полных_исходов_закрывает_парный_допуск(сам):
        замер = профиль.измерить(64*1024, 'A', режим='замер')
        другой = copy.deepcopy(замер)
        другой['исход']['сообщение_sha256'] = '0'*64
        with сам.assertRaises(ValueError):
            профиль.сверить_исходы(замер, другой)

    def test_гонка_за_выход_отклоняется_до_работников(сам):
        with tempfile.TemporaryDirectory() as каталог:
            выход = Path(каталог)/'выход.json'
            открыть = os.open
            def занять(путь, флаги, режим):
                выход.write_bytes(b'occupied')
                return открыть(путь, флаги, режим)
            with patch.object(sys, 'argv', [str(СКРИПТ), '--выход', str(выход)]), \
                    patch.object(профиль.os, 'open', side_effect=занять), \
                    patch.object(профиль, 'работник', side_effect=AssertionError('Запущен работник')) as запуск, \
                    patch.object(sys, 'stderr', io.StringIO()):
                with сам.assertRaises(SystemExit) as отказ:
                    профиль.главная()
                сам.assertEqual(2, отказ.exception.code)
                запуск.assert_not_called()
            сам.assertEqual(b'occupied', выход.read_bytes())

    def test_отказ_работника_сохраняет_незавершённый_выход(сам):
        with tempfile.TemporaryDirectory() as каталог:
            выход = Path(каталог)/'выход.json'
            with patch.object(sys, 'argv', [str(СКРИПТ), '--выход', str(выход)]), \
                    patch.object(профиль, 'работник', side_effect=ValueError('Отказ сценария')):
                with сам.assertRaisesRegex(ValueError, 'Отказ сценария'):
                    профиль.главная()
            сам.assertEqual({'схема': 'fum.незавершённый-профиль-переноса-модели.1', 'завершён': False},
                json.loads(выход.read_bytes()))

    def test_повреждение_старой_пары_не_становится_истинным_доказательством(сам):
        операция = профиль.операция
        def повредить(фикстура, прежняя, стадия=None):
            результат = операция(фикстура, прежняя, стадия)
            фикстура.пара[0].write_bytes(b'broken')
            return результат
        with patch.object(профиль, 'операция', side_effect=повредить), \
                сам.assertRaisesRegex(ValueError, 'старая пара'):
            профиль.измерить(64*1024, 'B', режим='замер')

    def test_неизвестный_вложенный_исход_отклоняется(сам):
        замер = профиль.измерить(64*1024, 'A', режим='замер')
        for ключ in (None, 'подготовка', 'курсор', 'история', 'модель'):
            другой = copy.deepcopy(замер)
            цель = (другой['исход'] if ключ is None else другой['исход']['подготовка']['модель']
                if ключ == 'модель' else другой['исход'][ключ])
            цель['неизвестное_поле'] = True
            with сам.subTest(ключ=ключ), сам.assertRaises(ValueError):
                профиль.проверить_выдачу(другой, 64*1024, 'A', 'замер')

    def test_необъявленные_узлы_не_теряются_из_эффектов(сам):
        операция = профиль.операция
        for вид in ('ссылка', 'FIFO', 'каталог', 'вложенный-git', 'Git-метаданные'):
            def добавить(фикстура, прежняя, стадия=None):
                результат = операция(фикстура, прежняя, стадия)
                узел = фикстура.корень/'необъявленный-узел'
                if вид == 'ссылка':
                    узел.symlink_to(фикстура.корень/'нет')
                elif вид == 'FIFO':
                    os.mkfifo(узел)
                elif вид == 'каталог':
                    узел.mkdir()
                elif вид == 'вложенный-git':
                    (фикстура.корень/'Журнал/.git').mkdir()
                else:
                    (фикстура.корень/'.git/необъявленный-файл').write_bytes(b'added')
                return результат
            with сам.subTest(вид=вид), patch.object(профиль, 'операция', side_effect=добавить), \
                    сам.assertRaisesRegex(ValueError, 'узел|публичные эффекты'):
                профиль.измерить(64*1024, 'A', режим='замер')

    def test_равное_дробное_число_не_подменяет_целый_исход(сам):
        замер = профиль.измерить(64*1024, 'A', режим='замер')
        другой = copy.deepcopy(замер)
        другой['исход']['байтов_источника'] = float(другой['исход']['байтов_источника'])
        with сам.assertRaises(ValueError):
            профиль.проверить_выдачу(другой, 64*1024, 'A', 'замер')
        with сам.assertRaises(ValueError):
            профиль.сверить_исходы(замер, другой)


if __name__ == '__main__':
    unittest.main()
