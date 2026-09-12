"""Воспроизводимый профиль точного транспорта на открытых префиксах JSONL."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import statistics
import subprocess
import tempfile
import time
from unittest import mock

from test_нативного_поручения import ОТПРАВИТЕЛЬ, ПОРУЧЕНИЕ, ТЕКСТ_ТРАНСПОРТА, нативная_запись, строка
import постановка_задачи as постановка
from приём_направления import ОшибкаПриёма


def измерить(путь, ожидаемый_исход):
    вложенные = []
    чтение = постановка.прочитать_ограниченный_префикс

    def прочитать(*аргументы, **параметры):
        начало = time.perf_counter_ns()
        try:
            return чтение(*аргументы, **параметры)
        finally:
            вложенные.append(time.perf_counter_ns() - начало)

    with mock.patch.object(постановка, "прочитать_ограниченный_префикс", прочитать):
        начало = time.perf_counter_ns()
        try:
            граница = постановка.проверить_нативное_поручение(путь, ОТПРАВИТЕЛЬ, ПОРУЧЕНИЕ)
            исход = "принято"
        except ОшибкаПриёма:
            граница = None
            исход = "отклонено"
        длительность = time.perf_counter_ns() - начало
    if исход != ожидаемый_исход or len(вложенные) != 1:
        raise AssertionError("Неверный исход или граница измерения")
    return {"исход": исход, "всего_наносекунды": длительность,
            "вложенное_чтение_наносекунды": вложенные[0], "граница": граница}


def выполнить():
    корень = Path(__file__).resolve().parents[3]
    результаты = []
    with tempfile.TemporaryDirectory() as временный:
        место = Path(временный).resolve()
        for размер in (4096, 131072, 1048576):
            for вид, текст, ожидаемый in (("канонический", ТЕКСТ_ТРАНСПОРТА, "принято"),
                                          ("двойной", ТЕКСТ_ТРАНСПОРТА.replace("&", "&amp;"), "отклонено")):
                данные = строка({"type": "session_meta", "payload": {"открытый_наполнитель": "я" * (размер // 2)}}) + нативная_запись(текст)
                путь = место / (str(размер) + "-" + вид + ".jsonl")
                путь.write_bytes(данные)
                прогоны = [измерить(путь, ожидаемый) for _ in range(3)]
                эталон = {"граница": len(данные), "sha256": hashlib.sha256(данные).hexdigest()}
                if ожидаемый == "принято" and any(прогон["граница"] != эталон for прогон in прогоны):
                    raise AssertionError("Не сохранены точные байты префикса")
                результаты.append({"сценарий": вид, "целевой_размер": размер, "сырой_префикс": эталон,
                                    "прогоны": прогоны,
                                    "медиана_наносекунды": statistics.median(прогон["всего_наносекунды"] for прогон in прогоны)})
    пути = [Path(постановка.__file__).resolve(), Path(__file__).resolve(), Path(__file__).with_name("test_нативного_поручения.py").resolve()]
    return {"схема": "fum.профиль-нативного-поручения.1", "python": platform.python_version(),
            "HEAD": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=корень, text=True).strip(),
            "исходники": {str(путь.relative_to(корень)): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in пути},
            "метод": "Три повтора каждого размера и исхода; подготовка файлов вне измерения. Вложенное чтение входит во всё время и не суммируется с ним. Холодный файловый кэш не гарантирован.",
            "результаты": результаты}


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--результат", type=Path, required=True)
    параметры = разбор.parse_args()
    данные = выполнить()
    параметры.результат.parent.mkdir(parents=True, exist_ok=True)
    параметры.результат.write_text(json.dumps(данные, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"сценарии": len(данные["результаты"]), "медианы_наносекунды": [пункт["медиана_наносекунды"] for пункт in данные["результаты"]]}, ensure_ascii=False))
