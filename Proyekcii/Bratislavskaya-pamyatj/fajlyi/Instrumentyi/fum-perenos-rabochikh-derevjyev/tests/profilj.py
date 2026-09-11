"""Открытый воспроизводимый профиль: обычный перенос, авария, возобновление и повтор."""
import argparse
from contextlib import redirect_stderr
import hashlib
import io
import json
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
from time import perf_counter_ns
from фикстуры import подготовить, процесс, перенос, КОРЕНЬ


def метки(текст):
    return [json.loads(строка[len('FUM-PROFILE '):]) for строка in текст.splitlines() if строка.startswith('FUM-PROFILE ')]


def измерить(число):
    результаты = []
    for номер in range(число):
        for сценарий in ('обычный','возобновляемый'):
            with tempfile.TemporaryDirectory() as временный:
                буфер = io.StringIO()
                with redirect_stderr(буфер):
                    привязки,план,путь_плана,путь_привязок = подготовить(Path(временный).resolve())
                результаты.append({'повтор':номер+1,'сценарий':сценарий,'действие':'план','метки':метки(буфер.getvalue())})
                if сценарий=='возобновляемый':
                    ответ = процесс(путь_плана,путь_привязок,'после-перемещения')
                    assert ответ.returncode==77,ответ.stderr.decode()
                for действие in ('исполнение','точный-повтор'):
                    начало = perf_counter_ns()
                    ответ = процесс(путь_плана,путь_привязок)
                    длительность = perf_counter_ns()-начало
                    assert ответ.returncode==0,ответ.stderr.decode()
                    результаты.append({'повтор':номер+1,'сценарий':сценарий,'действие':действие,'длительность_процесса_нс':длительность,'метки':метки(ответ.stderr.decode())})
    исходники = [Path(перенос.__file__),Path(__file__),Path(__file__).with_name('фикстуры.py'),Path(__file__).with_name('процесс.py'),КОРЕНЬ/'Инструменты/fum-snimki-indeksa/scripts/канон.py',КОРЕНЬ/'Инструменты/fum-snimki-indeksa/scripts/объекты.py',КОРЕНЬ/'Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py']
    return {'схема':'fum.профиль-переноса.1','условия':{'платформа':platform.system(),'версия_системы':platform.release(),'архитектура':platform.machine(),'python':platform.python_version(),'git':subprocess.check_output(['git','--version'],text=True).strip(),'повторы':число,'репозитории':3,'режим':'Один последовательный процесс на локальной временной фикстуре; время родителей включает детей.'},'исходники':{путь.relative_to(КОРЕНЬ).as_posix():hashlib.sha256(путь.read_bytes()).hexdigest() for путь in исходники},'наблюдения':результаты}


if __name__=='__main__':
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--выход',required=True,type=Path)
    парсер.add_argument('--повторы',type=int,default=3)
    параметры = парсер.parse_args()
    assert 1<=параметры.повторы<=10
    результат = измерить(параметры.повторы)
    параметры.выход.write_text(json.dumps(результат,ensure_ascii=False,sort_keys=True,indent=2)+'\n')
    print('Сохранены наблюдения:',len(результат['наблюдения']))
