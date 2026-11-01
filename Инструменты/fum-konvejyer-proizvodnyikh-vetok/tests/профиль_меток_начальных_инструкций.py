"""Сравнение чистого распознавателя с закреплённым исходником до исправления."""
import argparse
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import platform
import resource
import statistics
import subprocess
import sys
import tempfile
import time

sys.path[:0] = [str(Path(__file__).resolve().parents[1] / 'scripts'),
    str(Path(__file__).resolve().parents[2] / 'fum-reyestr-planirovaniya' / 'scripts')]
import начальные_инструкции_писателя as текущий
import test_начального_контекста_писателя as фикстура


def выполнить():
    парсер = argparse.ArgumentParser()
    парсер.add_argument('--выход', required=True)
    аргументы = парсер.parse_args()
    корень = Path(__file__).resolve().parents[3]
    путь = 'Инструменты/fum-konvejyer-proizvodnyikh-vetok/scripts/начальные_инструкции_писателя.py'
    база = 'e63e47a77d8461fa758ab0d67005d956e843e766'
    старые = subprocess.check_output(['git', '--no-optional-locks', 'show', база + ':' + путь], cwd=корень)
    новые = (корень / путь).read_bytes()
    if старые.replace('время == self.время'.encode(), 'время >= self.время'.encode(), 1) != новые:
        raise ValueError('Сравнение требует ровно закреплённого изменения предиката времени')
    общие = [{'type': 'session_meta', 'payload': {}},
        {'type': 'event_msg', 'payload': {'type': 'task_started', 'turn_id': фикстура.ХОД}},
        *[фикстура.начальная_инструкция(н) for н in range(3)],
        {'type': 'turn_context', 'payload': {'turn_id': фикстура.ХОД}}]
    возрастающие = copy.deepcopy(общие)
    for номер, время in enumerate((1790630744.586182, 1790630744.586184, 1790630744.586184), 2):
        возрастающие[номер]['payload']['internal_chat_message_metadata_passthrough']['create_time'] = время

    def прогнать(класс, записи):
        объект = класс()
        return tuple(объект.проверить(запись) for запись in записи)

    def измерить(класс, записи):
        начало = time.monotonic_ns()
        for _ in range(1000):
            прогнать(класс, записи)
        return time.monotonic_ns() - начало

    with tempfile.TemporaryDirectory(prefix='fum-profil-metok-') as каталог:
        прежний_путь = Path(каталог) / 'прежний.py'
        прежний_путь.write_bytes(старые)
        спецификация = importlib.util.spec_from_file_location('прежние_начальные_инструкции', прежний_путь)
        прежний = importlib.util.module_from_spec(спецификация)
        спецификация.loader.exec_module(прежний)
        классы = {'прежний': прежний.НачальныеИнструкцииПисателя, 'текущий': текущий.НачальныеИнструкцииПисателя}
        ожидаемые = (False, False, True, True, True, False)
        for класс in классы.values():
            if прогнать(класс, общие) != ожидаемые:
                raise ValueError('Изменён общий результат сравнения')
            for _ in range(20):
                прогнать(класс, общие)
        if прогнать(классы['текущий'], возрастающие) != ожидаемые:
            raise ValueError('Не принят наблюдённый ряд меток')
        try:
            прогнать(классы['прежний'], возрастающие)
        except ValueError:
            pass
        else:
            raise ValueError('Прежний распознаватель неожиданно принял возрастающие метки')
        замеры = {имя: [] for имя in классы}
        замеры['возрастающие'] = []
        for раунд in range(7):
            порядок = ('прежний', 'текущий') if раунд % 2 == 0 else ('текущий', 'прежний')
            for имя in порядок:
                замеры[имя].append(измерить(классы[имя], общие))
            замеры['возрастающие'].append(измерить(классы['текущий'], возрастающие))
    итог = {'схема': 'fum.профиль-меток-начальных-инструкций.1',
        'граница': 'чистый распознаватель шести событий; без Git, файлов, JSONL и сети внутри измерений',
        'база': база, 'прежний_sha256': hashlib.sha256(старые).hexdigest(),
        'текущий_sha256': hashlib.sha256(новые).hexdigest(),
        'входы_sha256': {имя: hashlib.sha256(json.dumps(записи, ensure_ascii=False, sort_keys=True).encode()).hexdigest()
            for имя, записи in (('общие', общие), ('возрастающие', возрастающие))},
        'вызовов_в_пакете': 1000, 'раундов': 7, 'прогревов': 20,
        'замеры_нс': замеры, 'медианы_пакетов_нс': {имя: int(statistics.median(ряд)) for имя, ряд in замеры.items()},
        'пиковый_RSS_процесса_байты': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * (1 if sys.platform == 'darwin' else 1024),
        'python': platform.python_version(), 'платформа': platform.system(),
        'ошибка_прежнего_не_является_ускорением': True}
    with Path(аргументы.выход).open('x') as выход:
        json.dump(итог, выход, ensure_ascii=False, sort_keys=True)
        выход.write('\n')
    return итог


if __name__ == '__main__':
    print(json.dumps(выполнить(), ensure_ascii=False))
