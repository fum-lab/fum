"""Конечный читатель сырых Git-объектов; архив переносим и не доверяет меткам."""
from __future__ import annotations

import base64
import hashlib
import json
import os
import re
import selectors
import subprocess
import sys
import tempfile
import time
import zlib
from pathlib import Path, PurePosixPath

ПРЕДЕЛ_ОБЪЕКТА = 8 * 1024 * 1024
ПРЕДЕЛ_ПАМЯТИ = 64 * 1024 * 1024
ПРЕДЕЛ_ПУТЕЙ = 32768
ПРЕДЕЛ_ГЛУБИНЫ = 64


def выполнить_ограниченно(команда, среда, вход=b"", предел=1024):
    """Ограничение потока действует во время чтения, до полного накопления."""
    if len(вход) > 128:
        raise ValueError("Превышен предел запроса Git")
    процесс = subprocess.Popen(команда, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=среда)
    потоки = {"выход": bytearray(), "ошибка": bytearray()}
    срок = time.monotonic() + 15
    try:
        процесс.stdin.write(вход)
        процесс.stdin.close()
        with selectors.DefaultSelector() as выбор:
            выбор.register(процесс.stdout, selectors.EVENT_READ, "выход")
            выбор.register(процесс.stderr, selectors.EVENT_READ, "ошибка")
            while выбор.get_map():
                осталось = срок - time.monotonic()
                if осталось <= 0:
                    raise subprocess.TimeoutExpired(команда, 15)
                for ключ, _ in выбор.select(осталось):
                    лимит = предел if ключ.data == "выход" else 4096
                    часть = os.read(ключ.fileobj.fileno(), min(65536, лимит - len(потоки[ключ.data]) + 1))
                    if not часть:
                        выбор.unregister(ключ.fileobj)
                    else:
                        потоки[ключ.data].extend(часть)
                        if len(потоки[ключ.data]) > лимит:
                            raise ValueError("Превышен предел вывода Git")
        код = процесс.wait(timeout=max(0.001, срок - time.monotonic()))
        return subprocess.CompletedProcess(команда, код, bytes(потоки["выход"]), bytes(потоки["ошибка"]))
    finally:
        if процесс.poll() is None:
            процесс.kill()
        процесс.wait()
        процесс.stdout.close()
        процесс.stderr.close()


def разобрать_архив(байты):
    def уникальные(пары):
        результат = {}
        for ключ, значение in пары:
            if ключ in результат:
                raise ValueError("Повторное поле архива")
            результат[ключ] = значение
        return результат
    if len(байты) > 64 * 1024 * 1024:
        raise ValueError("Превышен предел архива")
    архив = json.loads(байты, object_pairs_hook=уникальные)
    if (not isinstance(архив, dict) or set(архив) != {"схема", "цель", "примеры", "объекты"}
            or архив["схема"] != "fum.архив-объектов-внимания.1"
            or not isinstance(архив["цель"], str) or re.fullmatch("[0-9a-f]{40}", архив["цель"]) is None
            or not isinstance(архив["примеры"], list) or len(архив["примеры"]) > 16
            or not isinstance(архив["объекты"], dict)):
        raise ValueError("Неподдержанная оболочка архива")
    for пример in архив["примеры"]:
        if (not isinstance(пример, list) or len(пример) != 2 or not all(isinstance(п, str) for п in пример)
                or re.fullmatch("[0-9a-f]{40}", пример[0]) is None or not пример[1] or len(пример[1]) > 256):
            raise ValueError("Неверный пример архива")
    чтение = НаборОбъектов(архив["объекты"])
    for номер, запись in архив["объекты"].items():
        if (not isinstance(запись, dict) or set(запись) != {"тип", "байты"}
                or not isinstance(запись["тип"], str) or запись["тип"] not in {"commit", "tree", "blob"}):
            raise ValueError("Неверная запись архива")
        чтение.объект(номер, запись["тип"])
    return архив


def прочитать_архив(путь):
    with Path(путь).open("rb") as поток:
        return разобрать_архив(поток.read(64 * 1024 * 1024 + 1))


