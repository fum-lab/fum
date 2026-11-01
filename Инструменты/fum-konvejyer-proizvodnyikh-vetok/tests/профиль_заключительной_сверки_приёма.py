"""Измерить цену повторной сверки удерживаемых дочерних снимков."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from приватные_файлы_отказа import СнимокФайлов
import архивный_префикс_приёма as архивы


def выполнить():
    параметры = argparse.ArgumentParser(description=__doc__)
    параметры.add_argument('--выход', type=Path, required=True)
    аргументы = параметры.parse_args()
    начало = time.monotonic_ns()
    with tempfile.TemporaryDirectory(prefix='fum-сверка-детей-') as временное:
        каталог = Path(временное).resolve()
        корень = каталог / 'корень.jsonl'
        байты_корня = b'root\n'
        корень.write_bytes(байты_корня); корень.chmod(0o400)
        описание = {'путь': str(корень), 'начало': len(байты_корня),
            'начало_sha256': hashlib.sha256(байты_корня).hexdigest(),
            'граница': len(байты_корня), 'sha256': hashlib.sha256(байты_корня).hexdigest()}
        данные = bytes(range(256)) * 1024
        снимки, хэши = [], {}
        for слой in ('события', 'сообщения'):
            база = каталог / слой; база.mkdir(mode=0o700)
            снимок = СнимокФайлов()
            for номер in range(4):
                имя = f'свидетельство-{номер}.bin'; путь = база / имя
                путь.write_bytes(данные); путь.chmod(0o400)
                снимок.прочитать(имя, путь, база, json=False)
            хэши[слой] = снимок.сверить(); снимки.append(снимок)
        прежний, новый = архивы.АрхивыПриёма(описание), архивы.АрхивыПриёма(описание)
        for снимок in снимки: новый.сохранить_сверку(снимок.сверить)
        def измерить(проверка, режим):
            старт = time.monotonic_ns(); проверка.сверить()
            return {'режим': режим, 'длительность_нс': time.monotonic_ns() - старт}
        режимы = [(прежний, 'только-ROOT'), (новый, 'ROOT-и-дочерние-файлы')]
        прогрев = [измерить(*режим) for режим in режимы]
        измерения = []
        for номер in range(3):
            for проверка, режим in (режимы if номер % 2 == 0 else list(reversed(режимы))):
                измерения.append(dict(измерить(проверка, режим), повтор=номер + 1))
        for слой, снимок in zip(('события', 'сообщения'), снимки):
            assert снимок.сверить() == хэши[слой]
        итог = {'схема': 'fum.профиль-заключительной-сверки-приёма.1',
            'граница': 'Компонент повторной сверки двух дочерних снимков; без разбора ROOT, Git, Desktop и полного терминала',
            'ограничение': 'Режим только-ROOT измеряет прежний пропуск проверки и не является допустимой защитой',
            'вход': {'корень_sha256': описание['sha256'], 'дочерних_файлов': 8,
                'дочерних_байтов': len(данные) * 8, 'файлы_sha256': хэши},
            'прогрев': прогрев, 'измерения': измерения,
            'медианы_нс': {режим: int(statistics.median(x['длительность_нс']
                for x in измерения if x['режим'] == режим)) for _, режим in режимы},
            'входы_неизменны': True, 'всего_нс': time.monotonic_ns() - начало}
    сырые = (json.dumps(итог, ensure_ascii=False, sort_keys=True) + '\n').encode()
    with os.fdopen(os.open(аргументы.выход, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o644), 'wb') as файл:
        файл.write(сырые); файл.flush(); os.fsync(файл.fileno())
    print(json.dumps({'медианы_нс': итог['медианы_нс'], 'входы_неизменны': True}, ensure_ascii=False))


if __name__ == '__main__': выполнить()
