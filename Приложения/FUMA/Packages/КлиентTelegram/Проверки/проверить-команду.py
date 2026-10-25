#!/usr/bin/env python3
"""Проверка справки и закрытых отказов собранной команды; настоящую TDLib не подменяет."""
import hashlib
import json
import math
import os
import stat
from pathlib import Path
import subprocess
import sys
import tempfile
import time


ИСХОДНИК_ТРАНСПОРТА = r'''#include <errno.h>
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


def проверитьКомпилятор() -> Path:
    путь = Path(os.environ.get('ФУМ_КОМПИЛЯТОР', ''))
    if not путь.is_absolute():
        raise ValueError('Требуется явный абсолютный ФУМ_КОМПИЛЯТОР')
    физический = путь.resolve(strict=True)
    if not stat.S_ISREG(физический.stat().st_mode) or not os.access(физический, os.X_OK):
        raise ValueError('Выбранный компилятор не является исполняемым обычным файлом')
    return физический


def проверитьSDK() -> Path:
    путь = Path(os.environ.get('SDKROOT', ''))
    if not путь.is_absolute():
        raise ValueError('Требуется явный абсолютный SDKROOT')
    физический = путь.resolve(strict=True)
    if not физический.is_dir():
        raise ValueError('SDKROOT должен быть каталогом')
    return физический


def проверитьСинтетическуюБиблиотеку(исполняемый: Path) -> dict:
    компилятор = проверитьКомпилятор()
    sdk = проверитьSDK()
    хэшКомпилятора = hashlib.sha256(компилятор.read_bytes()).hexdigest()
    исходникТранспорта = ИСХОДНИК_ТРАНСПОРТА
    with tempfile.TemporaryDirectory(prefix='fum-telegram-tdlib-fixture-') as temp:
        root = Path(temp).resolve()
        исходныйФайл = root / 'tdjson-fixture.c'
        library = root / 'libtdjson-fixture.dylib'
        исходныйФайл.write_text(исходникТранспорта, encoding='utf-8')
        subprocess.run([str(компилятор), '-isysroot', str(sdk), '-dynamiclib', '-pthread', '-o', str(library), str(исходныйФайл)],
                       capture_output=True, text=True, timeout=30, check=True)
        квитанция = root / 'квитанция.json'
        квитанция.write_bytes((json.dumps({
            'схема': 'fum.синтетическая-c-библиотека.1', 'исход': 'успех',
            'исходникSha256': hashlib.sha256(исходныйФайл.read_bytes()).hexdigest(),
            'компиляторSha256': хэшКомпилятора,
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


def потребовать(условие: bool, причина: str) -> None:
    if not условие:
        raise ValueError(причина)


def заменитьОдинРаз(текст: str, прежнее: str, новое: str) -> str:
    потребовать(текст.count(прежнее) == 1, 'Нет единственного фрагмента C-фикстуры')
    return текст.replace(прежнее, новое, 1)


def снимокПриватногоАрхива(корень: Path) -> list:
    потребовать(корень.is_dir() and not корень.is_symlink(), 'Нет приватного архива')
    снимок = []
    for путь in [корень, *sorted(корень.rglob('*'))]:
        сведения = путь.lstat()
        потребовать(not stat.S_ISLNK(сведения.st_mode), 'Ссылка в приватном архиве')
        каталог = stat.S_ISDIR(сведения.st_mode)
        потребовать(каталог or stat.S_ISREG(сведения.st_mode), 'Нестандартный файл архива')
        режим = stat.S_IMODE(сведения.st_mode)
        потребовать(режим == (0o700 if каталог else 0o600), 'Неприватный режим архива')
        запись = {'путь': str(путь.relative_to(корень)), 'режим': режим, 'каталог': каталог}
        if not каталог:
            запись.update(байты=сведения.st_size, sha256=hashlib.sha256(путь.read_bytes()).hexdigest())
        снимок.append(запись)
    return снимок


def проверитьИнтервал(отчёт: dict, имя: str, минимум: float = 0) -> None:
    значение = отчёт.get(имя)
    потребовать(type(значение) in (int, float) and math.isfinite(значение)
               and значение >= минимум, 'Не подтверждён интервал ' + имя)


def измеритьПроцесс(аргументы: list, измерение: dict, фаза: str, поле: str,
                   каталог: Path, предел: int) -> subprocess.CompletedProcess:
    измерение['фаза'] = фаза
    начало = time.perf_counter_ns()
    вывод, ошибки = b'', b''
    try:
        результат = subprocess.run(аргументы, capture_output=True, timeout=предел)
        вывод, ошибки = результат.stdout, результат.stderr
        return результат
    except subprocess.TimeoutExpired as ошибка:
        вывод, ошибки = ошибка.output or b'', ошибка.stderr or b''
        raise
    finally:
        измерение[поле] = time.perf_counter_ns() - начало
        префикс = '' if фаза == 'запуск' else фаза + '-'
        (каталог / (префикс + 'stdout.bin')).write_bytes(вывод)
        (каталог / (префикс + 'stderr.bin')).write_bytes(ошибки)


def проверитьОтказы(исполняемый: Path) -> int:
    измерения = []
    каталогФикстур = None
    профиль = {'схема': 'fum.профиль-отказов-команды-телеграма.1', 'исход': 'неуспех',
               'измерения': измерения,
               'граница': 'Четыре синтетические C ABI библиотеки; отдельные процессы запуска и чтения. '
               'Внешний предел 45 секунд — отказ исполнителя. Кэши ОС не очищены. Настоящая TDLib не проверена.'}
    try:
        потребовать(исполняемый.is_absolute() and исполняемый.is_file(), 'Нет абсолютного пути команды')
        компилятор = проверитьКомпилятор()
        sdk = проверитьSDK()
        хэшКомпилятора = hashlib.sha256(компилятор.read_bytes()).hexdigest()
        профиль.update(исполняемыйШа256=hashlib.sha256(исполняемый.read_bytes()).hexdigest(),
                       исполнительШа256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                       основнойИсходникШа256=hashlib.sha256(
                           (Path(__file__).parent.parent / 'Sources/ПроверкаTelegram/main.swift').read_bytes()).hexdigest())
        начальныйФормат = r'\"authorizationStateWaitTdlibParameters\",\"@client_id\":%d,\"@extra\":\"%s\"'
        инструментированный = заменитьОдинРаз(
            ИСХОДНИК_ТРАНСПОРТА,
            'void td_send(int32_t client_id, const char *request) {',
            'void td_send(int32_t client_id, const char *request) {\n'
            r'    fprintf(stderr, "Фикстура отправки:%d:%s\n", client_id, request);')
        варианты = [
            ('неверная-корреляция', заменитьОдинРаз(инструментированный, начальныйФормат,
                начальныйФормат.replace(r'\"%s\"', r'\"чужая-%s\"'))),
            ('нет-корреляции', заменитьОдинРаз(инструментированный,
                начальныйФормат + r'}",' + '\n                 client_id, extra);',
                r'\"authorizationStateWaitTdlibParameters\",\"@client_id\":%d}",' + '\n                 client_id);')),
            ('неподходящее-состояние', заменитьОдинРаз(инструментированный, начальныйФормат,
                начальныйФормат.replace('authorizationStateWaitTdlibParameters', 'authorizationStateWaitPhoneNumber'))),
            ('нет-Closed', заменитьОдинРаз(инструментированный,
                'update_state("authorizationStateClosed");', 'update_state("authorizationStateClosing");')),
        ]
        каталогФикстур = Path(tempfile.mkdtemp(prefix='fum-telegram-cli-failures-')).resolve()
        for имя, исходник in варианты:
            измерение = {'сценарий': имя, 'исход': 'неуспех'}
            измерения.append(измерение)
            каталог = каталогФикстур / имя
            каталог.mkdir(mode=0o700)
            исходныйФайл = каталог / 'tdjson-fixture.c'
            библиотека = каталог / 'libtdjson-fixture.dylib'
            исходныйФайл.write_text(исходник, encoding='utf-8')
            компиляция = измеритьПроцесс(
                [str(компилятор), '-isysroot', str(sdk), '-dynamiclib', '-pthread', '-o', str(библиотека), str(исходныйФайл)],
                измерение, 'компиляция', 'компиляцияНаносекунд', каталог, 30)
            измерение['кодКомпиляции'] = компиляция.returncode
            потребовать(компиляция.returncode == 0, 'Компиляция фикстуры отказала')
            квитанция = каталог / 'квитанция.json'
            данныеКвитанции = {
                'схема': 'fum.синтетическая-c-библиотека.1', 'исход': 'успех',
                'исходникSha256': hashlib.sha256(исходныйФайл.read_bytes()).hexdigest(),
                'компиляторSha256': хэшКомпилятора,
                'библиотекаSha256': hashlib.sha256(библиотека.read_bytes()).hexdigest(),
                'библиотекаBytes': библиотека.stat().st_size,
                'архитектуры': ['arm64'], 'символы': ['td_create_client_id', 'td_send', 'td_receive']}
            квитанция.write_bytes((json.dumps(данныеКвитанции, ensure_ascii=False, sort_keys=True) + '\n').encode())
            хэшКвитанции = hashlib.sha256(квитанция.read_bytes()).hexdigest()
            привязка = ['--библиотека', str(библиотека), '--квитанция', str(квитанция),
                        '--sha256-квитанции', хэшКвитанции]
            измерение.update(исходникШа256=данныеКвитанции['исходникSha256'],
                            библиотекаШа256=данныеКвитанции['библиотекаSha256'], квитанцияШа256=хэшКвитанции)
            результат = измеритьПроцесс([str(исполняемый), *привязка, '--простой-секунд', '1'],
                                       измерение, 'запуск', 'процессНаносекунд', каталог, 45)
            измерение['код'] = результат.returncode
            потребовать(результат.returncode == 2, 'Нет штатного кода 2')
            отчёт = json.loads(результат.stdout)
            потребовать(type(отчёт) is dict and отчёт.get('схема') == 'fum.автономный-запуск-телеграма.1'
                       and отчёт.get('библиотекаЗагружена') is True
                       and отчёт.get('ошибка') == 'требуется_разбор', 'Неверная причина отказа')
            проверитьИнтервал(отчёт, 'ожиданиеОтветаСекунд', 5 if имя in ('неверная-корреляция', 'нет-корреляции') else 0)
            измерение['ожиданиеОтветаСекунд'] = отчёт['ожиданиеОтветаСекунд']
            проверитьИнтервал(отчёт, 'закрытиеСекунд', 5 if имя == 'нет-Closed' else 0)
            измерение['закрытиеСекунд'] = отчёт['закрытиеСекунд']
            for поле in ('загрузкаСекунд', 'связываниеСекунд'):
                проверитьИнтервал(отчёт, поле)
                измерение[поле] = отчёт[поле]
            закрытие = отчёт.get('закрытие', {})
            потребовать(type(закрытие) is dict, 'Неверная форма закрытия')
            потребовать(закрытие.get('всеЗакрыты') is (имя != 'нет-Closed')
                       and закрытие.get('потокиЗавершены') is True
                       and закрытие.get('требуетсяРазбор') is (имя == 'нет-Closed'), 'Неверная очистка')
            if имя in ('неверная-корреляция', 'нет-корреляции'):
                потребовать('начальныйОтвет' not in отчёт and 'простой' not in отчёт, 'Обновление заменило ответ')
            else:
                тип = 'authorizationStateWaitPhoneNumber' if имя == 'неподходящее-состояние' else 'authorizationStateWaitTdlibParameters'
                начальный = отчёт.get('начальныйОтвет')
                потребовать(type(начальный) is dict and начальный.get('тип') == тип, 'Неверный начальный ответ')
                потребовать(('простой' in отчёт) is (имя == 'нет-Closed'), 'Неверная граница простоя')
            строки = результат.stderr.splitlines()
            маркер = 'Фикстура отправки:1:'.encode()
            потребовать(len(строки) == 3 and all(строка.startswith(маркер) for строка in строки[:2]),
                       'Нет двух прямых вызовов C-send')
            исходящие = [строка[len(маркер):] for строка in строки[:2]]
            запросы = [json.loads(байты) for байты in исходящие]
            потребовать(all(type(запрос) is dict for запрос in запросы), 'Неверная форма отправленных запросов')
            потребовать([запрос.get('@type') for запрос in запросы] == ['getAuthorizationState', 'close'],
                       'Лишняя или неверная отправка')
            потребовать(all(type(запрос.get('@extra')) is str and запрос['@extra'] for запрос in запросы)
                       and запросы[0]['@extra'] != запросы[1]['@extra'], 'Нет уникальных корреляций')
            префикс = 'Приватные данные для разбора: '.encode()
            потребовать(строки[2].startswith(префикс), 'Не сохранён путь аварийного архива')
            кореньАрхива = Path(строки[2][len(префикс):].decode())
            снимок = снимокПриватногоАрхива(кореньАрхива)
            чтение = измеритьПроцесс([str(исполняемый), '--проверить-архив', str(кореньАрхива), *привязка],
                                    измерение, 'чтение', 'чтениеНаносекунд', каталог, 45)
            измерение['кодЧтения'] = чтение.returncode
            потребовать(чтение.returncode == 0 and чтение.stderr == b'', 'Чтение вызвало C-send или отказало')
            потребовать(снимокПриватногоАрхива(кореньАрхива) == снимок, 'Чтение изменило приватный архив')
            сохранённое = json.loads(чтение.stdout)
            потребовать(type(сохранённое) is dict, 'Неверная форма сводки архива')
            потребовать(сохранённое.get('поколений') == 1 and сохранённое.get('привязка') == отчёт['привязка'],
                       'Неверная привязка сохранённого архива')
            кадры = сохранённое.get('кадры', [])
            потребовать(type(кадры) is list and len(кадры) == 7 and all(type(кадр) is dict for кадр in кадры)
                       and [кадр['порядок'] for кадр in кадры] == list(range(2, 9)),
                       'Потеря или перестановка кадров')
            исходящиеКадры = [кадр for кадр in кадры if кадр['направление'] == 'исходящееНамерение']
            входящиеКадры = [кадр for кадр in кадры if кадр['направление'] == 'входящиеБайты']
            def обновление(состояние):
                return ('{"@type":"updateAuthorizationState","@client_id":1,"authorization_state":{"@type":"' + состояние + '"}}').encode()
            типОтвета = 'authorizationStateWaitPhoneNumber' if имя == 'неподходящее-состояние' else 'authorizationStateWaitTdlibParameters'
            ответ = {'@type': типОтвета, '@client_id': 1}
            if имя != 'нет-корреляции':
                ответ['@extra'] = ('чужая-' if имя == 'неверная-корреляция' else '') + запросы[0]['@extra']
            входящие = [обновление('authorizationStateWaitTdlibParameters'),
                        json.dumps(ответ, ensure_ascii=False, separators=(',', ':')).encode(),
                        json.dumps({'@type': 'ok', '@client_id': 1, '@extra': запросы[1]['@extra']},
                                   ensure_ascii=False, separators=(',', ':')).encode(),
                        обновление('authorizationStateClosing'),
                        обновление('authorizationStateClosing' if имя == 'нет-Closed' else 'authorizationStateClosed')]
            for группа, эталоны in [(исходящиеКадры, исходящие), (входящиеКадры, входящие)]:
                потребовать(len(группа) == len(эталоны), 'Неверное число кадров направления')
                потребовать([(кадр['размер'], кадр['байтыШа256']) for кадр in группа]
                           == [(len(байты), hashlib.sha256(байты).hexdigest()) for байты in эталоны],
                           'Байты не совпали с независимым оракулом')
            потребовать(исходящиеКадры[0]['порядок'] < входящиеКадры[0]['порядок']
                       and исходящиеКадры[1]['порядок'] < входящиеКадры[2]['порядок'], 'Нарушена причинная граница send')
            измерение.update(исход='успех', архивНеИзменился=True,
                            отправок=2, кадров=кадры, снимокАрхива=снимок)
        профиль['исход'] = 'успех'
        print(json.dumps(профиль, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as ошибка:
        профиль['ошибка'] = 'внешний_тайм_аут' if isinstance(ошибка, subprocess.TimeoutExpired) else 'неподтверждённая_проверка'
        print(json.dumps(профиль, ensure_ascii=False, indent=2))
        print('Проверка отказов не завершена: ' + str(ошибка), file=sys.stderr)
        if каталогФикстур is not None:
            print('Приватные материалы проверки: ' + str(каталогФикстур), file=sys.stderr)
        return 2


if __name__ == '__main__':
    if '--проверить-отказы' in sys.argv[1:]:
        if len(sys.argv) != 3 or sys.argv[2] != '--проверить-отказы':
            print('Требуется абсолютный путь команды и единственный --проверить-отказы', file=sys.stderr)
            raise SystemExit(2)
        raise SystemExit(проверитьОтказы(Path(sys.argv[1])))
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
