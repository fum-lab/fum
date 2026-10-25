"""Ранний допуск не допускает побочных эффектов скрытого или чужого состояния."""
from pathlib import Path
import os
import tempfile
import unittest
from unittest import mock

from test_proveritj_git_zavisimostj import (
    GitDependencyFixture,
    run_git,
    proveritj_git_zavisimostj as исходный,
)


class ПроверкиРаннегоДопуска(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.фикстура = GitDependencyFixture(Path(сам.временный.name).resolve())

    def test_гит_явно_закрывает_ленивое_получение_и_рекурсию(сам):
        настоящий = исходный.subprocess.run
        вызовы = []

        def наблюдать(*аргументы, **параметры):
            вызовы.append((аргументы[0], параметры['env']))
            return настоящий(*аргументы, **параметры)

        with mock.patch.object(исходный.subprocess, 'run', side_effect=наблюдать):
            исходный.run_git(сам.фикстура.superproject, 'rev-parse', 'HEAD')
        команда, среда = вызовы[0]
        сам.assertEqual('1', среда.get('GIT_NO_LAZY_FETCH'))
        сам.assertIn('--no-lazy-fetch', команда)
        сам.assertIn('submodule.recurse=false', команда)
        сам.assertIn('fetch.recurseSubmodules=false', команда)

    def test_скрытые_флаги_отклоняются_до_получения_и_выбора_ревизии(сам):
        сам.assertEqual([], сам.фикстура.add_dependency())
        зависимость = сам.фикстура.superproject / сам.фикстура.path
        run_git('update-index', '--assume-unchanged', 'README.md', cwd=зависимость)
        файл = зависимость / 'README.md'
        файл.write_text('Скрытое содержимое\n', encoding='utf-8')
        до = файл.read_bytes()
        настоящий = исходный.run_git
        эффекты = []

        def наблюдать(корень, *аргументы, **параметры):
            if аргументы and аргументы[0] in {'fetch', 'checkout', 'submodule'}:
                эффекты.append(аргументы)
            return настоящий(корень, *аргументы, **параметры)

        with mock.patch.object(исходный, 'run_git', side_effect=наблюдать):
            _, ошибки = исходный.initialize_registered_dependency(
                сам.фикстура.superproject, сам.фикстура.path)
        сам.assertTrue(ошибки)
        сам.assertEqual([], эффекты)
        сам.assertEqual(до, файл.read_bytes())

    def test_родительский_путь_не_заменяет_точную_связь_индекса(сам):
        сам.assertEqual([], сам.фикстура.add_dependency())
        ревизия, ошибки = исходный.read_index_gitlink_revision(
            сам.фикстура.superproject, 'Зависимости')
        сам.assertIsNone(ревизия)
        сам.assertTrue(ошибки)


if __name__ == '__main__':
    unittest.main()
