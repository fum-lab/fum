"""Полный bound процесс и отдельный читающий повтор настоящего Creator."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import unittest
from unittest.mock import patch

import test_смены_незапечатанной_подготовки as основа

КОРЕНЬ = Path(__file__).resolve().parents[3]
ПРЕФИКС = 'Инструменты/fum-svyaznostj-rabochej-sessii/'
BOOT = ПРЕФИКС + 'scripts/запуск_принятого_писателя.py'
ENGINE = ПРЕФИКС + 'scripts/исполнение_принятого_кода.py'
СОСТАВ = ПРЕФИКС + 'состав-принятого-писателя.json'
_spec = importlib.util.spec_from_file_location('свежесть_фикстуры_запуска',
    КОРЕНЬ / 'Инструменты/fum-svezhestj-markdown/scripts/update-md-recency.py')
свежесть = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = свежесть
_spec.loader.exec_module(свежесть)
база = основа.основа.исходные.обычная.база


class ПолнаяФикстура(база.СозданиеКоммита):
    """Metadata создаётся до базовых Git-коммитов; checker не подменяется."""
    def гит(сам, *аргументы):
        if аргументы[0] == 'commit':
            память = сам.корень / 'Глоссарий/память-FUM.md'
            if not память.exists():
                память.parent.mkdir()
                память.write_text('# Память FUM\n\nОткрытая синтетическая память Git-фикстуры.\n')
                super().гит('add', '--', str(память.relative_to(сам.корень)))
            tracked = set(super().гит('ls-files', '-z').split('\0'))
            итог = свежесть.update_repository(сам.корень, check=False)
            if итог.errors: raise ValueError(итог.errors)
            пути = [str(п.relative_to(сам.корень)) for п in итог.changed_paths]
            пути = [п for п in пути if п in tracked or п == 'Индексы/markdown-файлы-по-времени-редактирования.md']
            if пути: super().гит('add', '--', *пути)
        return super().гит(*аргументы)


def байты(объект):
    return (json.dumps(объект, ensure_ascii=False, sort_keys=True) + '\n').encode()


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


class ЗапускПисателя(unittest.TestCase):
    def setUp(сам):
        сам.ф = основа.СменаПодготовки('runTest')
        with patch.object(база, 'СозданиеКоммита', ПолнаяФикстура):
            сам.ф.setUp()
        сам.addCleanup(сам.ф.doCleanups)
        сам.операция = сам.ф.ф
        сам.с = сам.операция.с
        сам.Q = сам.с.ф.каталог / 'принятый-код'; сам.Q.mkdir()
        состав = json.loads((КОРЕНЬ / СОСТАВ).read_bytes())
        for имя in [*состав['код'], *состав['ресурсы'], BOOT, ENGINE, СОСТАВ]:
            цель = сам.Q / имя; цель.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(КОРЕНЬ / имя, цель)
        сам.гит('init', '-q'); сам.гит('config', 'gc.auto', '0')
        сам.гит('config', 'maintenance.auto', 'false')
        сам.гит('config', 'user.name', 'Открытая фикстура')
        сам.гит('config', 'user.email', 'fixture@example.invalid')
        сам.гит('add', '.'); сам.гит('commit', '-qm', 'Конечный принятый код')
        сам.q = сам.гит('rev-parse', 'HEAD').strip()
        сам.вход = сам.с.приватный('bound-вход.json', сам.с.вход)
        сам.настройки = {
            'схема': 'fum.запуск-принятого-писателя.1',
            'код': {'корень': str(сам.Q), 'коммит': сам.q},
            'данные': {'корень': str(сам.с.корень), 'коммит': сам.с.база, 'пути': ['Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/policy.json']},
            'вход': {'путь': str(сам.вход), 'хэш': хэш(сам.вход.read_bytes())},
            'новые_параметры': сам.ф.запрос['новые_параметры'],
            'проверки': [основа.основа.исходные.обычная.база.ЗАПУСК],
            'готовность': str(основа.писатель.коммит.готовность.КОРЕНЬ_СОСТОЯНИЯ),
            'возраст_проверок': 600,
        }
        сам.манифест = сам.с.приватный('bound-манифест.json', сам.настройки)
        сам.профиль = []

    def гит(сам, *аргументы):
        return subprocess.check_output(['git', '--no-optional-locks', '-C', str(сам.Q), *аргументы], text=True)

    def процесс(сам, режим, *, среда=None):
        начало = time.perf_counter_ns()
        р = subprocess.run([sys.executable, '-I', '-S', '-B', str(сам.Q / BOOT),
            '--корень-кода', str(сам.Q), '--коммит-кода', сам.q,
            '--bootstrap-sha256', хэш((сам.Q / BOOT).read_bytes()),
            '--engine-sha256', хэш((сам.Q / ENGINE).read_bytes()),
            '--манифест', str(сам.манифест), '--sha256', хэш(сам.манифест.read_bytes()),
            '--режим', режим], cwd=сам.с.корень, env=среда, capture_output=True, text=True, timeout=120)
        сам.профиль.append({'режим': режим, 'процесс_нс': time.perf_counter_ns()-начало})
        return р

    def сверить_снимок(сам, до):
        после = сам.операция.снимок()
        изменения = [п for п in sorted(set(до) | set(после)) if до.get(п) != после.get(п)]
        сам.assertFalse(изменения, [(п, [i for i in range(5)
            if до.get(п, (None,)*5)[i] != после.get(п, (None,)*5)[i]]) for п in изменения])

    def test_настоящий_Creator_и_RO_повтор_в_разных_процессах(сам):
        р = сам.процесс('смена')
        сам.assertEqual(0, р.returncode, р.stdout + р.stderr)
        итог = json.loads(р.stdout)
        сам.assertEqual(сам.ф.сохранённые, сам.ф.старые_свидетельства())
        сам.assertEqual('1', сам.с.ф.гит('rev-list', '--count', сам.с.база+'..HEAD').strip())
        до = сам.операция.снимок()
        повтор = сам.процесс('повтор')
        сам.assertEqual(0, повтор.returncode, повтор.stdout + повтор.stderr)
        восстановленный = json.loads(повтор.stdout)
        сам.assertEqual(итог['результат'], восстановленный['результат'])
        сам.assertNotEqual(итог['pid'], восстановленный['pid'])
        сам.сверить_снимок(до)
        сам.assertEqual(0, восстановленный['эффектов'])
        сам.assertEqual(0, восстановленный['API'])

    def test_подмена_принятого_ресурса_отказывает_до_поколения2(сам):
        имя = json.loads((сам.Q / СОСТАВ).read_bytes())['ресурсы'][0]
        (сам.Q / имя).write_bytes('подменено'.encode())
        до = сам.операция.снимок()
        р = сам.процесс('смена')
        сам.assertNotEqual(0, р.returncode)
        сам.assertIn('байты', р.stderr)
        сам.сверить_снимок(до)

    def test_относительный_PATH_отказывает_до_записи(сам):
        до = сам.операция.снимок()
        среда = dict(os.environ, PATH='.' + os.pathsep + os.environ['PATH'])
        р = сам.процесс('смена', среда=среда)
        сам.assertNotEqual(0, р.returncode)
        сам.assertIn('абсолютный непустой PATH', р.stderr)
        сам.сверить_снимок(до)

    def test_пишущая_форма_symbolic_ref_отказывает_до_Popen(сам):
        вход = json.loads((сам.Q / СОСТАВ).read_bytes())['вход']
        код = "import subprocess\nsubprocess.run(['git', '-C', U['корень'], 'symbolic-ref', 'HEAD', 'refs/heads/чужая'])\n"
        (сам.Q / вход).write_text(код)
        сам.гит('add', вход); сам.гит('commit', '-qm', 'Открытая отрицательная фикстура пишущего Git')
        сам.q = сам.гит('rev-parse', 'HEAD').strip()
        сам.настройки['код']['коммит'] = сам.q
        сам.манифест.write_bytes(байты(сам.настройки))
        до = сам.операция.снимок()
        р = сам.процесс('проверка')
        сам.assertNotEqual(0, р.returncode)
        сам.assertIn('пишущий Git в читающем режиме', р.stderr)
        сам.сверить_снимок(до)

    def test_чужой_executable_при_разрешённом_argv_отказывает_до_записи(сам):
        вход = json.loads((сам.Q / СОСТАВ).read_bytes())['вход']
        # Не доверяем argv отдельно от executable: те же аргументы, иной ELF/Mach-O.
        (сам.Q / вход).write_text("import subprocess\nsubprocess.run(команда_проверки, executable='/usr/bin/true')\n")
        сам.гит('add', вход); сам.гит('commit', '-qm', 'Открытая отрицательная фикстура executable')
        сам.q = сам.гит('rev-parse', 'HEAD').strip()
        сам.настройки['код']['коммит'] = сам.q
        сам.манифест.write_bytes(байты(сам.настройки))
        до = сам.операция.снимок()
        р = сам.процесс('смена')
        сам.assertNotEqual(0, р.returncode)
        сам.assertIn('subprocess не входит', р.stderr)
        сам.сверить_снимок(до)

    def test_изменённый_манифест_с_прежним_SHA_не_исполняется(сам):
        # Явный внешний SHA в команде не перепривязывается после порчи.
        старый = хэш(сам.манифест.read_bytes())
        сам.манифест.write_bytes(сам.манифест.read_bytes() + b'\n')
        р = subprocess.run([sys.executable, '-I', '-S', '-B', str(сам.Q / BOOT),
            '--корень-кода', str(сам.Q), '--коммит-кода', сам.q,
            '--bootstrap-sha256', хэш((сам.Q / BOOT).read_bytes()),
            '--engine-sha256', хэш((сам.Q / ENGINE).read_bytes()),
            '--манифест', str(сам.манифест), '--sha256', старый, '--режим', 'смена'],
            cwd=сам.с.корень, capture_output=True, text=True, timeout=20)
        сам.assertNotEqual(0, р.returncode)
        сам.assertIn('манифест', р.stderr)


def load_tests(loader, tests, pattern):
    # Helper наследует fixture API; самостоятельного повторного набора у него нет.
    return loader.loadTestsFromTestCase(ЗапускПисателя)


if __name__ == '__main__':
    unittest.main()
