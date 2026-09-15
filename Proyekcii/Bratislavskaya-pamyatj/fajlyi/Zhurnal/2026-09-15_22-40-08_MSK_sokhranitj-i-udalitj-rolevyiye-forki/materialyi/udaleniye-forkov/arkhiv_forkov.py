"""Ограниченное архивирование и удаление явно выбранных ролевых форков FUM."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time
import fcntl
import sys

РОЛИ = frozenset(["fum-yadro","fum-optimizator","fum-pisatelj","fum-stroitelj","fum-testirovsjhik","fum-arkhitektor","fum-predprinimatelj","fum-auditor","fum-dizajner","fum-analitik","fum-perevodchik","fum-upravlyayusjhij","fum-proyektirovsjhik","fum-yurist","fum-bukhgalter"])
РЕПОЗИТОРИИ = frozenset("fum-lab/" + имя for имя in РОЛИ)


def проверить_репозиторий(имя, данные):
    if имя not in РЕПОЗИТОРИИ or данные.get("full_name") != имя:
        raise ValueError("Репозиторий вне явного списка ролевых форков")
    if not данные.get("fork") or данные.get("parent", {}).get("full_name") != "fum-lab/fum":
        raise ValueError("Не подтверждён fork основного FUM")
    if данные.get("source", {}).get("full_name") != "fum-lab/fum" or not данные.get("permissions", {}).get("admin"):
        raise ValueError("Не подтверждены источник и право удаления")
    if данные.get("has_discussions") or данные.get("has_pages") or данные.get("forks_count"):
        raise ValueError("Есть дополнительные ресурсы вне поддержанного архива")
    if type(данные.get("id")) is not int or not данные.get("node_id"):
        raise ValueError("Нет устойчивой идентичности репозитория")
    return данные["id"]


def разобрать_ссылки(текст):
    результат = {}
    for строка in текст.splitlines():
        части = строка.split()
        if len(части) != 2 or not re.fullmatch("[0-9a-f]{40}", части[0]) or not части[1].startswith("refs/"):
            raise ValueError("Некорректная Git-ссылка")
        if части[1] in результат:
            raise ValueError("Повторная Git-ссылка")
        результат[части[1]] = части[0]
    if not результат:
        raise ValueError("Пустой набор Git-ссылок")
    return результат


def проверить_перед_удалением(имя, сохранённые, текущие, ссылки, текущие_ссылки, архив_проверен):
    проверить_репозиторий(имя, сохранённые)
    проверить_репозиторий(имя, текущие)
    if (сохранённые["id"], сохранённые["node_id"]) != (текущие["id"], текущие["node_id"]):
        raise ValueError("Изменилась идентичность репозитория")
    for поле in ("description", "default_branch", "updated_at", "pushed_at"):
        if сохранённые.get(поле) != текущие.get(поле):
            raise ValueError("Изменились метаданные репозитория")
    if not архив_проверен or not ссылки or ссылки != текущие_ссылки:
        raise ValueError("Архив неполон либо изменились Git-ссылки")


def сохранить_данные(путь, данные):
    with путь.open("x", encoding="utf-8") as файл:
        json.dump(данные, файл, ensure_ascii=False, indent=2)
        файл.write("\n")
        файл.flush()
        os.fsync(файл.fileno())
    дескриптор = os.open(путь.parent, os.O_RDONLY)
    try:
        os.fsync(дескриптор)
    finally:
        os.close(дескриптор)
    if sys.platform == "darwin":
        with путь.open("rb") as файл:
            fcntl.fcntl(файл.fileno(), fcntl.F_FULLFSYNC)


def закрепить_архив(каталог):
    for корень, каталоги, файлы in os.walk(каталог, topdown=False, followlinks=False):
        for имя in файлы:
            путь = Path(корень) / имя
            if путь.is_symlink():
                raise ValueError("Символическая ссылка в архиве")
            with путь.open("rb") as файл:
                os.fsync(файл.fileno())
                if sys.platform == "darwin":
                    fcntl.fcntl(файл.fileno(), fcntl.F_FULLFSYNC)
        for имя in каталоги:
            if (Path(корень) / имя).is_symlink():
                raise ValueError("Символическая ссылка в архиве")
        дескриптор = os.open(корень, os.O_RDONLY)
        try:
            os.fsync(дескриптор)
        finally:
            os.close(дескриптор)
    for родитель in каталог.parents:
        дескриптор = os.open(родитель, os.O_RDONLY)
        try:
            os.fsync(дескриптор)
        finally:
            os.close(дескриптор)
    if sys.platform == "darwin":
        with (каталог / "готовность.json").open("rb") as файл:
            fcntl.fcntl(файл.fileno(), fcntl.F_FULLFSYNC)


class Архив:
    def __init__(сам, каталог, ссылка_на_объекты):
        сам.каталог = Path(каталог)
        if not сам.каталог.is_absolute() or сам.каталог.resolve() != сам.каталог:
            raise ValueError("Нужен абсолютный физический каталог")
        сам.каталог.mkdir(mode=0o700, parents=True, exist_ok=True)
        if subprocess.run(["git", "-C", str(сам.каталог), "rev-parse", "--git-dir"], capture_output=True).returncode == 0:
            raise ValueError("Архив должен находиться вне Git")
        сам.ссылка_на_объекты = str(Path(ссылка_на_объекты).resolve())

    def выполнить(сам, каталог, аргументы, допустимый_отказ=False):
        начало = time.monotonic_ns()
        исход = subprocess.run(аргументы, capture_output=True, timeout=180,
                               env={**os.environ, "GIT_TERMINAL_PROMPT": "0", "GIT_OPTIONAL_LOCKS": "0"})
        номер = len(list(каталог.glob("вызов-*.json"))) + 1
        основа = каталог / f"вызов-{номер:04d}"
        основа.with_suffix(".stdout").write_bytes(исход.stdout)
        основа.with_suffix(".stderr").write_bytes(исход.stderr)
        сохранить_данные(основа.with_suffix(".json"), {
            "аргументы": аргументы, "код": исход.returncode,
            "наносекунды": time.monotonic_ns() - начало,
            "stdout_sha256": hashlib.sha256(исход.stdout).hexdigest(),
            "stderr_sha256": hashlib.sha256(исход.stderr).hexdigest(),
        })
        if исход.returncode and not допустимый_отказ:
            raise RuntimeError("Внешняя команда отказала; подробности сохранены в " + str(основа))
        return исход

    def запрос(сам, каталог, имя, суффикс="", много=False):
        аргументы = ["gh", "api", "repos/" + имя + суффикс]
        if много:
            аргументы += ["--paginate", "--slurp"]
        исход = сам.выполнить(каталог, аргументы)
        данные = json.loads(исход.stdout)
        if много:
            if not isinstance(данные, list) or any(not isinstance(страница, list) for страница in данные):
                raise ValueError("Неподдержанная пагинация")
            данные = [элемент for страница in данные for элемент in страница]
        return данные

    def получить_ссылки(сам, каталог, адрес):
        return разобрать_ссылки(сам.выполнить(каталог, ["git", "ls-remote", "--refs", адрес]).stdout.decode())

    def подготовить(сам, имя):
        if имя not in РЕПОЗИТОРИИ:
            raise ValueError("Репозиторий вне разрешённого списка")
        каталог = сам.каталог / имя.split("/")[1]
        if каталог.exists():
            raise ValueError("Архив уже существует; автоматическое повторение запрещено")
        каталог.mkdir(mode=0o700)
        метаданные = сам.запрос(каталог, имя)
        проверить_репозиторий(имя, метаданные)
        сохранить_данные(каталог / "репозиторий.json", метаданные)
        источники = {
            "issues": "/issues?state=all&per_page=100",
            "pulls": "/pulls?state=all&per_page=100",
            "comments": "/issues/comments?per_page=100",
            "review-comments": "/pulls/comments?per_page=100",
            "releases": "/releases?per_page=100",
            "deployments": "/deployments?per_page=100",
            "labels": "/labels?per_page=100",
            "milestones": "/milestones?state=all&per_page=100",
        }
        for ключ, суффикс in источники.items():
            данные = сам.запрос(каталог, имя, суффикс, много=True)
            сохранить_данные(каталог / (ключ + ".json"), данные)
            if данные and ключ not in {"labels", "milestones"}:
                raise ValueError("Непустой внешний ресурс требует расширения архива: " + ключ)
        for ключ, суффикс in {
            "actions": "/actions/runs?per_page=1",
            "artifacts": "/actions/artifacts?per_page=1",
        }.items():
            данные = сам.запрос(каталог, имя, суффикс)
            сохранить_данные(каталог / (ключ + ".json"), данные)
            if данные.get("total_count") != 0:
                raise ValueError("Есть Actions-данные вне поддержанного архива")
        адрес = "https://github.com/" + имя + ".git"
        ссылки = сам.получить_ссылки(каталог, адрес)
        зеркало = каталог / "репозиторий.git"
        сам.выполнить(каталог, ["git", "clone", "--mirror", "--reference-if-able", сам.ссылка_на_объекты,
                               "--dissociate", адрес, str(зеркало)])
        if (зеркало / "objects/info/alternates").exists():
            raise ValueError("Git-архив зависит от другого хранилища")
        сам.выполнить(каталог, ["git", "-C", str(зеркало), "fsck", "--full"])
        локальные = разобрать_ссылки(сам.выполнить(каталог, ["git", "-C", str(зеркало), "show-ref"]).stdout.decode())
        if локальные != ссылки or сам.получить_ссылки(каталог, адрес) != ссылки:
            raise ValueError("Git-ссылки изменились или сохранены не полностью")
        вики = сам.выполнить(каталог, ["git", "ls-remote", "--refs", "https://github.com/" + имя + ".wiki.git"], True)
        if вики.returncode:
            if b"Repository not found" not in вики.stderr and b"repository" not in вики.stderr.lower():
                raise ValueError("Не удалось установить состояние wiki")
            # Только точный GitHub-отказ отсутствия; сетевой/авторизационный отказ не принимается.
            if b"not found" not in вики.stderr.lower():
                raise ValueError("Не доказано отсутствие wiki")
            состояние_вики = "GitHub сообщил repository not found"
        elif вики.stdout.strip():
            raise ValueError("Непустая wiki требует отдельного Git-архива")
        else:
            состояние_вики = "пустой набор ссылок wiki"
        сохранить_данные(каталог / "готовность.json", {
            "схема": "fum.архив-ролевого-форка.1", "имя": имя, "id": метаданные["id"],
            "node_id": метаданные["node_id"], "ссылки": ссылки, "wiki": состояние_вики,
            "снимки": {путь.name: hashlib.sha256(путь.read_bytes()).hexdigest()
                        for путь in каталог.glob("*.json") if not путь.name.startswith("вызов-")},
        })
        return {"имя": имя, "ссылок": len(ссылки), "архив": str(каталог)}

    def удалить(сам, имя):
        if имя not in РЕПОЗИТОРИИ:
            raise ValueError("Репозиторий вне разрешённого списка")
        каталог = сам.каталог / имя.split("/")[1]
        готовность = json.loads((каталог / "готовность.json").read_text())
        if готовность.get("схема") != "fum.архив-ролевого-форка.1" or готовность.get("имя") != имя:
            raise ValueError("Чужой архив")
        if (каталог / "намерение-удаления.json").exists():
            raise ValueError("Попытка удаления уже зарегистрирована; сначала разберите её исход")
        for файл, хэш in готовность["снимки"].items():
            if Path(файл).name != файл or hashlib.sha256((каталог / файл).read_bytes()).hexdigest() != хэш:
                raise ValueError("Архив изменился")
        старые = json.loads((каталог / "репозиторий.json").read_text())
        текущие = сам.запрос(каталог, имя)
        for файл, суффикс in {
            "issues": "/issues?state=all&per_page=100",
            "pulls": "/pulls?state=all&per_page=100",
            "comments": "/issues/comments?per_page=100",
            "review-comments": "/pulls/comments?per_page=100",
            "releases": "/releases?per_page=100",
            "deployments": "/deployments?per_page=100",
            "labels": "/labels?per_page=100",
            "milestones": "/milestones?state=all&per_page=100",
        }.items():
            if сам.запрос(каталог, имя, суффикс, много=True) != json.loads((каталог / (файл + ".json")).read_text()):
                raise ValueError("GitHub-данные изменились после архивирования")
        ссылки = сам.получить_ссылки(каталог, "https://github.com/" + имя + ".git")
        зеркало = каталог / "репозиторий.git"
        сам.выполнить(каталог, ["git", "-C", str(зеркало), "fsck", "--full"])
        локальные = разобрать_ссылки(сам.выполнить(каталог, ["git", "-C", str(зеркало), "show-ref"]).stdout.decode())
        проверить_перед_удалением(имя, старые, текущие, готовность["ссылки"], ссылки,
                                 локальные == готовность["ссылки"])
        большие_объекты = сам.выполнить(каталог, ["git", "-C", str(зеркало), "lfs", "ls-files", "--all"])
        if большие_объекты.stdout.strip():
            raise ValueError("Git LFS требует отдельного архива объектов")
        for суффикс in ("/actions/runs?per_page=1", "/actions/artifacts?per_page=1"):
            if сам.запрос(каталог, имя, суффикс).get("total_count") != 0:
                raise ValueError("Появились несохранённые Actions-данные")
        вики = сам.выполнить(каталог, ["git", "ls-remote", "--refs", "https://github.com/" + имя + ".wiki.git"], True)
        if not ((вики.returncode == 0 and not вики.stdout.strip()) or
                (вики.returncode != 0 and b"repository" in вики.stderr.lower() and b"not found" in вики.stderr.lower())):
            raise ValueError("Wiki изменилась либо её отсутствие не подтверждено")
        закрепить_архив(каталог)
        сохранить_данные(каталог / "намерение-удаления.json", {
            "имя": имя, "id": текущие["id"], "node_id": текущие["node_id"],
            "исход": "ещё не подтверждён",
        })
        # CLI принимает точное имя после сверки ID. Атомарного условия на ID серверный вызов не обещает.
        ответ = сам.выполнить(каталог, ["gh", "repo", "delete", имя, "--yes"], True)
        if ответ.returncode:
            raise RuntimeError("Удаление не подтверждено; автоматического повтора нет")
        проверка = сам.выполнить(каталог, ["gh", "api", "repos/" + имя], True)
        основной = сам.запрос(каталог, "fum-lab/fum")
        if проверка.returncode == 0 or b"HTTP 404" not in проверка.stderr or основной.get("full_name") != "fum-lab/fum":
            raise RuntimeError("Не подтверждено отсутствие удалённого репозитория")
        сохранить_данные(каталог / "удалён.json", {"имя": имя, "id": текущие["id"],
                       "подтверждение": "gh repo delete и последующий HTTP 404; основной FUM доступен"})
        return {"имя": имя, "удалён": True}


def основная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("действие", choices=["подготовить", "удалить"])
    разбор.add_argument("--архив", required=True)
    разбор.add_argument("--объекты", required=True)
    разбор.add_argument("--репозитории", nargs="+", required=True)
    вход = разбор.parse_args()
    if len(set(вход.репозитории)) != len(вход.репозитории) or not set(вход.репозитории) <= РЕПОЗИТОРИИ:
        raise ValueError("Недопустимый список")
    архив = Архив(вход.архив, вход.объекты)
    for имя in вход.репозитории:
        действие = архив.подготовить if вход.действие == "подготовить" else архив.удалить
        print(json.dumps(действие(имя), ensure_ascii=False), flush=True)


if __name__ == "__main__":
    основная()
