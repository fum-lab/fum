"""Проверить сохранённый отчёт этапа и его связь с наблюдённым коммитом."""
import hashlib
import json
import subprocess
import sys
from pathlib import Path


корень = Path(__file__).resolve().parents[3]
коммит = "11d1b5fd4c912ade510a21c65dd5d515243a084d"
сессия = "Журнал/2026-09-09_21-31-19_MSK_продолжать-работу-после-коммита"
сценарии = корень / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts"
subprocess.run([sys.executable, "-B", str(сценарии / "отчёты_о_запусках_проверок.py"), "проверить", "--корень-репозитория", str(корень), "--запрос", str(Path(сессия) / "запрос.md")], check=True)
каталог = корень / сессия / "материалы/запуски-проверок"
снимок = json.loads((каталог / "снимок.json").read_text())
последний = json.loads((каталог / снимок["файлы"][-1]["имя"]).read_text())
if снимок["схема"] != "fum.test-run-report.v2" or последний["схема"] != "fum.test-run.v3":
    raise AssertionError("Ожидались текущие свидетельства v3")
итог = subprocess.run([sys.executable, "-B", str(сценарии / "связь_отпечатка_с_коммитом.py"), "--корень-репозитория", str(корень), "--сессия", сессия, "--коммит", коммит, "--отпечаток-закрытия", снимок["отпечаток_закрытия"], "--отпечаток-запуска", последний["профиль_проверки"]["отпечаток_снимка"]], check=True, capture_output=True, text=True)
доказательство = json.loads(итог.stdout)
доказательство["sha256_снимка"] = hashlib.sha256((каталог / "снимок.json").read_bytes()).hexdigest()
Path(__file__).with_name("проверка-коммита.json").write_text(json.dumps(доказательство, ensure_ascii=False, indent=2) + "\n")
print(итог.stdout, end="")
