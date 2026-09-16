"""Адресно сверить данные новой привязки по точным объектам M и L."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from time import perf_counter_ns
import types


КОРЕНЬ = Path.cwd()
ОСНОВА = "e95d7f5d1ef6387454b7825932cfbd737e600473"
ВЕДУЩАЯ = "01ca988635628b48024ae64c290d3c4912aff060"
ДЕРЕВО = "fd0a746227a2d015d7cf9cb185eb7957dca0e0b8"
ОБЛАСТЬ = Path("Инструменты/fum-proverka-mashinno-lokaljnyikh-putej")


def гит(*аргументы):
    return subprocess.check_output(["git", "--no-replace-objects", *аргументы], cwd=КОРЕНЬ)


def байты_объекта(ревизия, путь):
    return гит("show", ревизия + ":" + str(путь))


def загрузить(имя, путь):
    модуль = types.ModuleType(имя)
    модуль.__file__ = str(КОРЕНЬ / путь)
    sys.modules[имя] = модуль
    exec(compile(байты_объекта(ОСНОВА, путь), модуль.__file__, "exec"), модуль.__dict__)
    return модуль


def проверить():
    начало = perf_counter_ns()
    политика = (КОРЕНЬ / ОБЛАСТЬ / "policy-кандидата-слияния.json").read_bytes()
    ожидаемая = байты_объекта(ВЕДУЩАЯ, ОБЛАСТЬ / "policy.json")
    if политика != ожидаемая:
        raise ValueError("Политика кандидата ещё не соответствует закреплённому L")
    обычная = (КОРЕНЬ / ОБЛАСТЬ / "policy.json").read_bytes()
    if обычная != байты_объекта(ОСНОВА, ОБЛАСТЬ / "policy.json"):
        raise ValueError("Обычная политика M изменена")
    if гит("rev-parse", ВЕДУЩАЯ + "^{tree}").decode().strip() != ДЕРЕВО:
        raise ValueError("Иное дерево L")
    прежние = {запись["id"]: запись for запись in json.loads(обычная)["exceptions"]}
    новые = {запись["id"]: запись for запись in json.loads(политика)["exceptions"]}
    if len(прежние) != 419 or len(новые) != 432 or any(новые.get(имя) != запись for имя, запись in прежние.items()):
        raise ValueError("Изменена граница 419 прежних и 13 новых записей")
    происхождение = json.loads((КОРЕНЬ / ОБЛАСТЬ / "происхождение-политики-слияния.json").read_bytes())
    if происхождение != {
        "схема": "fum.политика-слияния.1", "ведущая_основа": ВЕДУЩАЯ,
        "дерево_основы": ДЕРЕВО, "прежних_исключений": 419,
        "дополнительных_исключений": 13, "принятие_слияния": False,
        "путь_политики": str(ОБЛАСТЬ / "policy-кандидата-слияния.json"),
        "хэш_политики": "sha256:" + hashlib.sha256(политика).hexdigest(),
    }:
        raise ValueError("Происхождение не связывает точные L, дерево и политику")
    руководство = (КОРЕНЬ / ОБЛАСТЬ / "SKILL.md").read_text()
    if ВЕДУЩАЯ not in руководство or ДЕРЕВО not in руководство or "432 исключения" not in руководство:
        raise ValueError("Руководство не соответствует новой привязке")
    for путь in (Path(".gitmodules"), Path("Зависимости")):
        if гит("ls-tree", ОСНОВА, "--", str(путь)) != гит("ls-tree", ВЕДУЩАЯ, "--", str(путь)):
            raise ValueError("Изменена обычная граница зависимостей")
    загрузить("request_folder_layout", Path("Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py"))
    загрузить("path_forms", ОБЛАСТЬ / "scripts/path_forms.py")
    сканер = загрузить("сканер_привязки", ОБЛАСТЬ / "scripts/proveritj-mashinno-lokaljnyiye-puti.py")
    сканер.parse_policy(json.loads(политика))
    кэш = {}
    for запись in новые.values():
        путь = запись["path"]
        if путь not in кэш:
            кэш[путь] = сканер.scan_text(путь, байты_объекта(ВЕДУЩАЯ, путь).decode())
        совпадения = [находка for находка in кэш[путь]
                      if находка.category.startswith("error.") and находка.kind == запись["kind"]
                      and находка.line_sha256 == запись["line_sha256"]]
        if len(совпадения) != запись["count"]:
            raise ValueError("Неверные строки или число совпадений: " + запись["id"])
    print(json.dumps({"прежних": len(прежние), "добавлено": len(новые) - len(прежние),
                      "сверено": len(новые), "файлов_L": len(кэш),
                      "длительность_наносекунды": perf_counter_ns() - начало}, ensure_ascii=False))


if __name__ == "__main__":
    проверить()
