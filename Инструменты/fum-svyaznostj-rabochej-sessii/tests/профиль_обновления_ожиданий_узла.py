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

КОРЕНЬ = Path(__file__).resolve().parents[3]
ХЭШИ = {Path(__file__).relative_to(КОРЕНЬ).as_posix(): hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}


def учесть_исполнение(событие, аргументы):
    # Поздние exec-модули сканера могут исчезнуть из sys.modules до конца образца.
    if событие != 'exec': return
    путь = Path(аргументы[0].co_filename)
    if not путь.is_absolute() or путь.suffix != '.py' or not путь.is_relative_to(КОРЕНЬ): return
    имя = путь.relative_to(КОРЕНЬ).as_posix()
    сырые = путь.read_bytes()
    требуемый = compile(сырые, аргументы[0].co_filename, 'exec',
        dont_inherit=True, optimize=sys.flags.optimize)
    assert аргументы[0] == требуемый, 'исполняемый код не соответствует исходнику'
    значение = hashlib.sha256(сырые).hexdigest()
    assert имя not in ХЭШИ or ХЭШИ[имя] == значение, 'исполняемый исходник изменился'
    ХЭШИ[имя] = значение


sys.addaudithook(учесть_исполнение)
import test_обновление_ожиданий_узла as испытание


def образец():
    ф = испытание.ОбновлениеОжиданий(); ф.setUp()
    ф.назначить_публикуемую_схему()
    писатель = испытание.писатель
    стадии = []
    сверки = []
    текущая_стадия = ['Вне таймеров']
    вызовы = [0]
    прежний = subprocess.Popen

    def процесс(аргументы, *позиционные, **именованные):
        if аргументы and Path(аргументы[0]).name == 'git': вызовы[0] += 1
        return прежний(аргументы, *позиционные, **именованные)

    def измерить(имя, действие):
        текущая_стадия[0] = имя
        до = вызовы[0]; tracemalloc.reset_peak(); начало = time.perf_counter_ns()
        результат = действие(); длительность = time.perf_counter_ns() - начало
        стадии.append({'стадия': имя, 'наносекунды': длительность, 'вызовы_гита': вызовы[0]-до,
            'пик_памяти_байтов': tracemalloc.get_traced_memory()[1],
            'максимум_резидентной_памяти_байтов': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
                * (1 if sys.platform == 'darwin' else 1024)})
        return результат

    прежняя_сверка = писатель.проверить_назначение
    def сверить(корень, вход):
        до = вызовы[0]; начало = time.perf_counter_ns()
        результат = прежняя_сверка(корень, вход)
        сверки.append({'стадия': текущая_стадия[0], 'наносекунды': time.perf_counter_ns()-начало,
            'вызовы_гита': вызовы[0]-до})
        return результат

    try:
        tracemalloc.start()
        with patch.object(subprocess, 'Popen', side_effect=процесс), \
                patch.object(писатель, 'проверить_назначение', side_effect=сверить):
            измерить('Чтение прежнего поколения', lambda: писатель.читатель.загрузить_ожидания(ф.доверие, корень=ф.корень))
            измерить('Проверка и сериализация кандидата', lambda: испытание.байты(
                писатель.проверить_кандидат(ф.файл_кандидата.read_bytes(), ф.доверие, ф.корень)))
            измерить('Полная валидация входа', lambda: писатель.проверить(ф.вход))
            план = измерить('Полный читающий план', lambda: писатель.план(ф.вход))
            измерить('Установка с повторной сверкой и fsync', lambda: писатель.установить(ф.вход, план))
            # Модель, staging, адресная проверка, готовность исключены из таймера commit.
            текущая_стадия[0] = 'Подготовка вне таймеров'
            ф.готовность()
            итог = измерить('Штатная фиксация .9 и подтверждение', lambda:
                писатель.зафиксировать(ф.вход, [испытание.обычная.база.ЗАПУСК]))
            повтор = измерить('Читающий повтор', lambda: писатель.повтор(ф.вход))
            assert итог == повтор
            assert ф.ф.гит('rev-list', '--count', ф.база+'..HEAD').strip() == '1'
        assert all(hashlib.sha256((КОРЕНЬ/имя).read_bytes()).hexdigest() == значение for имя, значение in ХЭШИ.items())
        return {'идентификатор_процесса': os.getpid(), 'стадии': стадии, 'сверки_назначения': сверки,
            'хэши_исполненных_исходников': dict(sorted(ХЭШИ.items())),
            'привязка_корня_байтов': len(ф.назначение['хэш_корня'].encode('ascii')),
            'прежняя_строка_корня_байтов': len(str(ф.корень).encode('utf-8')),
            'кандидат_байтов': ф.файл_кандидата.stat().st_size,
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
    образцы = []
    for _ in range(3):
        процесс = subprocess.run([sys.executable, '-B', str(Path(__file__).resolve()), '--образец'],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180, check=True)
        образцы.append(json.loads(процесс.stdout))
    assert len({о['идентификатор_процесса'] for о in образцы}) == 3
    хэши = образцы[0]['хэши_исполненных_исходников']
    assert all(о['хэши_исполненных_исходников'] == хэши for о in образцы)
    assert all(хэши[имя] == значение for имя, значение in ХЭШИ.items())
    assert all(hashlib.sha256((КОРЕНЬ/имя).read_bytes()).hexdigest() == значение for имя, значение in хэши.items())
    итог = {'схема': 'fum.профиль-обновления-ожиданий.2', 'хэши_исходников': хэши, 'образцы': образцы,
        'граница': 'Прежний синтетический корпус реальных Git/native с назначением .2; setup и readiness вне таймеров. Вложенные сверки назначения не суммируются со стадиями. Новая привязка не добавляет Git-вызовов в прежнюю сверку; сверка на пути подтверждения/повтора добавлена отдельно и измерена внутри этих стадий. Audit exec фиксирует собственные Python-исходники, включая поздние временные module aliases; Python/runtime вне этого манифеста. Накладные расходы измерительных перехватчиков включены. ОС-кэш не сбрасывается; RSS — максимум процесса. Счётчик Git наблюдает Popen родительского Python, включая run/check_output и прямой creator; Git внутри других интерпретаторов не учтён. Сеть отдельно не измеряется: вызовов нет.',
        'решение_об_оптимизации': 'Дополнительный кэш не вводится; сначала измерён безопасный проход.'}
    п.выход.write_text(json.dumps(итог, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps({'образцов': len(образцы), 'хэш_профиля': hashlib.sha256(п.выход.read_bytes()).hexdigest()}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
