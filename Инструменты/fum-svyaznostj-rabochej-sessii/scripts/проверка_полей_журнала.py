"""Раннее чтение обязательных полей пары; полная приёмка остаётся отдельной."""

import hashlib
import importlib.util
from pathlib import Path
import sys

from путь_пары_журнала import проверить_путь


спецификация = importlib.util.spec_from_file_location(
    "связность_для_проверки_полей",
    Path(__file__).with_name("check-session-coherence.py"),
)
if спецификация is None or спецификация.loader is None:
    raise RuntimeError("Недоступна реализация проверки связности")
связность = importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name] = связность
спецификация.loader.exec_module(связность)


def проверить(корень: Path, запрос: Path) -> dict:
    корень = корень.resolve(strict=True)
    запрос = запрос if запрос.is_absolute() else корень / запрос
    try:
        относительный = запрос.relative_to(корень)
    except ValueError as ошибка:
        raise ValueError("Запрос находится вне выбранного корня") from ошибка
    if ".." in относительный.parts or not связность.is_request_file(запрос, корень):
        raise ValueError("Нужен канонический запрос в папке Журнала")
    отчёт = запрос.with_name("отчёт.md")
    документы = (запрос, отчёт)
    for документ in документы:
        проверить_путь(корень, документ)
    исходники = {документ: документ.read_bytes() for документ in документы}
    тексты = {документ: исходник.decode("utf-8") for документ, исходник in исходники.items()}
    ошибки = связность.validate_request_filename_title(запрос)
    for документ, заголовок in (
        (запрос, связность.expected_request_heading(запрос)),
        (отчёт, связность.expected_journal_heading(запрос)),
    ):
        if not тексты[документ].startswith(заголовок + "\n"):
            ошибки.append("Неверный заголовок файла " + документ.name)
        ошибки.extend(связность.проверить_незаполненный_маркер_шаблона(
            тексты[документ], документ, корень))
    ошибки.extend(связность.validate_journal_time_profile(тексты[отчёт]))
    ошибки.extend(связность.validate_journal_direct_check_runs(тексты[отчёт]))
    ошибки.extend(связность.validate_used_tools_section(тексты[запрос], запрос))
    ошибки.extend(связность.codex_thread_id_from_request(тексты[запрос])[1])
    for документ, имя_соседа in ((запрос, "отчёт.md"), (отчёт, "запрос.md")):
        дословное = связность.request_text_line_span(тексты[документ]) if документ == запрос else None
        ссылки = [
            связность.MarkdownLink(документ, номер, связность.strip_link_title(совпадение.group(2)))
            for номер, строка in enumerate(связность.markdown_structural_text(тексты[документ]).splitlines(), 1)
            if дословное is None or not дословное[0] <= номер < дословное[1]
            for совпадение in связность.MARKDOWN_LINK_RE.finditer(строка)
        ]
        if not any(
            связность.resolve_markdown_target(ссылка, корень) == документ.with_name(имя_соседа)
            for ссылка in ссылки
        ):
            ошибки.append("Нет прямой ссылки из " + документ.name + " на " + имя_соседа)
    ошибки.extend(связность.validate_markdown_links(set(документы), корень))
    for документ in документы:
        проверить_путь(корень, документ)
        if документ.read_bytes() != исходники[документ]:
            raise ValueError("Файл пары изменился во время проверки")
    return {
        "схема": "fum.поля-журнала.1",
        "полная_приёмка": False,
        "ошибки": ошибки,
        "входы": [
            {
                "путь": документ.relative_to(корень).as_posix(),
                "байтов": len(исходники[документ]),
                "sha256": hashlib.sha256(исходники[документ]).hexdigest(),
            }
            for документ in документы
        ],
    }
