"""Три независимых процесса: fixture вне таймеров, сеть не вызывается."""
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

import test_обновление_ожиданий_узла as испытание


def образец():
    ф = испытание.ОбновлениеОжиданий(); ф.setUp()
    писатель = испытание.писатель
    стадии = []
    вызовы = [0]
    прежний = subprocess.Popen

    def процесс(аргументы, *позиционные, **именованные):
        if аргументы and Path(аргументы[0]).name == 'git': вызовы[0] += 1
        return прежний(аргументы, *позиционные, **именованные)

    def измерить(имя, действие):
        до = вызовы[0]; tracemalloc.reset_peak(); начало = time.perf_counter_ns()
        результат = действие(); длительность = time.perf_counter_ns() - начало
        стадии.append({'стадия': имя, 'наносекунды': длительность, 'вызовы_гита': вызовы[0]-до,
            'пик_памяти_байтов': tracemalloc.get_traced_memory()[1],
            'максимум_резидентной_памяти_байтов': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
                * (1 if sys.platform == 'darwin' else 1024)})
        return результат

    try:
        tracemalloc.start()
        with patch.object(subprocess, 'Popen', side_effect=процесс):
            измерить('Чтение прежнего поколения', lambda: писатель.читатель.загрузить_ожидания(ф.доверие, корень=ф.корень))
            измерить('Проверка и сериализация кандидата', lambda: испытание.байты(
                писатель.проверить_кандидат(ф.файл_кандидата.read_bytes(), ф.доверие, ф.корень)))
            план = измерить('Полный читающий план', lambda: писатель.план(ф.вход))
            измерить('Установка с повторной сверкой и fsync', lambda: писатель.установить(ф.вход, план))
            # Модель, staging, адресная проверка, готовность исключены из таймера commit.
            ф.готовность()
            итог = измерить('Штатная фиксация .9 и подтверждение', lambda:
                писатель.зафиксировать(ф.вход, [испытание.обычная.база.ЗАПУСК]))
            повтор = измерить('Читающий повтор', lambda: писатель.повтор(ф.вход))
            assert итог == повтор
            assert ф.ф.гит('rev-list', '--count', ф.база+'..HEAD').strip() == '1'
        return {'идентификатор_процесса': os.getpid(), 'стадии': стадии, 'кандидат_байтов': ф.файл_кандидата.stat().st_size,
            'хэш_кандидата': ф.вход['кандидат']['хэш'], 'коммит': итог['коммит']['коммит'],
            'сеть': 'не вызывается', 'отправки': 0, 'создания_чатов': 0}
    finally:
        tracemalloc.stop(); ф.doCleanups()


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument('--образец', action='store_true')
    разбор.add_argument('--выход', type=Path)
    п = разбор.parse_args()
    if п.образец:
        print(json.dumps(образец(), ensure_ascii=False, sort_keys=True)); return
    assert п.выход is not None and not п.выход.exists()
    корень = Path(__file__).resolve().parents[3]
    исходники = sorted({Path(м.__file__).resolve() for м in sys.modules.values()
        if getattr(м, '__file__', None) and Path(м.__file__).resolve().is_relative_to(корень)
        and Path(м.__file__).suffix == '.py'} | {Path(__file__).resolve()})
    хэши = {ф.relative_to(корень).as_posix(): hashlib.sha256(ф.read_bytes()).hexdigest() for ф in исходники}
    образцы = []
    for _ in range(3):
        процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--образец'],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180, check=True)
        образцы.append(json.loads(процесс.stdout))
    assert len({о['идентификатор_процесса'] for о in образцы}) == 3
    assert хэши == {ф.relative_to(корень).as_posix(): hashlib.sha256(ф.read_bytes()).hexdigest() for ф in исходники}
    итог = {'схема': 'fum.профиль-обновления-ожиданий.1', 'хэши_исходников': хэши, 'образцы': образцы,
        'граница': 'Синтетические реальные Git/native; setup и readiness вне таймеров. ОС-кэш не сбрасывается; RSS — максимум процесса. Счётчик Git наблюдает Popen родительского Python, включая run/check_output и прямой creator; Git внутри других интерпретаторов не учтён. Сеть отдельно не измеряется: вызовов нет.',
        'решение_об_оптимизации': 'Дополнительный кэш не вводится; сначала измерён безопасный проход.'}
    п.выход.write_text(json.dumps(итог, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps({'образцов': len(образцы), 'хэш_профиля': hashlib.sha256(п.выход.read_bytes()).hexdigest()}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
