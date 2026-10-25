"""Три новых процесса; измеряется настоящая смена, фиксация и читающий повтор."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import resource
import subprocess
import sys
import time
import tracemalloc
from unittest.mock import patch

import профиль_переподготовки_ожиданий_узла as аудит
import test_смены_незапечатанной_подготовки as испытание

аудит.ХЭШИ[Path(__file__).relative_to(аудит.КОРЕНЬ).as_posix()] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()


def образец():
    ф = испытание.СменаПодготовки(); ф.setUp()
    стадии = []; вызовы = [0]; исходный = subprocess.Popen
    def процесс(аргументы, *позиционные, **именованные):
        if аргументы and Path(аргументы[0]).name == 'git': вызовы[0] += 1
        return исходный(аргументы, *позиционные, **именованные)
    def измерить(имя, действие):
        до = вызовы[0]; tracemalloc.reset_peak(); начало = time.perf_counter_ns()
        результат = действие()
        стадии.append({'стадия': имя, 'наносекунды': time.perf_counter_ns()-начало,
            'вызовы_гита': вызовы[0]-до, 'пик_памяти_байтов': tracemalloc.get_traced_memory()[1],
            'максимум_резидентной_памяти_байтов': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
                * (1 if sys.platform == 'darwin' else 1024)})
        return результат
    try:
        tracemalloc.start()
        with patch.object(subprocess, 'Popen', side_effect=процесс):
            итог = измерить('Архив прежнего поколения, переход, genuine prepare и seal', ф.выполнить)
            assert итог['поколение'] == 2 and ф.сохранённые == ф.старые_свидетельства()
            повтор = измерить('Проверка запечатанного поколения 2', lambda:
                испытание.писатель.переподготовить(ф.ф.с.вход, ф.запрос['новые_параметры']))
            assert повтор == итог
            ф.ф.готовность(ф.п)
            коммит = измерить('Настоящая фиксация и подтверждение квитанции', lambda:
                испытание.писатель.зафиксировать(ф.ф.с.вход, [испытание.основа.исходные.обычная.база.ЗАПУСК]))
            до = ф.ф.снимок()
            квитанция = измерить('Читающий повтор без нового коммита', lambda:
                испытание.писатель.повтор(ф.ф.с.вход))
            assert коммит == квитанция and до == ф.ф.снимок()
            assert ф.ф.с.ф.гит('rev-list', '--count', ф.ф.с.база+'..HEAD').strip() == '1'
            assert ф.сохранённые == ф.старые_свидетельства()
        assert all(hashlib.sha256((аудит.КОРЕНЬ/имя).read_bytes()).hexdigest() == значение
            for имя, значение in аудит.ХЭШИ.items())
        return {'процесс': os.getpid(), 'стадии': стадии, 'поколение': 2, 'коммитов': 1,
            'сохранены_прежние_RAW': True, 'сеть': False, 'отправки': 0,
            'хэши_исполненных_исходников': dict(sorted(аудит.ХЭШИ.items()))}
    finally:
        tracemalloc.stop(); ф.doCleanups()


def главная():
    п = argparse.ArgumentParser(description=__doc__)
    п.add_argument('--образец', action='store_true'); п.add_argument('--выход', type=Path)
    арг = п.parse_args()
    if арг.образец:
        print(json.dumps(образец(), ensure_ascii=False, sort_keys=True)); return
    assert арг.выход is not None and not арг.выход.exists()
    образцы = []
    for _ in range(3):
        процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--образец'],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180, check=True)
        образцы.append(json.loads(процесс.stdout))
    assert len({о['процесс'] for о in образцы}) == 3
    хэши = образцы[0]['хэши_исполненных_исходников']
    assert all(о['хэши_исполненных_исходников'] == хэши for о in образцы)
    assert all(hashlib.sha256((аудит.КОРЕНЬ/имя).read_bytes()).hexdigest() == значение for имя, значение in хэши.items())
    итог = {'схема': 'fum.профиль-смены-незапечатанной-подготовки.1', 'образцы': образцы,
        'хэши_исходников': хэши,
        'граница': 'Три новых Python-процесса, настоящие Git и native JSONL. Setup, получение полной pending-подготовки, staging и готовность вне таймеров. Перехватчики включены, кэш ОС не сбрасывается. RSS является максимумом процесса; Popen считает Git данного Python. Удалённая доставка, bound Q и production-корпус не проверены.',
        'решение_об_оптимизации': 'Используются прежние guards и Creator. Смена не переустанавливает expected, не пересоздаёт ветку или чат. Обход проверок и дополнительный кэш не вводятся. Сравнение с первым поколением не является одинаковой нагрузкой; ускорение не заявляется.'}
    арг.выход.write_text(json.dumps(итог, ensure_ascii=False, indent=2)+'\n'); арг.выход.chmod(0o600)
    print(json.dumps({'образцов': 3, 'sha256': hashlib.sha256(арг.выход.read_bytes()).hexdigest()}))


if __name__ == '__main__':
    главная()
