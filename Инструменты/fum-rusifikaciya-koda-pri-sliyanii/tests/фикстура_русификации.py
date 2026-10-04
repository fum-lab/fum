"""Открытый кандидат настоящего Git; ожидаемые байты заданы независимо."""
import hashlib
import importlib
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

КАТАЛОГ = Path(__file__).resolve().parents[1]
КОРЕНЬ = КАТАЛОГ.parents[1]
sys.path.insert(0, str(КАТАЛОГ / 'scripts'))
ПЕРЕВОДЧИК = 'Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/'
ФАЙЛЫ_ПЕРЕВОДЧИКА = [ПЕРЕВОДЧИК + 'scripts/' + имя for имя in (
    'перевести-объявления-кода.py', 'пакет_перевода_python.py',
    'безопасные_привязки_python.py', 'разбор_сценария.py', 'аббревиатуры_контекста.py')]
ФАЙЛЫ_ПЕРЕВОДЧИКА.append(ПЕРЕВОДЧИК + 'аббревиатуры-контекста.json')


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def гит(корень, *аргументы):
    return subprocess.check_output(['git', '-C', str(корень), *аргументы], stderr=subprocess.PIPE)


class Кандидат:
    def __init__(сам, текст=b'def new_name():\n    return 7\n', потребитель=None, прежний=None, режим=0o644):
        сам.временный = tempfile.TemporaryDirectory(prefix='fum-rus-test-')
        сам.корень = Path(сам.временный.name).resolve() / 'repo'
        сам.корень.mkdir()
        гит(сам.корень, 'init', '-q', '-b', 'принимающая')
        гит(сам.корень, 'config', 'user.name', 'Фикстура')
        гит(сам.корень, 'config', 'user.email', 'fixture@example.invalid')
        for имя in ФАЙЛЫ_ПЕРЕВОДЧИКА:
            цель = сам.корень / имя
            цель.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(КОРЕНЬ / имя, цель)
        (сам.корень / 'пример.py').write_bytes(прежний if прежний is not None else '# исходное состояние\n'.encode())
        (сам.корень / 'пример.py').chmod(режим)
        if потребитель is not None:
            (сам.корень / 'потребитель.py').write_bytes(потребитель)
        гит(сам.корень, 'add', '.')
        гит(сам.корень, 'commit', '-qm', 'Начальная фикстура')
        сам.принимающий = гит(сам.корень, 'rev-parse', 'HEAD').decode().strip()
        гит(сам.корень, 'checkout', '-qb', 'источник')
        (сам.корень / 'пример.py').write_bytes(текст)
        гит(сам.корень, 'add', 'пример.py')
        гит(сам.корень, 'commit', '-qm', 'Входящий код')
        сам.источник = гит(сам.корень, 'rev-parse', 'HEAD').decode().strip()
        гит(сам.корень, 'checkout', '-q', 'принимающая')
        гит(сам.корень, 'merge', '--no-commit', '--no-ff', 'источник')
        сам.состояние = сам.корень.parent / 'транзакция'

    def закрыть(сам):
        сам.временный.cleanup()

    def вход(сам):
        модуль = importlib.import_module('контракт_русификации')
        индекс = Path(гит(сам.корень, 'rev-parse', '--git-path', 'index').decode().strip())
        if not индекс.is_absolute():
            индекс = сам.корень / индекс
        карта = сам.карта()
        return {'схема': 'fum.вход-русификации.1', 'принимающий': сам.принимающий, 'источник': сам.источник,
                'индекс_sha256': хэш(индекс.read_bytes()), 'область': ['пример.py', 'потребитель.py'],
                'карта_sha256': хэш(модуль.байты(карта)),
                'контур': {'ревизия': сам.принимающий, 'хэш_исполнителя': модуль.хэш_исполнителя(),
                           'файлы': [{'путь': п, 'sha256': хэш((сам.корень / п).read_bytes())}
                                     for п in ФАЙЛЫ_ПЕРЕВОДЧИКА]}}

    def карта(сам):
        return {'схема': 'fum.карта-русификации.1', 'происхождение': 'открытая независимая фикстура',
                'подтверждения': [{'путь': 'пример.py', 'язык': 'python', 'вид': 'функция',
                                  'имя': 'new_name', 'строка': 1, 'столбец': 1, 'новое': 'новое_имя'}],
                'пакеты': [{'язык': 'python', 'карта': {'схема': 'fum.пакет-перевода-python.1',
                    'файлы': [{'путь': 'пример.py', 'хэш': хэш((сам.корень / 'пример.py').read_bytes()),
                              'переводы': {'new_name': 'новое_имя'}, 'области': None,
                              'связи': [], 'передачи': []}]}}], 'исключения': []}

    def снимок(сам):
        индекс = Path(гит(сам.корень, 'rev-parse', '--git-path', 'index').decode().strip())
        if not индекс.is_absolute():
            индекс = сам.корень / индекс
        файлы = []
        for путь in sorted(сам.корень.rglob('*')):
            if '.git' in путь.relative_to(сам.корень).parts or путь.is_dir():
                continue
            данные = os.readlink(путь).encode() if путь.is_symlink() else путь.read_bytes()
            файлы.append((str(путь.relative_to(сам.корень)), путь.lstat().st_mode, данные))
        return (гит(сам.корень, 'rev-parse', 'HEAD'), гит(сам.корень, 'symbolic-ref', 'HEAD'),
                гит(сам.корень, 'show-ref'), индекс.read_bytes(), (сам.корень / '.git/MERGE_HEAD').read_bytes(),
                (сам.корень / '.git/config').read_bytes(), файлы)
