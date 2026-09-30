"""Закрытая форма внутренней копии: никаких новых полномочий из сжатия."""
import хранилище_незавершённого as файлы

хранение = файлы.хранение
ПОЛЯ_СООБЩЕНИЯ = {'type', 'id', 'role', 'content', 'internal_chat_message_metadata_passthrough'}
ВИДЫ_КОНТЕКСТА = (
    ['generic.developer_instructions', 'memories.instructions', 'permissions.instructions',
     'collaboration_mode.instructions', 'plugins.recommendations'],
    ['multi_agent.role_instructions'], ['multi_agent.mode_instructions'],
    ['agents_md.instructions', 'environments.environment_context'],
)


def _объект(данные, поля):
    хранение.требовать(type(данные) is dict and set(данные) == поля,
                      'Неизвестная или неполная форма нативного сжатия')


def _текст(значение):
    хранение.требовать(type(значение) is str and bool(значение) and '\0' not in значение,
                      'Неверное текстовое поле нативного сжатия')


def _целое(значение):
    хранение.требовать(type(значение) is int and значение >= 0,
                      'Неверный счётчик нативного сжатия')


def _сообщение(данные, номер, *, оригинал=False):
    _объект(данные, ПОЛЯ_СООБЩЕНИЯ)
    хранение.требовать(данные['type'] == 'message'
        and данные['role'] == ('user' if номер == 3 else 'developer'),
        'Неизвестная роль или порядок копии сжатия')
    _текст(данные['id'])
    метаданные = данные['internal_chat_message_metadata_passthrough']
    поля = {'turn_id', 'content_item_kinds'}
    if оригинал:
        поля |= {'create_time'}
    _объект(метаданные, поля)
    _текст(метаданные['turn_id'])
    if оригинал:
        хранение.требовать(type(метаданные['create_time']) in {int, float},
                          'Неизвестное происхождение исходного сообщения')
    хранение.требовать(метаданные['content_item_kinds'] == ВИДЫ_КОНТЕКСТА[номер]
        and type(метаданные['content_item_kinds']) is list,
        'Изменены виды частей начального контекста')
    части = данные['content']
    хранение.требовать(type(части) is list and len(части) == len(ВИДЫ_КОНТЕКСТА[номер]),
                      'Неполный набор частей начального контекста')
    for часть in части:
        _объект(часть, {'type', 'text'})
        хранение.требовать(часть['type'] == 'input_text' and type(часть['text']) is str,
                          'Неизвестная часть копии сжатия')
    return (данные['role'], части, метаданные['content_item_kinds'], метаданные['turn_id'])


def _метаданные(данные, ход):
    _объект(данные['retained_context'], {'incomplete', 'user_messages_incomplete',
        'user_messages', 'verified_answers', 'next_order'})
    остаток = данные['retained_context']
    хранение.требовать(остаток['incomplete'] is False and остаток['user_messages_incomplete'] is False
        and type(остаток['user_messages']) is list and not остаток['user_messages']
        and type(остаток['verified_answers']) is list and not остаток['verified_answers'],
        'Сжатие содержит неполноту или непроверенный новый ввод')
    _целое(остаток['next_order'])
    возобновление = данные['resume_metadata']
    _объект(возобновление, {'last_started_turn_id', 'multi_agent_version', 'previous_turn_settings'})
    хранение.требовать(возобновление['last_started_turn_id'] == ход,
                      'Сжатие относится к другому ходу')
    _текст(возобновление['multi_agent_version'])
    настройки = возобновление['previous_turn_settings']
    _объект(настройки, {'comp_hash', 'model', 'realtime_active'})
    _текст(настройки['comp_hash']); _текст(настройки['model'])
    хранение.требовать(настройки['realtime_active'] is False,
                      'Неизвестный режим сжатия')
    использование = данные['latest_token_usage_record']
    имена = {'response_id', 'root_turn_id', 'session_id', 'thread_id', 'turn_id'}
    суммы = {'usage', 'turn_token_usage', 'thread_token_usage'}
    _объект(использование, имена | суммы)
    for имя in имена:
        _текст(использование[имя])
    счётчики = {'input_tokens', 'cached_input_tokens', 'cache_write_input_tokens',
                'output_tokens', 'reasoning_output_tokens', 'total_tokens'}
    for имя in суммы:
        _объект(использование[имя], счётчики)
        for значение in использование[имя].values():
            _целое(значение)


