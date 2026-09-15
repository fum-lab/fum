"""Установить закреплённые Swift и NDK вне checkout на macOS ARM64."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import subprocess
import time


def проверить_архив(путь, ожидаемый):
    if путь.is_symlink() or not путь.is_file():
        raise ValueError("Архив должен быть обычным файлом")
    хэш = hashlib.sha256()
    with путь.open("rb") as поток:
        while часть := поток.read(1024 * 1024):
            хэш.update(часть)
    if хэш.hexdigest() != ожидаемый:
        raise ValueError("Архив не совпадает с закреплённым SHA-256: " + путь.name)


def подготовить(каталог):
    if platform.system() != "Darwin" or platform.machine() != "arm64":
        raise ValueError("Этот установщик проверен только на macOS ARM64")
    корень = Path(__file__).resolve().parents[3]
    каталог = каталог.resolve()
    if каталог == корень or корень in каталог.parents:
        raise ValueError("SDK и кэши должны оставаться вне checkout")
    каталог.mkdir(parents=True, exist_ok=True)
    версии = json.loads(Path(__file__).with_name("версии.json").read_text())
    профиль = []

    def этап(имя, действие):
        начало = time.monotonic_ns()
        исход = "отказ"
        try:
            результат = действие()
            исход = "успешно"
            return результат
        finally:
            профиль.append({"этап": имя, "наносекунды": time.monotonic_ns() - начало, "исход": исход})
            (каталог / "профиль-подготовки.json").write_text(json.dumps(профиль, ensure_ascii=False, indent=2) + "\n")

    def команда(*аргументы):
        return subprocess.run([str(часть) for часть in аргументы], check=True, capture_output=True, timeout=1800).stdout.decode()

    for архив in версии["архивы"]:
        путь = каталог / архив["имя"]
        if not путь.exists():
            временный = путь.with_suffix(путь.suffix + ".part")
            if временный.exists():
                raise ValueError("Сохранилась незавершённая загрузка: " + временный.name)
            этап("загрузка-" + путь.name, lambda: команда("curl", "--fail", "--location", "--silent", "--show-error",
                 архив["URL"], "--output", временный))
            этап("хэш-" + путь.name, lambda: проверить_архив(временный, архив["sha256"]))
            временный.rename(путь)
        else:
            этап("хэш-" + путь.name, lambda: проверить_архив(путь, архив["sha256"]))
    подпись = этап("подпись-toolchain", lambda: команда("pkgutil", "--check-signature", каталог / "swift-6.4.0.pkg"))
    (каталог / "подпись-toolchain.txt").write_text(подпись)
    развёрнутый = каталог / "toolchain-expanded"
    if not развёрнутый.exists():
        этап("распаковка-toolchain", lambda: команда("pkgutil", "--expand-full", каталог / "swift-6.4.0.pkg", развёрнутый))
    swift = развёрнутый / "swift-6.4.0-RELEASE-osx-package.pkg/Payload/usr/bin/swift"
    версия = этап("версия-toolchain", lambda: команда(swift, "--version"))
    if "swift-6.4-RELEASE" not in версия:
        raise ValueError("Не совпала версия открытого toolchain")
    установленные = команда(swift, "sdk", "list")
    if "swift-6.4.0-RELEASE_android" not in установленные.splitlines():
        этап("установка-Swift-SDK", lambda: команда(swift, "sdk", "install", каталог / "android-sdk.tar.gz",
             "--checksum", версии["архивы"][1]["sha256"]))
    ndk = каталог / "android-ndk-r30"
    if not ndk.exists():
        этап("распаковка-NDK", lambda: команда("unzip", "-q", каталог / "ndk.zip", "-d", каталог))
    if "30.0.16248370" not in (ndk / "source.properties").read_text():
        raise ValueError("Не совпала версия NDK")
    print(json.dumps({"swift": str(swift), "ndk": str(ndk), "SDK": "swift-6.4.0-RELEASE_android"}, ensure_ascii=False))


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--каталог", type=Path, required=True)
    подготовить(разбор.parse_args().каталог)
