"""Отдельные Git-границы и байты затронутых файлов; без записи и sandbox."""
import hashlib
import importlib
from pathlib import Path
import sys

import приём_направления as хранение

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "fum-svyaznostj-rabochej-sessii/scripts"))
охват = importlib.import_module("сверить-материалы-этапа")


def снимок(корень, задача, база, каталоги):
    владелец = хранение.Хранилище(корень, задача)._наблюдать_владельца()
    гит = lambda *а: хранение.гит(корень, "-c", "core.fileMode=true", "-c", "core.fsmonitor=false", *а, сырые=True)
    индекс = гит("ls-files", "--stage", "-z")
    флаги = гит("ls-files", "-v", "-z")
    хранение.требовать(all(э[:1] == b"H" for э in флаги.split(b"\0") if э), "Неподдержанный флаг индекса")
    режимы = {}
    for запись in индекс.split(b"\0"):
        if not запись:
            continue
        поля, имя = запись.split(b"\t", 1)
        режим, _, стадия = поля.split()
        хранение.требовать(стадия == b"0", "Конфликтный индекс")
        режимы[имя.decode("utf-8")] = режим
    состояния = {
        "база_HEAD": гит("diff", "--no-ext-diff", "--no-textconv", "--no-renames", "--ignore-submodules=none", "--name-only", "-z", база, владелец["HEAD"], "--"),
        "HEAD_индекс": гит("diff", "--no-ext-diff", "--no-textconv", "--no-renames", "--ignore-submodules=none", "--cached", "--name-only", "-z", "--"),
        "индекс_файлы": гит("diff", "--no-ext-diff", "--no-textconv", "--no-renames", "--ignore-submodules=none", "--name-only", "-z", "--"),
    }
    статус = гит("-c", "status.renames=false", "status", "--porcelain=v1", "-z", "--untracked-files=all", "--ignore-submodules=none")
    пути = {имя.decode("utf-8") for данные in состояния.values() for имя in данные.split(b"\0") if имя}
    пути.update(строка[3:].decode("utf-8") for строка in статус.split(b"\0") if строка)
    файлы, кэш = {}, {}
    for имя in sorted(пути):
        хранение.требовать(any(имя.startswith(каталог) for каталог in каталоги), "Путь вне области писателя: " + имя)
        хранение.требовать(not any(ord(знак) < 32 for знак in имя), "Управляющий символ в пути")
        путь = охват.точный_путь(корень, имя, кэш)
        хранение.требовать(режимы.get(имя, b"100644") in {b"100644", b"100755"}, "Неподдержанный тип цели индекса")
        if путь.exists():
            хранение.безопасный_путь(путь)
        файлы[имя] = охват.состояние_пути(путь)
    return {"владелец": владелец, "индекс_sha256": hashlib.sha256(индекс).hexdigest(),
            "статус_sha256": hashlib.sha256(статус).hexdigest(),
            "границы": {имя: hashlib.sha256(данные).hexdigest() for имя, данные in состояния.items()},
            "файлы": файлы}
