"""Три повтора точных новых операций; выход только в новом приватном файле."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
from time import perf_counter_ns

import test_братиславского_имени_пары as фикстура
import имя_обычного_журнала as имена


def главная():
    if len(sys.argv) != 2:
        raise ValueError('Нужен один новый приватный путь профиля')
    выход = Path(sys.argv[1])
    корень = фикстура.КОРЕНЬ
    if (not выход.is_absolute() or выход != выход.resolve() or выход.exists()
            or not выход.parent.is_dir() or any(п.is_symlink() or (п / '.git').exists() for п in выход.parents)):
        raise ValueError('Профиль требует свободный физический путь вне Git')
    путь_свежести = корень / 'Инструменты/fum-svezhestj-markdown/scripts/update-md-recency.py'
    описание = importlib.util.spec_from_file_location('профиль_свежести_имени', путь_свежести)
    свежесть = importlib.util.module_from_spec(описание)
    sys.modules[описание.name] = свежесть
    описание.loader.exec_module(свежесть)
    пути = [Path(__file__), Path(имена.__file__), Path(имена.каркас.__file__),
        Path(имена.загрузка.__file__), Path(фикстура.журнал.__file__), Path(фикстура.__file__),
        путь_свежести, фикстура.ЭТАЛОН,
        корень / 'Инструменты/fum-struktura-papok-zaprosov/каталоги-журнала.2.json',
        корень / 'Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py',
        корень / 'Инструменты/fum-proverka-nazvanij-avtomatizacij/Package.swift',
        корень / 'Инструменты/fum-proverka-nazvanij-avtomatizacij/Sources/preobrazovatj-nazvaniya/main.swift',
        корень / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/контракт_независимого_журнала.py',
        корень / 'Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py']
    def снимок():
        return {п.relative_to(корень).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest() for п in пути}
    до = снимок()
    фикстура.БратиславскоеИмяПары.setUpClass()
    ф = фикстура.БратиславскоеИмяПары()
    измерения = []
    def измерить(имя, повтор, действие):
        начало = perf_counter_ns()
        результат = действие()
        измерения.append({'этап': имя, 'повтор': повтор, 'длительность_нс': perf_counter_ns() - начало})
        return результат
    эталон = None
    for повтор in range(1, 4):
        файлы, план = измерить('renderer2', повтор, ф.новая_пара)
        байты = [ф.data for ф in файлы]
        if эталон is None:
            эталон = байты, план
        if (байты, план) != эталон:
            raise ValueError('Изменился результат одинаковых входов')
        if измерить('план2', повтор, lambda: имена.проверить_план(план)) != план:
            raise ValueError('Не подтверждён план2')
        мета = измерить('метаданные', повтор,
            lambda: имена.свойства(файлы[0].data.decode(), план['журнал']))
        if мета['имя'] != план['имя']:
            raise ValueError('Изменились метаданные')
        отчёт = корень / файлы[1].path
        текст = файлы[1].data.decode()
        _, отказ = измерить('recency-обычный', повтор,
            lambda: свежесть.стабильное_содержание_отчёта(отчёт, корень, текст))
        if отказ:
            raise ValueError('Отказ верного служебного блока')
        _, отказ = измерить('recency-повтор-маркера', повтор,
            lambda: свежесть.стабильное_содержание_отчёта(отчёт, корень,
                текст + '\n<!-- FUM-CHECK-RUNS:END -->\n'))
        if not отказ:
            raise ValueError('Принят повтор маркера')
    после = снимок()
    if после != до:
        raise ValueError('Дрейф исполняемых исходников во время профиля')
    данные = {'схема': 'fum.профиль-имени-обычного-журнала.1',
        'база': subprocess.run(['git', '-C', str(корень), 'rev-parse', 'HEAD'],
            check=True, capture_output=True).stdout.decode().strip(),
        'код': 'рабочие байты до коммита; отдельные SHA до и после',
        'python': platform.python_version(), 'система': platform.system(),
        'архитектура': platform.machine(), 'LinguisticKit': имена.РЕВИЗИЯ,
        'условия': 'Проверяемый кэш Swift уже подготовлен; кэш ОС не очищался; подготовка фикстуры исключена. Метки включены. Вложенные интервалы не складываются.',
        'вход': {'sourceLabel': ф.метка, 'журнал': эталон[1]['журнал'],
            'title': эталон[1]['имя']['title']},
        'исходники_до': до, 'исходники_после': после, 'измерения': измерения,
        'результат_sha256': [hashlib.sha256(б).hexdigest() for б in эталон[0]]}
    сырые = (json.dumps(данные, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode()
    with os.fdopen(os.open(выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), 'wb') as поток:
        поток.write(сырые); поток.flush(); os.fsync(поток.fileno())
    print(json.dumps({'схема': данные['схема'], 'sha256': hashlib.sha256(сырые).hexdigest(),
        'измерения': измерения}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
