"""Адресный профиль: десять повторов реального входа, точные SHA и исходы."""
import argparse
import hashlib
import json
import platform
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from медиапакет_поддержки import собрать, пары


def измерить(корень, вход, выход):
    начало = time.perf_counter_ns()
    байты = Path(вход).read_bytes()
    данные = json.loads(байты, object_pairs_hook=пары)
    исходники = [Path(__file__), Path(__file__).resolve().parents[1]/'scripts'/'медиапакет_поддержки.py', Path(__file__).resolve().parents[1]/'scripts'/'медиапакет-поддержки.py']
    хэши = {str(путь.relative_to(корень)): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники}
    подготовка = time.perf_counter_ns()-начало
    замеры = []
    ожидаемый = None
    for номер in range(10):
        начало = time.perf_counter_ns()
        результат = собрать(корень, данные)
        длительность = time.perf_counter_ns()-начало
        хэш = hashlib.sha256(json.dumps(результат, ensure_ascii=False, sort_keys=True).encode()).hexdigest()
        if ожидаемый is not None and хэш != ожидаемый: raise ValueError('неповторяемый выход')
        ожидаемый = хэш
        замеры.append({'повтор': номер+1, 'наносекунды': длительность, 'выход_sha256': хэш})
    if хэши != {str(путь.relative_to(корень)): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники}: raise ValueError('исходник изменился')
    итог = {'схема': 'fum.профиль-медиапакета.1', 'Python': platform.python_version(), 'вход_sha256': hashlib.sha256(байты).hexdigest(), 'исходники': хэши, 'подготовка_наносекунды': подготовка, 'замеры': замеры, 'код': 0, 'граница': 'Сборка пакета включает чтение Git; подготовка отдельно; файловый кэш ОС не очищался; интервалы не перекрываются.'}
    Path(выход).write_text(json.dumps(итог, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps(итог, ensure_ascii=False))


if __name__ == '__main__':
    разбор = argparse.ArgumentParser()
    разбор.add_argument('--корень-репозитория', required=True)
    разбор.add_argument('--вход', required=True)
    разбор.add_argument('--выход', required=True)
    параметры = разбор.parse_args()
    измерить(Path(параметры.корень_репозитория).resolve(), параметры.вход, параметры.выход)
