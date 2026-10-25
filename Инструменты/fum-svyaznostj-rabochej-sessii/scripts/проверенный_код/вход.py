"""Доверенный вызывающий вход. Bootstrap сначала читается как данные."""
import hashlib
from pathlib import Path
import re
import subprocess
import time


def получить_снимок(корень, закрепление, манифест):
    """Исполнить только внешне закреплённый bootstrap из точного Q."""
    начало_интервала = time.perf_counter_ns()
    if not isinstance(закрепление, dict) or set(закрепление) != {"коммит", "начало", "манифест_sha256"}:
        raise ValueError("неверный независимый вход")
    коммит = закрепление["коммит"]
    if not isinstance(коммит, str) or not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", коммит):
        raise ValueError("нужен полный OID Q")
    вход = закрепление["начало"]
    if not isinstance(вход, dict) or set(вход) != {"путь", "режим", "blob", "sha256"}:
        raise ValueError("неверное закрепление bootstrap")
    путь = вход["путь"]
    if not isinstance(путь, str) or "/" not in путь or путь.split("/")[-1] != "начало.py" or any(
            not часть.isidentifier() for часть in путь[:-3].split("/")):
        raise ValueError("неверный путь bootstrap")
    if вход["режим"] != "100644" or not isinstance(вход["blob"], str) or not re.fullmatch(
            r"[0-9a-f]{" + str(len(коммит)) + r"}", вход["blob"]):
        raise ValueError("неверный режим или blob bootstrap")
    for значение in (вход["sha256"], закрепление["манифест_sha256"]):
        if not isinstance(значение, str) or not re.fullmatch(r"[0-9a-f]{64}", значение):
            raise ValueError("неверный SHA-256 закрепления")
    if not isinstance(манифест, bytes) or hashlib.sha256(манифест).hexdigest() != закрепление["манифест_sha256"]:
        raise ValueError("внешний SHA-256 манифеста не совпадает")
    корень = Path(корень).resolve(strict=True)

    def гит(*аргументы):
        try:
            return subprocess.check_output(["git", "--no-replace-objects", "-C", str(корень), *аргументы], stderr=subprocess.PIPE)
        except subprocess.CalledProcessError as ошибка:
            raise ValueError("Git-объект недоступен") from ошибка

    if гит("cat-file", "-t", коммит) != b"commit\n":
        raise ValueError("Q не является коммитом")
    строка = гит("ls-tree", "-z", коммит, "--", путь)
    ожидаемая = (вход["режим"] + " blob " + вход["blob"] + "\t" + путь).encode() + b"\0"
    if строка != ожидаемая:
        raise ValueError("внешнее закрепление bootstrap не совпадает с Q")
    удержанное = гит("cat-file", "blob", вход["blob"])
    if hashlib.sha256(удержанное).hexdigest() != вход["sha256"]:
        raise ValueError("SHA-256 bootstrap не совпадает")
    хэш_объекта = hashlib.sha1 if len(коммит) == 40 else hashlib.sha256
    if хэш_объекта(b"blob " + str(len(удержанное)).encode() + b"\0" + удержанное).hexdigest() != вход["blob"]:
        raise ValueError("Git blob bootstrap не совпадает")
    чтение = time.perf_counter_ns() - начало_интервала
    момент = time.perf_counter_ns()
    код = compile(удержанное, f"git:{коммит}:{путь}", "exec", dont_inherit=True)
    компиляция = time.perf_counter_ns() - момент
    область = {"__name__": "_удержанная_точка_входа", "__file__": f"git:{коммит}:{путь}"}
    exec(код, область)
    return область["проверить_инвентарь"](корень, закрепление, манифест, удержанное, чтение, компиляция)
