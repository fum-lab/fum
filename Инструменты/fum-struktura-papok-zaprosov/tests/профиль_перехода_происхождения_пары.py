"""Три новых PID: захваченный Git-код, чистый план, две замены, нулевой повтор."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import resource
import subprocess
import sys
import tempfile
import time

ПАПКА = 'Инструменты/fum-struktura-papok-zaprosov/'
СВЯЗНОСТЬ = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/'
ДВИЖОК = СВЯЗНОСТЬ + 'исполнение_принятого_кода.py'
ХЭШ_ДВИЖКА = 'd2fe64709a92cc642ec28e1a669cbc15561fdcc1b73c9fb81b7736821465605f'
ВХОД_ПРОФИЛЯ = ПАПКА + 'tests/профиль_перехода_происхождения_пары.py'
СОСТАВ = {
    'fum-otchyotyi-o-zapuskakh-proverok': ['закрытый_отчёт_из_гита', 'отчёты_о_запусках_проверок', 'связь_отпечатка_с_коммитом'],
    'fum-proverka-mashinno-lokaljnyikh-putej': ['path_forms'],
    'fum-proyektnyiye-fajlyi': ['project_files'],
    'fum-reyestr-planirovaniya': ['постановка_задачи', 'приём_направления'],
    'fum-snimki-indeksa': ['происхождение_сообщений'],
    'fum-struktura-papok-zaprosov': ['request_folder_layout', 'блоки_карточки', 'независимый_журнал',
        'отпечатки_загрузки', 'переход_происхождения_пары', 'публичное_представление_событий', 'управляемые_блоки'],
    'fum-svezhestj-markdown': ['update-md-recency', 'маска_архива', 'ограды_цитат'],
    'fum-svyaznostj-rabochej-sessii': ['check-session-coherence', 'автор_коммита', 'готовность_коммита',
        'готовность_этапа', 'граница_выбранных_команд', 'исторические_неподтверждённые_приёмки',
        'история_модели', 'история_пути_гита', 'контракт_независимого_журнала', 'кэш_сверки_остатка',
        'независимый_индекс_журнала', 'обработка_сообщений', 'обычное_поручение', 'обязательства_задачи',
        'перенести_историю_модели', 'перенос_модели_этапа', 'перепривязать_историю_модели',
        'подготовка_этапа_коммита', 'поколения_готовности', 'приём_делегации', 'сверить-материалы-этапа',
        'создание_коммита', 'сообщения_задачи', 'текст_команды_с_изображением', 'типизированная_контрольная_точка'],
}
ПУТИ = sorted((Path('Инструменты') / каталог / 'scripts' / (имя + '.py')).as_posix()
    for каталог, имена in СОСТАВ.items() for имя in имена) + [ВХОД_ПРОФИЛЯ]
РЕСУРСЫ = [ПАПКА + 'шаблоны/' + имя + '.md.шаблон' for имя in ('запрос', 'отчёт')]
ПСЕВДОНИМЫ = {Path(п).stem: п for п in ПУТИ}
for имена, путь in [
    (['связность_создания_коммита', 'связность_раннего_охвата'], СВЯЗНОСТЬ + 'check-session-coherence.py'),
    (['охват_создания_коммита', 'охват_обычного_поручения'], СВЯЗНОСТЬ + 'сверить-материалы-этапа.py'),
    (['отчёты_создания_коммита', 'fum_машинный_отчёт_о_запусках'],
        'Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py'),
    (['свежесть_подготовки_этапа'], 'Инструменты/fum-svezhestj-markdown/scripts/update-md-recency.py'),
    (['fum_происхождение_сообщений_0177'], 'Инструменты/fum-snimki-indeksa/scripts/происхождение_сообщений.py'),
    (['формы_адресов_публичного_журнала'], 'Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/path_forms.py'),
]:
    ПСЕВДОНИМЫ.update({имя: путь for имя in имена})


def канон(значение):
    return json.dumps(значение, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()


def хэш(данные):
    return hashlib.sha256(данные).hexdigest()


def снимок(корень):
    return {str(п): [хэш(п.read_bytes()), п.stat().st_mode, п.stat().st_ino, п.stat().st_mtime_ns]
        for п in корень.rglob('*') if п.is_file()}


def образец():
    # Эти globals передаёт проверенный bootstrap после захвата; fixture imports здесь нет.
    import переход_происхождения_пары as переход
    вход, акт, выбор, каталог = ПРОФИЛЬНЫЙ_ВХОД
    стадии = {}; процессор = time.process_time_ns()
    начало = time.perf_counter_ns()
    план = переход.построить_план(вход, выбранное_поручение=акт, выбранный_переход=выбор)
    стадии['план_нс'] = time.perf_counter_ns() - начало
    ПРОФИЛЬНЫЙ_КОНТУР.сверить()
    начало = time.perf_counter_ns()
    первый = переход.применить_план(вход, план, ожидаемый_хэш=хэш(канон(план)),
        выбранное_поручение=акт, выбранный_переход=выбор)
    стадии['две_замены_нс'] = time.perf_counter_ns() - начало
    assert первый['записано'] == 2
    # Снимок включает W/.git, refs/index/config, все источники и внешние входы.
    ПРОФИЛЬНЫЙ_КОНТУР.сверить(); до = снимок(Path(каталог))
    начало = time.perf_counter_ns()
    второй = переход.применить_план(вход, план, ожидаемый_хэш=хэш(канон(план)),
        выбранное_поручение=акт, выбранный_переход=выбор)
    стадии['повтор_нс'] = time.perf_counter_ns() - начало
    assert второй['записано'] == 0 and до == снимок(Path(каталог))
    ПРОФИЛЬНЫЙ_КОНТУР.сверить()
    print(json.dumps({'pid': os.getpid(), 'стадии': стадии,
        'процессор_нс': time.process_time_ns() - процессор,
        'maxrss': resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
        'команд': len(план['команды']), 'записано': [первый['записано'], второй['записано']],
        'выходы': [{к: з[к] for к in ('путь', 'sha256', 'режим')} for з in план['выходы']]}, ensure_ascii=False))


ЗАПУСК_ДВИЖКА = '''import importlib.util,json,sys,time,hashlib
from pathlib import Path
# Только стандартная библиотека до hooks; проектные imports выполняет K.
import argparse,ast,configparser,datetime,decimal,html,inspect,platform,shlex,string,typing,urllib.parse,uuid,xml.etree.ElementTree,zoneinfo
а=json.loads(sys.argv[1]); п=Path(а['движок'])
assert hashlib.sha256(п.read_bytes()).hexdigest()==а['sha256']
с=importlib.util.spec_from_file_location('доверенный_движок_профиля',п)
м=importlib.util.module_from_spec(с);с.loader.exec_module(м)
н=time.perf_counter_ns()
к=м.захватить_источники(Path(а['код']),а['коммит'],а['пути'],
    {'корень':а['код'],'коммит':а['коммит'],'пути':а['ресурсы']})
захват=time.perf_counter_ns()-н
к.глобальные.update(ПРОФИЛЬНЫЙ_КОНТУР=к,ПРОФИЛЬНЫЙ_ВХОД=а['вход'])
н=time.perf_counter_ns();к.исполнить(а['entry'],имена=а['имена'],аргументы_запуска=['--образец'])
assert hashlib.sha256(п.read_bytes()).hexdigest()==а['sha256']
print(json.dumps({'захват_нс':захват,'исполнение_нс':time.perf_counter_ns()-н,'загрузки':к.журнал}))
'''


def главная():
    import statistics
    п = argparse.ArgumentParser(description=__doc__)
    п.add_argument('--выход', type=Path, required=True)
    а = п.parse_args(); assert not os.path.lexists(а.выход)
    корень = Path(__file__).resolve().parents[3]
    исходные = {п: {'sha256': хэш((корень / п).read_bytes()), 'режим': (корень / п).stat().st_mode}
        for п in [*ПУТИ, *РЕСУРСЫ, ДВИЖОК]}
    assert исходные[ДВИЖОК]['sha256'] == ХЭШ_ДВИЖКА
    # Нативная/Git фикстура создаётся только в родителе до измерений.
    sys.path.insert(0, str(Path(__file__).parent))
    from test_перехода_происхождения_пары import ФикстураПары
    образцы = []
    with tempfile.TemporaryDirectory() as временный:
        код = Path(временный).resolve() / 'K'; код.mkdir()
        среда = {к: з for к, з in os.environ.items() if not к.startswith('GIT_')}
        def гит(*аргументы):
            return subprocess.check_output(['git', '--no-optional-locks', '-C', str(код), *аргументы], env=среда)
        for имя in [*ПУТИ, *РЕСУРСЫ]:
            путь = код / имя; путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_bytes((корень / имя).read_bytes()); путь.chmod(0o644)
        гит('init', '-q'); гит('config', 'user.name', 'Фикстура'); гит('config', 'user.email', 'fixture@example.invalid')
        гит('add', '.'); гит('commit', '-qm', 'Конечный код фикстуры профиля')
        коммит = гит('rev-parse', 'HEAD').decode().strip()
        for _ in range(3):
            ф = ФикстураПары()
            try:
                ф.только_пара(); ф.прежняя_форма('буквальная')
                ф.люди(['Сохранить ёлку.\n', 'Сохранить другой оригинал.\n', 'Сохранить ёлку.\n'])
                аргументы = {'код': str(код), 'коммит': коммит, 'пути': ПУТИ, 'ресурсы': РЕСУРСЫ,
                    'движок': str(корень / ДВИЖОК), 'sha256': ХЭШ_ДВИЖКА, 'entry': ВХОД_ПРОФИЛЯ,
                    'имена': ПСЕВДОНИМЫ, 'вход': [ф.вход(), ф.фикс.выбор, ф.выбор(),
                        str(Path(ф.прежняя.каталог.name).resolve())]}
                начало = time.perf_counter_ns()
                р = subprocess.run([sys.executable, '-I', '-S', '-B', '-c', ЗАПУСК_ДВИЖКА,
                    json.dumps(аргументы)], cwd=ф.фикс.корень, capture_output=True, timeout=60)
                длительность = time.perf_counter_ns() - начало
                assert р.returncode == 0, (р.stdout + р.stderr).decode()
                строки = р.stdout.splitlines(); assert len(строки) == 2
                образцы.append({**json.loads(строки[0]), **json.loads(строки[1]), 'процесс_нс': длительность})
            finally:
                ф.закрыть()
    assert len({о['pid'] for о in образцы}) == 3 and all(о['pid'] != os.getpid() for о in образцы)
    assert исходные == {п: {'sha256': хэш((корень / п).read_bytes()), 'режим': (корень / п).stat().st_mode}
        for п in исходные}
    for о in образцы:
        загружены = {з['путь'] for з in о['загрузки'] if з['событие'] == 'exec'}
        assert ПАПКА + 'scripts/переход_происхождения_пары.py' in загружены
        assert all(з['sha256'] == исходные[з['путь']]['sha256'] and з['коммит'] == коммит for з in о['загрузки'])
    результат = {'схема': 'fum.профиль-перехода-происхождения-пары.1', 'образцы': образцы,
        'конечный_код_фикстуры': коммит, 'исходники_до_и_после': исходные,
        'медианы_нс': {к: statistics.median(о['стадии'][к] for о in образцы) for к in образцы[0]['стадии']},
        'граница': 'Три новых -I -S -B PID; 43 файла helper closure и профиль entry из точных Git blobs, два P1 ресурса. Fixture setup/commits вне таймера. Кэш ОС не сбрасывался. maxrss в единицах хоста. Это не приёмка рабочего K, D, ROOT или реальный consumer переход.',
        'решение_об_оптимизации': 'Полные повторные guards сохранены. Отказ прежней специализации не образует сравнимое успешное время; ускорение не заявляется.'}
    with а.выход.open('xb') as поток:
        поток.write(канон(результат) + b'\n')
    а.выход.chmod(0o600)
    print(json.dumps({'pid': [о['pid'] for о in образцы], 'медианы_нс': результат['медианы_нс']}, ensure_ascii=False))


if __name__ == '__main__':
    if sys.argv[1:] == ['--образец']:
        образец()
    else:
        главная()
