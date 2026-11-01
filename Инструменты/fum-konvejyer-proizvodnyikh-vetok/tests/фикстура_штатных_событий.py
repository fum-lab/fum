"""Открытые наблюдённые формы; значения вымышлены, приватных байтов нет."""
from contextlib import contextmanager
from pathlib import Path


def изменение_файлов(изменения=None):
    return {'type': 'event_msg', 'payload': {'type': 'item_completed', 'item': {
        'type': 'FileChange', 'id': 'файлы', 'status': 'completed', 'stdout': '', 'stderr': '',
        'changes': изменения if изменения is not None else {
            'открытый.txt': {'type': 'add', 'content': 'Открытые данные с ё.\n'}}}}}


def обновление():
    return {'type': 'update', 'move_path': None, 'unified_diff': '@@ -1 +1 @@\n-а\n+ё\n'}


def служебный_контекст():
    return {'type': 'response_item', 'payload': {'type': 'message', 'role': 'user',
        'content': [{'type': 'input_text', 'text': 'Начальные правила открытой фикстуры.'},
                    {'type': 'input_text', 'text': 'Начальная среда открытой фикстуры.'}],
        'internal_chat_message_metadata_passthrough': {
            'content_item_kinds': ['agents_md.instructions', 'environments.environment_context']}}}


def копия_транспорта(оригинал):
    данные = оригинал['payload']
    return {'type': 'event_msg', 'payload': {'type': 'item_completed', 'item': {
        'type': 'FunctionCallOutput', 'id': 'копия', 'namespace': 'codex_app',
        'name': данные['name'], 'output': данные['output']}}}


def начальные_события():
    оригинал = {'type': 'response_item', 'payload': {'type': 'function_call_output',
        'name': 'create_thread', 'output': 'Первоначальное поручение открытой фикстуры.'}}
    return [служебный_контекст(), {'type': 'turn_context', 'payload': {
        'model': 'gpt-6-sol', 'effort': 'ultra'}}, оригинал, копия_транспорта(оригинал),
        изменение_файлов()]


@contextmanager
def полный_получатель():
    from фикстура_нативного_приёма import фикстура, строка
    with фикстура() as ф:
        остановка = Path(ф['свидетельство']['остановка']['путь'])
        строки = остановка.read_bytes().splitlines(keepends=True)
        остановка.write_bytes(строки[0] + b''.join(map(строка, начальные_события()))
                              + b''.join(строки[1:]))
        ф['свидетельство'] = ф['сохранить'](входы=[ф['транспорт'],
            копия_транспорта(ф['транспорт']), изменение_файлов({'открытый.txt': обновление()})])
        yield ф
