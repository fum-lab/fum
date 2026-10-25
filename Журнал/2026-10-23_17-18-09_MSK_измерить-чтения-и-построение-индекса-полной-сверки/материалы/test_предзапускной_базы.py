"""Постановка без требуемого кода не допускает создание новой задачи."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


class ПредзапускнаяБаза(unittest.TestCase):
    @classmethod
    def setUpClass(класс):
        путь = Path(__file__).with_name('предзапускная_база.py')
        описание = importlib.util.spec_from_file_location('предзапускная_база', путь)
        класс.м = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(класс.м)

    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name).resolve()
        self.среда = {к: з for к, з in os.environ.items() if not к.startswith('GIT_')}
        self.среда.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_SYSTEM=os.devnull,
            GIT_AUTHOR_NAME='Фикстура', GIT_AUTHOR_EMAIL='fixture@example.invalid',
            GIT_COMMITTER_NAME='Фикстура', GIT_COMMITTER_EMAIL='fixture@example.invalid')
        self.гит('init', '-q', '--template=')
        self.постановка = b'Finite agreed task\n'
        self.код = b'raise AssertionError("must not execute source")\n'
        self.читатель = b'READER = True\n'
        self.источники = [('код.py', hashlib.sha256(self.код).hexdigest()),
            ('читатель.py', hashlib.sha256(self.читатель).hexdigest())]

    def гит(self, *аргументы, вход=None):
        return subprocess.check_output(['git', '--no-replace-objects',
            '-c', 'core.hooksPath=' + os.devnull, '-C', str(self.корень), *аргументы],
            input=вход, env=self.среда)

    def коммит(self, *, код=True, читатель=True, режим='100644'):
        записи = [('постановка.md', '100644', self.постановка)]
        if код: записи.append(('код.py', режим, self.код))
        if читатель: записи.append(('читатель.py', '100644', self.читатель))
        строки = []
        for имя, мода, сырые in sorted(записи):
            идентификатор = self.гит('hash-object', '-w', '--stdin', вход=сырые).decode().strip()
            строки.append(f'{мода} blob {идентификатор}\t{имя}\n')
        дерево = self.гит('mktree', вход=''.join(строки).encode()).decode().strip()
        return self.гит('commit-tree', дерево, '-m', 'Открытая фикстура').decode().strip()

    def проверить(self, коммит, **поля):
        return self.м.проверить(self.корень, коммит, 'постановка.md',
            поля.get('sha256', hashlib.sha256(self.постановка).hexdigest()),
            поля.get('код', self.источники))

    def test_постановка_и_код_проверяются_в_одном_коммите_без_исполнения(self):
        коммит = self.коммит()
        результат = self.проверить(коммит)
        self.assertEqual(результат['коммит'], коммит)
        self.assertEqual(len(результат['код']), 2)
        self.assertIs(результат['разрешает_запись'], False)

    def test_плановая_ветка_без_кода_отвергается(self):
        with self.assertRaisesRegex(ValueError, 'нет требуемого обычного файла'):
            self.проверить(self.коммит(код=False, читатель=False))

    def test_частичное_кодовое_замыкание_отвергается(self):
        with self.assertRaisesRegex(ValueError, 'нет требуемого обычного файла'):
            self.проверить(self.коммит(читатель=False))

    def test_подмена_постановки_или_кода_отвергается(self):
        коммит = self.коммит()
        with self.assertRaisesRegex(ValueError, 'неверный SHA256'):
            self.проверить(коммит, sha256='0' * 64)
        with self.assertRaisesRegex(ValueError, 'неверный SHA256'):
            self.проверить(коммит, код=[('код.py', '0' * 64)])

    def test_символический_код_и_иной_регистр_отвергаются(self):
        with self.assertRaisesRegex(ValueError, 'нет требуемого обычного файла'):
            self.проверить(self.коммит(режим='120000'))
        with self.assertRaisesRegex(ValueError, 'нет требуемого обычного файла'):
            self.проверить(self.коммит(), код=[('Код.py', self.источники[0][1])])

    def test_сокращённый_oid_и_повторные_пути_отвергаются(self):
        коммит = self.коммит()
        with self.assertRaises(ValueError): self.проверить(коммит[:8])
        with self.assertRaises(ValueError): self.проверить(коммит, код=self.источники * 2)

    def test_полнота_машинной_постановки_не_зависит_от_частичного_argv(self):
        self.постановка = json.dumps({
            'схема': 'fum.постановка-исторической-совместимости.1',
            'обязательные_исходники': [{'путь': п, 'sha256': х} for п, х in self.источники]
        }, ensure_ascii=False).encode()
        коммит = self.коммит()
        with self.assertRaisesRegex(ValueError, 'перечень кода отличается от постановки'):
            self.проверить(коммит, код=self.источники[:1])
        self.assertIs(self.проверить(коммит)['полный_перечень_постановки'], True)

    def test_читающий_detector_не_наследует_global_system_config(self):
        коммит = self.коммит()
        исходный = subprocess.run
        вызовы = []
        def наблюдать(*аргументы, **поля):
            вызовы.append(поля['env'].copy())
            return исходный(*аргументы, **поля)
        with patch.object(self.м.subprocess, 'run', наблюдать):
            self.проверить(коммит)
        self.assertTrue(вызовы)
        for среда in вызовы:
            self.assertEqual(среда.get('GIT_CONFIG_GLOBAL'), os.devnull)
            self.assertEqual(среда.get('GIT_CONFIG_SYSTEM'), os.devnull)


if __name__ == '__main__':
    unittest.main()
