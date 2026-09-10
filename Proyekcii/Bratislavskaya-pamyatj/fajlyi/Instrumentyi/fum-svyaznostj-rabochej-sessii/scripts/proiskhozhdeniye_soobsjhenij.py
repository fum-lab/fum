"""Чистая классификация одного сырого payload ResponseItem::Message.

«Человек» означает полную аннотацию runtime UserInput, а не личность автора.
«Служебный hook» означает только ограниченную XML-форму, не квитанцию запуска
или валидный Stop block. Вызывающий слой сохраняет raw, выбирает response_item,
коррелирует typed-свидетельства и не экспортирует их второй раз. Здесь нет
чтения истории, склейки фрагментов, выполнения команд или загрузки медиа.
Вход — обычные JSON-значения, до нормализующего декодера runtime.
"""
from xml.parsers import expat


МАКСИМУМ_ФРАГМЕНТОВ = 256
МАКСИМУМ_СИМВОЛОВ_РАЗМЕТКИ = 262144
МАКСИМУМ_СУММАРНЫХ_СИМВОЛОВ_РАЗМЕТКИ = 1048576
МАКСИМУМ_ИДЕНТИФИКАТОРА = 1024
_ВИДЫ_ПОЛЬЗОВАТЕЛЯ = {
    "user.text": ("input_text", "output_text"),
    "user.image": ("input_image",),
    "user.audio": ("input_audio",),
}
_ВИДЫ_КОНТЕКСТА = frozenset((
    "plugins.recommendations", "agents_md.instructions",
    "environments.environment_context",
))
_ПОЛЯ_КОНТЕНТА = {
    "input_text": ("text", frozenset(("type", "text"))),
    "output_text": ("text", frozenset(("type", "text"))),
    "input_image": ("image_url", frozenset(("type", "image_url", "detail"))),
    "input_audio": ("audio_url", frozenset(("type", "audio_url"))),
}


class _НедопустимаяРазметка(ValueError):
    """Внутренний останов ограниченного потокового парсера."""


def _полный_служебный_фрагмент(текст: str) -> bool:
    """Проверить структуру, не возвращая декодированный/нормализованный текст."""
    # Expat молча поглощает BOM; конструктор фрагмента его не выдаёт.
    if not текст or текст[0] != "<" or len(текст) > МАКСИМУМ_СИМВОЛОВ_РАЗМЕТКИ:
        return False
    глубина = 0
    корень_прочитан = False
    разбор = expat.ParserCreate()

    def отклонить(*аргументы):
        raise _НедопустимаяРазметка()

    def начало(имя, атрибуты):
        nonlocal глубина, корень_прочитан
        if (глубина != 0 or корень_прочитан or имя != "hook_prompt"
                or set(атрибуты) != {"hook_run_id"}):
            отклонить()
        идентификатор = атрибуты["hook_run_id"]
        if not идентификатор.strip() or len(идентификатор) > МАКСИМУМ_ИДЕНТИФИКАТОРА:
            отклонить()
        глубина = 1
        корень_прочитан = True

    def конец(имя):
        nonlocal глубина
        if глубина != 1 or имя != "hook_prompt":
            отклонить()
        глубина = 0

    def символы(значение):
        if глубина != 1:
            отклонить()

    # Внешние имена обработчиков закреплены API Expat. DTD отвергается до
    # объявления сущностей; загрузчик внешних сущностей отсутствует.
    for имя, обработчик in (
        ("StartElementHandler", начало), ("EndElementHandler", конец),
        ("CharacterDataHandler", символы), ("DefaultHandler", отклонить),
        ("StartDoctypeDeclHandler", отклонить), ("EntityDeclHandler", отклонить),
        ("ExternalEntityRefHandler", отклонить), ("SkippedEntityHandler", отклонить),
        ("ProcessingInstructionHandler", отклонить), ("CommentHandler", отклонить),
        ("StartCdataSectionHandler", отклонить), ("XmlDeclHandler", отклонить),
    ):
        setattr(разбор, имя, обработчик)
    разбор.SetParamEntityParsing(expat.XML_PARAM_ENTITY_PARSING_NEVER)
    try:
        разбор.Parse(текст, True)
    except (_НедопустимаяРазметка, expat.ExpatError, UnicodeError, ValueError):
        return False
    return корень_прочитан and глубина == 0


def _корректный_контент(часть) -> bool:
    if type(часть) is not dict:
        return False
    вид = часть.get("type")
    if type(вид) is not str or вид not in _ПОЛЯ_КОНТЕНТА:
        return False
    поле, разрешённые = _ПОЛЯ_КОНТЕНТА[вид]
    if not часть.keys() <= разрешённые or type(часть.get(поле)) is not str:
        return False
    # Медиа остаются непрозрачными строками: ни URL-парсинга, ни декодирования.
    if вид == "input_image" and часть.get("detail") not in (None, "auto", "low", "high", "original"):
        return False
    return True


def классифицировать_сообщение(сообщение) -> str:
    """Вернуть один из четырёх исходов без изменения исходного объекта.

    Точная роль user, тип message, фаза null/отсутствует и полная корректная
    content_item_kinds обязательны для подтверждённого UserInput. При наличии
    поля kinds его null/частичность/неизвестность исключают XML-fallback. Иные
    поля passthrough не являются свидетельством происхождения. При отсутствии
    kinds допустим только строгий hook-fallback; всё прочее неоднозначно.
    Аннотированный текст не разбирается как XML и не ограничивается его длиной.
    """
    if (type(сообщение) is not dict or сообщение.get("type") != "message"
            or сообщение.get("role") != "user" or сообщение.get("phase") is not None):
        return "неоднозначный"
    содержимое = сообщение.get("content")
    if (type(содержимое) is not list or not 0 < len(содержимое) <= МАКСИМУМ_ФРАГМЕНТОВ
            or not all(_корректный_контент(часть) for часть in содержимое)):
        return "неоднозначный"
    метаданные = сообщение.get("internal_chat_message_metadata_passthrough")
    if метаданные is not None and type(метаданные) is not dict:
        return "неоднозначный"
    if метаданные is not None and "content_item_kinds" in метаданные:
        виды = метаданные["content_item_kinds"]
        if (type(виды) is not list or len(виды) != len(содержимое)
                or not all(type(вид) is str for вид in виды)):
            return "неоднозначный"
        if all(вид in _ВИДЫ_ПОЛЬЗОВАТЕЛЯ and часть["type"] in _ВИДЫ_ПОЛЬЗОВАТЕЛЯ[вид]
               for вид, часть in zip(виды, содержимое)):
            return "человек"
        if all(вид in _ВИДЫ_КОНТЕКСТА and часть["type"] == "input_text"
               for вид, часть in zip(виды, содержимое)):
            return "служебный контекст"
        return "неоднозначный"
    размер = 0
    for часть in содержимое:
        if часть["type"] != "input_text":
            return "неоднозначный"
        размер += len(часть["text"])
        if размер > МАКСИМУМ_СУММАРНЫХ_СИМВОЛОВ_РАЗМЕТКИ or not _полный_служебный_фрагмент(часть["text"]):
            return "неоднозначный"
    return "служебный hook"
