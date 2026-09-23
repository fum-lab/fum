"""Монотонный профиль читающей области; подготовка Git вне измерений."""
import argparse
import hashlib
import json
from pathlib import Path
import time

from test_области_писателя import область_фикстура, экспорт
import запуск_слоёв
import область_писателя


def измерить():
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument("--выход", required=True)
    аргументы = парсер.parse_args()
    фазы = []
    with область_фикстура() as (_, объект, _, план, _, дети):
        первый = None
        for имя in ("первое чтение", "повторное чтение", "отказ чужого пути"):
            if имя == "отказ чужого пути":
                (дети["события"][0] / "общий.txt").write_text("Чужой файл\n")
            начало = time.perf_counter_ns()
            try:
                результат = экспорт(объект, план, дети)
            except ValueError as ошибка:
                if имя != "отказ чужого пути" or "вне области" not in str(ошибка):
                    raise
                исход = "ожидаемый отказ"
            else:
                assert имя != "отказ чужого пути"
                if первый is None:
                    первый = результат
                assert первый == результат
                исход = "успех"
            фазы.append({"стадия": имя, "наносекунды": time.perf_counter_ns() - начало, "исход": исход})
    корень = Path(__file__).resolve().parents[3]
    пути = set(запуск_слоёв.КОД) | set(область_писателя.КОД) | {Path(__file__).resolve(), Path(__file__).with_name("test_области_писателя.py"),
                                  Path(__file__).with_name("test_запуска_слоёв.py")}
    результат = {"схема": "fum.профиль-области-писателя.1", "фазы": фазы,
                 "граница": "Открытая Git-фикстура. Подготовка Git исключена; допуск происхождения checkout подменён фикстурой. Desktop и сеть не вызываются.",
                 "исходники": {путь.relative_to(корень).as_posix(): hashlib.sha256(путь.read_bytes()).hexdigest() for путь in sorted(пути)}}
    with Path(аргументы.выход).open("x") as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
        поток.write("\n")
    print(json.dumps({"схема": результат["схема"], "фазы": фазы}, ensure_ascii=False))


if __name__ == "__main__":
    измерить()
