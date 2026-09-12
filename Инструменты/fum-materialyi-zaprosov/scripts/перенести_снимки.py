"""Адресно переносит URL-снимки из служебных каталогов Git по проверенному плану."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path, PurePosixPath
import sys

from source_archive import служебное_имя_Git, url_output_dir, validate_snapshot_manifest

ПАРСЕР = Path(__file__).parents[2] / "fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/scripts/pereimenovatj-fajl-s-obnovleniyem-ssyilok.py"
СПЕЦИФИКАЦИЯ = importlib.util.spec_from_file_location("перенос_снимков_ссылки", ПАРСЕР)
ССЫЛКИ = importlib.util.module_from_spec(СПЕЦИФИКАЦИЯ)
sys.modules[СПЕЦИФИКАЦИЯ.name] = ССЫЛКИ
СПЕЦИФИКАЦИЯ.loader.exec_module(ССЫЛКИ)


def хэш(байты):
    return hashlib.sha256(байты).hexdigest()


def путь_внутри(корень, имя):
    путь = PurePosixPath(имя)
    if путь.is_absolute() or not путь.parts or any(часть in {".", ".."} for часть in путь.parts):
        raise ValueError("Нужен точный относительный путь внутри checkout")
    текущий = корень
    for часть in путь.parts:
        текущий = текущий / часть
        if текущий.is_symlink():
            raise ValueError("Символическая ссылка в пути")
    return текущий


def подготовить(корень, вход):
    корень = корень.resolve()
    if set(вход) != {"каталоги", "markdown", "манифесты"} or not вход["каталоги"]:
        raise ValueError("Нужны каталоги, явные Markdown-ссылатели и JSON-манифесты")
    переносы = []; снимки = {}; изменения = {}; отображение = {}
    for имя in вход["каталоги"]:
        старый = путь_внутри(корень, имя)
        if not имя.startswith("Источники/URL/") or not служебное_имя_Git(старый.name) or not старый.is_dir():
            raise ValueError("Перенос ограничен служебным каталогом URL-снимка")
        for файл in старый.rglob("*"):
            if файл.is_symlink() or not файл.is_file():
                raise ValueError("Нужен плоский снимок из обычных файлов")
            снимки[файл.relative_to(корень).as_posix()] = хэш(файл.read_bytes())
        validate_snapshot_manifest(старый)
        адрес = (старый / "source-url.txt").read_text().strip()
        новый = url_output_dir(корень, адрес)
        путь_внутри(корень, новый.relative_to(корень).as_posix())
        if новый.parent != старый.parent or новый == старый or новый.exists() or старый in отображение or новый in отображение.values():
            raise ValueError("Коллизия или неподдержанный перенос промежуточного сегмента")
        отображение[старый] = новый
        переносы.append({"из": имя, "в": новый.relative_to(корень).as_posix(), "url": адрес})

    def новая_цель(цель):
        for старый, новый in отображение.items():
            if цель.is_relative_to(старый):
                return новый / цель.relative_to(старый)
        return цель

    for имя in вход["markdown"]:
        файл = путь_внутри(корень, имя)
        if файл.suffix != ".md" or имя.startswith(("Источники/", "Proyekcii/")):
            raise ValueError("Ссылатель должен быть каноническим производным Markdown")
        байты = файл.read_bytes(); текст = байты.decode(); маска = ССЫЛКИ.markdown_hidden_mask(текст)
        защита = ССЫЛКИ.request_text_spans(текст, маска, PurePosixPath(имя)) if файл.name == "запрос.md" else ()
        замены = []
        for токен in ССЫЛКИ.markdown_link_tokens(текст, маска):
            if ССЫЛКИ.position_in_spans(токен.destination_start, защита):
                continue
            цель = ССЫЛКИ.resolve_destination(токен, файл, корень, PurePosixPath(имя))
            if not цель.is_local or цель.target is None:
                continue
            новая = новая_цель(цель.target)
            if новая != цель.target:
                замены.append((токен.destination_start, токен.destination_end, ССЫЛКИ.rewritten_destination(файл, новая, цель, токен)))
        изменения[имя] = (байты, ССЫЛКИ.apply_text_replacements(текст, замены).encode())

    def обновить_поля(значение):
        if isinstance(значение, list):
            return [обновить_поля(элемент) for элемент in значение]
        if isinstance(значение, dict):
            результат = {}
            for ключ, элемент in значение.items():
                if ключ == "путь" and isinstance(элемент, str):
                    результат[ключ] = новая_цель(путь_внутри(корень, элемент)).relative_to(корень).as_posix()
                else:
                    результат[ключ] = обновить_поля(элемент)
            return результат
        return значение

    for имя in вход["манифесты"]:
        файл = путь_внутри(корень, имя)
        if файл.suffix != ".json" or имя.startswith(("Источники/", "Proyekcii/")):
            raise ValueError("Манифест должен быть отдельным каноническим JSON")
        байты = файл.read_bytes()
        новые = (json.dumps(обновить_поля(json.loads(байты)), ensure_ascii=False, indent=2) + "\n").encode()
        изменения[имя] = (байты, новые)
    план = {"схема": "fum.перенос-служебных-URL-снимков.1", "переносы": переносы,
            "байты_снимков": снимки, "файлы": {имя: {"до": хэш(пара[0]), "после": хэш(пара[1])} for имя, пара in изменения.items()}}
    return план, изменения


def построить_план(корень, вход):
    return подготовить(корень, вход)[0]


def применить(корень, вход, ожидаемый):
    план, изменения = подготовить(корень, вход)
    if план != ожидаемый:
        raise ValueError("Вход изменился после проверки плана")
    выполнены = []; записаны = []
    try:
        for перенос in план["переносы"]:
            (корень / перенос["из"]).rename(корень / перенос["в"])
            выполнены.append(перенос)
        for имя, (прежде, после) in изменения.items():
            записаны.append(имя)
            (корень / имя).write_bytes(после)
    except BaseException:
        for имя in reversed(записаны):
            (корень / имя).write_bytes(изменения[имя][0])
        for перенос in reversed(выполнены):
            (корень / перенос["в"]).rename(корень / перенос["из"])
        raise


def главная():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument("--корень-репозитория", required=True, type=Path)
    парсер.add_argument("--вход", required=True, type=Path)
    парсер.add_argument("--применить-план", type=Path)
    аргументы = парсер.parse_args()
    вход = json.loads(аргументы.вход.read_text())
    if аргументы.применить_план:
        применить(аргументы.корень_репозитория, вход, json.loads(аргументы.применить_план.read_text()))
        print("Проверенный план переноса применён")
    else:
        print(json.dumps(построить_план(аргументы.корень_репозитория, вход), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    главная()
