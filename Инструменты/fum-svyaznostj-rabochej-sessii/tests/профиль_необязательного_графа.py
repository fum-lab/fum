"""Измерить разбор и проверку ссылок на открытой фикстуре без пользовательского графа."""
import argparse
import hashlib
import json
import platform
import tempfile
import time
from pathlib import Path

from test_check_session_coherence import check_session_coherence as связность


def измерить(выход):
    результаты = []
    with tempfile.TemporaryDirectory() as временный:
        корень = Path(временный).resolve()
        источник = корень / "Журнал/2026-08-01_12-00-00_MSK/отчёт.md"
        источник.parent.mkdir(parents=True)
        граф = корень / ".obsidian/graph.json"
        граф.parent.mkdir()
        for случай in ("отсутствует", "существует", "похожее имя"):
            if случай == "существует":
                граф.write_bytes(b'{"scale":1.234}\n')
            адрес = "graph.json.bak" if случай == "похожее имя" else "graph.json"
            текст = "# Открытая фикстура\n\n" + f"[Граф](../../.obsidian/{адрес})\n" * 25
            источник.write_text(текст, encoding="utf-8")
            замеры = []
            for повтор in range(5):
                начало = time.perf_counter_ns()
                for вызов in range(10):
                    ссылки = связность.iter_markdown_links(источник)
                разбор = time.perf_counter_ns() - начало
                начало = time.perf_counter_ns()
                for вызов in range(10):
                    ошибки = связность.validate_markdown_links({источник}, корень)
                проверка = time.perf_counter_ns() - начало
                assert len(ссылки) == 25
                assert len(ошибки) == (25 if случай == "похожее имя" else 0)
                замеры.append({"разбор_наносекунды": разбор,
                               "проверка_включая_разбор_наносекунды": проверка})
            результаты.append({"случай": случай, "ссылок": 25, "вызовов_на_замер": 10,
                               "вход_sha256": hashlib.sha256(текст.encode()).hexdigest(),
                               "замеры": замеры})
        assert граф.read_bytes() == b'{"scale":1.234}\n'
    данные = {"схема": "fum.профиль-необязательного-графа.1",
              "python": platform.python_version(), "платформа": platform.system(),
              "реализация_sha256": hashlib.sha256(Path(связность.__file__).read_bytes()).hexdigest(),
              "сценарий_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              "результаты": результаты,
              "граница": "Подготовка фикстуры исключена. Проверка включает разбор; интервалы не складываются."}
    выход.write_text(json.dumps(данные, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    разбор = argparse.ArgumentParser(description=__doc__)
    разбор.add_argument("--выход", type=Path, required=True)
    измерить(разбор.parse_args().выход)
