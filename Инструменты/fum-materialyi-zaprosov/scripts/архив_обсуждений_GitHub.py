"""Неизменяемые байты обсуждений и автономное представление памяти Issues."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time
from urllib.parse import urlsplit, parse_qs, urlencode


def _байты_формата(значение):
    return (json.dumps(значение, ensure_ascii=False, sort_keys=True, indent=2) + '\n').encode('utf-8')


def _корень(корень, репозиторий):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', репозиторий):
        raise ValueError('Нужен точный владелец/репозиторий')
    if any(к in {'.', '..'} for к in репозиторий.split('/')):
        raise ValueError('Выход из каталога запрещён')
    корень = Path(корень).resolve(strict=True)
    путь = корень / 'Issues' / репозиторий
    текущий = корень
    for компонент in путь.relative_to(корень).parts:
        текущий /= компонент
        if текущий.is_symlink() or (текущий.exists() and not текущий.is_dir()):
            raise ValueError('Небезопасный каталог памяти')
    return путь


def _обычный(путь):
    if путь.is_symlink() or (путь.exists() and not путь.is_file()):
        raise ValueError('Нужен обычный файл')


def _синхронизировать_каталог(путь):
    дескриптор = os.open(путь, os.O_RDONLY)
    try:
        os.fsync(дескриптор)
    finally:
        os.close(дескриптор)


def _каталог(путь):
    if путь.is_symlink():
        raise ValueError('Символическая ссылка в памяти')
    if путь.exists():
        if not путь.is_dir():
            raise ValueError('Нужен каталог')
        return
    _каталог(путь.parent)
    путь.mkdir()
    _синхронизировать_каталог(путь.parent)
    _синхронизировать_каталог(путь)


def _неизменяемый(путь, байты):
    _обычный(путь)
    _каталог(путь.parent)
    if путь.exists():
        if путь.read_bytes() != байты:
            raise ValueError('Подмена уже сохранённых байтов')
        return
    временный = путь.with_name(путь.name + '.tmp'); _обычный(временный)
    with временный.open('xb') as выход:
        выход.write(байты)
        выход.flush()
        os.fsync(выход.fileno())
    os.replace(временный, путь)
    _синхронизировать_каталог(путь.parent)


def _метаданные(путь, значение):
    _обычный(путь)
    временный = путь.with_name(путь.name + '.tmp')
    _обычный(временный)
    with временный.open('xb') as выход:
        выход.write(_байты_формата(значение)); выход.flush(); os.fsync(выход.fileno())
    os.replace(временный, путь)
    _синхронизировать_каталог(путь.parent)


def _записи(байты):
    # Прежний gh --paginate сохранял последовательность самостоятельных JSON-массивов.
    текст = байты.decode('utf-8'); декодер = json.JSONDecoder(); позиция = 0; записи = []
    while позиция < len(текст):
        while позиция < len(текст) and текст[позиция].isspace():
            позиция += 1
        if позиция == len(текст):
            break
        часть, позиция = декодер.raw_decode(текст, позиция)
        if isinstance(часть, dict):
            часть = [часть]
        if not isinstance(часть, list) or any(not isinstance(к, dict) for к in часть):
            raise ValueError('Нужен объект или массив объектов GitHub')
        записи.extend(часть)
    if not текст.strip():
        raise ValueError('Пустой транспорт не является пустым списком')
    return записи


def _проверить_записи(тип, байты, репозиторий):
    if тип not in {'issues', 'comments'}:
        raise ValueError('Неизвестный тип обсуждения')
    записи = _записи(байты)
    for запись in записи:
        if type(запись.get('id')) is not int or запись['id'] <= 0:
            raise ValueError('Нет постоянного ID GitHub')
        if 'body' not in запись or not isinstance(запись.get('updated_at'), str):
            raise ValueError('Краткий список не содержит полного тела и версии')
        if тип == 'issues':
            if type(запись.get('number')) is not int or запись['number'] <= 0:
                raise ValueError('Нет номера Issue/PR')
            if not isinstance(запись.get('title'), str) or запись.get('state') not in {'open', 'closed'}:
                raise ValueError('Нет заголовка или состояния Issue')
            вид = 'pull' if 'pull_request' in запись else 'issues'
            if запись.get('html_url') != f"https://github.com/{репозиторий}/{вид}/{запись['number']}":
                raise ValueError('Issue другого репозитория')
        elif not re.fullmatch(r'https://api\.github\.com/repos/' + re.escape(репозиторий)
                             + r'/issues/[1-9][0-9]*', запись.get('issue_url', '')):
            raise ValueError('Комментарий другого репозитория')
        if запись.get('body') is not None and not isinstance(запись.get('body'), str):
            raise ValueError('Некорректное тело обсуждения')
    return записи


def _начать(корень, репозиторий, метка, связи):
    if not re.fullmatch(r'[\w.-]{1,160}', метка, flags=re.UNICODE) or метка in {'.', '..'}:
        raise ValueError('Неканоническая метка наблюдения')
    база = _корень(корень, репозиторий)
    каталог = база / 'наблюдения' / метка
    for родитель in (база / 'наблюдения', каталог, база / 'данные'):
        if родитель.is_symlink():
            raise ValueError('Символическая ссылка в памяти')
    файл = каталог / 'наблюдение.json'
    if файл.exists():
        _обычный(файл)
        return база, файл, json.loads(файл.read_bytes()), True
    _каталог(каталог)
    прежние = list((база / 'наблюдения').glob('*/наблюдение.json'))
    порядок = max((json.loads(к.read_bytes())['порядок'] for к in прежние), default=0) + 1
    данные = {'схема': 'fum.наблюдение-обсуждений-GitHub.1', 'репозиторий': репозиторий,
              'метка': метка, 'порядок': порядок,
              'время': datetime.now(timezone.utc).isoformat(), 'страницы': [],
              'полнота': False, 'состояние': 'неполное', 'связи': связи or {},
              'обработка': 'не разобрано', 'граница': 'Только полученные версии; ненаблюдённые редакции неизвестны.'}
    _метаданные(файл, данные)
    return база, файл, данные, False


def _страница(база, файл, данные, тип, байты, адрес=None, следующий=None):
    хэш = hashlib.sha256(байты).hexdigest()
    _неизменяемый(база / 'данные' / (хэш + '.json'), байты)
    данные['страницы'].append({'тип': тип, 'sha256': хэш, 'байты': len(байты),
                               'адрес': адрес, 'следующий': следующий, 'разбор': 'не проверен'})
    _метаданные(файл, данные)
    _проверить_записи(тип, байты, данные['репозиторий'])
    данные['страницы'][-1]['разбор'] = 'проверен'
    _метаданные(файл, данные)


def импортировать(корень, репозиторий, метка, страницы, *, полнота=False, связи=None):
    страницы = list(страницы)
    for тип, байты in страницы:
        _проверить_записи(тип, байты, репозиторий)
    база, файл, данные, повтор = _начать(корень, репозиторий, метка, связи)
    if повтор:
        ожидание = [(тип, hashlib.sha256(байты).hexdigest()) for тип, байты in страницы]
        фактически = [(к['тип'], к['sha256']) for к in данные['страницы']]
        if ожидание != фактически or полнота != данные['полнота'] or (связи or {}) != данные['связи']:
            raise ValueError('Неизвестный исход либо иные параметры прежней попытки')
        прочитать(корень, репозиторий)
        return {'повтор': True, 'наблюдение': данные}
    for тип, байты in страницы:
        _страница(база, файл, данные, тип, байты)
    данные['полнота'] = bool(полнота and {к['тип'] for к in данные['страницы']} == {'issues', 'comments'})
    данные['состояние'] = 'завершено' if данные['полнота'] else 'неполное'
    данные['граница'] = 'Полнота объявлена импортёром; HTTP-пагинация этим входом не доказана.'
    _метаданные(файл, данные)
    return {'повтор': False, 'наблюдение': данные}


def _запрос(адрес):
    разобранный = urlsplit(адрес)
    if разобранный.scheme != 'https' or разобранный.netloc != 'api.github.com' or разобранный.fragment:
        raise ValueError('Неожиданный адрес пагинации')
    ответ = subprocess.run(['gh', 'api', '--include', '--method', 'GET', адрес],
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True).stdout
    разделитель = b'\r\n\r\n' if b'\r\n\r\n' in ответ else b'\n\n'
    заголовки, тело = ответ.split(разделитель, 1)
    строки = заголовки.decode('ascii').splitlines()
    if not re.match(r'^HTTP/\S+ 200(?: |$)', строки[0]):
        raise ValueError('Нет успешного HTTP-ответа')
    следующие = []
    for строка in строки[1:]:
        if строка.lower().startswith('link:'):
            следующие += re.findall(r'<([^>]+)>;\s*rel="next"', строка)
    if len(следующие) > 1:
        raise ValueError('Неоднозначная следующая страница')
    return тело, следующие[0] if следующие else None


def _следующая(адрес, репозиторий, тип):
    if адрес is None:
        return None
    разобранный = urlsplit(адрес)
    хвост = '/issues' if тип == 'issues' else '/issues/comments'
    пути = [f'/repos/{репозиторий}{хвост}']
    if re.fullmatch(r'/repositories/[1-9][0-9]*' + re.escape(хвост), разобранный.path):
        пути.append(разобранный.path)
    if разобранный.scheme != 'https' or разобранный.netloc != 'api.github.com' or разобранный.fragment or разобранный.path not in пути:
        raise ValueError('Пагинация вышла из репозитория')
    параметры = parse_qs(разобранный.query, keep_blank_values=True)
    допустимые = {'page', 'per_page', 'after', 'before'} | ({'state'} if тип == 'issues' else set())
    if not set(параметры) <= допустимые or any(len(к) != 1 for к in параметры.values()):
        raise ValueError('Неоднозначные параметры пагинации')
    страница = параметры.get('page', [''])[0]
    if not re.fullmatch(r'[1-9][0-9]*', страница) or параметры.get('per_page', ['100']) != ['100']:
        raise ValueError('Неизвестная страница')
    if тип == 'issues' and параметры.get('state', ['all']) != ['all']:
        raise ValueError('Пагинация потеряла все состояния')
    запрос = {'page': страница, 'per_page': '100'}
    курсоры = set(параметры) & {'after', 'before'}
    if len(курсоры) > 1:
        raise ValueError('Неоднозначный курсор пагинации')
    for имя in курсоры:
        значение = параметры[имя][0]
        if not значение or len(значение) > 4096:
            raise ValueError('Некорректный курсор пагинации')
        запрос[имя] = значение
    if тип == 'issues':
        запрос['state'] = 'all'
    # Числовой URL Link сохраняется в наблюдении; запрос идёт по исходному имени
    # репозитория, поэтому чужой числовой ID не меняет область чтения.
    return f'https://api.github.com/repos/{репозиторий}{хвост}?' + urlencode(запрос)


def получить(корень, репозиторий, метка, *, транспорт=None, связи=None):
    база, файл, данные, повтор = _начать(корень, репозиторий, метка, связи)
    if повтор:
        raise ValueError('Сначала сверить сохранённый исход; слепой повтор чтения не допускается')
    транспорт = транспорт or _запрос
    начало = time.monotonic_ns()
    try:
        for тип, суффикс in [('issues', '/issues?state=all&per_page=100'),
                             ('comments', '/issues/comments?per_page=100')]:
            адрес = 'https://api.github.com/repos/' + репозиторий + суффикс
            просмотренные = set()
            while адрес:
                if адрес in просмотренные or len(просмотренные) >= 10000:
                    raise ValueError('Цикл или чрезмерная пагинация')
                if not адрес.startswith('https://api.github.com/repos/' + репозиторий + '/issues'):
                    raise ValueError('Пагинация вышла из репозитория')
                просмотренные.add(адрес)
                тело, следующий = транспорт(адрес)
                _страница(база, файл, данные, тип, тело, адрес, следующий)
                адрес = _следующая(следующий, репозиторий, тип)
        данные['полнота'] = True; данные['состояние'] = 'завершено'
        данные['граница'] = 'Завершены обе наблюдённые цепочки Link; это не атомарный снимок GitHub.'
    except Exception:
        данные['состояние'] = 'прервано'
        raise
    finally:
        данные['длительность_нс'] = time.monotonic_ns() - начало
        _метаданные(файл, данные)
    return данные


def прочитать(корень, репозиторий):
    база = _корень(корень, репозиторий)
    наблюдения = []
    папка = база / 'наблюдения'
    if папка.is_symlink() or (база / 'данные').is_symlink():
        raise ValueError('Небезопасный путь чтения')
    for файл in папка.glob('*/наблюдение.json'):
        if файл.parent.is_symlink():
            raise ValueError('Ссылка вместо наблюдения')
        _обычный(файл); запись = json.loads(файл.read_bytes())
        if запись.get('схема') != 'fum.наблюдение-обсуждений-GitHub.1' or запись.get('репозиторий') != репозиторий:
            raise ValueError('Иная схема или репозиторий')
        наблюдения.append(запись)
    наблюдения.sort(key=lambda к: к['порядок'])
    if len({к['порядок'] for к in наблюдения}) != len(наблюдения):
        raise ValueError('Неоднозначный порядок наблюдений')
    обращения = {}; виденные = {}; проверенные_страницы = {}
    for наблюдение in наблюдения:
        for страница in наблюдение['страницы']:
            хэш = страница['sha256']
            if not re.fullmatch(r'[0-9a-f]{64}', хэш):
                raise ValueError('Неканонический SHA256')
            ключ_страницы = (хэш, страница['тип'])
            if ключ_страницы not in проверенные_страницы:
                файл = база / 'данные' / (хэш + '.json'); _обычный(файл); байты = файл.read_bytes()
                if len(байты) != страница['байты'] or hashlib.sha256(байты).hexdigest() != хэш:
                    raise ValueError('Повреждённые исходные байты')
                записи = _проверить_записи(страница['тип'], байты, репозиторий)
                проверенные_страницы[ключ_страницы] = (len(байты), [
                    (запись, hashlib.sha256(_байты_формата(запись)).hexdigest()) for запись in записи])
            длина, записи = проверенные_страницы[ключ_страницы]
            if длина != страница['байты']:
                raise ValueError('Иная длина повторной страницы')
            for запись, версия in записи:
                номер = str(запись['number']) if страница['тип'] == 'issues' else запись['issue_url'].rsplit('/', 1)[1]
                карточка = обращения.setdefault(номер, {'версии': [], 'комментарии': {}, 'связи': [], 'обработка': 'не разобрано'})
                карточка['связи'] = sorted(set(карточка['связи']) | set(наблюдение['связи'].get(номер, [])))
                ключ = (страница['тип'], запись['id'], версия)
                if ключ in виденные:
                    continue
                виденные[ключ] = True
                if страница['тип'] == 'issues':
                    карточка['версии'].append(запись)
                else:
                    карточка['комментарии'].setdefault(str(запись['id']), []).append(запись)
    return {'схема': 'fum.локальная-история-обсуждений.1', 'репозиторий': репозиторий,
            'наблюдения': наблюдения, 'обращения': обращения,
            'последнее_наблюдение_полно': bool(наблюдения and наблюдения[-1]['полнота'])}


def выполнить():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--корень-репозитория', type=Path, required=True)
    парсер.add_argument('--репозиторий', default='fum-lab/fum')
    парсер.add_argument('--метка')
    парсер.add_argument('--номер', type=int)
    парсер.add_argument('операция', choices=['получить', 'прочитать'])
    аргументы = парсер.parse_args()
    if аргументы.операция == 'получить':
        if not аргументы.метка:
            парсер.error('Для нового наблюдения обязательна сохранённая метка')
        результат = получить(аргументы.корень_репозитория, аргументы.репозиторий, аргументы.метка)
        print(json.dumps(результат, ensure_ascii=False))
    else:
        результат = прочитать(аргументы.корень_репозитория, аргументы.репозиторий)
        if аргументы.номер is not None:
            результат['обращения'] = {str(аргументы.номер): результат['обращения'].get(str(аргументы.номер))}
        print(json.dumps(результат, ensure_ascii=False))


if __name__ == '__main__':
    выполнить()
