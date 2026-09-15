"""Воспроизводимая сборка и проверка общего сценария FUMA на Android."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import time
import uuid


def ожидаемые_байты(вход):
    return вход.decode("utf-8", errors="strict").encode("utf-32-le")


def проверить_байты(ожидание, выход, повтор):
    if выход != ожидание or повтор != ожидание:
        raise ValueError("Выход либо повтор отличается от независимого эталона")


def записать_json(путь, значение):
    путь.write_text(json.dumps(значение, ensure_ascii=False, indent=2, sort_keys=True) + "\n")


def выполнить(параметры):
    корень = Path(__file__).resolve().parents[3]
    каталог = параметры.выход.resolve()
    if каталог == корень or корень in каталог.parents:
        raise ValueError("Runtime-данные и логи должны быть вне checkout")
    каталог.mkdir(parents=True, exist_ok=False)
    профиль = []

    def процесс(этап, команда, среда=None, допустимый_отказ=False):
        начало = time.monotonic_ns()
        итог = subprocess.run([str(часть) for часть in команда], cwd=корень, env=среда,
                             capture_output=True, timeout=параметры.тайм_аут)
        профиль.append({"этап": этап, "наносекунды": time.monotonic_ns() - начало,
                        "код": итог.returncode})
        (каталог / (str(len(профиль)) + ".log")).write_bytes(итог.stdout + итог.stderr)
        записать_json(каталог / "профиль-процессов.json", профиль)
        if итог.returncode and not допустимый_отказ:
            raise RuntimeError("Отказ этапа " + этап + ": " + итог.stderr.decode(errors="replace")[-2000:])
        return итог

    def adb(этап, *команда, допустимый_отказ=False):
        return процесс(этап, [параметры.adb, "-s", параметры.устройство, *команда],
                       допустимый_отказ=допустимый_отказ)

    def оболочка(этап, *команда, допустимый_отказ=False):
        return adb(этап, "shell", shlex.join([str(часть) for часть in команда]),
                   допустимый_отказ=допустимый_отказ)

    архитектура = оболочка("ABI", "getprop", "ro.product.cpu.abi").stdout.decode().strip()
    уровень = int(оболочка("API", "getprop", "ro.build.version.sdk").stdout.strip())
    if архитектура != "arm64-v8a" or уровень < 23:
        raise ValueError("Нужен Android arm64-v8a API23 или новее")
    версия = процесс("версия-компилятора", [параметры.swift, "--version"]).stdout.decode().strip()
    if "6.4" not in версия or "RELEASE" not in версия:
        raise ValueError("Нужен открытый toolchain Swift 6.4.0 RELEASE")
    if "30.0.16248370" not in (параметры.ndk / "source.properties").read_text():
        raise ValueError("Нужен NDK r30 30.0.16248370")
    среда = dict(os.environ, ANDROID_NDK_HOME=str(параметры.ndk), SWIFTCI_USE_LOCAL_DEPS="1")
    команда_сборки = [параметры.swift, "build", "--package-path", "Приложения/FUMA",
                      "--scratch-path", параметры.кэш, "--swift-sdk", "swift-6.4.0-RELEASE_android",
                      "--triple", "aarch64-unknown-linux-android23", "--static-swift-stdlib",
                      "--product", "сценарий-runtime", "-c", "release", "--jobs", "4"]
    if параметры.бинарник:
        бинарник = параметры.бинарник.resolve()
    else:
        процесс("сборка", команда_сборки, среда)
        путь = процесс("путь-бинарника", команда_сборки + ["--show-bin-path"], среда).stdout.decode().strip()
        бинарник = Path(путь) / "сценарий-runtime"
    if бинарник.read_bytes()[:4] != b"\x7fELF":
        raise ValueError("Ожидался ELF-бинарник Android")
    библиотеки = list(параметры.ndk.glob("toolchains/llvm/prebuilt/*/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so"))
    if len(библиотеки) != 1:
        raise ValueError("Неоднозначная libc++ NDK")
    удалённый = "/data/local/tmp/fuma-" + uuid.uuid4().hex
    оболочка("каталог", "mkdir", "-m", "700", удалённый)
    adb("бинарник", "push", бинарник, удалённый + "/runtime")
    adb("libc++", "push", библиотеки[0], удалённый + "/libc++_shared.so")
    оболочка("исполняемый-файл", "chmod", "700", удалённый + "/runtime")
    определение = корень / "Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory/Определения/UTF-8-в-UTF-32LE.json"
    (каталог / "определение.json").write_bytes(определение.read_bytes())
    adb("определение", "push", определение, удалённый + "/definition.json")
    случаи = [b"", bytes.fromhex("0041d191f09f8ebb"),
              ("Ёж\nA\u0301 🎻\u0000" * 128).encode(),
              bytes.fromhex("c0af"), bytes.fromhex("eda080"), bytes.fromhex("f4908080"), bytes.fromhex("e282")]
    результаты = []
    for номер, вход in enumerate(случаи):
        местный = каталог / str(номер)
        местный.mkdir()
        (местный / "вход.bin").write_bytes(вход)
        try:
            эталон = ожидаемые_байты(вход)
        except UnicodeDecodeError:
            эталон = None
        путь = удалённый + "/" + str(номер)
        оболочка("каталоги-случая", "mkdir", "-m", "700", путь, путь + "/store", путь + "/out")
        adb("вход", "push", местный / "вход.bin", путь + "/input.bin")
        итог = оболочка("исполнение-" + str(номер), "env", "LD_LIBRARY_PATH=" + удалённый,
                        удалённый + "/runtime", удалённый + "/definition.json", путь + "/input.bin",
                        путь + "/store", путь + "/out", допустимый_отказ=True)
        if эталон is None:
            if итог.returncode == 0:
                raise ValueError("Неверный UTF-8 принят runtime")
            проверка = оболочка("отсутствие-наблюдения", "test", "!", "-e", путь + "/store/сегмент.fumobs",
                                 допустимый_отказ=True)
            if проверка.returncode != 0:
                raise ValueError("Неверный UTF-8 создал контейнер")
        else:
            if итог.returncode != 0:
                raise RuntimeError("Runtime завершился отказом: " + итог.stderr.decode(errors="replace"))
            adb("результат", "pull", путь + "/out/.", местный)
            adb("контейнер", "pull", путь + "/store/сегмент.fumobs", местный / "сегмент.fumobs")
            (местный / "ожидание.bin").write_bytes(эталон)
            проверить_байты(эталон, (местный / "выход.bin").read_bytes(), (местный / "повтор.bin").read_bytes())
        результаты.append({"номер": номер, "код": итог.returncode, "байты_входа": len(вход),
                           "ожидаемый_отказ": эталон is None})
    манифест = {"схема": "fum.проверка-android-runtime.1", "ABI": архитектура, "API_устройства": уровень,
                "API_сборки": 23, "swift": версия, "NDK": "30.0.16248370",
                "бинарник_sha256": hashlib.sha256(бинарник.read_bytes()).hexdigest(),
                "определение_sha256": hashlib.sha256(определение.read_bytes()).hexdigest(),
                "готовый_бинарник": параметры.бинарник is not None, "случаи": результаты,
                "мост": "отдельный процесс через adb; JNI не используется"}
    записать_json(каталог / "манифест.json", манифест)
    print(json.dumps(манифест, ensure_ascii=False))


def main():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--swift", required=True, type=Path)
    разбор.add_argument("--adb", required=True, type=Path)
    разбор.add_argument("--ndk", required=True, type=Path)
    разбор.add_argument("--устройство", required=True)
    разбор.add_argument("--кэш", required=True, type=Path)
    разбор.add_argument("--выход", required=True, type=Path)
    разбор.add_argument("--бинарник", type=Path)
    разбор.add_argument("--тайм-аут", type=int, default=600)
    выполнить(разбор.parse_args())


if __name__ == "__main__":
    main()
