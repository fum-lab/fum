"""Небольшая настоящая Git-история для отдельных границ читающего допуска."""
from contextlib import contextmanager
from pathlib import Path
import tempfile

from фикстура_приёма_интеграции import хранение


def коммит(корень, база, правки):
    хранение.гит(корень, 'read-tree', база)
    for путь, значение in правки.items():
        if значение is None:
            хранение.гит(корень, 'update-index', '--force-remove', '--', путь)
        else:
            режим, байты = значение
            объект = хранение.гит(корень, 'hash-object', '-w', '--stdin', вход=байты).strip()
            хранение.гит(корень, 'update-index', '--add', '--cacheinfo', режим + ',' + объект + ',' + путь)
    дерево = хранение.гит(корень, 'write-tree').strip()
    return хранение.гит(корень, 'commit-tree', дерево, '-p', база, '-m', 'Открытая проверочная история').strip()


@contextmanager
def фикстура():
    with tempfile.TemporaryDirectory(prefix='fum-границы-приёма-') as временное:
        корень = Path(временное).resolve() / 'репозиторий'
        корень.mkdir()
        хранение.гит(корень, 'init', '-b', 'codex/фикстура')
        хранение.гит(корень, 'config', 'user.name', 'Открытая фикстура')
        хранение.гит(корень, 'config', 'user.email', 'fixture@example.invalid')
        хранение.гит(корень, 'config', 'commit.gpgSign', 'false')
        for имя in ('AGENTS.md', 'Правила/правило.md', 'Инструменты/вложенный.py', '.codex/config.toml'):
            путь = корень / имя
            путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_text('Открытые исходные байты\n')
        хранение.гит(корень, 'add', '.')
        хранение.гит(корень, 'commit', '-qm', 'База')
        база = хранение.гит(корень, 'rev-parse', 'HEAD').strip()
        вершина = коммит(корень, база, {'первый.txt': ('100644', b'first\n')})
        срез = коммит(корень, вершина, {'второй.txt': ('100644', b'second\n')})
        yield корень, база, вершина, срез
