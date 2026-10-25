"""Составить аргументы следующего поручения из явного выбора адресата.

Выбор предоставляет координатор по актуальному человеческому указанию.
Модуль не устанавливает его подлинность и не переключает текущий ход.
"""
import uuid

from вход_направления import проверить_профиль


def подготовить(выбор, вызов):
    if type(выбор) is not dict or set(выбор) != {"исполнитель", "профиль"}:
        raise ValueError("Нужен явный выбор исполнителя и профиля")
    адресат = выбор["исполнитель"]
    if type(адресат) is not str or str(uuid.UUID(адресат)) != адресат:
        raise ValueError("Неканонический UUID исполнителя")
    профиль = проверить_профиль(выбор["профиль"])
    if type(вызов) is not dict or not {"threadId", "prompt"} <= set(вызов):
        raise ValueError("Нужны адресат и текст следующего поручения")
    if set(вызов) - {"threadId", "prompt", "hostId", "model", "thinking"}:
        raise ValueError("Неизвестные аргументы поручения")
    if вызов["threadId"] != адресат:
        raise ValueError("Выбран профиль другого исполнителя")
    if type(вызов["prompt"]) is not str or not вызов["prompt"].strip():
        raise ValueError("Пустое поручение")
    if "hostId" in вызов and (type(вызов["hostId"]) is not str or not вызов["hostId"]):
        raise ValueError("Некорректный hostId")
    for ключ, значение in профиль.items():
        if ключ in вызов and вызов[ключ] != значение:
            raise ValueError("Параметры поручения противоречат выбранному профилю: " + ключ)
    return {**вызов, **профиль}
