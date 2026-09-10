"""Измеряет реальные комплекты двух версий на временных синтетических коммитах."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def главная():
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--репозиторий", type=Path, required=True)
    разбор.add_argument("--ведущая", required=True)
    разбор.add_argument("--кандидат", type=Path, required=True)
    разбор.add_argument("--вывод", type=Path, required=True)
    аргументы = разбор.parse_args()
    среда = dict(os.environ, GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull,
                 GIT_AUTHOR_NAME="Синтетический профиль", GIT_AUTHOR_EMAIL="fixture@example.invalid",
                 GIT_COMMITTER_NAME="Синтетический профиль", GIT_COMMITTER_EMAIL="fixture@example.invalid")
    связность = "Инструменты/fum-svyaznostj-rabochej-sessii/"
    отчёты = "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/"
    общие = [связность + "scripts/" + имя for имя in (
        "перехватить-завершение.py", "проверить-продолжение-задачи.py", "обязательства_задачи.py",
        "подготовить-комплект-завершения.py", "проверить-комплект-завершения.py")]
    общие.append(отчёты + "отчёты_о_запусках_проверок.py")
    результаты = []
    for вариант in ("ведущая", "кандидат"):
        пути = list(общие)
        if вариант == "ведущая":
            пути.append(связность + "tests/test_обязательства_задачи.py")
            исходники = {путь: subprocess.run(["git", "--no-optional-locks", "-C", str(аргументы.репозиторий),
                         "show", аргументы.ведущая + ":" + путь], env=среда, capture_output=True, check=True).stdout
                         for путь in пути}
        else:
            пути += [связность + "scripts/" + имя for имя in ("обязательства_задачи_v2.py", "история_пути_гита.py")]
            пути += [отчёты + имя for имя in ("закрытый_отчёт_из_гита.py", "связь_отпечатка_с_коммитом.py")]
            пути.append(связность + "tests/test_обязательства_задачи_v2.py")
            исходники = {путь: (аргументы.кандидат / путь).read_bytes() for путь in пути}
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            def гит(*доводы):
                return subprocess.run(["git", "-c", "core.hooksPath=" + os.devnull,
                                       "-C", str(корень), *доводы], env=среда,
                                      capture_output=True, check=True).stdout
            гит("init", "-q")
            for имя, байты in исходники.items():
                путь = корень / имя
                путь.parent.mkdir(parents=True, exist_ok=True)
                путь.write_bytes(байты)
            гит("add", "--all")
            гит("commit", "-qm", "Синтетический снимок исполняемых входов профиля")
            коммит = гит("rev-parse", "HEAD").decode().strip()
            процесс = subprocess.run([sys.executable, "-I", "-S", "-B",
                         str(корень / связность / "scripts/проверить-комплект-завершения.py"),
                         "--источник", str(корень), "--commit", коммит],
                         env=среда, capture_output=True, timeout=180)
            if процесс.returncode:
                raise ValueError(вариант + ": " + процесс.stderr.decode("utf-8"))
            данные = json.loads(процесс.stdout)
            if len(данные["сценарии"]) != 6 or not all(запись["успешно"] for запись in данные["сценарии"]):
                raise ValueError("неполная проверка исходов комплекта")
            результаты.append({"вариант": вариант, "измерения": данные,
                               "исходники_sha256": {имя: hashlib.sha256(байты).hexdigest() for имя, байты in исходники.items()}})
    результат = {"схема": "fum.профиль-слияния-комплектов.1", "ведущая": аргументы.ведущая,
                 "граница": "Коммиты внутри результатов созданы только во временных синтетических репозиториях из перечисленных точных исходников. Это профиль четырёхфайлового комплекта ведущей и восьмифайлового кандидата, не приёмка C и не установка native hook. Варианты идут последовательно, файловый кэш не контролируется.",
                 "измеритель_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), "результаты": результаты}
    with аргументы.вывод.open("x", encoding="utf-8") as поток:
        json.dump(результат, поток, ensure_ascii=False, indent=2)
        поток.write("\n")
    print(json.dumps(результат, ensure_ascii=False))


if __name__ == "__main__":
    главная()
