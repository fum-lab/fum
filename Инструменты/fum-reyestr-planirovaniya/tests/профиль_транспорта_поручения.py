"""Профиль чтения открытого нативного поручения; без Git, Desktop и сети."""
import argparse
import hashlib
import html
import json
from pathlib import Path
import statistics
import time

from test_транспорта_поручения import ПроверкаТранспортаПоручения, постановка


def измерить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", required=True)
    вход = разбор.parse_args()
    фикстура = ПроверкаТранспортаПоручения()
    фикстура.setUp()
    фазы = []
    try:
        for имя, кодирование, текст in (("прежний буквальный транспорт", "буквальный", фикстура.поручение),
                           ("XML-экранированный транспорт", "xml-v1", html.escape(фикстура.поручение, quote=False))):
            фикстура.записать(текст)
            исходник = фикстура.источник.read_bytes()
            замеры = []
            for _ in range(21):
                начало = time.perf_counter_ns()
                результат = постановка.прочитать_нативное_поручение(фикстура.источник, кодирование=кодирование)
                замеры.append(time.perf_counter_ns() - начало)
                assert результат["текст"] == фикстура.поручение
                assert результат["отправитель"] == фикстура.отправитель
            assert фикстура.источник.read_bytes() == исходник
            фазы.append({"стадия": имя, "повторы": len(замеры),
                         "наносекунды": замеры, "медиана_наносекунды": statistics.median(замеры),
                         "вход_байты": len(исходник), "вход_sha256": hashlib.sha256(исходник).hexdigest()})
    finally:
        фикстура.doCleanups()
    корень = Path(__file__).resolve().parents[3]
    пути = [Path(__file__).resolve(), Path(__file__).with_name("test_транспорта_поручения.py").resolve(),
            Path(постановка.__file__).resolve(), Path(постановка.хранение.__file__).resolve()]
    результат = {"схема": "fum.профиль-транспорта-поручения.1", "фазы": фазы,
                 "граница": "Открытая малая фикстура, один процесс, 21 чтение каждого формата; создание файла исключено. Нет экстраполяции на полный JSONL, допуск слоя или Desktop.",
                 "исходники": {п.relative_to(корень).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest() for п in пути}}
    with Path(вход.выход).open("x") as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
        поток.write("\n")
    print(json.dumps({"схема": результат["схема"], "фазы": [{k: v for k, v in фаза.items() if k != "наносекунды"} for фаза in фазы]}, ensure_ascii=False))


if __name__ == "__main__":
    измерить()
