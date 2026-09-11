"""Минимальный открытый JSONL для независимых проверок обязательств."""
import json
from pathlib import Path
import tempfile


def пустой_диалог(проверка, задача):
    каталог = Path(проверка.enterContext(tempfile.TemporaryDirectory())).resolve()
    путь = каталог / "диалог.jsonl"
    путь.write_text(json.dumps({"type": "session_meta", "payload": {"id": задача}}) + "\n")
    return путь
