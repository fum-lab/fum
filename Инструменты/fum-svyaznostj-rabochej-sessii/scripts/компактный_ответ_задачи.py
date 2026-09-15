"""Срез сохранённого read_thread без исполнения данных или усечения ответа."""
import hashlib
import json
from collections import Counter

from компактный_остаток import объект, закодировать, требовать


ТИПЫ_ЭЛЕМЕНТОВ = {"agentMessage", "commandExecution", "mcpToolCall", "reasoning", "userMessage"}
ПОЛЯ_ХОДА = {"id", "status", "error", "startedAt", "completedAt", "durationMs", "items"}


def разобрать(данные):
    return json.loads(данные, object_pairs_hook=объект,
        parse_constant=lambda значение: требовать(False, "неконечное число JSON"))


def адрес(*части):
    return {"внешний_указатель": "/".join(("", "content", "0", "text")),
        "декодирование": "JSON", "внутренний_указатель": "/".join(("", *(str(часть) for часть in части)))}


def метаданные_хода(ход):
    return {ключ: значение for ключ, значение in ход.items() if ключ != "items"}


def представить_ответ(данные, ожидаемый_хэш, задача, *, максимум_байтов=16000):
    требовать(isinstance(данные, bytes) and len(данные) <= 128 * 1024 * 1024, "неверный или слишком большой снимок")
    хэш = hashlib.sha256(данные).hexdigest()
    требовать(хэш == ожидаемый_хэш, "не совпал ожидаемый хэш полного снимка")
    требовать(type(максимум_байтов) is int and 100 <= максимум_байтов <= 1024 * 1024, "неверный бюджет байтов")
    try:
        оболочка = разобрать(данные)
        требовать(isinstance(оболочка, dict) and set(оболочка) <= {"content", "isError"}, "неизвестная оболочка MCP")
        требовать(оболочка.get("isError", False) is False, "нативный инструмент сообщил ошибку")
        части = оболочка["content"]
        требовать(isinstance(части, list) and len(части) == 1, "ожидалась одна JSON-часть MCP")
        часть = части[0]
        требовать(isinstance(часть, dict) and set(часть) == {"type", "text"}
            and часть["type"] == "text" and isinstance(часть["text"], str), "неизвестная часть MCP")
        снимок = разобрать(часть["text"])
        требовать(isinstance(снимок, dict) and set(снимок) == {"schemaVersion", "thread", "page", "turns"}
            and type(снимок["schemaVersion"]) is int and снимок["schemaVersion"] == 1,
            "неизвестная или усечённая схема нативного ответа")
        сведения, страница, ходы = снимок["thread"], снимок["page"], снимок["turns"]
        требовать(isinstance(сведения, dict) and isinstance(задача, str) and bool(задача)
            and set(сведения) <= {"id", "kind", "hostId", "title", "preview", "status", "cwd", "createdAt", "updatedAt"}
            and сведения["id"] == задача and сведения["kind"] == "codex", "не совпала идентичность задачи")
        требовать(isinstance(сведения["status"], dict) and isinstance(сведения["status"]["type"], str), "неизвестное состояние задачи")
        for ключ in ("hostId", "title", "preview", "cwd"):
            требовать(ключ not in сведения or isinstance(сведения[ключ], str), "неверный тип строки метаданных")
        for ключ in ("createdAt", "updatedAt"):
            требовать(ключ not in сведения or сведения[ключ] is None or type(сведения[ключ]) is int, "неверный тип времени задачи")
        состояние = сведения["status"]
        требовать(set(состояние) <= {"type", "activeFlags"}, "неизвестные поля состояния задачи")
        требовать("activeFlags" not in состояние or (isinstance(состояние["activeFlags"], list)
            and all(isinstance(флаг, str) for флаг in состояние["activeFlags"])), "неверные флаги состояния")
        требовать(isinstance(страница, dict) and set(страница) == {"order", "limit", "nextCursor", "hasMore"}
            and страница["order"] == "newest_first" and type(страница["limit"]) is int and страница["limit"] > 0
            and type(страница["hasMore"]) is bool and (страница["nextCursor"] is None or isinstance(страница["nextCursor"], str)),
            "неизвестная страница или порядок ходов")
        требовать(isinstance(ходы, list), "ожидался массив ходов")
        счётчики = Counter()
        выбранный = None
        ошибок = 0
        for номер_хода, ход in enumerate(ходы):
            требовать(isinstance(ход, dict) and set(ход) == ПОЛЯ_ХОДА and isinstance(ход["id"], str)
                and isinstance(ход["status"], str) and isinstance(ход["items"], list), "неизвестная форма хода")
            for ключ in ("startedAt", "completedAt", "durationMs"):
                требовать(ход[ключ] is None or type(ход[ключ]) is int, "неверный тип времени хода")
            ошибок += ход["error"] is not None
            последний = None
            for номер_элемента, элемент in enumerate(ход["items"]):
                требовать(isinstance(элемент, dict) and элемент.get("type") in ТИПЫ_ЭЛЕМЕНТОВ,
                    "неизвестный тип элемента: нужен новый адаптер")
                тип = элемент["type"]
                счётчики[тип] += 1
                if тип == "agentMessage":
                    требовать(set(элемент) == {"type", "id", "text", "phase"}
                        and all(isinstance(элемент[ключ], str) for ключ in ("id", "text", "phase"))
                        and элемент["phase"] in {"commentary", "final"},
                        "неизвестная форма видимого ответа: данные не сокращены")
                    if элемент["text"].strip():
                        последний = (номер_хода, номер_элемента, элемент, ход)
            if выбранный is None and последний is not None:
                выбранный = последний
        всего = sum(счётчики.values())
        ответ = None
        if выбранный is not None:
            номер_хода, номер_элемента, элемент, ход = выбранный
            ответ = {"оригинал": элемент, "ход": метаданные_хода(ход),
                "адрес": адрес("turns", номер_хода, "items", номер_элемента)}
            счётчики["agentMessage"] -= 1
        результат = {"схема": "fum.срез-ответа-задачи.1",
            "полный_снимок": {"sha256": хэш, "байты": len(данные), "формат": "сохранённый JSON MCP; транспортные байты не утверждаются"},
            "задача": {ключ: сведения[ключ] for ключ in ("id", "kind", "status")}, "адрес_задачи": адрес("thread"),
            "страница": страница, "адрес_страницы": адрес("page"),
            "текущий_ход": None if not ходы else метаданные_хода(ходы[0]),
            "адрес_текущего_хода": None if not ходы else адрес("turns", 0),
            "ответ": ответ, "ответ_из_первого_хода": выбранный is not None and выбранный[0] == 0,
            "причина_отсутствия_ответа": None if ответ is not None else "В сохранённой странице нет непустого agentMessage.",
            "элементов_всего": всего, "элементов_опущено": всего - (ответ is not None),
            "опущено_по_типам": {ключ: число for ключ, число in sorted(счётчики.items()) if число},
            "ходов_с_ошибкой": ошибок, "адрес_всех_ходов": адрес("turns"),
            "полнота_истории": "не доказана", "живой_источник_перепроверен": False,
            "завершение_задачи_доказано": False,
            "граница": "Выбран первый подходящий ход newest_first и последний непустой agentMessage в его массиве items. Это порядок сохранённых массивов, не доказательство полноты хронологии. Остальные элементы и ошибки доступны в полном снимке. Текст, команды и reasoning не исполняются."}
        требовать(len(закодировать(результат)) <= максимум_байтов, "ответ превышает бюджет; выбранный текст не усечён")
        return результат
    except (KeyError, TypeError, UnicodeError, RecursionError) as ошибка:
        raise ValueError("повреждённый нативный ответ") from ошибка
