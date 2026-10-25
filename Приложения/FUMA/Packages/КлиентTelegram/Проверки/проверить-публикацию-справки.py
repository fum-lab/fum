"""Проверить реальные байты справки и измерить пять отдельных запусков CLI."""

import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys
import time


def проверить(команда: Path) -> int:
    корень = Path(__file__).resolve().parents[5]
    sys.path.insert(0, str(корень / "Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts"))
    import path_forms

    измерения = []
    справка = None
    процесс = None
    результат = {
        "схема": "fum.публикация-справки-телеграма.2",
        "командаШа256": None,
        "исполнительШа256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "распознавательШа256": hashlib.sha256(Path(path_forms.__file__).read_bytes()).hexdigest(),
        "справкаШа256": None,
        "запусков": 0,
        "длительностиНаносекунд": измерения,
        "медианаНаносекунд": None,
        "машинныхПутей": None,
        "ошибка": None,
    }
    код = 2
    try:
        отпечаток = hashlib.sha256(команда.read_bytes()).hexdigest()
        результат["командаШа256"] = отпечаток
        for номер in range(1, 6):
            процесс = None
            начало = time.perf_counter_ns()
            try:
                процесс = subprocess.run([str(команда), "--help"], capture_output=True, timeout=5)
            except (subprocess.TimeoutExpired, OSError) as ошибка:
                результат["ошибка"] = {"вид": "тайм_аут" if isinstance(ошибка, subprocess.TimeoutExpired) else type(ошибка).__name__,
                    "номерЗапуска": номер, "длительностьНаносекунд": time.perf_counter_ns() - начало}
                raise
            длительность = time.perf_counter_ns() - начало
            if процесс.returncode != 0 or процесс.stderr or (справка is not None and справка != процесс.stdout):
                результат["ошибка"] = {"вид": "исход_процесса" if процесс.returncode != 0 or процесс.stderr else "изменённая_справка",
                    "номерЗапуска": номер, "кодПроцесса": процесс.returncode, "длительностьНаносекунд": длительность}
                raise ValueError("Неверный исход или изменённые байты справки")
            измерения.append(длительность)
            справка = процесс.stdout
        текст = справка.decode("utf-8", errors="strict")
        обязательное = (
            "Автономная проверка TDLib без аккаунта:",
            "проверить-telegram --библиотека <абсолютный-путь-к-библиотеке> [--простой-секунд 1..30]",
            "проверить-telegram --профиль поток [--кадров 1..2048]",
            "проверить-telegram --профиль отмена [--повторов 1..100]",
            "проверить-telegram --сквозной-хвост подготовить|восстановить --каталог <приватный-каталог>",
            "проверить-telegram --профиль-восстановления подготовить|восстановить --каталог <приватный-каталог> --попыток 16|256",
            "Пути библиотеки и приватного каталога должны быть абсолютными.",
        )
        if not set(обязательное).issubset({строка.strip() for строка in текст.splitlines()}):
            результат["ошибка"] = {"вид": "неполная_справка"}
            raise ValueError("Не подтверждено содержимое справки")
        формы = path_forms.detect_path_forms(текст)
        результат["машинныхПутей"] = len(формы)
        if hashlib.sha256(команда.read_bytes()).hexdigest() != отпечаток:
            raise ValueError("Команда изменилась во время измерения")
        код = 1 if формы else 0
    except (OSError, ValueError, subprocess.TimeoutExpired) as ошибка:
        if результат["ошибка"] is None:
            результат["ошибка"] = {"вид": type(ошибка).__name__}
        for значение in ((ошибка.stdout, ошибка.stderr) if isinstance(ошибка, subprocess.TimeoutExpired)
                         else (процесс.stdout, процесс.stderr) if процесс is not None else ()):
            if значение:
                print(значение.decode("utf-8", errors="replace") if isinstance(значение, bytes) else значение, file=sys.stderr)
    результат["запусков"] = len(измерения)
    if справка is not None:
        результат["справкаШа256"] = hashlib.sha256(справка).hexdigest()
    if измерения:
        результат["медианаНаносекунд"] = statistics.median(измерения)
    print(json.dumps(результат, ensure_ascii=False, sort_keys=True))
    return код


if __name__ == "__main__":
    if len(sys.argv) != 2 or not Path(sys.argv[1]).is_absolute():
        raise SystemExit("Нужен абсолютный путь собранной команды")
    raise SystemExit(проверить(Path(sys.argv[1])))
