"""Профиль собственного чтения и плана пары; подготовка Git не измеряется."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import time
from unittest import mock

from test_области_писателя import область_фикстура
import дочернее_назначение
import журнал_слоя


def измерить():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", required=True)
    вход = разбор.parse_args()
    фазы = []
    with область_фикстура(v2=True) as (_, _, _, _, _, дети):
        корень, задача, источник = дети["события"]
        with mock.patch.dict(os.environ, {"CODEX_THREAD_ID": задача}):
            предыдущий = None
            for имя in ("первое дочернее чтение", "повторное дочернее чтение", "план собственной пары", "отказ чужого пути"):
                if имя == "отказ чужого пути":
                    (корень / "общий.txt").write_text("Чужое изменение\n")
                начало = time.perf_counter_ns()
                try:
                    if имя == "план собственной пары":
                        файлы, метаданные = журнал_слоя.подготовить(корень, задача, источник, ["Команда открытой фикстуры."])
                        assert len(файлы) == 2 and not метаданные["разрешение_установки"]
                    else:
                        результат = дочернее_назначение.прочитать(корень, задача, источник)
                        assert предыдущий in (None, результат)
                        предыдущий = результат
                except ValueError as ошибка:
                    if имя != "отказ чужого пути" or "вне области" not in str(ошибка):
                        raise
                    исход = "ожидаемый отказ"
                else:
                    assert имя != "отказ чужого пути"
                    исход = "успех"
                фазы.append({"стадия": имя, "наносекунды": time.perf_counter_ns() - начало, "исход": исход})
    репозиторий = Path(__file__).resolve().parents[3]
    пути = set(дочернее_назначение.КОД) | set(дочернее_назначение.область_писателя.КОД) | set(журнал_слоя.КОД)
    пути.update(Path(__file__).with_name(имя) for имя in ("test_области_писателя.py", "test_запуска_слоёв.py", Path(__file__).name))
    результат = {"схема": "fum.профиль-дочернего-назначения.1", "фазы": фазы,
                 "граница": "Открытая Git-фикстура; создание Git и раннего подтверждения вне замеров. Совпадение checkout исполняемого кода подменено фикстурой. Нет Desktop, сети или установки пары.",
                 "исходники": {п.relative_to(репозиторий).as_posix(): hashlib.sha256(п.read_bytes()).hexdigest() for п in sorted(пути)}}
    with Path(вход.выход).open("x") as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
        поток.write("\n")
    print(json.dumps({"схема": результат["схема"], "фазы": фазы}, ensure_ascii=False))


if __name__ == "__main__":
    измерить()
