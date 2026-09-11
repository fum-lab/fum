"""Проверки переносимости исходников и запуска runner без живого приложения."""
import json
import importlib.util
import hashlib
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import tempfile
import unittest

ПРИЛОЖЕНИЕ = Path(__file__).resolve().parents[1]


class ПроверкиАдаптации(unittest.TestCase):
    def test_манифест_сохраняет_39_исходных_и_все_новые_файлы(self):
        манифест = json.loads((ПРИЛОЖЕНИЕ / 'манифест-переноса.json').read_text())
        self.assertEqual(39, len(манифест['файлы']))
        self.assertEqual(39, len({запись['источник'] for запись in манифест['файлы']}))
        назначения = set()
        for запись in манифест['файлы'] + манифест['новые_файлы']:
            имя = запись['назначение']
            self.assertNotIn(имя, назначения)
            назначения.add(имя)
            self.assertFalse(Path(имя).is_absolute())
            self.assertNotIn('..', Path(имя).parts)
            путь = ПРИЛОЖЕНИЕ / имя
            self.assertFalse(путь.is_symlink())
            self.assertEqual(запись['конечный_sha256'], hashlib.sha256(путь.read_bytes()).hexdigest(), имя)
            self.assertEqual(запись['конечный_режим'], '100755' if путь.stat().st_mode & 0o111 else '100644', имя)
        фактические = {str(путь.relative_to(ПРИЛОЖЕНИЕ)) for путь in ПРИЛОЖЕНИЕ.rglob('*')
                      if путь.is_file() and путь.name != 'манифест-переноса.json' and '__pycache__' not in путь.parts}
        self.assertEqual(назначения, фактические)

    def test_исходники_не_зависят_от_машинного_checkout(self):
        нарушения = []
        for путь in ПРИЛОЖЕНИЕ.rglob('*'):
            if not путь.is_file() or путь.suffix not in {'.swift', '.h', '.c', '.plist', '.pbxproj', '.sh', '.md'}:
                continue
            if re.search(r'/(?:Users|home)/[^/\s]+/|/opt/' + 'homebrew', путь.read_text()):
                нарушения.append(str(путь.relative_to(ПРИЛОЖЕНИЕ)))
        self.assertEqual([], нарушения)

    def test_mpv_объявлен_системной_зависимостью(self):
        манифест = (ПРИЛОЖЕНИЕ / 'Package.swift').read_text()
        self.assertIn('pkgConfig: "mpv"', манифест)
        self.assertIn('.systemLibrary(', манифест)
        self.assertIn('#include <mpv/client.h>', (ПРИЛОЖЕНИЕ / 'Sources/CMpvShim/include/CMpvShim.h').read_text())

    def test_шаблоны_не_предполагают_системных_каталогов(self):
        for путь in sorted((ПРИЛОЖЕНИЕ / 'script').glob('*.sh')):
            текст = '\n'.join(путь.read_text().splitlines()[1:])
            self.assertNotIn('$' + 'HOME', текст, путь.name)
            self.assertNotIn('/usr/' + 'bin/', текст, путь.name)
            self.assertNotIn('/usr/' + 'libexec/', текст, путь.name)

    def test_преобразование_публичного_шаблона_сохраняет_shebang(self):
        описание = importlib.util.spec_from_file_location('адаптация', ПРИЛОЖЕНИЕ / 'сценарии/адаптировать-пути.py')
        модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(модуль)
        исходный = '#!/usr/bin/env bash\n'
        исходный += '/usr/bin/plutil '
        исходный += '"$HOME/Library/LaunchAgents/a.plist"\n'
        результат = модуль.публичный_шаблон(исходный)
        self.assertTrue(результат.startswith('#!/usr/bin/env bash\nplutil '))
        self.assertIn('FUM_LAUNCH_AGENTS_DIR', результат)
        self.assertEqual(результат, модуль.публичный_шаблон(результат))

    def test_launchd_хранится_как_неприменённый_шаблон(self):
        for путь in sorted((ПРИЛОЖЕНИЕ / 'launchd').glob('*.plist')):
            with self.subTest(путь=путь.name):
                данные = plistlib.loads(путь.read_bytes())
                self.assertEqual('${FUM_RUNTIME_ROOT}', данные['WorkingDirectory'])
                self.assertTrue(данные['StandardOutPath'].startswith('${FUM_RUNTIME_ROOT}/'))

    def test_установщики_закрыты_до_внешнего_действия(self):
        for путь in sorted((ПРИЛОЖЕНИЕ / 'script').glob('install_*.sh')):
            with self.subTest(путь=путь.name):
                строки = путь.read_text().splitlines()
                self.assertIn('Неприменённый шаблон', строки[1])
                self.assertEqual('exit 2', строки[2])

    def test_runner_собирает_свой_пакет_из_чужого_cwd(self):
        with tempfile.TemporaryDirectory(prefix='fum-runner-') as каталог:
            временный = Path(каталог)
            команды = временный / 'commands'
            команды.mkdir()
            сборка = временный / 'build with spaces'
            прежний = сборка / 'release/fum-mcp'
            прежний.parent.mkdir(parents=True)
            прежний.write_text('#!/bin/sh\nprintf stale\n')
            прежний.chmod(0o755)
            журнал = временный / 'argv.json'
            компилятор = команды / 'swift'
            компилятор.write_text('#!' + sys.executable + '\n' + '''import json, os, pathlib, sys
аргументы = sys.argv[1:]
pathlib.Path(os.environ['FUM_TEST_ARGV']).write_text(json.dumps(аргументы))
корень = pathlib.Path(аргументы[аргументы.index('--scratch-path') + 1])
цель = корень / 'release/fum-mcp'
цель.parent.mkdir(parents=True, exist_ok=True)
цель.write_text('#!/bin/sh\\nprintf "%s" "$FUM_RUNTIME_ROOT"\\n')
цель.chmod(0o755)
''')
            компилятор.chmod(0o755)
            среда = dict(os.environ)
            среда.update(PATH=str(команды) + os.pathsep + среда['PATH'], FUM_TEST_ARGV=str(журнал),
                         FUM_BUILD_ROOT=str(сборка), FUM_RUNTIME_ROOT=str(временный / 'runtime'),
                         FUM_MCP_APP_HELPER=str(временный / 'missing-installed-helper'))
            результат = subprocess.run(['bash', str(ПРИЛОЖЕНИЕ / 'script/fum_mcp.sh')],
                                        cwd=временный, env=среда, capture_output=True, text=True)
            self.assertEqual(0, результат.returncode, результат.stderr)
            аргументы = json.loads(журнал.read_text())
            self.assertEqual(str(ПРИЛОЖЕНИЕ), аргументы[аргументы.index('--package-path') + 1])
            self.assertEqual(str(сборка), аргументы[аргументы.index('--scratch-path') + 1])
            self.assertEqual(среда['FUM_RUNTIME_ROOT'], результат.stdout)
            self.assertFalse((ПРИЛОЖЕНИЕ / '.build').exists())

    def test_shell_синтаксис_без_исполнения(self):
        for путь in sorted((ПРИЛОЖЕНИЕ / 'script').glob('*.sh')):
            with self.subTest(путь=путь.name):
                результат = subprocess.run(['bash', '-n', str(путь)], capture_output=True, text=True)
                self.assertEqual(0, результат.returncode, результат.stderr)

    def test_миграция_отклоняет_выход_манифеста_из_области(self):
        описание = importlib.util.spec_from_file_location('адаптация', ПРИЛОЖЕНИЕ / 'сценарии/адаптировать-пути.py')
        модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(модуль)
        with tempfile.TemporaryDirectory(prefix='fum-manifest-') as каталог:
            временный = Path(каталог)
            with self.assertRaises(ValueError):
                модуль.подготовить(временный, {'схема': 'fum.перенос-исходников.1', 'файлы': [
                    {'источник': '../outside', 'назначение': '../outside', 'sha256': '0' * 64}
                ]})

    def test_миграция_формирует_отчёт_при_относительном_корне(self):
        with tempfile.TemporaryDirectory(prefix='fum-migration-') as каталог:
            временный = Path(каталог)
            записи = []
            for номер in range(39):
                имя = f'Sources/FUMApp/Fixture{номер}.swift'
                назначение = 'Приложения/FUMA/macOS/' + имя
                путь = временный / назначение
                путь.parent.mkdir(parents=True, exist_ok=True)
                байты = b'let fixture = "/fixture/root/run/latest.json"\n'
                путь.write_bytes(байты)
                записи.append({'источник': имя, 'назначение': назначение,
                               'коммит': '39eb66a29c0be6844e73bcb8072e68b914ea7387',
                               'sha256': hashlib.sha256(байты).hexdigest()})
            манифест = временный / 'manifest.json'
            манифест.write_text(json.dumps({'схема': 'fum.перенос-исходников.1', 'файлы': записи}))
            результат = subprocess.run([sys.executable, str(ПРИЛОЖЕНИЕ / 'сценарии/адаптировать-пути.py'),
                '--корень', '.', '--исходный-манифест', str(манифест), '--применить'],
                cwd=временный, capture_output=True, text=True)
            self.assertEqual(0, результат.returncode, результат.stderr)
            отчёт = json.loads(результат.stdout)
            self.assertEqual(39, len(отчёт['изменения']))
            self.assertEqual(назначение, отчёт['изменения'][-1]['путь'])


    def test_runner_явный_helper_не_требует_сборку(self):
        with tempfile.TemporaryDirectory(prefix='fum-installed-fixture-') as каталог:
            временный = Path(каталог)
            помощник = временный / 'helper'
            помощник.write_text('#!' + sys.executable + '\nprint("fixture-installed")\n')
            помощник.chmod(0o755)
            среда = dict(os.environ)
            среда.pop('FUM_BUILD_ROOT', None)
            среда['FUM_MCP_APP_HELPER'] = str(помощник)
            результат = subprocess.run(['bash', str(ПРИЛОЖЕНИЕ / 'script/fum_mcp.sh')],
                                      cwd=временный, env=среда, capture_output=True, text=True)
            self.assertEqual(0, результат.returncode, результат.stderr)
            self.assertEqual('fixture-installed\n', результат.stdout)


if __name__ == '__main__':
    unittest.main()
