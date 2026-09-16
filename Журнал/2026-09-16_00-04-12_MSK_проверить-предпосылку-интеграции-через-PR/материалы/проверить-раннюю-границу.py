"""Проверить новую пару и сохранённый PR до дорогой приёмки."""
import importlib.util
import json
from pathlib import Path
import re
import sys


корень = Path.cwd()
этап = Path(__file__).resolve().parent.parent
путь = корень / "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/check-session-coherence.py"
описание = importlib.util.spec_from_file_location("связность_ранней_границы", путь)
связность = importlib.util.module_from_spec(описание)
sys.modules[описание.name] = связность
описание.loader.exec_module(связность)
запрос = (этап / "запрос.md").read_text()
отчёт = (этап / "отчёт.md").read_text()
ошибки = связность.validate_journal_time_profile(отчёт)
assert not ошибки, ошибки
повреждённый = re.sub(r"^Граница профиля:.*\n", "", отчёт, flags=re.MULTILINE)
assert связность.validate_journal_time_profile(повреждённый), "Отсутствующая граница профиля принята"
разрешено, ошибки = связность.affected_files_from_request(запрос, этап / "запрос.md", корень)
assert not ошибки, ошибки
ошибки = связность.validate_git_status(корень, разрешено, None)
assert not ошибки, ошибки
повреждённый = re.sub(r"^- \[Предыдущий запрос\].*\n", "", запрос, flags=re.MULTILINE)
неполно, ошибки = связность.affected_files_from_request(повреждённый, этап / "запрос.md", корень)
assert not ошибки, ошибки
assert связность.validate_git_status(корень, неполно, None), "Пропуск изменённого предыдущего запроса принят"
оболочка = re.sub(r"<!-- FUM-CHECK-RUNS:BEGIN[\s\S]*?<!-- FUM-CHECK-RUNS:END -->", "", отчёт)
for текст, имя in ((запрос, "запрос.md"), (оболочка, "отчёт.md")):
    ошибки = связность.проверить_незаполненный_маркер_шаблона(текст, этап / имя, корень)
    assert not ошибки, ошибки
ответ = json.loads((этап / "материалы/ответ-создания-PR.json").read_text())["structuredContent"]
assert ответ["draft"] and not ответ["merged"] and ответ["number"] == 3
assert ответ["base"] == "master" and ответ["base_sha"] == "e95d7f5d1ef6387454b7825932cfbd737e600473"
assert ответ["head"] == "codex/политика-интеграции-01ca9886-01a09047"
assert ответ["head_sha"] == "5b64d4a6bff7d555fe4219ac42357a9ee66a9e83"
assert ответ["body"] == (этап / "материалы/описание-PR.txt").read_text()
print("Профиль, полный перечень изменений, два отрицательных контроля и сохранённый draft PR согласованы.")