class ИсторияНачальногоКонтекста:
    """Якоря берутся только из прямого более раннего response_item этого потока."""
    def __init__(self):
        self.сообщения = []
        self.сжатие_проверено = False

    def проверить(self, запись):
        хранение.требовать(type(запись) is dict and type(запись.get('payload')) is dict,
                          'Неизвестная запись истории нативного сжатия')
        данные = запись['payload']
        if запись.get('type') == 'response_item' and данные.get('type') == 'message' \
                and type(данные.get('role')) is str and данные['role'] in {'developer', 'user'}:
            хранение.требовать(not self.сжатие_проверено,
                'После сжатия получен новый контекст; нужен разбор координатора')
            self.сообщения.append(данные)
        if запись.get('type') != 'compacted':
            return False
        _объект(запись, {'type', 'ordinal', 'timestamp', 'payload'})
        _целое(запись['ordinal']); _текст(запись['timestamp'])
        _объект(данные, {'compaction_response_id', 'first_window_id', 'latest_token_usage_record',
            'message', 'previous_window_id', 'replacement_history', 'replacement_history_metadata',
            'resume_metadata', 'retained_context', 'window_id', 'window_number'})
        for поле in ('compaction_response_id', 'first_window_id', 'previous_window_id', 'window_id'):
            _текст(данные[поле])
        _целое(данные['window_number'])
        хранение.требовать(данные['message'] == '' and type(данные['message']) is str,
                          'Непроверенный текст в событии сжатия')
        копии, метаданные = данные['replacement_history'], данные['replacement_history_metadata']
        хранение.требовать(type(копии) is list and len(копии) == 5
            and type(метаданные) is list and len(метаданные) == 5 and len(self.сообщения) == 4,
            'Нет полной однозначной истории начального контекста')
        ходы, исходные_имена, новые_имена = set(), set(), set()
        for номер, (оригинал, копия) in enumerate(zip(self.сообщения, копии[:4])):
            исходное = _сообщение(оригинал, номер, оригинал=True)
            новое = _сообщение(копия, номер)
            хранение.требовать(исходное == новое, 'Сжатие изменило исходный контекст')
            исходные_имена.add(оригинал['id']); новые_имена.add(копия['id']); ходы.add(исходное[-1])
        хранение.требовать(len(ходы) == 1 and len(исходные_имена) == len(новые_имена) == 4,
                          'Неоднозначное происхождение копий сжатия')
        ход = next(iter(ходы))
        непрозрачное = копии[4]
        _объект(непрозрачное, {'type', 'id', 'encrypted_content', 'internal_chat_message_metadata_passthrough'})
        _объект(непрозрачное['internal_chat_message_metadata_passthrough'], {'turn_id'})
        хранение.требовать(непрозрачное['type'] == 'compaction'
            and непрозрачное['internal_chat_message_metadata_passthrough']['turn_id'] == ход,
            'Неизвестный непрозрачный блок сжатия')
        _текст(непрозрачное['id'])
        хранение.требовать(непрозрачное['id'] not in новые_имена
            and type(непрозрачное['encrypted_content']) is str and bool(непрозрачное['encrypted_content']),
            'Неизвестный непрозрачный блок сжатия')
        for номер, метка in enumerate(метаданные):
            _объект(метка, {'client_authored'} if номер < 4 else
                    {'client_authored', 'compaction_model_hash', 'mcp_attribution'})
            хранение.требовать(метка['client_authored'] is False,
                              'Неизвестный автор копии сжатия')
        последняя = метаданные[4]
        _текст(последняя['compaction_model_hash'])
        _объект(последняя['mcp_attribution'], {'status'})
        хранение.требовать(последняя['mcp_attribution']['status'] == 'none',
                          'Неизвестное происхождение непрозрачного блока')
        _метаданные(данные, ход)
        # Ничего из compacted не добавляется в якоря, prompt, управление или вывод.
        self.сжатие_проверено = True
        return True
