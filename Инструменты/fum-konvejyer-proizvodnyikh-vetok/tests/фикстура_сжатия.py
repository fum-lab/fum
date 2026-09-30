"""Открытая синтетическая форма сжатия без первичных инструкций и секретов."""
import json


ВИДЫ = [
    ['generic.developer_instructions', 'memories.instructions', 'permissions.instructions',
     'collaboration_mode.instructions', 'plugins.recommendations'],
    ['multi_agent.role_instructions'], ['multi_agent.mode_instructions'],
    ['agents_md.instructions', 'environments.environment_context'],
]


def строка(запись):
    return json.dumps({'timestamp': '2026-09-30T12:00:00Z', **запись},
                      ensure_ascii=False).encode() + b'\n'


def контекст():
    сообщения = []
    for номер, виды in enumerate(ВИДЫ):
        сообщения.append({'type': 'message', 'id': f'оригинал-{номер}',
            'role': 'user' if номер == 3 else 'developer',
            'content': [{'type': 'input_text', 'text': f'Открытая часть {номер}:{часть}'}
                        for часть in range(len(виды))],
            'internal_chat_message_metadata_passthrough': {
                'turn_id': 'первый-ход', 'create_time': 1.0, 'content_item_kinds': виды[:]}})
    return сообщения


def сжатие(сообщения=None):
    сообщения = контекст() if сообщения is None else сообщения
    копии = []
    for номер, сообщение in enumerate(сообщения):
        # Native создаёт новые ID и удаляет create_time, сохраняя turn_id и части.
        копии.append({**сообщение, 'id': f'копия-{номер}',
            'internal_chat_message_metadata_passthrough': {
                'turn_id': сообщение['internal_chat_message_metadata_passthrough']['turn_id'],
                'content_item_kinds': сообщение['internal_chat_message_metadata_passthrough']['content_item_kinds'][:]}})
    копии.append({'type': 'compaction', 'id': 'непрозрачный-блок',
                  'encrypted_content': 'открытая-фикстура-не-секрет',
                  'internal_chat_message_metadata_passthrough': {'turn_id': 'первый-ход'}})
    счётчики = {ключ: 0 for ключ in ('input_tokens', 'cached_input_tokens',
        'cache_write_input_tokens', 'output_tokens', 'reasoning_output_tokens', 'total_tokens')}
    return {'type': 'compacted', 'ordinal': 7, 'timestamp': '2026-09-30T12:00:00Z',
        'payload': {'compaction_response_id': 'ответ-сжатия', 'first_window_id': 'окно-0',
            'previous_window_id': 'окно-0', 'window_id': 'окно-1', 'window_number': 1,
            'message': '', 'replacement_history': копии,
            'replacement_history_metadata': [{'client_authored': False} for _ in range(4)] +
                [{'client_authored': False, 'compaction_model_hash': 'непрозрачный-хэш',
                  'mcp_attribution': {'status': 'none'}}],
            'resume_metadata': {'last_started_turn_id': 'первый-ход', 'multi_agent_version': '1',
                'previous_turn_settings': {'comp_hash': 'непрозрачные-настройки',
                                          'model': 'gpt-6-astra', 'realtime_active': False}},
            'retained_context': {'incomplete': False, 'user_messages_incomplete': False,
                                 'user_messages': [], 'verified_answers': [], 'next_order': 12},
            'latest_token_usage_record': {**{ключ: 'открытый-идентификатор' for ключ in
                ('response_id', 'root_turn_id', 'session_id', 'thread_id', 'turn_id')},
                'usage': счётчики.copy(), 'turn_token_usage': счётчики.copy(),
                'thread_token_usage': счётчики.copy()}}}


def префикс(задача):
    return (строка({'type': 'session_meta', 'payload': {'id': задача}})
        + b''.join(строка({'type': 'response_item', 'payload': сообщение}) for сообщение in контекст())
        + строка({'type': 'turn_context', 'payload': {'model': 'gpt-6-astra', 'effort': 'low'}}))
