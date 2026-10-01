#!/usr/bin/env python3
"""Проверка справки и закрытых отказов собранной команды; настоящую TDLib не подменяет."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time


def проверитьСинтетическуюБиблиотеку(исполняемый: Path) -> dict:
    исходникТранспорта = r'''#include <errno.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t ready = PTHREAD_COND_INITIALIZER;
static char queue[16][1024];
static unsigned int read_index = 0, write_index = 0, count = 0;
static char result[1024];

static void enqueue(const char *json) {
    if (count < 16) {
        snprintf(queue[write_index], sizeof(queue[write_index]), "%s", json);
        write_index = (write_index + 1) % 16;
        count++;
        pthread_cond_broadcast(&ready);
    }
}

static void extra_from(const char *request, char *extra, size_t capacity) {
    const char *start = strstr(request, "\"@extra\":\"");
    if (!start) { extra[0] = 0; return; }
    start += strlen("\"@extra\":\"");
    const char *end = strchr(start, '\"');
    if (!end) { extra[0] = 0; return; }
    size_t length = (size_t)(end - start);
    if (length >= capacity) length = capacity - 1;
    memcpy(extra, start, length);
    extra[length] = 0;
}

static void update_state(const char *state) {
    char json[1024];
    snprintf(json, sizeof(json),
             "{\"@type\":\"updateAuthorizationState\",\"@client_id\":1,\"authorization_state\":{\"@type\":\"%s\"}}",
             state);
    enqueue(json);
}

int32_t td_create_client_id(void) { return 1; }

void td_send(int32_t client_id, const char *request) {
    char extra[256];
    char json[1024];
    extra_from(request, extra, sizeof(extra));
    pthread_mutex_lock(&lock);
    if (strstr(request, "getAuthorizationState")) {
        update_state("authorizationStateWaitTdlibParameters");
        snprintf(json, sizeof(json),
                 "{\"@type\":\"authorizationStateWaitTdlibParameters\",\"@client_id\":%d,\"@extra\":\"%s\"}",
                 client_id, extra);
        enqueue(json);
    } else if (strstr(request, "close")) {
        snprintf(json, sizeof(json), "{\"@type\":\"ok\",\"@client_id\":%d,\"@extra\":\"%s\"}",
                 client_id, extra);
        enqueue(json);
        update_state("authorizationStateClosing");
        update_state("authorizationStateClosed");
    }
    pthread_mutex_unlock(&lock);
}

const char *td_receive(double timeout) {
    struct timespec deadline;
    clock_gettime(CLOCK_REALTIME, &deadline);
    deadline.tv_sec += (time_t)timeout;
    deadline.tv_nsec += (long)((timeout - (double)(time_t)timeout) * 1000000000.0);
    if (deadline.tv_nsec >= 1000000000L) { deadline.tv_sec++; deadline.tv_nsec -= 1000000000L; }
    pthread_mutex_lock(&lock);
    while (count == 0) {
        int status = pthread_cond_timedwait(&ready, &lock, &deadline);
        if (status == ETIMEDOUT) { pthread_mutex_unlock(&lock); return 0; }
    }
    snprintf(result, sizeof(result), "%s", queue[read_index]);
    read_index = (read_index + 1) % 16;
    count--;
    pthread_mutex_unlock(&lock);
    return result;
}
'''
    with tempfile.TemporaryDirectory(prefix='fum-telegram-tdlib-fixture-') as temp:
        root = Path(temp).resolve()
        исходныйФайл = root / 'tdjson-fixture.c'
        library = root / 'libtdjson-fixture.dylib'
        исходныйФайл.write_text(исходникТранспорта, encoding='utf-8')
        subprocess.run(['/usr/bin/clang', '-dynamiclib', '-pthread', '-o', str(library), str(исходныйФайл)],
                       capture_output=True, text=True, timeout=30, check=True)
        квитанция = root / 'квитанция.json'
        квитанция.write_bytes((json.dumps({
            'схема': 'fum.синтетическая-c-библиотека.1', 'исход': 'успех',
            'исходникSha256': hashlib.sha256(исходныйФайл.read_bytes()).hexdigest(),
            'компиляторSha256': hashlib.sha256(Path('/usr/bin/clang').resolve().read_bytes()).hexdigest(),
            'библиотекаSha256': hashlib.sha256(library.read_bytes()).hexdigest(),
            'библиотекаBytes': library.stat().st_size,
            'архитектуры': ['arm64'], 'символы': ['td_create_client_id', 'td_send', 'td_receive']
        }, ensure_ascii=False, sort_keys=True) + '\n').encode())
        хэшКвитанции = hashlib.sha256(квитанция.read_bytes()).hexdigest()
        аргументыПривязки = ['--библиотека', str(library), '--квитанция', str(квитанция), '--sha256-квитанции', хэшКвитанции]
        отказ = subprocess.run([str(исполняемый), *аргументыПривязки[:-1], '0' * 64], capture_output=True, text=True, timeout=15)
        assert отказ.returncode == 2, (отказ.stdout, отказ.stderr)
        assert 'Приватные данные' not in отказ.stderr
        runs = []
        for номер in range(2):
            result = subprocess.run([str(исполняемый), *аргументыПривязки, '--простой-секунд', '1'],
                                    capture_output=True, text=True, timeout=20)
            assert result.returncode == 0, (номер, result.returncode, result.stdout, result.stderr)
            report = json.loads(result.stdout)
            assert report['схема'] == 'fum.автономный-запуск-телеграма.1'
            assert report['библиотекаЗагружена'] is True and report.get('ошибка') is None
            assert report['начальныйОтвет']['тип'] == 'authorizationStateWaitTdlibParameters'
            assert report['закрытие']['всеЗакрыты'] and report['закрытие']['потокиЗавершены']
            assert not report['закрытие']['требуетсяРазбор']
            assert isinstance(report['загрузкаСекунд'], (int, float)) and report['загрузкаСекунд'] >= 0
            assert isinstance(report['закрытиеСекунд'], (int, float)) and report['закрытиеСекунд'] >= 0
            assert report['простой']['длительностьСекунд'] >= 1.0
            префиксАрхива = 'Приватный архив сохранён: '
            assert result.stderr.startswith(префиксАрхива) and result.stderr.count('\n') == 1
            кореньАрхива = Path(result.stderr[len(префиксАрхива):].strip())
            assert кореньАрхива.is_dir() and (кореньАрхива / 'ключ').stat().st_size == 32
            сегмент = кореньАрхива / 'журнал/обмен/сегмент.fumobs'
            хэшДоЧтения = hashlib.sha256(сегмент.read_bytes()).hexdigest()
            чтение = subprocess.run([str(исполняемый), '--проверить-архив', str(кореньАрхива), *аргументыПривязки],
                                    capture_output=True, text=True, timeout=20, check=True)
            assert hashlib.sha256(сегмент.read_bytes()).hexdigest() == хэшДоЧтения
            сводкаСохранённогоАрхива = json.loads(чтение.stdout)
            assert сводкаСохранённогоАрхива['привязка'] == report['привязка'] and сводкаСохранённогоАрхива['поколений'] == 1
            исходящиеКадры = [кадр for кадр in сводкаСохранённогоАрхива['кадры'] if кадр['направление'] == 'исходящееНамерение']
            входящиеКадры = [кадр for кадр in сводкаСохранённогоАрхива['кадры'] if кадр['направление'] == 'входящиеБайты']
            assert len(исходящиеКадры) == 2 and len(входящиеКадры) == 5
            for позиция, состояние in [(0, 'authorizationStateWaitTdlibParameters'), (3, 'authorizationStateClosing'), (4, 'authorizationStateClosed')]:
                эталон = ('{"@type":"updateAuthorizationState","@client_id":1,"authorization_state":{"@type":"' + состояние + '"}}').encode()
                assert входящиеКадры[позиция]['байтыШа256'] == hashlib.sha256(эталон).hexdigest()
            runs.append({'загрузкаСекунд': report['загрузкаСекунд'],
                         'связываниеСекунд': report['связываниеСекунд'], 'кадровВАрхиве': len(сводкаСохранённогоАрхива['кадры']),
                         'закрытиеСекунд': report['закрытиеСекунд'],
                         'закрытиеПодтверждено': report['закрытие']['всеЗакрыты']})
        return {'повторов': len(runs), 'исходы': runs,
                'граница': 'Прежняя синтетическая dylib проверяет C ABI и жизненный цикл; три литеральных входящих кадра сверены с архивом. Побайтный C-свидетель и отсутствие C-вызовов при replay этим fixture не удостоверены. Настоящая TDLib не заменена.'}


def проверить(исполняемый: Path) -> None:
    справка = subprocess.run([str(исполняемый), '--help'], capture_output=True, text=True, timeout=10, check=True)
    assert '--библиотека' in справка.stdout and 'без аккаунта' in справка.stdout
    случаи = [
        ([], 'неверные_входы'),
        (['--профиль', 'отмена', '--повторов', '0'], 'неверные_входы'),
        (['--профиль', 'отмена', '--повторов', '101'], 'неверные_входы'),
        (['--профиль', 'отмена', '--кадров', '2'], 'неверные_входы'),
        (['--профиль', 'неизвестный'], 'неверные_входы'),
        (['--профиль', 'поток', '--кадров', '0'], 'неверные_входы'),
        (['--профиль', 'поток', '--кадров', '2049'], 'неверные_входы'),
        (['--профиль', 'поток', '--кадров', 'нет'], 'неверные_входы'),
        (['--профиль', 'поток', '--библиотека', '/внешняя.dylib'], 'неверные_входы'),
        (['--raw', 'sendMessage'], 'неверные_входы'),
        (['--библиотека', 'относительный.dylib'], 'неверные_входы'),
        (['--библиотека', '/несуществующий/tdjson.dylib', '--простой-секунд', '0'], 'неверные_входы'),
        (['--библиотека', '/несуществующий/tdjson.dylib'], 'неверные_входы'),
    ]
    for аргументы, ошибка in случаи:
        результат = subprocess.run([str(исполняемый), *аргументы], capture_output=True, text=True, timeout=15)
        assert результат.returncode == 2, (аргументы, результат.returncode)
        отчёт = json.loads(результат.stdout)
        assert отчёт['схема'] == 'fum.автономный-запуск-телеграма.1'
        assert отчёт['библиотекаЗагружена'] is False
        assert отчёт['ошибка'] == ошибка
        assert 'начальныйОтвет' not in отчёт and 'простой' not in отчёт and 'закрытие' not in отчёт
    результат = subprocess.run([str(исполняемый), '--профиль', 'поток', '--кадров', '16'],
                               capture_output=True, text=True, timeout=30)
    assert результат.returncode == 0, (результат.returncode, результат.stdout, результат.stderr)
    отчёт = json.loads(результат.stdout)
    assert отчёт['схема'] == 'fum.профиль-клиента.1' and отчёт['сценарий'] == 'поток'
    assert отчёт['получено'] == отчёт['применено'] == 48
    assert отчёт['полученоБайтов'] == 48 * 4096 and отчёт['неприменено'] == 0
    assert отчёт['фикстурыШа256'] == отчёт['полученныеШа256'] == '13affc4f86b0e403deb5a24a403230bc8f9034bf0d676eafe8f1af36a6596d26'
    assert отчёт['байтыСохранены'] and отчёт['порядокСохранён']
    assert '--профиль поток' in справка.stdout
    результат = subprocess.run([str(исполняемый), '--профиль', 'отмена', '--повторов', '2'],
                               capture_output=True, text=True, timeout=30)
    assert результат.returncode == 0, (результат.returncode, результат.stdout, результат.stderr)
    отмена = json.loads(результат.stdout)
    assert отмена['схема'] == 'fum.профиль-клиента.1' and отмена['сценарий'] == 'отмена'
    assert отмена['хвостовПроверено'] == 7 and отмена['байтыСохранены']
    assert отмена['полученоКадров'] == отмена['непримененоКадров'] == 28
    assert отмена['примененоКадров'] == 0 and отмена['задержка']['число'] == 2
    assert len(отмена['измеренияНаносекунд']) == 2
    synthetic = проверитьСинтетическуюБиблиотеку(исполняемый)
    print(json.dumps({'случаев': len(случаи) + 5, 'исход': 'успех',
                      'исполняемый_sha256': hashlib.sha256(исполняемый.read_bytes()).hexdigest(),
                      'синтетическаяБиблиотека': synthetic}, ensure_ascii=False))


class НеполноеИзмерение(Exception):
    def __init__(self, отчёт: dict, диагностика: str):
        super().__init__('Профиль не завершён')
        self.отчёт = отчёт
        self.диагностика = диагностика


def текст_диагностики(значение) -> str:
    return значение.decode('utf-8', errors='replace') if isinstance(значение, bytes) else (значение or '')


def измерить(исполняемый: Path) -> dict:
    запуски = []
    отчёт = {'схема': 'fum.профили-команды.1', 'исполняемыйШа256': hashlib.sha256(исполняемый.read_bytes()).hexdigest(),
             'исполнительШа256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
             'граница': 'Два последовательных отдельных процесса, каждый ограничен 45 секундами; полный процесс включает запуск и очистку. Внутренние интервалы заданы каждым результатом.',
             'запуски': запуски}
    for сценарий, параметр, количество in [('поток', '--кадров', '1000'), ('отмена', '--повторов', '30')]:
        начало = time.perf_counter_ns()
        процесс = None
        try:
            процесс = subprocess.run([str(исполняемый), '--профиль', сценарий, параметр, количество],
                                     capture_output=True, text=True, timeout=45, check=True)
            длительность = time.perf_counter_ns() - начало
            результат = json.loads(процесс.stdout)
            if not isinstance(результат, dict) or результат.get('схема') != 'fum.профиль-клиента.1' or результат.get('сценарий') != сценарий or not результат.get('байтыСохранены'):
                raise ValueError('Не подтверждён исход профиля')
            if сценарий == 'поток' and (результат.get('измеряемыхКадров') != 1000 or результат.get('получено') != 1032
                                      or результат.get('применено') != 1032 or результат.get('неприменено') != 0):
                raise ValueError('Не совпало сохранение кадров потока')
            if сценарий == 'отмена' and (результат.get('измеряемыхОтмен') != 30 or результат.get('хвостовПроверено') != 35):
                raise ValueError('Не совпало число отмен и сохранённых хвостов')
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired, OSError, ValueError) as исключение:
            ошибка = {'сценарий': сценарий, 'процессНаносекунд': time.perf_counter_ns() - начало}
            if isinstance(исключение, subprocess.CalledProcessError):
                ошибка.update(причина='код_процесса', код=исключение.returncode)
            elif isinstance(исключение, subprocess.TimeoutExpired):
                ошибка.update(причина='тайм_аут', пределСекунд=45)
            else:
                ошибка['причина'] = 'запуск_недоступен' if isinstance(исключение, OSError) else 'неверный_результат'
            вывод = getattr(исключение, 'stdout', None) if процесс is None else процесс.stdout
            диагностика = getattr(исключение, 'stderr', None) if процесс is None else процесс.stderr
            подробности = f'Профиль {сценарий}: {ошибка["причина"]}\n'
            подробности += текст_диагностики(вывод) + '\n' + текст_диагностики(диагностика)
            if isinstance(исключение, OSError): подробности += '\n' + str(исключение)
            отчёт.update(исход='неуспех', ошибка=ошибка)
            raise НеполноеИзмерение(отчёт, подробности) from исключение
        запуски.append({'сценарий': сценарий, 'процессНаносекунд': длительность, 'результат': результат})
    return отчёт


def измерить_и_вывести(исполняемый: Path) -> int:
    try:
        отчёт = измерить(исполняемый)
    except НеполноеИзмерение as исключение:
        print(json.dumps(исключение.отчёт, ensure_ascii=False, indent=2))
        print(исключение.диагностика, file=sys.stderr)
        return 2
    print(json.dumps(отчёт, ensure_ascii=False, indent=2))
    return 0


def измерить_архив(исполняемый: Path) -> dict:
    начало = time.perf_counter_ns()
    процессПрофиля = subprocess.run([str(исполняемый), '--профиль', 'архив'], capture_output=True, text=True, timeout=60, check=True)
    длительность = time.perf_counter_ns() - начало
    профиль = json.loads(процессПрофиля.stdout)
    assert профиль['схема'] == 'fum.профиль-сырого-обмена.1'
    assert (профиль['прогрев'], профиль['входящих'], профиль['исходящих'], профиль['размерКадра']) == (32, 1000, 16, 4096)
    префиксАрхива = 'Приватный архив сохранён: '
    assert процессПрофиля.stderr.startswith(префиксАрхива) and процессПрофиля.stderr.count('\n') == 1
    приватныйКорень = Path(процессПрофиля.stderr[len(префиксАрхива):].strip())
    сегментПрофиля = приватныйКорень / 'журнал/обмен/сегмент.fumobs'
    прежнийХэш = hashlib.sha256(сегментПрофиля.read_bytes()).hexdigest()
    началоЧтения = time.perf_counter_ns()
    чтение = subprocess.run([str(исполняемый), '--проверить-архив', str(приватныйКорень)], capture_output=True, text=True, timeout=60, check=True)
    времяЧтения = time.perf_counter_ns() - началоЧтения
    assert hashlib.sha256(сегментПрофиля.read_bytes()).hexdigest() == прежнийХэш
    сохранённое = json.loads(чтение.stdout)
    def фикстура(порядковыйНомер):
        данные = ('{"@type":"fixture","n":' + str(порядковыйНомер) + ',"text":"ё"}').encode()
        return данные + b' ' * (4096 - len(данные))
    ожидаемыеКадры = [фикстура(порядковыйНомер) for порядковыйНомер in range(1032)] + [фикстура(порядковыйНомер) for порядковыйНомер in range(16)]
    хэш = hashlib.sha256(b''.join(ожидаемыеКадры)).hexdigest()
    assert профиль['сохранённыеШа256'] == сохранённое['сохранённыеШа256'] == хэш
    assert сохранённое['привязка'] == профиль['привязка'] and сохранённое['поколений'] == 1
    кадрыПрофиля = сохранённое['кадры']
    assert len(кадрыПрофиля) == 1048 and [элемент['порядок'] for элемент in кадрыПрофиля] == list(range(2, 1050))
    assert [элемент['байтыШа256'] for элемент in кадрыПрофиля] == [hashlib.sha256(элемент).hexdigest() for элемент in ожидаемыеКадры]
    assert [элемент['направление'] for элемент in кадрыПрофиля] == ['входящиеБайты'] * 1032 + ['исходящееНамерение'] * 16
    assert all(элемент['размер'] == 4096 for элемент in кадрыПрофиля)
    пакет = Path(__file__).resolve().parent.parent
    кореньРепозитория = пакет.parents[3]
    входы = []
    for выбранный in [пакет, пакет.parent / 'КонтейнерНаблюдений']:
        for исходныйФайл in sorted(выбранный.rglob('*')):
            if исходныйФайл.is_file() and исходныйФайл.suffix in {'.swift', '.py', '.json'} and not any(элемент in {'.build', '.swiftpm', '__pycache__'} for элемент in исходныйФайл.relative_to(выбранный).parts):
                if исходныйФайл.name != '2026-10-01-архив-обмена.json':
                    входы.append({'путь': str(исходныйФайл.relative_to(кореньРепозитория)), 'sha256': hashlib.sha256(исходныйФайл.read_bytes()).hexdigest()})
    return {'схема': 'fum.двухпроцессный-профиль-архива.1', 'исход': 'успех',
            'исполняемыйШа256': hashlib.sha256(исполняемый.read_bytes()).hexdigest(),
            'исполнительШа256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'профильПроцессаНаносекунд': длительность, 'чтениеНовогоПроцессаНаносекунд': времяЧтения,
            'независимыйШа256': хэш, 'прочитаноКадров': len(кадрыПрофиля), 'архивНеИзменился': True,
            'исполняемыеВходы': входы, 'результат': профиль,
            'граница': 'Открытые литеральные Python-фикстуры сверены с отдельным процессом чтения. Внутренний поток проходит wrapper/очередь/actor/JSON; C ABI отдельно. SDK и исходный машинный код receipt этим измерением не удостоверены.'}


if __name__ == '__main__':
    assert len(sys.argv) in (2, 3), 'Требуется абсолютный путь собранной команды и необязательный --измерить'
    исполняемый = Path(sys.argv[1])
    assert исполняемый.is_absolute() and исполняемый.is_file()
    if len(sys.argv) == 3:
        assert sys.argv[2] in {'--измерить', '--измерить-архив'}
        if sys.argv[2] == '--измерить-архив':
            print(json.dumps(измерить_архив(исполняемый), ensure_ascii=False, indent=2))
        else:
            raise SystemExit(измерить_и_вывести(исполняемый))
    else:
        проверить(исполняемый)
