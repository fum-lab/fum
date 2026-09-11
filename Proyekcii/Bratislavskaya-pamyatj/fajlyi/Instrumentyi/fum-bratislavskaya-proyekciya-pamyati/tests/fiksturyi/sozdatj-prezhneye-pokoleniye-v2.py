#!/usr/bin/env python3
"""Воспроизводит открытую фикстуру точным прежним кодом из Git, без Swift."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import types


КОММИТ = "aeae18cb146a34563ff39c84d9bc5ef59fffab91"
КАТАЛОГ = "Инструменты/fum-bratislavskaya-proyekciya-pamyati"


def воспроизвести(корень, выход):
    def объект(путь):
        return subprocess.check_output(["git", "--no-replace-objects", "-C", str(корень), "show", f"{КОММИТ}:{путь}"])

    код = объект(f"{КАТАЛОГ}/scripts/братиславская_проекция_памяти.py")
    if hashlib.sha256(код).hexdigest() != "74b320d2201e4203a1f506985063eb97d4be93cd0476f5f8fa68386b82635c88":
        raise ValueError("Изменились байты закреплённого прежнего сценария")
    политика = json.loads(объект(f"{КАТАЛОГ}/контракт-v2.json"))
    прежний = types.ModuleType("прежняя_проекция")
    прежний.__file__ = str(корень / КАТАЛОГ / "scripts/братиславская_проекция_памяти.py")
    exec(compile(код, f"{КОММИТ}:проекция", "exec"), прежний.__dict__)
    if прежний.хэш_значения(политика) != "sha256:9f262153c9de986270cec76ad3c37da34c99ace0c187474ba8a1bc736222220a":
        raise ValueError("Изменился закреплённый прежний контракт")
    исходники = {"Пример.txt": "Ёж и строка\r\n".encode("utf-8")}
    соответствия = {"Пример": "Primer"}
    преобразователь = lambda строки: [соответствия.get(строка, строка) for строка in строки]
    with tempfile.TemporaryDirectory(prefix="fum-prezhnyaya-proyekciya-") as временный:
        репозиторий = Path(временный)

        def команда(*аргументы):
            subprocess.run(["git", "-C", str(репозиторий), *аргументы], check=True,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        команда("init", "-q")
        for путь, данные in исходники.items():
            (репозиторий / путь).write_bytes(данные)
        команда("add", "-A")
        команда("-c", "user.name=Проверка", "-c", "user.email=proverka@example.invalid",
                "-c", "commit.gpgSign=false", "commit", "-q", "-m", "Фикстура")
        команда("update-index", "--add", "--cacheinfo",
                "160000,837e2ce107b97ee7b9d3344c9fe99142281fe393,Зависимости/LinguisticKit")
        план = прежний.построить_план(репозиторий, политика, преобразователь)
        выходы = {запись["целевой_путь"]: исходники[запись["исходный_путь"]]
                  for запись in план["записи"]}
        манифест = прежний.сформировать_манифест(план, выходы)
        прежний.проверить_манифест_владения(политика, манифест)
    фикстура = {
        "происхождение": {"коммит": КОММИТ, "хэш_кода": "sha256:" + hashlib.sha256(код).hexdigest(),
                          "хэш_политики": прежний.хэш_значения(политика)},
        "исходники_hex": {путь: данные.hex() for путь, данные in исходники.items()},
        "выходы_hex": {путь: данные.hex() for путь, данные in выходы.items()},
        "соответствия": соответствия,
        "план": план,
        "манифест": манифест,
    }
    выход.write_text(json.dumps(фикстура, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print(f"Фикстура прежнего поколения: {len(исходники)} исходник, {len(выходы)} выход")


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--корень-репозитория", type=Path, required=True)
    разбор.add_argument("--выход", type=Path, required=True)
    параметры = разбор.parse_args()
    воспроизвести(параметры.корень_репозитория.resolve(), параметры.выход)
