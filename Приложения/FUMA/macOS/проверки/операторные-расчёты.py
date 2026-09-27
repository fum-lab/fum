"""Проверить настоящий CLI и повтор из памяти. Предметную арифметику выполняет FUMA."""

import argparse
import hashlib
import json
from pathlib import Path
import resource
import subprocess
import time


def проверить(корень, бинарник, набор, выход, повторов):
    корень = корень.resolve(strict=True)
    бинарник = бинарник.resolve(strict=True)
    выход = выход.resolve()
    if выход.exists() or any((п / ".git").exists() for п in [выход, *выход.parents]):
        raise ValueError("Нужен новый каталог вне Git")
    if not 1 <= повторов <= 10:
        raise ValueError("Допустимы 1–10 повторов")
    имена = {"рюкзак": ("оператор-рюкзака.json", "вход-рюкзака.json"),
             "пакет": ("оператор-пакета.json", "содержание.json")}
    определение, вход = [корень / "Описания/пакет-FUMA" / имя for имя in имена[набор]]
    исходные = {str(п.relative_to(корень)): hashlib.sha256(п.read_bytes()).hexdigest()
                for п in [определение, вход]}
    выход.mkdir(parents=True, mode=0o700)
    память = выход / "память"
    память.mkdir(mode=0o700)
    профиль = []
    эталон = None
    for номер in range(повторов + 1):
        команда = [str(бинарник), "--журнал", str(память), "--профиль"]
        if номер == 0:
            команда += ["--выполнить-оператор", "--определение", str(определение),
                        "--вход", str(вход), "--тип-входа", "текст", "--источник-входа", "LLM"]
        else:
            команда += ["--повторить-оператор", идентификатор]
        до = resource.getrusage(resource.RUSAGE_CHILDREN)
        начало = time.perf_counter_ns()
        запуск = subprocess.run(команда, capture_output=True, timeout=60, check=False)
        наносекунды = time.perf_counter_ns() - начало
        после = resource.getrusage(resource.RUSAGE_CHILDREN)
        (выход / f"{номер}-ответ.json").write_bytes(запуск.stdout)
        (выход / f"{номер}-профиль.jsonl").write_bytes(запуск.stderr)
        if запуск.returncode:
            raise RuntimeError(f"FUMA отказал: код {запуск.returncode}; свидетельство {выход}")
        ответ = json.loads(запуск.stdout)
        assert ответ["схема"] == "fuma.результат-исполнения.1"
        наблюдение = ответ["наблюдение"]
        if номер == 0:
            эталон = наблюдение
            идентификатор = ответ["квитанция"]["описание"]["идентификатор"]
        else:
            assert наблюдение == эталон, "Повтор изменил наблюдение"
        метки = [json.loads(строка) for строка in запуск.stderr.splitlines()]
        профиль.append({"номер": номер, "повтор": номер != 0,
                        "полный_вызов_наносекунды": наносекунды,
                        "CPU_секунды": после.ru_utime + после.ru_stime - до.ru_utime - до.ru_stime,
                        "метки": метки})
    for имя, хэш in исходные.items():
        assert hashlib.sha256((корень / имя).read_bytes()).hexdigest() == хэш, "Вход изменился"
    assert эталон["результат"]["тип"] == "текст"
    данные = json.loads(эталон["результат"]["значение"])
    if набор == "рюкзак":
        assert [п["масса_г"] for п in данные["варианты"]] == [8100, 10600, 15600]
        assert [[п["секунд"] for п in в["нагрузки"]] for в in данные["варианты"]] == [
            [6000, 3272, 1777], [12000, 6545, 3555], [24000, 13090, 7111]]
    else:
        расчёты = данные["расчёты"]
        assert расчёты["известная_сумма_RUB_копейки"] == 70990000
        assert расчёты["капитальные_расходы_RUB_копейки"] is None
        assert расчёты["подписка_USD_центы_год"] == 240000
        assert расчёты["шесть_устройств_Apple_USD_центы"] == 2359400
    (выход / "результат.json").write_text(json.dumps(данные, ensure_ascii=False, indent=2) + "\n")
    итог = {"схема": "fuma.проверка-расчёта-CLI.1", "набор": набор,
            "входы_sha256": исходные, "бинарник_sha256": hashlib.sha256(бинарник.read_bytes()).hexdigest(),
            "хэш_наблюдения": эталон["хэшНаблюдения"], "повторов": повторов,
            "профиль": профиль, "граница": "Полный вызов включает запуск процесса и долговечную запись; повтор читает растущую память. Это не изолированный benchmark арифметики."}
    (выход / "проверка.json").write_text(json.dumps(итог, ensure_ascii=False, indent=2) + "\n")
    return {"каталог": str(выход), "набор": набор, "повторов": повторов,
            "хэш_наблюдения": итог["хэш_наблюдения"],
            "полные_вызовы_мс": [round(п["полный_вызов_наносекунды"] / 1e6, 3) for п in профиль]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--корень", type=Path, required=True)
    parser.add_argument("--FUMA", type=Path, required=True)
    parser.add_argument("--набор", choices=["рюкзак", "пакет"], required=True)
    parser.add_argument("--выход", type=Path, required=True)
    parser.add_argument("--повторов", type=int, default=3)
    args = parser.parse_args()
    print(json.dumps(проверить(args.корень, args.FUMA, args.набор, args.выход, args.повторов), ensure_ascii=False))
