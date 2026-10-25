"""Bootstrap из Q: только stdlib до проверки всего конечного инвентаря."""
import hashlib
import json
import re
import subprocess
import time


def проверить_инвентарь(корень, закрепление, манифест, начальные_байты, чтение, компиляция):
    начало_интервала = time.perf_counter_ns()

    def строгий_объект(пары):
        результат = {}
        for ключ, значение in пары:
            if ключ in результат:
                raise ValueError("повтор JSON-ключа")
            результат[ключ] = значение
        return результат

    try:
        описание = json.loads(манифест, object_pairs_hook=строгий_объект,
            parse_constant=lambda _: (_ for _ in ()).throw(ValueError("нечисловая константа JSON")))
    except (UnicodeError, json.JSONDecodeError) as ошибка:
        raise ValueError("неверный JSON манифеста") from ошибка
    if not isinstance(описание, dict) or set(описание) != {"схема", "пространство", "каталог", "модули"} or описание["схема"] != "fum.проверенный-код.1":
        raise ValueError("неверная схема манифеста")
    пространство = описание["пространство"]
    каталог = описание["каталог"]
    if not isinstance(пространство, str) or not пространство.isidentifier() or каталог != пространство:
        raise ValueError("нужен один явно объявленный корневой пакет")
    коммит = закрепление["коммит"]

    def гит(*аргументы):
        try:
            return subprocess.check_output(["git", "--no-replace-objects", "-C", str(корень), *аргументы], stderr=subprocess.PIPE)
        except subprocess.CalledProcessError as ошибка:
            raise ValueError("Git-инвентарь недоступен") from ошибка

    запись_каталога = гит("ls-tree", "-z", коммит, "--", каталог)
    if not запись_каталога.startswith(b"040000 tree ") or not запись_каталога.endswith(b"\t" + каталог.encode() + b"\0") or запись_каталога.count(b"\0") != 1:
        raise ValueError("конечная область Q не является единственным деревом")
    инвентарь = {}
    for строка in гит("ls-tree", "-rz", "--full-tree", коммит, "--", каталог).split(b"\0"):
        if строка:
            мета, путь = строка.split(b"\t", 1)
            режим, вид, объект_гита = мета.decode("ascii").split()
            if вид != "blob" or режим != "100644":
                raise ValueError("инвентарь допускает только обычный Python-файл 100644")
            имя_пути = путь.decode("utf-8")
            if имя_пути in инвентарь:
                raise ValueError("повтор пути в дереве Q")
            инвентарь[имя_пути] = (режим, объект_гита)
    элементы = описание["модули"]
    if not isinstance(элементы, list) or not элементы:
        raise ValueError("нужен конечный непустой инвентарь")
    записи, байты, пути, пакеты = {}, {}, set(), set()
    for элемент in элементы:
        if not isinstance(элемент, dict) or set(элемент) != {"имя", "путь", "режим", "blob", "sha256"}:
            raise ValueError("неверная запись модуля")
        путь, имя = элемент["путь"], элемент["имя"]
        if not isinstance(путь, str) or not путь.startswith(каталог + "/") or not путь.endswith(".py") or any(
                not часть.isidentifier() for часть in путь[:-3].split("/")):
            raise ValueError("неканонический путь модуля")
        пакет = путь.split("/")[-1] == "__init__.py"
        ожидаемое_имя = путь[:-12].replace("/", ".") if пакет else путь[:-3].replace("/", ".")
        if имя != ожидаемое_имя or имя in записи or путь in пути:
            raise ValueError("коллизия или несогласованное имя модуля")
        if (элемент["режим"], элемент["blob"]) != инвентарь.get(путь):
            raise ValueError("режим или blob модуля не совпадает с Q")
        контрольная_сумма = элемент["sha256"]
        if not isinstance(контрольная_сумма, str) or not re.fullmatch(r"[0-9a-f]{64}", контрольная_сумма):
            raise ValueError("неверный SHA-256 модуля")
        записи[имя] = (путь, пакет)
        пути.add(путь)
        if пакет:
            пакеты.add(имя)
    if пути != set(инвентарь):
        raise ValueError("объявлен не полный инвентарь Q")
    if пространство not in пакеты or any(имя.rsplit(".", 1)[0] not in пакеты for имя in записи if "." in имя):
        raise ValueError("отсутствует объявленный родительский пакет")
    # Пакетное чтение уменьшает число Git-процессов; хэши остаются раздельными.
    try:
        процесс = subprocess.run(["git", "--no-replace-objects", "-C", str(корень), "cat-file", "--batch"],
            input=("\n".join(э["blob"] for э in элементы) + "\n").encode("ascii"),
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    except subprocess.CalledProcessError as ошибка:
        raise ValueError("пакет Git-объектов недоступен") from ошибка
    поток, позиция = процесс.stdout, 0
    for элемент in элементы:
        конец = поток.find(b"\n", позиция)
        if конец < 0:
            raise ValueError("нет заголовка Git blob")
        заголовок = поток[позиция:конец].split(b" ")
        if len(заголовок) != 3 or заголовок[:2] != [элемент["blob"].encode(), b"blob"] or not re.fullmatch(rb"0|[1-9][0-9]*", заголовок[2]):
            raise ValueError("неверный заголовок Git blob")
        размер = int(заголовок[2])
        начало = конец + 1
        конец = начало + размер
        if конец >= len(поток) or поток[конец:конец + 1] != b"\n":
            raise ValueError("неполный Git blob")
        данные = поток[начало:конец]
        позиция = конец + 1
        хэш_объекта = hashlib.sha1 if len(коммит) == 40 else hashlib.sha256
        if hashlib.sha256(данные).hexdigest() != элемент["sha256"] or хэш_объекта(
                b"blob " + str(len(данные)).encode() + b"\0" + данные).hexdigest() != элемент["blob"]:
            raise ValueError("байты модуля не совпадают с обоими хэшами")
        байты[элемент["имя"]] = данные
    if позиция != len(поток):
        raise ValueError("лишние байты пакетного Git-ответа")
    начало = пространство + ".начало"
    if записи.get(начало) != (закрепление["начало"]["путь"], False) or байты.get(начало) != начальные_байты:
        raise ValueError("bootstrap отсутствует в полном инвентаре")
    for имя in (пространство + ".снимок", пространство + ".загрузчик"):
        if имя not in записи or записи[имя][1]:
            raise ValueError("помощник отсутствует в полном инвентаре")
    чтение += time.perf_counter_ns() - начало_интервала
    # Вся проверка уже завершена. Ни один проектный import ещё не выполнялся.
    область = {"__name__": "_удержанные_помощники"}
    for суффикс in ("снимок", "загрузчик"):
        имя = пространство + "." + суффикс
        момент = time.perf_counter_ns()
        код = compile(байты[имя], f"git:{коммит}:{записи[имя][0]}", "exec", dont_inherit=True)
        компиляция += time.perf_counter_ns() - момент
        exec(код, область)
    return область["Снимок"](коммит, пространство, записи, байты, чтение, компиляция)
