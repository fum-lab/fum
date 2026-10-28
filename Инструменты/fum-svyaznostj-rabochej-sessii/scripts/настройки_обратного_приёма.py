"""Ограниченный Git-контур без внешних hook, драйверов и рекурсии."""
import hashlib
import os

from наблюдение_обратного_приёма import _адрес_гит, _гит, _требовать


def проверить_настройки(корень):
    сырые = _гит(корень, "config", "--null", "--list")
    for строка in сырые.split(b"\0"):
        if not строка:
            continue
        ключ, _, значение = строка.partition(b"\n")
        ключ = ключ.lower()
        _требовать(not (ключ.startswith(b"filter.")
                       or ключ.startswith(b"merge.") and ключ.endswith(b".driver")
                       or ключ.startswith(b"branch.") and ключ.endswith(b".mergeoptions")),
                  "Внешний драйвер или особый режим merge не поддержан")
        _требовать(ключ != b"core.hookspath", "Особый hook-каталог не поддержан")
        if ключ in {b"submodule.recurse", b"merge.autostash", b"rerere.enabled",
                     b"commit.gpgsign", b"merge.verifysignatures", b"core.sparsecheckout"}:
            _требовать(значение.lower() in {b"false", b"no", b"off", b"0"},
                      "Исполняемая настройка Git не поддержана: " + ключ.decode())
    каталог = _адрес_гит(корень, "hooks")
    _требовать(not каталог.is_symlink(), "Символический hook-каталог не поддержан")
    if каталог.exists():
        _требовать(каталог.is_dir(), "Необычный hook-каталог")
        for путь in каталог.iterdir():
            if not путь.name.endswith(".sample"):
                _требовать(not путь.is_symlink() and not os.access(путь, os.X_OK),
                          "Исполняемый hook не поддержан: " + путь.name)
    return hashlib.sha256(сырые).hexdigest()
