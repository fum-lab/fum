"""Проверка роли автора перед коммитом на настоящем Git-окружении."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ПУТЬ = Path(__file__).resolve().parents[1] / 'scripts/check-session-coherence.py'
СПЕЦИФИКАЦИЯ = importlib.util.spec_from_file_location('связность_автора', ПУТЬ)
СВЯЗНОСТЬ = importlib.util.module_from_spec(СПЕЦИФИКАЦИЯ)
sys.modules[СПЕЦИФИКАЦИЯ.name] = СВЯЗНОСТЬ
СПЕЦИФИКАЦИЯ.loader.exec_module(СВЯЗНОСТЬ)


class ДопускАвтора(unittest.TestCase):
    def setUp(сам):
        временный = tempfile.TemporaryDirectory()
        сам.addCleanup(временный.cleanup)
        сам.корень = Path(временный.name)
        for аргументы in [('init', '-q'), ('config', 'user.name', 'FUM'), ('config', 'user.email', 'fixture@example.invalid')]:
            subprocess.run(['git', *аргументы], cwd=сам.корень, check=True, capture_output=True)

    def test_точный_автор_и_неизменный_коммиттер(сам):
        снимать = lambda: subprocess.check_output(['git', 'var', 'GIT_COMMITTER_IDENT'], cwd=сам.корень, text=True).split('>')[0]
        до = снимать()
        with mock.patch.dict(os.environ, {'GIT_AUTHOR_NAME': 'FUM Интегратор'}):
            сам.assertEqual([], СВЯЗНОСТЬ.проверить_имя_автора(сам.корень, 'FUM Интегратор'))
        сам.assertEqual(до, снимать())

    def test_повторная_ошибка_пробела_отклоняется(сам):
        with mock.patch.dict(os.environ, {'GIT_AUTHOR_NAME': 'FUMИнтегратор'}):
            ошибки = СВЯЗНОСТЬ.проверить_имя_автора(сам.корень, 'FUM Интегратор')
            сам.assertTrue(ошибки)
            сам.assertIn('не совпадает', ошибки[0])

    def test_ошибка_в_ожидании_не_узаконивает_автора(сам):
        for имя in ('FUMИнтегратор', 'FUM  Интегратор', 'FUM\u00a0Интегратор', 'FUM интегратор', 'FUM Интегратор '):
            with сам.subTest(имя=имя), mock.patch.dict(os.environ, {'GIT_AUTHOR_NAME': имя}):
                сам.assertTrue(СВЯЗНОСТЬ.проверить_имя_автора(сам.корень, имя))

    def test_cli_отказывает_до_чтения_отсутствующего_журнала(сам):
        окружение = {**os.environ, 'GIT_AUTHOR_NAME': 'FUMИнтегратор'}
        ответ = subprocess.run([sys.executable, '-B', str(ПУТЬ), '--repo-root', str(сам.корень), '--request', 'нет.md', '--имя-автора', 'FUM Интегратор'], env=окружение, capture_output=True, text=True)
        сам.assertEqual(1, ответ.returncode)
        сам.assertIn('не совпадает', ответ.stderr)
        сам.assertNotIn('request file', ответ.stderr)

    def test_вне_git_допуск_не_выдаётся(сам):
        with tempfile.TemporaryDirectory() as каталог:
            сам.assertTrue(СВЯЗНОСТЬ.проверить_имя_автора(Path(каталог), 'FUM Интегратор'))

    def test_полное_имя_принимается_и_сравнивается_целиком(сам):
        имя = 'FUM Писатель [gpt-6-astra; effort=max]'
        with mock.patch.dict(os.environ, {'GIT_AUTHOR_NAME': имя}):
            сам.assertEqual([], СВЯЗНОСТЬ.проверить_имя_автора(сам.корень, имя))
            сам.assertTrue(СВЯЗНОСТЬ.проверить_имя_автора(сам.корень, имя.replace('max', 'low')))
            сам.assertTrue(СВЯЗНОСТЬ.проверить_имя_автора(сам.корень, имя.replace('astra', 'luna')))
            сам.assertTrue(СВЯЗНОСТЬ.проверить_имя_автора(сам.корень, 'FUM Писатель'))

    def test_неполные_и_неоднозначные_суффиксы_отклоняются(сам):
        имена = (
            'FUM Писатель [gpt-6-astra; effort=unknown]',
            'FUM Писатель [unknown; effort=max]',
            'FUM Писатель [gpt-6-astra; effort=]',
            'FUM Писатель [gpt-6-astra; effort=max] хвост',
            'FUM Писатель [gpt-6-astra;  effort=max]',
            'FUM Писатель [gpt-6-astra; effort=max\n]',
        )
        for имя in имена:
            with сам.subTest(имя=имя), mock.patch.dict(os.environ, {'GIT_AUTHOR_NAME': имя}):
                сам.assertTrue(СВЯЗНОСТЬ.проверить_имя_автора(сам.корень, имя))
