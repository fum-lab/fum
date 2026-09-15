"""Воспроизводимый начальный и повторный приём синтетических 70 МиБ."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from история_модели import импортировать


def измерить():
    задача = "00000000-0000-0000-0000-000000000001"
    with tempfile.TemporaryDirectory() as временный:
        каталог = Path(временный).resolve()
        корень = каталог / "репозиторий"
        корень.mkdir()
        источник = каталог / "native.jsonl"
        with источник.open("wb") as поток:
            поток.write((json.dumps({"type": "session_meta", "payload": {"id": задача}}) + "\n").encode())
            строка = (json.dumps({"type": "event_msg", "payload": {"text": "x" * 1024}}) + "\n").encode()
            for номер in range(70000):
                поток.write(строка)
                if номер % 10000 == 0:
                    поток.write((json.dumps({"type": "turn_context", "timestamp": "2026-09-15T16:00:00Z",
                        "payload": {"model": "gpt-6-astra", "effort": "low" if номер % 20000 == 0 else "high"}}) + "\n").encode())
        вызовы = []
        for номер in range(3):
            результат = импортировать(источник, задача, корень_репозитория=корень,
                кэш=каталог / "курсор.json", история=корень / "история.json", без_записи=номер == 2)
            вызовы.append(результат)
        assert вызовы[0]["число_наблюдений"] == 7
        assert all(вызов["профиль"]["прочитано_байтов"] == 0 for вызов in вызовы[1:])
        return {"схема": "fum.профиль-истории-модели.1", "байтов": источник.stat().st_size,
            "python": sys.version, "условия": "Подготовка исключена; кэш ОС не очищен; последовательные вызовы API",
            "исходники": {путь.name: hashlib.sha256(путь.read_bytes()).hexdigest() for путь in
                (Path(__file__), Path(__file__).parents[1] / "scripts" / "история_модели.py",
                 Path(__file__).parents[1] / "scripts" / "сообщения_задачи.py")}, "вызовы": вызовы}


if __name__ == "__main__":
    print(json.dumps(измерить(), ensure_ascii=False, indent=2))
