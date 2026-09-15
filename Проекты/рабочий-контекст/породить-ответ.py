"""Вызвать существующий исполнитель операторов для двух выходов одного описания."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys


def породить(исполнитель, описание, определения):
    данные = описание.read_bytes()
    результаты = {}
    for язык, имя in (("Swift", "МоделиОтвета.swift"), ("Python", "модели_ответа.py")):
        процесс = subprocess.run([str(исполнитель), "исполнить", "--определение",
            str(определения / ("генерация-" + язык + ".json")), "--вход", "текст"],
            input=данные, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        if процесс.returncode:
            raise ValueError("Исполнитель отклонил описание для " + язык)
        наблюдение = json.loads(процесс.stdout)
        if наблюдение["типВхода"] != "текст" or наблюдение["результат"]["тип"] != "текст":
            raise ValueError("Не совпал тип наблюдения оператора")
        if [шаг["идентификатор"] for шаг in наблюдение["шаги"]] != ["описание", "представление"]:
            raise ValueError("Нет двух исполняемых шагов генерации")
        if наблюдение["хэшИсходныхБайтов"] != "sha256:" + hashlib.sha256(данные).hexdigest():
            raise ValueError("Наблюдение не связано с исходными байтами описания")
        результаты[имя] = наблюдение["результат"]["значение"].encode("utf8")
    return результаты


def выполнить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--исполнитель", type=Path, required=True)
    разбор.add_argument("--описание", type=Path, default=Path(__file__).resolve().parent / "контракты/описание-ответа.json")
    разбор.add_argument("--выход", type=Path, required=True)
    разбор.add_argument("--проверить", action="store_true")
    параметры = разбор.parse_args()
    try:
        результаты = породить(параметры.исполнитель, параметры.описание, Path(__file__).resolve().parent / "контракты")
        if параметры.проверить:
            if any((параметры.выход / имя).read_bytes() != данные for имя, данные in результаты.items()):
                raise ValueError("Обнаружен дрейф порождённых файлов")
        else:
            параметры.выход.mkdir(parents=True, exist_ok=True)
            for имя, данные in результаты.items():
                (параметры.выход / имя).write_bytes(данные)
        print(json.dumps({имя: {"байты": len(данные), "sha256": hashlib.sha256(данные).hexdigest()}
            for имя, данные in результаты.items()}, ensure_ascii=False))
        return 0
    except (ValueError, OSError, KeyError, TypeError):
        print("Генерация или проверка дрейфа отклонена", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(выполнить())
