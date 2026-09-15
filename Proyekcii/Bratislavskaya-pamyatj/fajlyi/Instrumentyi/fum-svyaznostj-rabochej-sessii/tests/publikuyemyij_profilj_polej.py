"""Производное представление профиля без абсолютного временного корня."""

import hashlib
import json
from pathlib import Path


def представить_профиль(данные: dict, корень: Path) -> dict:
    сырой = json.dumps(данные, ensure_ascii=False, indent=2) + "\n"
    префикс = json.dumps(str(корень), ensure_ascii=False)[1:-1]
    количество = сырой.count(префикс)
    результат = json.loads(сырой.replace(префикс, "<корень-фикстуры>"))
    результат["публикационное_представление"] = {
        "исходный_sha256": hashlib.sha256(сырой.encode("utf-8")).hexdigest(),
        "замен": количество,
        "обозначение": "<корень-фикстуры>",
        "преобразователь_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    }
    return результат
