"""Настоящие малые Git-фикстуры отдельного обычного consumer."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import threading
import time
import unittest
from unittest.mock import patch

import test_обычной_дочерней_точки as обычная
import test_запуска_принятого_писателя as прежняя

КОРЕНЬ = Path(__file__).resolve().parents[3]
ПРЕФИКС = 'Инструменты/fum-svyaznostj-rabochej-sessii/'
ПУСК = ПРЕФИКС + 'scripts/запуск_принятого_создателя.py'
ВХОД = ПРЕФИКС + 'scripts/вход_принятого_создателя.py'
ДВИЖОК = ПРЕФИКС + 'scripts/исполнение_принятого_кода.py'
СОСТАВ = ПРЕФИКС + 'состав-принятого-писателя.json'
ВАЛИДАТОР_ЗАВИСИМОСТЕЙ = 'Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py'


def байты(значение):
    return (json.dumps(значение, ensure_ascii=False, sort_keys=True) + '\n').encode()


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


class ПринятыйСоздатель(unittest.TestCase):
    def setUp(сам):
        сам.о = обычная.ОбычнаяДочерняяТочка('runTest')
        with patch.object(обычная.база, 'СозданиеКоммита', прежняя.ПолнаяФикстура):
            сам.о.setUp()
        сам.addCleanup(сам.о.doCleanups)
        сам.ф = сам.о.фикстура
        сам.параметры = сам.о.параметры
        индекс = 'Индексы/markdown-файлы-по-времени-редактирования.md'
        сам.о.акт['область'].append(индекс)
        акт = сам.ф.корень / 'Планирование/обычное-поручение.json'
        акт.write_bytes(байты(сам.о.акт))
        сам.ф.гит('add', '--', 'Планирование/обычное-поручение.json')
        сам.ф.гит('commit', '-qm', 'Закрепить состав настоящей фикстуры')
        сам.база = сам.ф.гит('rev-parse', 'HEAD').strip()
        сам.о.выбор.update(коммит=сам.база, sha256=хэш(акт.read_bytes()))
        сам.параметры.update(исходный_коммит=сам.база, родители=[сам.база],
            выбранное_поручение=сам.о.выбор)
        сам.параметры['разрешённые_цели'].append(индекс)
        сам.К = сам.ф.каталог / 'принятый-код'
        сам.К.mkdir()
        состав = json.loads((КОРЕНЬ / СОСТАВ).read_bytes())
        for имя in dict.fromkeys([*состав['код'], *состав['ресурсы'], ПУСК, ВХОД, ДВИЖОК, СОСТАВ,
                                 ВАЛИДАТОР_ЗАВИСИМОСТЕЙ]):
            цель = сам.К / имя
            цель.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(КОРЕНЬ / имя, цель)
        сам.гит('init', '-q')
        сам.гит('config', 'gc.auto', '0')
        сам.гит('config', 'maintenance.auto', 'false')
        сам.гит('config', 'user.name', 'Открытая фикстура')
        сам.гит('config', 'user.email', 'fixture@example.invalid')
        сам.гит('add', '.')
        сам.гит('commit', '-qm', 'Закрепить синтетический принимающий код')
        сам.к = сам.гит('rev-parse', 'HEAD').strip()
        сам.вход = сам.приватный('ordinary-вход.json', сам.параметры)
        сам.выбор = сам.приватный('ordinary-ACT.json', сам.о.выбор)
        сам.профиль = []

    def гит(сам, *аргументы):
        return subprocess.check_output(['git', '--no-optional-locks', '-C', str(сам.К),
            *аргументы], text=True, stderr=subprocess.PIPE)

    def зарегистрировать_вложенную_фикстуру(сам):
        """Настоящий linked W и отдельный leaf; никакой подмены index/READY."""
        первичный = сам.ф.корень
        сам.ф.гит('add', '.')
        сам.ф.гит('commit', '-qm', 'Закрепить исходные данные связанной фикстуры')
        рабочий = сам.ф.каталог / 'собственное-дерево'
        сам.ф.гит('worktree', 'add', '-q', '-b', 'codex/вложенная-фикстура', str(рабочий))
        сам.ф.корень = рабочий
        сам.ф.запрос = рабочий / обычная.база.ЗАПРОС
        (сам.ф.запрос.parent / 'материалы').mkdir(exist_ok=True)
        сам.параметры.update(корень=str(рабочий), ветка='refs/heads/codex/вложенная-фикстура')
        def внешний_гит(где, *аргументы):
            return subprocess.check_output(['git', '--no-optional-locks', '-C', str(где),
                *аргументы], text=True, stderr=subprocess.PIPE).strip()
        исходник = сам.ф.каталог / 'исходник-зависимости'
        исходник.mkdir()
        внешний_гит(исходник, 'init', '-q', '-b', 'master')
        внешний_гит(исходник, 'config', 'user.name', 'Фикстура')
        внешний_гит(исходник, 'config', 'user.email', 'fixture@example.invalid')
        (исходник / 'лист.txt').write_text('Независимая открытая Git-фикстура.\n')
        внешний_гит(исходник, 'add', '.')
        внешний_гит(исходник, 'commit', '-qm', 'Закрепить лист зависимости')
        сам.пин_зависимости = внешний_гит(исходник, 'rev-parse', 'HEAD')
        форк, оригинал, источник = [сам.ф.каталог / имя for имя in
            ('форк.git', 'оригинал.git', 'FUM-источник.git')]
        for откуда, куда in ((исходник, форк), (исходник, оригинал), (первичный, источник)):
            subprocess.run(['git', '-c', 'protocol.file.allow=always', 'clone', '-q', '--bare',
                str(откуда), str(куда)], check=True, capture_output=True)
        сам.ф.гит('remote', 'add', 'origin', str(источник))
        сам.путь_зависимости = 'Зависимости/LinguisticKit'
        сам.ф.гит('-c', 'protocol.file.allow=always', 'submodule', 'add', '-q', '--',
            str(форк), сам.путь_зависимости)
        сам.зависимость = рабочий / сам.путь_зависимости
        внешний_гит(сам.зависимость, 'remote', 'add', 'upstream', str(оригинал))
        внешний_гит(сам.зависимость, 'fetch', '-q', 'upstream')
        внешний_гит(сам.зависимость, 'checkout', '-q', '--detach', сам.пин_зависимости)
        сам.ф.гит('config', '-f', '.gitmodules', 'submodule.' + сам.путь_зависимости +
            '.fumUpstream', str(оригинал))
        сам.ф.гит('add', '.gitmodules', сам.путь_зависимости)
        сам.ф.гит('commit', '-qm', 'Закрепить зарегистрированный gitlink до рождения')
        рождение = сам.ф.гит('rev-parse', 'HEAD').strip()
        сам.о.нативные_записи[0]['payload'].update(cwd=str(рабочий), git={'commit_hash': рождение})
        сам.о.нативные_записи[1]['payload']['cwd'] = str(рабочий)
        сам.о.сохранить_нативный()
        сам.о.акт['ветка'] = сам.параметры['ветка']
        сам.о.акт['постановка']['коммит'] = рождение
        акт = рабочий / 'Планирование/обычное-поручение.json'
        акт.write_bytes(байты(сам.о.акт))
        сам.ф.гит('add', 'Планирование/обычное-поручение.json')
        сам.ф.гит('commit', '-qm', 'Закрепить адресный ACT связанного дерева')
        сам.база = сам.ф.гит('rev-parse', 'HEAD').strip()
        сам.о.выбор.update(коммит=сам.база, sha256=хэш(акт.read_bytes()))
        сам.параметры.update(исходный_коммит=сам.база, родители=[сам.база])
        сам.вход.write_bytes(байты(сам.параметры))
        сам.выбор.write_bytes(байты(сам.о.выбор))
        сам.первичный_сосед = первичный
        сам.служебный = Path(сам.ф.гит('rev-parse', '--absolute-git-dir').strip())
        подготовка = КОРЕНЬ / 'Инструменты/fum-proverka-git-zavisimostej/scripts/подготовка_зависимостей.py'
        команда = [sys.executable, '-B', str(подготовка)]
        снимок = subprocess.run([*команда, 'снимок', '--корень-репозитория', str(рабочий)],
            check=True, capture_output=True)
        файл_снимка = сам.приватный('снимок-зависимости.json', json.loads(снимок.stdout))
        готовность = subprocess.run([*команда, 'подготовить', '--корень-репозитория', str(рабочий),
            '--снимок', str(файл_снимка), '--исполнитель', обычная.ИСПОЛНИТЕЛЬ,
            '--корневая-задача', обычная.база.ЗАДАЧА], capture_output=True)
        сам.assertEqual(0, готовность.returncode, готовность.stderr.decode())
        сам.assertTrue(json.loads(готовность.stdout)['готова'])
        квитанция = сам.служебный / 'fum-подготовка-зависимостей-v1.json'
        сам.выбор_чтения = сам.приватный('выбор-чтения-зависимостей.json', {
            'схема': 'fum.выбор-чтения-зависимостей.1', 'корень': str(рабочий), 'коммит': сам.база,
            'исполнитель': обычная.ИСПОЛНИТЕЛЬ, 'координатор': обычная.база.ЗАДАЧА,
            'описание_sha256': хэш((рабочий / '.gitmodules').read_bytes()),
            'квитанция_sha256': хэш(квитанция.read_bytes()),
            'зависимости': [{'путь': сам.путь_зависимости, 'секция': сам.путь_зависимости,
                'ревизия': сам.пин_зависимости, 'форк': str(форк), 'оригинал': str(оригинал)}]})
        # Внешние staging/preview фикстуры также не обновляют optional D index.
        os.environ['GIT_OPTIONAL_LOCKS'] = '0'

    def test_зарегистрированная_вложенная_копия_проходит_полный_цикл(сам):
        сам.зарегистрировать_вложенную_фикстуру()
        до = сам.неизменяемые_листы()
        сам.цикл()
        сам.сверить_листы(до)

    def сверить_листы(сам, до):
        после = сам.неизменяемые_листы()
        изменённые = [п for п in до.keys() | после.keys() if до.get(п) != после.get(п)]
        сам.assertFalse(изменённые, 'изменённые leaf/peer пути: ' + repr(изменённые))

    def неизменяемые_листы(сам):
        """Bytes/identity D и контроль первичного соседа; общий object store W не замораживается."""
        итог = {}
        служебный = сам.служебный / 'modules' / сам.путь_зависимости
        пути = [*сам.зависимость.rglob('*'), *служебный.rglob('*')]
        пути += [п for п in сам.первичный_сосед.rglob('*') if '.git' not in п.relative_to(сам.первичный_сосед).parts]
        пути += [сам.первичный_сосед / '.git' / имя for имя in ('HEAD', 'index', 'config')]
        for путь in пути:
            с = путь.lstat()
            данные = (путь.read_bytes() if stat.S_ISREG(с.st_mode) else
                os.fsencode(os.readlink(путь)) if stat.S_ISLNK(с.st_mode) else None)
            метка = (с.st_dev, с.st_ino, с.st_mode, с.st_uid, с.st_nlink)
            if not stat.S_ISDIR(с.st_mode):
                метка += (с.st_size, с.st_mtime_ns, с.st_ctime_ns)
            итог[str(путь)] = (метка, данные)
        итог['ссылка_соседа'] = subprocess.check_output(['git', '--no-optional-locks', '-C',
            str(сам.первичный_сосед), 'rev-parse', 'HEAD'])
        return итог

    def отказ_вложенной(сам, **значения):
        до = сам.неизменяемые_листы()
        итог = сам.отказ('подготовить', **значения)
        сам.assertEqual(до, сам.неизменяемые_листы())
        сам.assertEqual('', итог.stdout)
        return итог

    def test_неверные_выбор_регистрация_и_квитанция_зависимости(сам):
        сам.зарегистрировать_вложенную_фикстуру()
        исходный = сам.выбор_чтения.read_bytes()
        for поле, значение in (('корень', str(сам.первичный_сосед)), ('коммит', '0' * 40),
                ('исполнитель', '00000000-0000-0000-0000-000000000099'),
                ('описание_sha256', '0' * 64), ('квитанция_sha256', '0' * 64)):
            with сам.subTest(поле=поле):
                выбор = json.loads(исходный)
                выбор[поле] = значение
                сам.выбор_чтения.write_bytes(байты(выбор))
                сам.отказ_вложенной()
        for поле, значение in (('путь', str(Path('..') / 'чужая')),
                ('путь', str(Path(сам.путь_зависимости) / 'другой')),
                ('секция', 'чужая'), ('ревизия', '0' * 40), ('форк', 'https://example.invalid/другой')):
            with сам.subTest(регистрация=поле, значение=значение):
                выбор = json.loads(исходный)
                выбор['зависимости'][0][поле] = значение
                сам.выбор_чтения.write_bytes(байты(выбор))
                сам.отказ_вложенной()
        сам.выбор_чтения.write_bytes(исходный)
        настройки = сам.настройки('подготовить')
        настройки['зависимости']['sha256'] = '0' * 64
        сам.отказ_вложенной(настройки=настройки)
        квитанция = сам.служебный / 'fum-подготовка-зависимостей-v1.json'
        прежняя = квитанция.read_bytes()
        for поле, значение in (('готова', False), ('схема', 'fum.подготовка-зависимостей.2'),
                ('исполнитель', '00000000-0000-0000-0000-000000000099'),
                ('корневая_задача', '00000000-0000-0000-0000-000000000099'),
                ('снимок', dict(json.loads(прежняя)['снимок'], корень=str(сам.первичный_сосед))),
                ('состояния', {сам.путь_зависимости: 'не_завершена'}), ('события', [])):
            with сам.subTest(квитанция=поле):
                данные = json.loads(прежняя)
                данные[поле] = значение
                квитанция.write_bytes(байты(данные))
                выбор = json.loads(исходный)
                выбор['квитанция_sha256'] = хэш(квитанция.read_bytes())
                сам.выбор_чтения.write_bytes(байты(выбор))
                сам.отказ_вложенной()
        квитанция.write_bytes(прежняя)
        сам.выбор_чтения.write_bytes(исходный)

    def test_опасные_конфигурации_и_неполное_хранилище_отказывают_до_исполнения(сам):
        сам.зарегистрировать_вложенную_фикстуру()
        служебный = сам.служебный / 'modules' / сам.путь_зависимости
        конфиг = служебный / 'config'
        исходный = конфиг.read_bytes()
        отметка = сам.ф.каталог / 'внешний-код-исполнен'
        помощник = сам.ф.каталог / 'помощник'
        помощник.write_text('#!' + shutil.which('sh') + '\ntouch ' + str(отметка) + '\nexit 1\n')
        помощник.chmod(0o700)
        for добавка in ('[include]\n path = ' + str(помощник), '[extensions]\n partialClone = origin',
                '[remote "origin"]\n promisor = true', '[remote "origin"]\n partialCloneFilter = blob:none',
                '[extensions]\n refStorage = reftable'):
            with сам.subTest(конфигурация=добавка):
                конфиг.write_bytes(исходный + ('\n' + добавка + '\n').encode())
                сам.отказ_вложенной()
                сам.assertFalse(отметка.exists())
        конфиг.write_bytes(исходный)
        for имя in ('config.worktree', 'commondir', 'shallow', 'info/grafts', 'objects/info/alternates'):
            with сам.subTest(метаданные=имя):
                путь = служебный / имя
                путь.parent.mkdir(exist_ok=True)
                путь.write_text('[include]\npath = ' + os.devnull + '\n' if имя == 'config.worktree' else 'неполно\n')
                сам.отказ_вложенной()
                путь.unlink()
        указатель = сам.зависимость / '.git'
        прежний = указатель.read_bytes()
        указатель.write_text('gitdir: ' + str(сам.первичный_сосед / '.git') + '\n')
        сам.отказ_вложенной()
        указатель.write_bytes(прежний)
        объект = служебный / 'objects' / сам.пин_зависимости[:2] / сам.пин_зависимости[2:]
        содержимое = объект.read_bytes()
        объект.unlink()
        os.mkfifo(объект)
        начало = time.monotonic()
        итог = сам.отказ_вложенной()
        сам.assertIn('хранилище', итог.stderr)
        сам.assertLess(time.monotonic() - начало, 30)
        объект.unlink()
        объект.write_bytes(содержимое)
        ссылка = служебный / 'refs/remotes/origin/опасная'
        os.mkfifo(ссылка)
        итог = сам.отказ_вложенной()
        сам.assertIn('files ref', итог.stderr)
        ссылка.unlink()

    def test_зависимость_не_исполняет_монитор_хуки_и_фильтры(сам):
        сам.зарегистрировать_вложенную_фикстуру()
        отметка = сам.ф.каталог / 'D-helper-исполнен'
        помощник = сам.ф.каталог / 'D-helper'
        помощник.write_text('#!' + shutil.which('sh') + '\ntouch ' + str(отметка) + '\nexit 1\n')
        помощник.chmod(0o700)
        for поле in ('core.fsmonitor', 'core.hooksPath', 'filter.злой.clean', 'filter.злой.smudge', 'diff.злой.textconv'):
            subprocess.run(['git', '-C', str(сам.зависимость), 'config', поле, str(помощник)], check=True)
        контроль = subprocess.run(['git', '-C', str(сам.зависимость), 'status', '--porcelain'], capture_output=True)
        сам.assertTrue(отметка.exists(), контроль.stderr.decode())
        отметка.unlink()
        сам.маркер_помощника = отметка
        до = сам.неизменяемые_листы()
        сам.цикл()
        сам.assertEqual(до, сам.неизменяемые_листы())
        сам.assertFalse(отметка.exists())

    def test_скрывающий_индекс_грязные_вложенные_и_неотслеживаемые_файлы_отказывают(сам):
        сам.зарегистрировать_вложенную_фикстуру()
        def гит(*аргументы):
            return subprocess.run(['git', '--no-optional-locks', '-C', str(сам.зависимость),
                *аргументы], check=True, capture_output=True)
        лист = сам.зависимость / 'лист.txt'
        исходный = лист.read_bytes()
        метка = лист.stat()
        лист.write_bytes(b'X' * len(исходный))
        os.utime(лист, ns=(метка.st_atime_ns, метка.st_mtime_ns))
        итог = сам.отказ_вложенной()
        сам.assertIn('raw tracked', итог.stderr)
        лист.write_bytes(исходный)
        for флаг, обратный in (('--assume-unchanged', '--no-assume-unchanged'), ('--skip-worktree', '--no-skip-worktree')):
            with сам.subTest(флаг=флаг):
                гит('update-index', флаг, '--', 'лист.txt')
                сам.отказ_вложенной()
                гит('update-index', обратный, '--', 'лист.txt')
        индекс = сам.служебный / 'modules' / сам.путь_зависимости / 'index'
        прежний = индекс.read_bytes()
        гит('update-index', '--add', '--cacheinfo', '160000,' + сам.пин_зависимости + ',вложенная')
        сам.отказ_вложенной()
        индекс.write_bytes(прежний)
        лишний = сам.зависимость / 'посторонний.txt'
        лишний.write_text('не отслеживается\n')
        сам.отказ_вложенной()
        лишний.unlink()

    def test_версия_один_и_вложенные_мутаторы_остаются_закрыты(сам):
        сам.зарегистрировать_вложенную_фикстуру()
        настройки = сам.настройки('подготовить')
        настройки['схема'] = 'fum.запуск-принятого-создателя.1'
        del настройки['зависимости']
        сам.закрепить_пробу('import subprocess\nsubprocess.run(["git", "-C", ' + repr(str(сам.зависимость)) + ', "rev-parse", "HEAD"])\n')
        сам.отказ_вложенной(настройки=настройки)
        исходный = (КОРЕНЬ / ВХОД).read_text().split('import создание_коммита as создатель')[0]
        for хвост in (['write-tree'], ['commit', '--cleanup=verbatim', '--file', сам.параметры['сообщение']],
                ['config', 'user.name', 'Чужой'], ['symbolic-ref', 'HEAD', 'refs/heads/чужая'],
                ['status', '--short'], ['ls-tree', '-r', '-z', 'HEAD'], ['rev-parse', '--git-dir']):
            with сам.subTest(хвост=хвост):
                сам.закрепить_пробу(исходный + '\nimport subprocess\nsubprocess.run(' +
                    repr(['git', '-C', str(сам.зависимость), *хвост]) + ', check=True)\n')
                сам.отказ_вложенной()

    def test_внешний_дрейф_после_допуска_отказывает_перед_следующим_эффектом(сам):
        сам.зарегистрировать_вложенную_фикстуру()
        служебный = сам.служебный / 'modules' / сам.путь_зависимости
        исходный = (КОРЕНЬ / ВХОД).read_text().split('import создание_коммита as создатель')[0]
        цели = [сам.зависимость / '.git', служебный / 'index', сам.зависимость / 'лист.txt',
            служебный / 'config', служебный / 'refs/remotes/upstream/master',
            служебный / 'objects' / сам.пин_зависимости[:2] / сам.пин_зависимости[2:]]
        for номер, цель in enumerate(цели):
            with сам.subTest(цель=цель.name):
                прежний = цель.read_bytes()
                продолжить = сам.ф.каталог / ('барьер-' + str(номер))
                текст = исходный + '\nfrom pathlib import Path\nimport time\n' + \
                    "Path(параметры['сообщение']).write_bytes(b'')\n" + \
                    'срок = time.monotonic() + 20\nwhile not Path(' + repr(str(продолжить)) + ').exists():\n' + \
                    '    if time.monotonic() > срок: raise ValueError("внешний барьер не открыт")\n    time.sleep(0.01)\n' + \
                    "Path(параметры['сообщение']).write_bytes(b'forbidden')\n"
                сам.закрепить_пробу(текст)
                сообщение = Path(сам.параметры['сообщение'])
                ошибки = []
                остановить = threading.Event()
                def внешний_писатель():
                    try:
                        срок = time.monotonic() + 90
                        while not сообщение.exists():
                            if остановить.wait(0.01): return
                            if time.monotonic() > срок:
                                raise AssertionError('startup не дошёл до барьера')
                        if 'objects' in цель.parts:
                            цель.unlink()  # local clone может иметь read-only hardlink object.
                        цель.write_bytes(прежний + b'\n')
                        продолжить.write_bytes(b'open')
                    except Exception as ошибка:
                        ошибки.append(ошибка)
                поток = threading.Thread(target=внешний_писатель, daemon=True)
                до = сам.снимок()
                поток.start()
                try:
                    итог = сам.процесс('подготовить')
                finally:
                    остановить.set()
                    поток.join(timeout=10)
                сам.assertFalse(поток.is_alive())
                сам.assertFalse(ошибки, ошибки)
                сам.assertTrue(сообщение.exists(), итог.stderr)
                сам.assertNotEqual(0, итог.returncode, итог.stdout + итог.stderr)
                сам.assertEqual('', итог.stdout)
                сам.assertIn('dependency', итог.stderr)
                сам.assertEqual(b'', сообщение.read_bytes())
                сам.assertEqual(прежний + b'\n', цель.read_bytes(), 'внешний drift не исправляется consumer')
                сообщение.unlink()
                цель.write_bytes(прежний)
                продолжить.unlink()
                сам.assertEqual(до, сам.снимок())

    def test_внешний_барьер_перед_штатной_готовностью_и_созданием_сохраняет_выходы(сам):
        сам.зарегистрировать_вложенную_фикстуру()
        сам.подготовить()
        исходный = (КОРЕНЬ / ВХОД).read_text()
        лист = сам.зависимость / 'лист.txt'
        конфиг = сам.служебный / 'modules' / сам.путь_зависимости / 'config.worktree'
        for этап in ('готово', 'создать'):
            with сам.subTest(этап=этап):
                if этап == 'создать':
                    сам.закрепить_пробу(исходный)
                    готово = сам.процесс('готово')
                    сам.assertEqual(0, готово.returncode, готово.stderr)
                достигнут = сам.ф.каталог / ('достигнут-' + этап)
                продолжить = сам.ф.каталог / ('продолжить-' + этап)
                вставка = 'Path(' + repr(str(достигнут)) + ").write_bytes(b'')\n" + \
                    'срок = time.monotonic() + 20\nwhile not Path(' + repr(str(продолжить)) + ').exists():\n' + \
                    '    if time.monotonic() > срок: raise ValueError("барьер stock API не открыт")\n    time.sleep(0.01)\n'
                сам.закрепить_пробу(исходный.replace("этап = настройки['этап']", вставка + "\nэтап = настройки['этап']"))
                до = сам.снимок()
                прежний = лист.read_bytes()
                ошибки, после_дрейфа = [], []
                остановить = threading.Event()
                def внешний_писатель():
                    try:
                        срок = time.monotonic() + 90
                        while not достигнут.exists():
                            if остановить.wait(0.01): return
                            if time.monotonic() > срок: raise AssertionError('не достигнут stock барьер')
                        if этап == 'готово':
                            метка = лист.stat()
                            лист.write_bytes(b'Z' * len(прежний))
                            os.utime(лист, ns=(метка.st_atime_ns, метка.st_mtime_ns))
                        else:
                            конфиг.write_text('[core]\nfsmonitor = ' + os.devnull + '\n')
                        после_дрейфа.append(сам.неизменяемые_листы())
                        продолжить.write_bytes(b'open')
                    except Exception as ошибка:
                        ошибки.append(ошибка)
                поток = threading.Thread(target=внешний_писатель, daemon=True)
                поток.start()
                try:
                    итог = сам.процесс(этап)
                finally:
                    остановить.set()
                    поток.join(timeout=10)
                сам.assertFalse(поток.is_alive())
                сам.assertFalse(ошибки, ошибки)
                сам.assertTrue(достигнут.exists(), итог.stderr)
                сам.assertEqual(2, итог.returncode, итог.stdout + итог.stderr)
                сам.assertEqual('', итог.stdout)
                сам.assertEqual(до, сам.снимок())
                сам.assertEqual(после_дрейфа[0], сам.неизменяемые_листы())
                if этап == 'готово': лист.write_bytes(прежний)
                else: конфиг.unlink()
                достигнут.unlink()
                продолжить.unlink()

    def приватный(сам, имя, значение):
        путь = сам.ф.каталог / имя
        путь.write_bytes(байты(значение))
        путь.chmod(0o600)
        return путь

    def настройки(сам, этап):
        подготовка = Path(сам.параметры['подготовка'])
        квитанция = Path(сам.параметры['квитанция'])
        ссылка = lambda путь: {'путь': str(путь), 'sha256': хэш(путь.read_bytes())}
        итог = {'схема': 'fum.запуск-принятого-создателя.1', 'этап': этап,
            'код': {'корень': str(сам.К), 'коммит': сам.к},
            'данные': {'корень': str(сам.ф.корень), 'коммит': сам.база,
                'пути': ['Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/policy.json']},
            'вход': ссылка(сам.вход), 'поручение': ссылка(сам.выбор),
            'подготовка': None if этап == 'подготовить' else ссылка(подготовка),
            'квитанция': ссылка(квитанция) if этап == 'повтор' else None,
            'проверки': [обычная.база.ЗАПУСК],
            'готовность': str(сам.ф.каталог / 'готовность'), 'возраст_проверок': 600}
        if hasattr(сам, 'выбор_чтения'):
            итог.update(схема='fum.запуск-принятого-создателя.2', зависимости=ссылка(сам.выбор_чтения))
        return итог

    def процесс(сам, этап, *, настройки=None, команда=None):
        манифест = сам.приватный('manifest-' + этап + '.json',
            сам.настройки(этап) if настройки is None else настройки)
        аргументы = [sys.executable, '-I', '-S', '-B', str(сам.К / ПУСК),
            '--корень-кода', str(сам.К), '--коммит-кода', сам.к,
            '--bootstrap-sha256', хэш((сам.К / ПУСК).read_bytes()),
            '--engine-sha256', хэш((сам.К / ДВИЖОК).read_bytes()),
            '--манифест', str(манифест), '--sha256', хэш(манифест.read_bytes()), '--этап', этап]
        начало = time.perf_counter_ns()
        процесс = subprocess.run(аргументы if команда is None else команда(аргументы),
            cwd=сам.ф.корень, capture_output=True, text=True, timeout=120)
        if hasattr(сам, 'маркер_помощника'):
            сам.assertFalse(сам.маркер_помощника.exists(), 'helper выполнен непосредственно consumer фазой ' + этап)
        сам.профиль.append({'этап': этап, 'процесс_нс': time.perf_counter_ns() - начало})
        if процесс.returncode == 0:
            ответ = json.loads(процесс.stdout)
            сам.профиль[-1].update(захват_нс=ответ['захват_нс'], вызов_нс=ответ.get('вызов_нс'), исполнитель=ответ['pid'])
            for поле in ('допуск_зависимостей_нс', 'чтений_зависимостей_при_допуске', 'чтений_зависимостей_после_допуска'):
                if поле in ответ:
                    сам.профиль[-1][поле] = ответ[поле]
        return процесс

    def подготовить(сам):
        итог = сам.процесс('подготовить')
        сам.assertEqual(0, итог.returncode, итог.stdout + итог.stderr)
        # Внешние fixture checks/staging не исполняют D monitor и не подменяют
        # среду consumer: context заканчивается до следующего его процесса.
        with patch.dict(os.environ, {'GIT_CONFIG_COUNT': '1',
                'GIT_CONFIG_KEY_0': 'core.fsmonitor', 'GIT_CONFIG_VALUE_0': 'false'}):
            сам.о.проверить_данные()
            результат = прежняя.свежесть.update_repository(сам.ф.корень, check=False)
            сам.assertFalse(результат.errors)
            сам.ф.гит('add', '.')
            сам.ф.отчёты.выполнить_предпросмотр(сам.ф.корень, сам.ф.запрос)
            сам.ф.гит('add', str(Path(обычная.база.ЗАПРОС).parent))

    def цикл(сам):
        сам.подготовить()
        готовность = сам.процесс('готово')
        сам.assertEqual(0, готовность.returncode, готовность.stdout + готовность.stderr)
        файл_готовности = Path(json.loads(готовность.stdout)['результат']['путь'])
        эпоха = json.loads(файл_готовности.read_bytes())['готовность']['готов_в_наносекундах_эпохи']
        первый = сам.процесс('создать')
        сам.assertEqual(0, первый.returncode, первый.stdout + первый.stderr)
        сам.assertEqual(эпоха, json.loads(файл_готовности.read_bytes())['готовность']['готов_в_наносекундах_эпохи'])
        до = {str(п): (п.read_bytes(), п.stat().st_mtime_ns, п.stat().st_ino)
            for п in сам.ф.каталог.rglob('*') if п.is_file() and not п.is_relative_to(сам.К)}
        повтор = сам.процесс('повтор')
        сам.assertEqual(0, повтор.returncode, повтор.stdout + повтор.stderr)
        второй = json.loads(повтор.stdout)
        сам.assertEqual(json.loads(первый.stdout)['результат'], второй['результат'])
        сам.assertEqual(0, второй['эффектов'])
        сам.assertEqual(0, второй['пишущих_процессов'])
        for имя, состояние in до.items():
            п = Path(имя)
            сам.assertEqual(состояние, (п.read_bytes(), п.stat().st_mtime_ns, п.stat().st_ino), имя)
        сам.assertEqual('1', сам.ф.гит('rev-list', '--count', сам.база + '..HEAD').strip())
        return сам.профиль

    def test_настоящие_подготовка_готовность_создание_и_читающий_повтор_квитанции(сам):
        сам.цикл()

    def снимок(сам):
        пути = [Path(сам.параметры[п]) for п in ('сообщение', 'подготовка', 'квитанция', 'кэш_модели')]
        пути += [сам.ф.корень / сам.параметры['история_модели']]
        пути += [п for п in (сам.ф.каталог / 'готовность').rglob('*') if п.is_file()]
        индекс = Path(сам.ф.гит('rev-parse', '--path-format=absolute', '--git-path', 'index').strip())
        return (сам.ф.гит('rev-parse', 'HEAD'), индекс.read_bytes(),
            {str(п): п.read_bytes() if п.exists() else None for п in пути})

    def отказ(сам, этап, **значения):
        до = сам.снимок()
        итог = сам.процесс(этап, **значения)
        сам.assertNotEqual(0, итог.returncode, итог.stdout + итог.stderr)
        сам.assertEqual(до, сам.снимок())
        return итог

    def закрепить_пробу(сам, текст):
        (сам.К / ВХОД).write_text(текст)
        сам.гит('add', '--', ВХОД)
        сам.гит('commit', '-qm', 'Закрепить отрицательную синтетическую пробу')
        сам.к = сам.гит('rev-parse', 'HEAD').strip()

    def test_подменённые_код_манифест_поручение_и_исполнитель_отказывают_до_выходов(сам):
        ресурс = сам.К / 'Инструменты/fum-struktura-papok-zaprosov/шаблоны/запрос.md.шаблон'
        прежний = ресурс.read_bytes()
        ресурс.write_bytes(прежний + b'\n')
        сам.отказ('подготовить')
        ресурс.write_bytes(прежний)
        настройки = сам.настройки('подготовить')
        настройки['поручение']['sha256'] = '0' * 64
        сам.отказ('подготовить', настройки=настройки)
        сам.отказ('подготовить', команда=lambda а: [*а[:-3], '0' * 64, *а[-2:]])
        прежний_выбор = dict(сам.о.выбор)
        сам.о.выбор['sha256'] = '0' * 64
        сам.выбор.write_bytes(байты(сам.о.выбор))
        сам.вход.write_bytes(байты(сам.параметры))
        сам.отказ('подготовить')
        сам.о.выбор.update(прежний_выбор)
        сам.выбор.write_bytes(байты(сам.о.выбор))
        сам.параметры['исполнитель'] = '00000000-0000-0000-0000-000000000099'
        сам.вход.write_bytes(байты(сам.параметры))
        сам.отказ('подготовить')

    def test_лишний_неотслеживаемый_ресурс_не_становится_принятым(сам):
        (сам.К / 'Инструменты/fum-struktura-papok-zaprosov/шаблоны/лишний.шаблон').write_text('Чужой ресурс')
        итог = сам.отказ('подготовить')
        сам.assertIn('ресурс', итог.stderr)

    def test_чужая_ветка_и_индекс_закрыто_отказывают(сам):
        сам.ф.гит('switch', '-qc', 'codex/чужая')
        сам.отказ('подготовить')
        сам.ф.гит('switch', '-q', 'codex/фикстура')
        (сам.ф.корень / 'чужое.txt').write_text('Не назначено')
        сам.ф.гит('add', 'чужое.txt')
        сам.отказ('подготовить')

    def test_субпроцессы_пишущие_формы_гита_и_среда_запрещены(сам):
        пробы = [
            'import subprocess, sys\nsubprocess.run([sys.executable])\n',
            "import os\nos.system('true')\n",
            "import subprocess\nsubprocess.run(['git', '-C', параметры['корень'], 'symbolic-ref', 'HEAD', 'refs/heads/codex/чужая'])\n",
            "import subprocess\nsubprocess.run(['git', '-C', параметры['корень'], 'diff', '--output=' + параметры['сообщение']])\n",
            "import subprocess\nsubprocess.run(['git', '-C', параметры['корень'], 'config', 'user.name', 'Чужой'])\n",
            "import subprocess, os\nsubprocess.run(['git', '-C', параметры['корень'], 'status', '--short'], env=dict(os.environ, GIT_INDEX_FILE=параметры['сообщение']))\n",
            "import subprocess, sys\nsubprocess.run(['git', '-C', параметры['корень'], 'status', '--short'], executable=sys.executable)\n",
            "import subprocess\nsubprocess.run(['git', '-C', параметры['корень'], 'status', '--short'], cwd='/')\n",
        ]
        for текст in пробы:
            with сам.subTest(текст=текст):
                сам.закрепить_пробу(текст)
                сам.отказ('подготовить')

    def test_код_кандидата_не_исполняется_а_свежесть_берётся_из_принятого(сам):
        цель = 'Инструменты/fum-svezhestj-markdown/scripts/update-md-recency.py'
        файл = сам.ф.корень / цель
        файл.parent.mkdir(parents=True)
        отметка = сам.ф.каталог / 'W-исполнен'
        файл.write_text("from pathlib import Path\nPath(__file__).resolve().parents[3].parent.joinpath('W-исполнен').touch()\nraise RuntimeError('W')\n")
        сам.о.акт['область'].append(цель)
        акт = сам.ф.корень / 'Планирование/обычное-поручение.json'
        акт.write_bytes(байты(сам.о.акт))
        сам.ф.гит('add', '--', цель, 'Планирование/обычное-поручение.json')
        сам.ф.гит('commit', '-qm', 'Закрепить W как данные')
        сам.база = сам.ф.гит('rev-parse', 'HEAD').strip()
        сам.о.выбор.update(коммит=сам.база, sha256=хэш(акт.read_bytes()))
        сам.параметры.update(исходный_коммит=сам.база, родители=[сам.база])
        сам.параметры['разрешённые_цели'].append(цель)
        сам.вход.write_bytes(байты(сам.параметры))
        сам.выбор.write_bytes(байты(сам.о.выбор))
        сам.цикл()
        сам.assertFalse(отметка.exists())

    def test_хуки_монитор_и_фильтры_кандидата_не_исполняются(сам):
        сам.подготовить()
        отметка = сам.ф.каталог / 'Git-исполнил-W'
        злой = сам.ф.каталог / 'внешний-код'
        злой.write_text('#!' + shutil.which('sh') + '\ntouch ' + str(отметка) + '\ncat\n')
        злой.chmod(0o700)
        хуки = сам.ф.корень / '.git/hooks'
        хуки.mkdir(exist_ok=True)
        shutil.copyfile(злой, хуки / 'pre-commit')
        (хуки / 'pre-commit').chmod(0o700)
        сам.ф.гит('config', 'core.fsmonitor', str(злой))
        сам.ф.гит('config', 'filter.злой.clean', str(злой))
        сам.ф.гит('config', 'filter.злой.required', 'true')
        (сам.ф.корень / '.git/info/attributes').write_text('данные.txt filter=злой\n')
        for этап in ('готово', 'создать', 'повтор'):
            итог = сам.процесс(этап)
            сам.assertEqual(0, итог.returncode, итог.stdout + итог.stderr)
        сам.assertFalse(отметка.exists())

    def test_поздняя_приватная_запись_отказывает_после_дрейфа(сам):
        текст = (сам.К / ВХОД).read_text()
        вставка = "\nисходный_допуск = сверить_эффект\nизменено = False\ndef проба_допуска():\n    global изменено\n    if not изменено and Path(параметры['сообщение']).exists():\n        изменено = True\n        Path(__file__).write_bytes(Path(__file__).read_bytes() + bytes([10]))\n    исходный_допуск()\nсверить_эффект = проба_допуска\n"
        сам.закрепить_пробу(текст.replace("этап = настройки['этап']", вставка + "\nэтап = настройки['этап']"))
        итог = сам.процесс('подготовить')
        сам.assertNotEqual(0, итог.returncode, итог.stdout + итог.stderr)
        сам.assertEqual(b'', Path(сам.параметры['сообщение']).read_bytes())
        сам.assertFalse(Path(сам.параметры['подготовка']).exists())

    def test_пустая_и_отсутствующая_конфигурация_проверяются_до_гита(сам):
        конфиг = сам.ф.каталог / 'поздний-global-config'
        отметка = сам.ф.каталог / 'поздний-фильтр-исполнен'
        помощник = сам.ф.каталог / 'поздний-фильтр'
        помощник.write_text('#!' + shutil.which('sh') + '\ntouch ' + str(отметка) + '\ncat\n')
        помощник.chmod(0o700)
        (сам.ф.корень / '.git/info/attributes').write_text('данные.txt filter=поздний\n')
        (сам.ф.корень / 'данные.txt').write_text('Изменённые данные для настоящего фильтра\n')
        текст = '[filter "поздний"]\nclean = ' + str(помощник) + '\n'
        сам.закрепить_пробу('import os, subprocess\nfrom pathlib import Path\n'
            + 'Path(os.environ["GIT_CONFIG_GLOBAL"]).write_text(' + repr(текст) + ')\n'
            + "subprocess.run(['git', '-C', параметры['корень'], 'status', '--short'], check=True, capture_output=True)\n")
        for существует in (True, False):
            with сам.subTest(существует=существует):
                конфиг.unlink(missing_ok=True)
                отметка.unlink(missing_ok=True)
                if существует:
                    конфиг.touch()
                with patch.dict(os.environ, GIT_CONFIG_GLOBAL=str(конфиг), GIT_CONFIG_NOSYSTEM='1'):
                    итог = сам.отказ('подготовить')
                сам.assertIn('конфигурац', итог.stderr)
                сам.assertFalse(отметка.exists())

    def test_закрытие_атомарной_записи_не_дописывает_после_отказа(сам):
        текст = (сам.К / ВХОД).read_text()
        вставка = "\nисходный_допуск = сверить_эффект\nизменено = False\ndef проба_допуска():\n    global изменено\n    временные = list(Path(параметры['кэш_модели']).parent.glob('.сообщения-*'))\n    if временные and not изменено:\n        изменено = True\n        Path(__file__).write_bytes(Path(__file__).read_bytes() + bytes([10]))\n    исходный_допуск()\nсверить_эффект = проба_допуска\n"
        сам.закрепить_пробу(текст.replace("этап = настройки['этап']", вставка + "\nэтап = настройки['этап']"))
        итог = сам.процесс('подготовить')
        сам.assertNotEqual(0, итог.returncode)
        остатки = list(сам.ф.каталог.glob('.сообщения-*'))
        сам.assertTrue(остатки)
        сам.assertTrue(all(п.read_bytes() == b'' for п in остатки))
        сам.assertFalse(Path(сам.параметры['кэш_модели']).exists())

    def test_блокировка_проверяет_дрейф_непосредственно_до_эффекта(сам):
        отметка = сам.ф.каталог / 'flock-исполнен'
        сам.закрепить_пробу("import os, fcntl\nfrom pathlib import Path\n"
            'дескриптор = os.open(' + repr(str(отметка)) + ", os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)\n"
            'try:\n    Path(__file__).write_bytes(Path(__file__).read_bytes() + bytes([10]))\n'
            "    fcntl.flock(дескриптор, fcntl.LOCK_EX | fcntl.LOCK_NB)\n    os.write(дескриптор, b'flock')\nfinally:\n    os.close(дескриптор)\n")
        итог = сам.процесс('подготовить')
        сам.assertNotEqual(0, итог.returncode)
        сам.assertEqual(b'', отметка.read_bytes())

    def test_буфер_вывода_не_выходит_при_позднем_отказе(сам):
        сам.закрепить_пробу("from pathlib import Path\nprint('Ложный успешный результат', end='')\n"
            'Path(__file__).write_bytes(Path(__file__).read_bytes() + bytes([10]))\n')
        до = сам.снимок()
        итог = сам.процесс('подготовить')
        сам.assertNotEqual(0, итог.returncode)
        сам.assertEqual('', итог.stdout)
        сам.assertEqual(до, сам.снимок())

    def test_посторонние_компиляция_импорт_и_обход_свежести_запрещены(сам):
        пробы = [
            "compile('pass', str(__import__('pathlib').Path(параметры['корень']) / 'чужой.py'), 'exec')\n",
            "import importlib.util\nimportlib.util.spec_from_file_location('чужой', str(__import__('pathlib').Path(параметры['корень']) / 'чужой.py'))\n",
            "import создание_коммита as с\nошибки = с.связность.validate_md_recency(__import__('pathlib').Path(__file__).parents[3])\nassert not ошибки, ошибки\n",
        ]
        for текст in пробы:
            with сам.subTest(текст=текст):
                сам.закрепить_пробу(текст)
                сам.отказ('подготовить')

    def test_потерянная_повреждённая_и_неполная_квитанция_и_дрейф_модели(сам):
        сам.цикл()
        файл = Path(сам.параметры['квитанция'])
        оригинал = файл.read_bytes()
        квитанция = json.loads(оригинал)
        квитанция['процесс']['исполнение_завершено'] = False
        файл.write_bytes(байты(квитанция))
        сам.отказ('повтор')
        файл.write_bytes(b'{invalid\n')
        сам.отказ('повтор')
        файл.unlink()
        настройки = сам.настройки('создать')
        настройки['этап'] = 'повтор'
        настройки['квитанция'] = {'путь': str(файл), 'sha256': хэш(оригинал)}
        сам.отказ('повтор', настройки=настройки)
        файл.write_bytes(оригинал)
        файл.chmod(0o600)
        сам.о.нативные_записи.append({'type': 'turn_context', 'timestamp': '2026-10-01T00:00:01Z',
            'payload': {'model': 'gpt-6-astra', 'effort': 'high'}})
        сам.о.сохранить_нативный()
        повтор = сам.процесс('повтор')
        сам.assertEqual(0, повтор.returncode, повтор.stdout + повтор.stderr)
        сам.assertEqual(оригинал, файл.read_bytes())

    def test_неполная_копия_не_запускает_помощник_до_захвата(сам):
        отметка = сам.ф.каталог / 'remote-helper-запущен'
        помощник = сам.ф.каталог / 'git-remote-fumprobe'
        помощник.write_text('#!' + shutil.which('sh') + '\ntouch ' + str(отметка) + '\nexit 1\n')
        помощник.chmod(0o700)
        сам.ф.гит('config', 'extensions.partialClone', 'origin')
        сам.ф.гит('config', 'remote.origin.url', 'fumprobe::fixture')
        сам.ф.гит('config', 'remote.origin.promisor', 'true')
        сам.ф.гит('config', 'remote.origin.partialclonefilter', 'blob:none')
        сам.ф.гит('config', 'protocol.fumprobe.allow', 'always')
        имя = 'Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/policy.json'
        объект = сам.ф.гит('rev-parse', сам.база + ':' + имя).strip()
        (сам.ф.корень / '.git/objects' / объект[:2] / объект[2:]).unlink()
        with patch.dict(os.environ, {'PATH': str(сам.ф.каталог) + os.pathsep + os.environ['PATH']}):
            контроль = subprocess.run(['git', '-C', str(сам.ф.корень), 'cat-file', 'blob', объект],
                capture_output=True, timeout=30)
            сам.assertNotEqual(0, контроль.returncode)
            сам.assertTrue(отметка.exists(), контроль.stderr.decode())
            отметка.unlink()
            итог = сам.процесс('подготовить')
        сам.assertNotEqual(0, итог.returncode, итог.stdout + итог.stderr)
        сам.assertIn('partial/promisor', итог.stderr)
        сам.assertFalse(отметка.exists())
        сам.assertFalse(Path(сам.параметры['сообщение']).exists())


if __name__ == '__main__':
    unittest.main()
