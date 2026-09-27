"""Воспроизводимый начальный и повторный приём синтетических 70 МиБ."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from история_модели import импортировать
from перепривязать_историю_модели import перепривязать


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
        исходная_история = (корень / "история.json").read_bytes()
        перепривязки = []
        for _ in range(3):
            новый = каталог / "новый.jsonl"
            начало_подготовки = time.perf_counter_ns()
            shutil.copyfile(источник, новый)
            os.replace(новый, источник)
            подготовка = time.perf_counter_ns() - начало_подготовки
            начало = time.perf_counter_ns()
            результат = перепривязать(источник, задача, корень_репозитория=корень,
                кэш=каталог / "курсор.json", история=корень / "история.json")
            стена = time.perf_counter_ns() - начало
            assert результат["полнота"] and результат["новых_наблюдений"] == 0
            assert (корень / "история.json").read_bytes() == исходная_история
            перепривязки.append({"подготовка_нового_inode_наносекунды": подготовка,
                "перепривязка_wall_наносекунды": стена, "результат": результат})
        return {"схема": "fum.профиль-истории-модели.2", "байтов": источник.stat().st_size,
            "python": sys.version, "условия": "Подготовка нового inode указана отдельно; кэш ОС не очищен; последовательные вызовы API",
            "исходники": {путь.name: hashlib.sha256(путь.read_bytes()).hexdigest() for путь in
                (Path(__file__), Path(__file__).parents[1] / "scripts" / "история_модели.py",
                 Path(__file__).parents[1] / "scripts" / "сообщения_задачи.py",
                 Path(__file__).parents[1] / "scripts" / "перепривязать_историю_модели.py",
                 Path(__file__).parents[1] / "scripts" / "перепривязать-историю-модели.py")},
            "вызовы": вызовы, "перепривязки": перепривязки}


if __name__ == "__main__":
    print(json.dumps(измерить(), ensure_ascii=False, indent=2))