class НаборОбъектов:
    def __init__(сам, объекты=None, корень=None):
        сам.объекты = {} if объекты is None else объекты
        сам.корень = корень
        сам.кэш = {}
        сам.объём_кэша = 0
        if not isinstance(сам.объекты, dict) or len(сам.объекты) > 8192:
            raise ValueError("Неверный или слишком большой набор объектов")

    def объект(сам, номер, тип):
        if not isinstance(номер, str) or re.fullmatch("[0-9a-f]{40}", номер) is None:
            raise ValueError("Нужен полный SHA-1 OID")
        if (номер, тип) in сам.кэш:
            return сам.кэш[номер, тип]
        if номер not in сам.объекты and сам.корень is not None:
            if len(сам.объекты) >= 8192:
                raise ValueError("Превышен предел набора объектов")
            среда = {ключ: значение for ключ, значение in os.environ.items() if not ключ.startswith("GIT_")}
            среда.update(GIT_NO_REPLACE_OBJECTS="1", GIT_NO_LAZY_FETCH="1", GIT_OPTIONAL_LOCKS="0")
            команда = ["git", "-c", "core.fsmonitor=false", "-C", str(сам.корень), "cat-file"]
            метаданные = выполнить_ограниченно(команда + ["--batch-check"], среда, (номер + "\n").encode())
            поля = метаданные.stdout.split()
            if (метаданные.returncode or len(поля) != 3 or поля[0] != номер.encode() or поля[1] != тип.encode()
                    or not поля[2].isdigit()):
                raise ValueError("Git-объект недоступен либо имеет иной тип")
            размер = int(поля[2])
            if размер > ПРЕДЕЛ_ОБЪЕКТА or сам.объём_кэша + размер > ПРЕДЕЛ_ПАМЯТИ:
                raise ValueError("Превышен предел объекта либо памяти")
            ответ = выполнить_ограниченно(команда + ["--batch"], среда, (номер + "\n").encode(), размер + 128)
            заголовок, разделитель, остаток = ответ.stdout.partition(b"\n")
            поля = заголовок.split()
            if ответ.returncode or not разделитель or len(поля) != 3 or поля[0] != номер.encode() or поля[1] != тип.encode():
                raise ValueError("Git-объект недоступен либо имеет иной тип")
            if not поля[2].isdigit() or int(поля[2]) != размер or len(остаток) != размер + 1 or остаток[-1:] != b"\n":
                raise ValueError("Неполный пакетный ответ Git")
            сам.объекты[номер] = {"тип": тип, "байты": base64.b64encode(остаток[:-1]).decode()}
        запись = сам.объекты.get(номер)
        if not isinstance(запись, dict) or set(запись) != {"тип", "байты"} or запись["тип"] != тип:
            raise ValueError("Нет объекта требуемого типа")
        if not isinstance(запись["байты"], str) or len(запись["байты"]) > 4 * ((ПРЕДЕЛ_ОБЪЕКТА + 2) // 3):
            raise ValueError("Превышен предел закодированного объекта")
        try:
            байты = base64.b64decode(запись["байты"], validate=True)
        except (ValueError, TypeError) as ошибка:
            raise ValueError("Повреждены байты объекта") from ошибка
        if len(байты) > ПРЕДЕЛ_ОБЪЕКТА or тип not in {"commit", "tree", "blob"} or сам.объём_кэша + len(байты) > ПРЕДЕЛ_ПАМЯТИ:
            raise ValueError("Неподдержанный объект")
        проверенный = hashlib.sha1(тип.encode() + b" " + str(len(байты)).encode() + b"\0" + байты).hexdigest()
        if проверенный != номер:
            raise ValueError("OID не соответствует сырым байтам")
        сам.кэш[номер, тип] = байты
        сам.объём_кэша += len(байты)
        return байты

    def коммит(сам, номер):
        байты = сам.объект(номер, "commit")
        заголовок, разделитель, _ = байты.partition(b"\n\n")
        деревья = re.findall(rb"^tree ([0-9a-f]{40})$", заголовок, re.MULTILINE)
        родители = re.findall(rb"^parent ([0-9a-f]{40})$", заголовок, re.MULTILINE)
        if not разделитель or len(деревья) != 1 or len(родители) != len(set(родители)):
            raise ValueError("Неподдержанный заголовок коммита")
        if any(строка.startswith(b"parent ") and re.fullmatch(rb"parent [0-9a-f]{40}", строка) is None for строка in заголовок.splitlines()):
            raise ValueError("Неполный родитель коммита")
        return {"дерево": деревья[0].decode(), "родители": [родитель.decode() for родитель in родители]}

    def дерево(сам, номер):
        байты = сам.объект(номер, "tree")
        результат = {}
        позиция = 0
        while позиция < len(байты):
            конец = байты.find(b"\0", позиция)
            if конец < 0 or конец + 21 > len(байты):
                raise ValueError("Неполное дерево Git")
            поля = байты[позиция:конец].split(b" ", 1)
            if len(поля) != 2:
                raise ValueError("Неверная запись дерева")
            режим, имя = поля[0].decode(), поля[1].decode("utf-8")
            if имя in результат or имя in {"", ".", ".."} or "/" in имя:
                raise ValueError("Повторное либо неверное имя дерева")
            результат[имя] = (режим, байты[конец + 1:конец + 21].hex())
            позиция = конец + 21
        return результат

    def путь(сам, коммит, имя):
        путь = PurePosixPath(имя)
        if not имя or путь.is_absolute() or any(часть in {"", ".", ".."} for часть in имя.split("/")):
            raise ValueError("Нужен точный относительный путь")
        номер = сам.коммит(коммит)["дерево"]
        for порядковый, часть in enumerate(путь.parts):
            запись = сам.дерево(номер).get(часть)
            if запись is None:
                raise ValueError("Путь отсутствует в выбранном дереве")
            режим, номер = запись
            if порядковый < len(путь.parts) - 1 and режим != "40000":
                raise ValueError("Промежуточный путь не является деревом")
        return режим, номер

    def файл(сам, коммит, имя):
        режим, номер = сам.путь(коммит, имя)
        if режим not in {"100644", "100755"}:
            raise ValueError("Источник не является обычным файлом")
        return номер, сам.объект(номер, "blob")

    def файлы_каталога(сам, коммит, имя):
        режим, номер = сам.путь(коммит, имя)
        if режим != "40000":
            raise ValueError("Ожидался каталог")
        результат = {}
        for путь, (режим, объект) in сам.дерево(номер).items():
            if режим not in {"100644", "100755"}:
                raise ValueError("Каталог свидетельств содержит иной тип объекта")
            результат[путь] = сам.объект(объект, "blob")
        return результат

    def ancestry(сам, источник, цель):
        сам.коммит(источник)
        просмотрено = set()
        остаток = [цель]
        while остаток:
            номер = остаток.pop()
            if номер in просмотрено:
                continue
            if len(просмотрено) >= 4096:
                raise ValueError("История превысила конечный предел")
            коммит = сам.коммит(номер)
            просмотрено.add(номер)
            остаток.extend(коммит["родители"])
        # Положительный ответ тоже требует полного заявленного замыкания.
        return {"источник": источник, "цель": цель, "предок": "да" if источник in просмотрено else "нет",
                "полнота": "полная", "коммитов": len(просмотрено),
                "хэшИстории": hashlib.sha256("\n".join(sorted(просмотрено)).encode()).hexdigest()}

    def собрать_разницу(сам, старое, новое, сессия, префикс="", бюджет=None, глубина=0):
        бюджет = [0] if бюджет is None else бюджет
        if глубина > ПРЕДЕЛ_ГЛУБИНЫ:
            raise ValueError("Превышена глубина дерева")
        до = сам.дерево(старое) if старое else {}
        после = сам.дерево(новое) if новое else {}
        # Атрибуты на каждом затронутом пути — также исходные Git-объекты.
        for таблица in (до, после):
            if ".gitattributes" in таблица:
                режим, номер = таблица[".gitattributes"]
                if режим != "100644":
                    raise ValueError("Неподдержанный источник атрибутов")
                сам.объект(номер, "blob")
        for имя in sorted(set(до) | set(после)):
            бюджет[0] += 1
            if бюджет[0] > ПРЕДЕЛ_ПУТЕЙ:
                raise ValueError("Превышен предел путей разницы")
            путь = префикс + имя
            if (путь == "Proyekcii" or путь == (PurePosixPath(сессия) / "отчёт.md").as_posix()
                    or путь == (PurePosixPath(сессия) / "материалы" / "запуски-проверок").as_posix()):
                for таблица in (до, после):
                    if имя in таблица and таблица[имя][0] == "40000":
                        сам.дерево(таблица[имя][1])
                continue
            старый, новый = до.get(имя), после.get(имя)
            if старый == новый:
                continue
            if any(запись and запись[0] == "40000" for запись in (старый, новый)):
                сам.собрать_разницу(старый[1] if старый and старый[0] == "40000" else None,
                                   новый[1] if новый and новый[0] == "40000" else None, сессия, путь + "/", бюджет, глубина + 1)
            for запись in (старый, новый):
                if запись and запись[0] in {"100644", "100755", "120000"}:
                    сам.объект(запись[1], "blob")
                elif запись and запись[0] not in {"40000", "160000"}:
                    raise ValueError("Неподдержанный режим разницы")

    def замыкание_деревьев(сам, номер, просмотрено=None, глубина=0):
        if глубина > ПРЕДЕЛ_ГЛУБИНЫ:
            raise ValueError("Превышена глубина дерева")
        просмотрено = set() if просмотрено is None else просмотрено
        if номер in просмотрено:
            return
        if len(просмотрено) >= 4096:
            raise ValueError("Превышен предел деревьев")
        просмотрено.add(номер)
        for имя, (режим, дочерний) in сам.дерево(номер).items():
            if имя == ".gitattributes":
                raise ValueError("Первый профиль не поддерживает отслеживаемые атрибуты")
            if режим == "40000":
                сам.замыкание_деревьев(дочерний, просмотрено, глубина + 1)


def восстановить_отпечаток(чтение, коммит, сессия, корень_гит):
    """Точный v3 framing и Git diff; временные объекты вне Git, без записи refs."""
    каталог_инструмента = Path(__file__).resolve().parents[3] / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts"
    if str(каталог_инструмента) not in sys.path:
        sys.path.insert(0, str(каталог_инструмента))
    from связь_отпечатка_с_коммитом import ФЛАГИ_РАЗНИЦЫ, пути_границы, добавить_часть_отпечатка
    исходный = чтение.коммит(коммит)
    if len(исходный["родители"]) != 1:
        raise ValueError("Первый срез принимает приёмку коммита с одним родителем")
    родитель = исходный["родители"][0]
    прежде = чтение.коммит(родитель)
    просмотрено = set()
    чтение.замыкание_деревьев(прежде["дерево"], просмотрено)
    чтение.замыкание_деревьев(исходный["дерево"], просмотрено)
    чтение.собрать_разницу(прежде["дерево"], исходный["дерево"], сессия)
    среда = {ключ: значение for ключ, значение in os.environ.items() if not ключ.startswith("GIT_")}
    среда.update(GIT_NO_REPLACE_OBJECTS="1", GIT_NO_LAZY_FETCH="1", GIT_OPTIONAL_LOCKS="0", LC_ALL="C",
                 GIT_ATTR_NOSYSTEM="1", GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull,
                 GIT_ATTR_SOURCE=коммит, GIT_ALTERNATE_OBJECT_DIRECTORIES="")
    with tempfile.TemporaryDirectory(prefix="fum-объекты-внимания-") as временный:
        каталог = Path(временный)
        метаданные = каталог / "git"
        метаданные.mkdir()
        (метаданные / "refs").mkdir()
        (метаданные / "objects").mkdir()
        (метаданные / "HEAD").write_text(коммит + "\n")
        (метаданные / "config").write_text("[core]\n\tbare = true\n\trepositoryformatversion = 0\n")
        среда["GIT_DIR"] = str(метаданные)
        суммарно = 0
        for номер, запись in чтение.объекты.items():
            байты = чтение.объект(номер, запись["тип"])
            суммарно += len(байты)
            if суммарно > 64 * 1024 * 1024:
                raise ValueError("Архив превысил 64 МиБ")
            файл = каталог / номер[:2] / номер[2:]
            файл.parent.mkdir(exist_ok=True)
            файл.write_bytes(zlib.compress(запись["тип"].encode() + b" " + str(len(байты)).encode() + b"\0" + байты))
        среда["GIT_OBJECT_DIRECTORY"] = str(каталог)
        среда["GIT_INDEX_FILE"] = str(каталог / "неиспользуемый-индекс")
        итог = выполнить_ограниченно(["git", "-C", str(каталог), "-c", "core.fsmonitor=false", "-c", "core.attributesFile=" + os.devnull,
                               "diff", *ФЛАГИ_РАЗНИЦЫ, "--abbrev=8", родитель, коммит, "--", *пути_границы(сессия)],
                              среда, предел=16 * 1024 * 1024)
        if итог.returncode:
            raise ValueError("Разница не восстановлена из конечного архива Git: " + итог.stderr[:1024].decode("utf-8", errors="replace"))
    отпечаток = hashlib.sha256()
    добавить_часть_отпечатка(отпечаток, "вершина", родитель.encode())
    добавить_часть_отпечатка(отпечаток, "индекс", итог.stdout)
    добавить_часть_отпечатка(отпечаток, "рабочее_дерево", b"")
    return {"схема": "fum.связь-отпечатка-с-коммитом.1", "коммит": коммит, "родитель": родитель,
            "сессия": сессия, "режим": "исторический", "кандидат": "sha256:" + отпечаток.hexdigest(),
            "профиль": "Git default diff с abbrev=8, без атрибутов и внешней конфигурации",
            "хэшРазницы": hashlib.sha256(итог.stdout).hexdigest()}
