"""Первоначальный служебный контекст и точные копии нативного транспорта."""
import снимок_нативного_источника as снимок

хранение = снимок.хранение
происхождение = снимок.сообщения_задачи._КЛАССИФИКАТОР


class КонтрольПервичногоПотока:
    def __init__(self):
        self.начало = True
        self.контекст = False
        self.оригинал = None
        self.копия = False

    def проверить(self, запись):
        """Вернуть true только для единственной точной транспортной копии."""
        данные = запись['payload']
        тип, вид = запись.get('type'), данные.get('type')
        элемент = данные.get('item')
        вложенный_человек = тип == 'event_msg' and type(элемент) is dict \
            and (элемент.get('type') == 'UserMessage' or элемент.get('role') == 'user')
        хранение.требовать(not (тип == 'event_msg' and вид in {'user_message', 'turn_aborted'}
            or вложенный_человек), 'Получено новое управляющее событие: необработанный пользовательский '
            'ввод или отмена; нужен разбор координатора')
        if тип == 'response_item' and вид == 'message' and данные.get('role') == 'user':
            хранение.требовать(self.начало and not self.контекст
                and происхождение.классифицировать_сообщение(данные) == 'служебный контекст'
                and данные['internal_chat_message_metadata_passthrough']['content_item_kinds']
                    == ['agents_md.instructions', 'environments.environment_context'],
                'Новый или неоднозначный пользовательский ввод не является начальным служебным контекстом')
            self.контекст = True
        if тип == 'turn_context' or тип == 'event_msg' and вид == 'task_complete':
            self.начало = False
        if тип == 'response_item' and вид in {'function_call', 'custom_tool_call'}:
            хранение.требовать(данные.get('name') not in снимок.ТРАНСПОРТЫ,
                'Получен новый управляющий вызов транспорта; нужен разбор координатора')
        if тип == 'response_item' and вид == 'function_call_output' \
                and данные.get('name') in снимок.ТРАНСПОРТЫ:
            хранение.требовать(type(данные.get('output')) is str,
                'Получено новое управляющее событие: неизвестное содержимое нативного транспорта')
            self.начало = False
            self.оригинал = (данные['name'], данные['output'])
            self.копия = False
        if тип == 'event_msg' and type(элемент) is dict:
            if элемент.get('type') == 'FunctionCallOutput' and элемент.get('name') in снимок.ТРАНСПОРТЫ:
                хранение.требовать(вид == 'item_completed' and not self.копия and self.оригинал is not None
                    and элемент.get('namespace') == 'codex_app'
                    and (элемент.get('name'), элемент.get('output')) == self.оригинал,
                    'Подменено, повторено или не подтверждено транспортное завершение поручения')
                self.копия = True
                return True
            хранение.требовать(элемент.get('name') not in снимок.ТРАНСПОРТЫ
                and элемент.get('tool') not in снимок.ТРАНСПОРТЫ,
                'Получен новый управляющий вызов транспорта; нужен разбор координатора')
        return False
