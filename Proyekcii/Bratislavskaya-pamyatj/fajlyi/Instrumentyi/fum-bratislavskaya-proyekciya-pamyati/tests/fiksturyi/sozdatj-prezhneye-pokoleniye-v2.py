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


поколения = {
    "до-карты-авторов": ("9a410dea90c09e24954fab7e4c28f613b8bda06f", "5bd38619b548a70b05c3172dcd6eba8e6dd1151391b79d9d8a77ba68b8396ac7", "sha256:5ecd1d393cb59ab5ccfaeebc9d43a6c93476125547698c47283e6a348af6fb21"),
    "до-объединения-форматов": ("f80bdf424350a6c07fb5e5acf25e5b252cfd03be", "bbdbb100da672deb22ed58380a7a0158a2b03b014c2bd0b03ed85f0f6dcd1d7f", "sha256:9f9c4a040b592396ccca722c33f0895342901dfba1ffd5a63bc9bb45c2604ac2"),
    "до-сценариев-ответа": ("2e01e5dc9a130ea0fb2f6c10514d7db56817361b", "f5a87027cab531c99811fafc3d7917b0131d5697faf9608b2d019b7374e9c377", "sha256:6f6d399cfb2734a5445eeb52358af3a0d71c74d8b811416d9531b514b210993d"),
    "до-форматов-приложения": (
        КОММИТ,
        "74b320d2201e4203a1f506985063eb97d4be93cd0476f5f8fa68386b82635c88",
        "sha256:9f262153c9de986270cec76ad3c37da34c99ace0c187474ba8a1bc736222220a",
    ),
    "master": (
        "9d01af6de4fc2f1c9265ee8805cda4998322e004",
        "a430c52b383ec1196477a4c721f6931384e5088acf5d37c35a899c01ca807f6a",
        "sha256:43652412d709576d3cbda4fa22538a6ad030789f6224315b52c97dfae4e96f3c",
    ),
    "ведущая": (
        "62a8dfc8c8182d1d37cce9c0d1b86717f52303e0",
        "fe09bb63c61f5fcce60037d01e772e72ed6c04f1166753938cabb8f926032dd9",
        "sha256:519247e248fca466e3344aaf256e04c7df31c6fdcc41fd5c8ad80858643b34bc",
    ),
}


def воспроизвести(корень, выход, поколение="до-форматов-приложения", *, изменить_пример=False):
    if изменить_пример and поколение != "master":
        raise ValueError("Изменённый пример предназначен только для стороны master")
    коммит, хэш_кода, хэш_политики = поколения[поколение]
    def объект(путь):
        return subprocess.check_output(["git", "--no-replace-objects", "-C", str(корень), "show", f"{коммит}:{путь}"])

    код = объект(f"{КАТАЛОГ}/scripts/братиславская_проекция_памяти.py")
    if hashlib.sha256(код).hexdigest() != хэш_кода:
        raise ValueError("Изменились байты закреплённого прежнего сценария")
    политика = json.loads(объект(f"{КАТАЛОГ}/контракт-v2.json"))
    прежний = types.ModuleType("прежняя_проекция")
    прежний.__file__ = str(корень / КАТАЛОГ / "scripts/братиславская_проекция_памяти.py")
    exec(compile(код, f"{коммит}:проекция", "exec"), прежний.__dict__)
    if прежний.хэш_значения(политика) != хэш_политики:
        raise ValueError("Изменился закреплённый прежний контракт")
    исходники = {"Пример.txt": "Ёж и строка\r\n".encode("utf-8")}
    if изменить_пример:
        исходники["Пример.txt"] = "Ёж и изменённая строка\r\n".encode("utf-8")
    if поколение == "ведущая":
        исходники[".mailmap"] = "FUM Интегратор <fum@local> FUMИнтегратор <fum@local>\n".encode("utf-8")
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
        "происхождение": {"коммит": коммит, "хэш_кода": "sha256:" + hashlib.sha256(код).hexdigest(),
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
    разбор.add_argument("--поколение", choices=sorted(поколения), default="до-форматов-приложения")
    разбор.add_argument("--изменить-пример", action="store_true")
    параметры = разбор.parse_args()
    воспроизвести(параметры.корень_репозитория.resolve(), параметры.выход,
                 параметры.поколение, изменить_пример=параметры.изменить_пример)
