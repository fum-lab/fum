"""Три воспроизводимых сценария, по три чередующиеся пары свежих процессов."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import resource
import runpy
import statistics
import subprocess
import sys
import time


КОРЕНЬ = Path(__file__).resolve().parents[1]
СКРИПТ = КОРЕНЬ / 'scripts/компактный_JSON.py'


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def записать(путь, значение):
    данные = (json.dumps(значение, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    with Path(путь).open('xb') as поток:
        os.chmod(путь, 0o600)
        поток.write(данные)
        поток.flush()
        os.fsync(поток.fileno())


def дочерний(п):
    начало = time.perf_counter_ns()
    код = 0
    if п.режим == 'исходный':
        with open(п.источник, encoding='utf-8') as поток:
            print(json.dumps(json.load(поток), ensure_ascii=False))
    else:
        sys.path.insert(0, str(СКРИПТ.parent))
        sys.argv = [str(СКРИПТ), '--источник', п.источник, '--sha256', п.sha256,
                    '--бюджет-байтов', '4096', '--глубина', '2', '--элементы', '8']
        for указатель in п.указатель:
            sys.argv.extend(['--указатель', указатель])
        try:
            runpy.run_path(str(СКРИПТ), run_name='__main__')
        except SystemExit as исход:
            код = исход.code
    sys.stdout.flush()
    записать(п.метрики, {'внутренних_наносекунд': time.perf_counter_ns() - начало,
        'пик_RSS': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
        'единица_RSS': 'байт' if sys.platform == 'darwin' else 'КиБ', 'код': код})
    return код


def состояние(путь):
    с = путь.stat()
    return (с.st_mode, с.st_ino, с.st_mtime_ns, с.st_ctime_ns, с.st_size)


def профиль(п):
    каталог = Path(п.каталог).resolve()
    assert каталог.is_dir() and not any((к / '.git').exists() for к in (каталог, *каталог.parents))
    assert not Path(п.выход).exists()
    исходники = [СКРИПТ, Path(__file__), СКРИПТ.with_name('компактный_остаток.py'),
                 СКРИПТ.with_name('захват_вывода.py')]
    состав = {к.name: хэш(к.read_bytes()) for к in исходники}
    случаи = [
        ('много-малых-скаляров', {'схема': 'открытая-фикстура', 'состояние': 'готово',
            'metadata': {'expected': True}, 'inventory': [{'id': н, 'ok': True} for н in range(5000)]},
            ['/схема', '/состояние', '/metadata/expected', '/inventory']),
        ('один-гигантский-скаляр', {'состояние': 'готово', 'inventory': 'ё' * (4 * 1024 * 1024)},
            ['/состояние', '/inventory']),
        ('вложенность-и-ширина', {'узел': [{'массив': list(range(8))} for _ in range(8)]}, ['/узел'])]
    результаты = []
    for имя, значение, указатели in случаи:
        данные = (json.dumps(значение, ensure_ascii=False, sort_keys=True, separators=(',', ':')) + '\n').encode()
        путь = каталог / (имя + '.json')
        with путь.open('xb') as поток:
            os.chmod(путь, 0o600)
            поток.write(данные)
        до = состояние(путь)
        сырой_хэш = хэш(данные)
        пары = []
        for номер in range(3):
            измерения = {}
            порядок = ['исходный', 'компактный'] if номер % 2 == 0 else ['компактный', 'исходный']
            for режим in порядок:
                префикс = каталог / f'{имя}-{номер}-{режим}'
                вывод = префикс.with_suffix('.stdout')
                ошибка = префикс.with_suffix('.stderr')
                метрики = префикс.with_suffix('.metrics.json')
                команда = [sys.executable, '-B', str(Path(__file__).resolve()), '--режим', режим,
                    '--источник', str(путь), '--sha256', сырой_хэш, '--метрики', str(метрики)]
                for указатель in указатели:
                    команда.extend(['--указатель', указатель])
                начало = time.perf_counter_ns()
                with вывод.open('xb') as наружу, ошибка.open('xb') as ошибки:
                    os.chmod(вывод, 0o600)
                    os.chmod(ошибка, 0o600)
                    процесс = subprocess.run(команда, stdout=наружу, stderr=ошибки)
                длительность = time.perf_counter_ns() - начало
                assert процесс.returncode == 0 and ошибка.stat().st_size == 0
                assert состояние(путь) == до and хэш(путь.read_bytes()) == сырой_хэш
                полные_байты = вывод.read_bytes()
                if режим == 'компактный':
                    assert len(полные_байты) <= 4096 and полные_байты.endswith(b'\n')
                    ответ = json.loads(полные_байты)
                    assert ответ['источник']['raw_sha256'] == сырой_хэш
                    assert [з['указатель'] for з in ответ['выборки']] == указатели
                    for указатель, запись in zip(указатели, ответ['выборки']):
                        выбранное = значение
                        for часть in указатель.split('/')[1:]:
                            выбранное = выбранное[часть]
                        канон = json.dumps(выбранное, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()
                        assert запись['sha256'] == хэш(канон)
                        assert запись['канонических_байтов'] == len(канон)
                else:
                    assert json.loads(полные_байты) == значение
                измерения[режим] = {'процесс_наносекунд': длительность,
                    'stdout_байтов_с_LF': len(полные_байты), 'stdout_sha256': хэш(полные_байты),
                    'stderr_байтов': 0, **json.loads(метрики.read_bytes())}
            пары.append({'порядок': порядок, 'измерения': измерения})
        результаты.append({'сценарий': имя, 'исходных_байтов': len(данные), 'raw_sha256': сырой_хэш,
            'указатели': указатели, 'бюджет_байтов': 4096, 'глубина': 2, 'элементы': 8,
            'источник_неизменён': True, 'пары': пары,
            'медианы_процесс_наносекунд': {р: statistics.median(пара['измерения'][р]['процесс_наносекунд']
                for пара in пары) for р in ['исходный', 'компактный']}})
    assert состав == {к.name: хэш(к.read_bytes()) for к in исходники}
    итог = {'схема': 'fum.профиль-компактного-JSON.1', 'Python': sys.version.split()[0],
        'исходники_sha256': состав, 'сценарии': результаты,
        'граница': 'Свежий процесс на каждый вызов, CLI через runpy; wall-clock включает запуск и I/O. '
            'Создание фикстур и запись итогового профиля исключены; кэш ОС не очищается. '
            'Внутренние интервалы вложены, RSS измерен отдельно каждым процессом. '
            'Оплаченные токены, сеть, получение моделью и полный ROOT-путь не измерены.',
        'решение_оптимизации': 'Сохранить реализацию: основной результат — ограниченный проверенный вывод; '
            'малый профиль не обосновывает дополнительное усложнение алгоритма.'}
    записать(п.выход, итог)
    print(json.dumps({'схема': итог['схема'], 'сценариев': len(результаты), 'пар': 9,
        'профиль_sha256': хэш(Path(п.выход).read_bytes())}, ensure_ascii=False))
    return 0


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument('--режим', choices=['исходный', 'компактный'])
    разбор.add_argument('--источник')
    разбор.add_argument('--sha256')
    разбор.add_argument('--метрики')
    разбор.add_argument('--указатель', action='append')
    разбор.add_argument('--каталог')
    разбор.add_argument('--выход')
    п = разбор.parse_args()
    if п.режим:
        return дочерний(п)
    return профиль(п)


if __name__ == '__main__':
    raise SystemExit(главная())
