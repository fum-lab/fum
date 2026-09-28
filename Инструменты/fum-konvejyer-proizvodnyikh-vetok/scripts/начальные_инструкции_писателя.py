"""Конечный служебный префикс первого native хода; не новый ввод или полномочия."""
import hashlib
import math
from pathlib import Path

import приём_направления as хранение

КОД_ПРИ_ЗАГРУЗКЕ = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
ГРУППЫ = (
    ['generic.developer_instructions', 'memories.instructions', 'permissions.instructions',
        'collaboration_mode.instructions', 'plugins.recommendations'],
    ['multi_agent.role_instructions'], ['multi_agent.mode_instructions'],
)


class НачальныеИнструкцииПисателя:
    def __init__(self):
        self.номер = 0
        self.ход = None
        self.время = None
        self.закрыт = False

    def проверить(self, запись):
        данные = запись['payload']; тип, вид = запись.get('type'), данные.get('type')
        if тип == 'event_msg' and вид == 'task_started':
            self.ход = данные.get('turn_id')
            return False  # Единственность начала проверяет полный поток.
        if тип == 'response_item' and вид == 'message' and данные.get('role') == 'developer':
            хранение.требовать(not self.закрыт and self.номер < len(ГРУППЫ)
                and хранение.идентификатор_задачи(self.ход),
                'Поздние, повторные или непривязанные начальные инструкции')
            хранение.поля(данные, {'type', 'id', 'role', 'content', 'internal_chat_message_metadata_passthrough'})
            метаданные = данные['internal_chat_message_metadata_passthrough']
            хранение.поля(метаданные, {'turn_id', 'create_time', 'content_item_kinds'})
            содержимое = данные['content']; время = метаданные['create_time']
            хранение.требовать(type(данные['id']) is str and данные['id'] and '\0' not in данные['id']
                and метаданные['turn_id'] == self.ход
                and метаданные['content_item_kinds'] == ГРУППЫ[self.номер]
                and type(время) in (int, float) and math.isfinite(время) and время > 0
                and (self.номер == 0 or время == self.время)
                and type(содержимое) is list and len(содержимое) == len(ГРУППЫ[self.номер])
                and all(type(э) is dict and set(э) == {'type', 'text'} and э['type'] == 'input_text'
                    and type(э['text']) is str and э['text'] for э in содержимое),
                'Повреждён служебный состав начальных инструкций')
            self.время = время
            self.номер += 1
            return True
        if тип != 'session_meta':
            self.закрыт = True
            хранение.требовать(self.номер in (0, len(ГРУППЫ)), 'Неполный блок начальных инструкций')
        if тип == 'turn_context' and self.номер:
            хранение.требовать(данные.get('turn_id') == self.ход,
                'Первый контекст принадлежит другому ходу начальных инструкций')
        return False
