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

if sys.flags.optimize != 0:
    raise RuntimeError('Профиль запрещает оптимизацию Python: обязательные assert должны исполняться')

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
import test_переподготовка_ожиданий_узла as испытание


def образец():
    ф = испытание.ПереподготовкаОжиданий(); ф.setUp()
    писатель = испытание.писатель
    стадии = []
    вызовы = [0]
    исходный = subprocess.Popen
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
            def отказ_прежнего_повтора():
                with ф.assertRaises(писатель.коммит.ОшибкаКоммита):
                    писатель.коммит.подготовить(ф.новые, сохранить_историю=True,
                        доверенное_поручение=ф.с.вход['акт'])
            измерить('Отказ прежнего повтора при новом наблюдении', отказ_прежнего_повтора)
            итог = измерить('Архив, fence, обычная подготовка, печать и активация',
                lambda: писатель.переподготовить(ф.с.вход, ф.ссылка))
            повтор = измерить('Повтор запечатанного поколения',
                lambda: писатель.переподготовить(ф.с.вход, ф.ссылка))
            assert итог == повтор
            ф.готовность()
            коммит = измерить('Настоящая фиксация и подтверждение новой квитанции',
                lambda: писатель.зафиксировать(ф.с.вход, [испытание.исходные.обычная.база.ЗАПУСК]))
            до = ф.снимок()
            квитанция = измерить('Читающий повтор квитанции', lambda: писатель.повтор(ф.с.вход))
            assert коммит == квитанция and до == ф.снимок()
            assert ф.с.ф.гит('rev-list', '--count', ф.с.база+'..HEAD').strip() == '1'
            assert ф.цель.read_bytes() == ф.байты
        assert all(hashlib.sha256((КОРЕНЬ/имя).read_bytes()).hexdigest() == значение for имя, значение in ХЭШИ.items())
        прежняя = json.loads(ф.старые['подготовка'])
        новая = json.loads(Path(ф.новые['подготовка']).read_bytes())
        return {'идентификатор_процесса': os.getpid(), 'стадии': стадии,
            'хэши_исполненных_исходников': dict(sorted(ХЭШИ.items())),
            'кандидат_байтов': len(ф.байты), 'хэш_кандидата': ф.с.вход['кандидат']['хэш'],
            'наблюдений_до': прежняя['наблюдений'], 'наблюдений_после': новая['наблюдений'],
            'поколений': итог['поколение'],
            'коммитов': 1, 'коммит': коммит['коммит']['коммит'],
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
    итог = {'схема': 'fum.профиль-переподготовки-ожиданий.1', 'хэши_исходников': хэши, 'образцы': образцы,
        'граница': 'Три новых Python-процесса на малом настоящем Git/native корпусе. Setup, установка expected, append turn_context, staging, отчётная проверка и готовность вне таймеров. Стадии не перекрываются. Audit exec сверяет наблюдённые собственные Python-байты с исполняемым кодом и повторно с файлами; Python/runtime и внешнее развёртывание Q вне манифеста. Измерительные перехватчики включены, ОС-кэш не сбрасывается, RSS — максимум процесса. Popen считает Git родительского Python, Git других интерпретаторов не учтён. Перерывы и гонки измеряются отдельным тестовым запуском; падение ОС/питания, production-данные и доставка Q не проверены.',
        'решение_об_оптимизации': 'Дополнительный кэш не вводится: проверяемая неизменность оснований важнее обхода повторных строгих проверок. Фактические затраты сохраняются по стадиям; ускорение не заявляется.'}
    п.выход.write_text(json.dumps(итог, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps({'образцов': len(образцы), 'хэш_профиля': hashlib.sha256(п.выход.read_bytes()).hexdigest()}, ensure_ascii=False))


if __name__ == '__main__':
    главная()
