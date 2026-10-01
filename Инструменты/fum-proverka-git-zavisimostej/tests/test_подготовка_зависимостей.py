"""Общий допуск и подготовка используют настоящие отдельные Git-репозитории."""
import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from test_proveritj_git_zavisimostj import GitDependencyFixture, run_git


def загрузить_подготовку():
    путь = Path(__file__).resolve().parents[1] / 'scripts' / 'подготовка_зависимостей.py'
    описание = importlib.util.spec_from_file_location('подготовка_зависимостей', путь)
    модуль = importlib.util.module_from_spec(описание)
    sys.modules[описание.name] = модуль
    описание.loader.exec_module(модуль)
    return модуль


class ПроверкиОбщейПодготовки(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.фикстура = GitDependencyFixture(Path(сам.временный.name).resolve())
        сам.assertEqual([], сам.фикстура.add_dependency())
        сам.фикстура.publish_dependency_registration()
        клон = сам.фикстура.fresh_clone(recurse_submodules=False)
        сам.корень = сам.фикстура.root / 'собственное-дерево'
        run_git('worktree', 'add', '-b', 'codex/подготовка', str(сам.корень), 'HEAD', cwd=клон)
        сам.модуль = загрузить_подготовку()
        сам.исполнитель = '00000000-0000-0000-0000-000000000001'
        сам.задача = '00000000-0000-0000-0000-000000000002'
        сам.среда = mock.patch.dict(os.environ, {'CODEX_THREAD_ID': сам.исполнитель})
        сам.среда.start()
        сам.addCleanup(сам.среда.stop)

    def test_пустой_каталог_не_получает_ревизию_суперпроекта(сам):
        до = сам.модуль.снять_снимок(сам.корень)
        результат = сам.модуль.проверить_готовность_зависимости(сам.корень, сам.фикстура.path)
        сам.assertFalse(результат['готова'])
        сам.assertEqual('не_материализована', результат['состояние'])
        сам.assertIsNone(результат['фактическая_ревизия'])
        сам.assertEqual('суперпроект', результат['корень_копии'])
        сам.assertEqual(сам.фикстура.first_revision, результат['ревизия_индекса'])
        сам.assertEqual(до, сам.модуль.снять_снимок(сам.корень))

    def test_нет_регистрации_отличается_от_пустого_клона(сам):
        результат = сам.модуль.проверить_готовность_зависимости(сам.корень, 'Зависимости/Неизвестная')
        сам.assertEqual('нет_регистрации', результат['состояние'])
        сам.assertIsNone(результат['фактическая_ревизия'])

    def test_готовая_копия_при_повторе_не_получает_объекты(сам):
        снимок = сам.модуль.снять_снимок(сам.корень)
        результат = сам.модуль.подготовить_зависимости(сам.корень, снимок, сам.исполнитель, сам.задача)
        сам.assertTrue(результат['готова'])
        сам.assertEqual(снимок, сам.модуль.снять_снимок(сам.корень))
        with mock.patch.object(сам.модуль.исходный, 'initialize_registered_dependency',
                               side_effect=AssertionError('повтор init запрещён')):
            повтор = сам.модуль.подготовить_зависимости(сам.корень, снимок, сам.исполнитель, сам.задача)
        сам.assertTrue(повтор['готова'])
        готовность = сам.модуль.проверить_готовность_зависимости(сам.корень, сам.фикстура.path)
        сам.assertTrue(готовность['готова'])
        сам.assertEqual(сам.фикстура.first_revision, готовность['фактическая_ревизия'])

    def test_весь_инвентарь_проверяется_до_первой_инициализации(сам):
        файл = сам.корень / '.gitmodules'
        with файл.open('a') as запись:
            запись.write('\n[submodule "лишняя"]\n\tpath = Зависимости/Лишняя\n'
                         '\turl = https://github.com/unused/Extra.git\n'
                         '\tfumUpstream = https://github.com/source/Extra.git\n')
        run_git('add', '.gitmodules', cwd=сам.корень)
        снимок = сам.модуль.снять_снимок(сам.корень)
        каталог = Path(run_git('rev-parse', '--absolute-git-dir', cwd=сам.корень))
        до = set(каталог.iterdir())
        with mock.patch.object(сам.модуль.исходный, 'initialize_registered_dependency',
                               side_effect=AssertionError('init до допуска')):
            with сам.assertRaises(RuntimeError):
                сам.модуль.подготовить_зависимости(сам.корень, снимок, сам.исполнитель, сам.задача)
        сам.assertEqual(до, set(каталог.iterdir()))

    def test_старый_модуль_в_памяти_не_исполняется(сам):
        import test_proveritj_git_zavisimostj as прежний
        with mock.patch.object(прежний.proveritj_git_zavisimostj, 'run_git',
                               side_effect=AssertionError('чужой загруженный модуль')):
            новый = загрузить_подготовку()
            сам.assertIsNot(новый.исходный, прежний.proveritj_git_zavisimostj)
            итог = новый.проверить_готовность_зависимости(сам.корень, сам.фикстура.path)
        сам.assertEqual('не_материализована', итог['состояние'])

    def test_сдвиг_индекса_закрывает_подготовку_до_записи(сам):
        снимок = сам.модуль.снять_снимок(сам.корень)
        (сам.корень / 'добавка.txt').write_text('Новый индекс\n', encoding='utf-8')
        run_git('add', 'добавка.txt', cwd=сам.корень)
        каталог = Path(run_git('rev-parse', '--absolute-git-dir', cwd=сам.корень))
        до = set(каталог.iterdir())
        with сам.assertRaises(RuntimeError):
            сам.модуль.подготовить_зависимости(сам.корень, снимок, сам.исполнитель, сам.задача)
        сам.assertEqual(до, set(каталог.iterdir()))


if __name__ == '__main__':
    unittest.main()
