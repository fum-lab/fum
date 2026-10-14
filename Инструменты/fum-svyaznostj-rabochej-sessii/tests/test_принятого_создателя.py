"""Настоящие малые Git-фикстуры отдельного обычного consumer."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
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
        for имя in dict.fromkeys([*состав['код'], *состав['ресурсы'], ПУСК, ВХОД, ДВИЖОК, СОСТАВ]):
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

    def приватный(сам, имя, значение):
        путь = сам.ф.каталог / имя
        путь.write_bytes(байты(значение))
        путь.chmod(0o600)
        return путь

    def настройки(сам, этап):
        подготовка = Path(сам.параметры['подготовка'])
        квитанция = Path(сам.параметры['квитанция'])
        ссылка = lambda путь: {'путь': str(путь), 'sha256': хэш(путь.read_bytes())}
        return {'схема': 'fum.запуск-принятого-создателя.1', 'этап': этап,
            'код': {'корень': str(сам.К), 'коммит': сам.к},
            'данные': {'корень': str(сам.ф.корень), 'коммит': сам.база,
                'пути': ['Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/policy.json']},
            'вход': ссылка(сам.вход), 'поручение': ссылка(сам.выбор),
            'подготовка': None if этап == 'подготовить' else ссылка(подготовка),
            'квитанция': ссылка(квитанция) if этап == 'повтор' else None,
            'проверки': [обычная.база.ЗАПУСК],
            'готовность': str(сам.ф.каталог / 'готовность'), 'возраст_проверок': 600}

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
        сам.профиль.append({'этап': этап, 'процесс_нс': time.perf_counter_ns() - начало})
        if процесс.returncode == 0:
            ответ = json.loads(процесс.stdout)
            сам.профиль[-1].update(захват_нс=ответ['захват_нс'], вызов_нс=ответ.get('вызов_нс'), исполнитель=ответ['pid'])
        return процесс

    def подготовить(сам):
        итог = сам.процесс('подготовить')
        сам.assertEqual(0, итог.returncode, итог.stdout + итог.stderr)
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
        return (сам.ф.гит('rev-parse', 'HEAD'), (сам.ф.корень / '.git/index').read_bytes(),
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
