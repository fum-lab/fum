"""Позднее управление, подмена источника и частичная запись снимка."""
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import test_запуска_слоёв  # Канонические пути модулей открытой фикстуры.
import снимок_нативного_источника as снимок

ЗАДАЧА = '00000000-0000-0000-0000-000000000001'


def строка(тип, данные):
    return json.dumps({'type': тип, 'timestamp': '2026-09-24T12:00:00Z',
                       'payload': данные}, ensure_ascii=False).encode() + b'\n'


class ПроверкаНативногоСнимка(unittest.TestCase):
    def setUp(self):
        self.временный = tempfile.TemporaryDirectory()
        self.addCleanup(self.временный.cleanup)
        self.корень = Path(self.временный.name).resolve()
        self.источник = self.корень / 'native.jsonl'
        self.сырые = строка('session_meta', {'id': ЗАДАЧА}) + строка('turn_context',
            {'model': 'gpt-6-astra', 'effort': 'low'})
        self.источник.write_bytes(self.сырые)
        self.пакет = self.корень / 'снимок'

    def создать(self):
        return снимок.создать(self.источник, ЗАДАЧА, self.пакет)

    def test_закрывает_все_формы_нового_управления(self):
        self.создать()
        входы = [строка('response_item', {'type': 'message', 'role': роль}) for роль in ('user', 'developer')]
        входы += [строка('event_msg', {'type': вид}) for вид in ('user_message', 'turn_aborted', 'unknown')]
        входы += [строка('turn_context', {'model': 'gpt-6-astra', 'effort': 'max'})]
        входы += [строка('response_item', {'type': 'function_call_output', 'name': имя,
            'output': '<codex_delegation>поручение</codex_delegation>'}) for имя in снимок.ТРАНСПОРТЫ]
        входы += [строка('event_msg', {'type': 'item_completed', 'item': {
            'type': 'FunctionCallOutput', 'name': 'send_message_to_thread'}}),
            строка('event_msg', {'type': 'item_completed', 'item': {'type': 'UserMessage'}})]
        for хвост in входы:
            with self.subTest(хвост=хвост):
                self.источник.write_bytes(self.сырые + хвост)
                with self.assertRaisesRegex(ValueError, 'новое управляющее'):
                    снимок.прочитать(self.пакет, ЗАДАЧА)

    def test_не_принимает_переписанный_уже_наблюдённый_нейтральный_хвост(self):
        self.создать()
        хвост = строка('response_item', {'type': 'custom_tool_call_output', 'output': 'первый'})
        self.источник.write_bytes(self.сырые + хвост)
        курсор = self.корень / 'наблюдение.json'
        снимок.наблюдать(self.пакет, ЗАДАЧА, курсор, первое=True)
        self.источник.write_bytes(self.сырые + хвост.replace('первый'.encode(), 'второй'.encode()))
        with self.assertRaisesRegex(ValueError, 'ранее наблюдённый хвост'):
            снимок.наблюдать(self.пакет, ЗАДАЧА, курсор)

    def test_потеря_курсора_не_сбрасывает_ранее_наблюдённую_границу(self):
        self.создать()
        курсор = self.корень / 'наблюдение.json'
        self.источник.write_bytes(self.сырые + строка('event_msg', {'type': 'token_count'}))
        снимок.наблюдать(self.пакет, ЗАДАЧА, курсор, первое=True)
        курсор.unlink(); self.источник.write_bytes(self.сырые)
        with self.assertRaisesRegex(ValueError, 'Курсор наблюдения потерян'):
            снимок.наблюдать(self.пакет, ЗАДАЧА, курсор)
        self.assertFalse(курсор.exists())

    def test_ссылка_на_курсор_отклоняется_без_замены(self):
        self.создать()
        курсор = self.корень / 'наблюдение.json'
        снимок.наблюдать(self.пакет, ЗАДАЧА, курсор, первое=True)
        другой = self.корень / 'другой-курсор.json'; курсор.rename(другой); курсор.symlink_to(другой)
        with self.assertRaises(ValueError):
            снимок.наблюдать(self.пакет, ЗАДАЧА, курсор)
        self.assertTrue(курсор.is_symlink())

    def test_усечение_после_отказа_не_стирает_замеченное_управление(self):
        self.создать()
        курсор = self.корень / 'наблюдение.json'
        снимок.наблюдать(self.пакет, ЗАДАЧА, курсор, первое=True)
        self.источник.write_bytes(self.сырые + строка('event_msg', {'type': 'user_message'}))
        with self.assertRaisesRegex(ValueError, 'новое управляющее'):
            снимок.наблюдать(self.пакет, ЗАДАЧА, курсор)
        self.источник.write_bytes(self.сырые)
        with self.assertRaisesRegex(ValueError, 'передача остаётся закрытой'):
            снимок.наблюдать(self.пакет, ЗАДАЧА, курсор)

    def test_управление_перед_созданием_снимка_тоже_закрывает_передачу(self):
        import полный_поток_передачи as полный
        поручение = строка('response_item', {'type': 'function_call_output',
            'name': 'create_thread', 'output': 'начальное поручение'})
        префикс = self.сырые + поручение
        завершение = строка('event_msg', {'type': 'item_completed', 'item': {
            'type': 'FunctionCallOutput', 'name': 'create_thread', 'namespace': 'codex_app',
            'output': 'начальное поручение'}})
        полный.проверить(префикс + завершение, len(префикс))
        for хвост in (строка('event_msg', {'type': 'user_message', 'message': 'Остановись.'}),
            строка('event_msg', {'type': 'turn_aborted'}),
            строка('response_item', {'type': 'message', 'role': 'developer'}),
            строка('response_item', {'type': 'function_call_output', 'name': 'send_message_to_thread'})):
            with self.subTest(хвост=хвост), self.assertRaisesRegex(ValueError, 'новое управляющее'):
                полный.проверить(префикс + завершение + хвост, len(префикс))

    def test_подмена_inode_при_тех_же_байтах_не_проходит(self):
        self.создать()
        новый = self.корень / 'другой.jsonl'; новый.write_bytes(self.сырые)
        os.replace(новый, self.источник)
        with self.assertRaisesRegex(ValueError, 'заменён'):
            снимок.прочитать(self.пакет, ЗАДАЧА)

    def test_усечение_перезапись_и_неполный_LF_закрываются(self):
        self.создать()
        for байты in (self.сырые[:-1], self.сырые.split(b'\n')[0] + b'\n',
                      self.сырые.replace(b'low', b'max'), self.сырые + b'{'):
            with self.subTest(байты=байты):
                self.источник.write_bytes(байты)
                with self.assertRaises(ValueError):
                    снимок.прочитать(self.пакет, ЗАДАЧА)

    def test_частичная_запись_не_становится_готовым_пакетом(self):
        запись = снимок.файлы._записать
        def прервать(путь, байты):
            if путь.name == 'описание.json':
                raise OSError('Сбой сохранения описания')
            запись(путь, байты)
        with mock.patch.object(снимок.файлы, '_записать', side_effect=прервать):
            with self.assertRaises(OSError):
                self.создать()
        inode = (self.пакет / 'источник.jsonl').stat().st_ino
        with self.assertRaisesRegex(ValueError, 'Неполный состав'):
            self.создать()
        self.assertEqual(inode, (self.пакет / 'источник.jsonl').stat().st_ino)

    def test_запрещает_Git_ссылки_и_неверные_права(self):
        git = self.корень / 'git'; git.mkdir(mode=0o700); (git / '.git').mkdir()
        bare = self.корень / 'bare'; bare.mkdir(mode=0o700)
        (bare / 'HEAD').touch(); (bare / 'objects').mkdir(); (bare / 'refs').mkdir()
        for родитель in (git, bare):
            with self.subTest(родитель=родитель):
                with self.assertRaisesRegex(ValueError, 'Git'):
                    снимок.создать(self.источник, ЗАДАЧА, родитель / 'снимок')
                self.assertFalse((родитель / 'снимок').exists())
        ссылка = self.корень / 'ссылка.jsonl'; ссылка.symlink_to(self.источник)
        with self.assertRaises(ValueError):
            снимок.создать(ссылка, ЗАДАЧА, self.пакет)
        self.создать()
        (self.пакет / 'источник.jsonl').chmod(0o644)
        with self.assertRaisesRegex(ValueError, 'права'):
            снимок.прочитать(self.пакет, ЗАДАЧА)

    def test_неизвестная_модель_или_чужой_UUID_не_создают_снимок(self):
        for сырые in (self.сырые.replace(b'"effort": "low"', b'"missing": "low"'),
                      self.сырые.replace(ЗАДАЧА.encode(), b'00000000-0000-0000-0000-000000000002')):
            self.источник.write_bytes(сырые)
            with self.assertRaises(ValueError):
                self.создать()
            self.assertFalse(self.пакет.exists())


if __name__ == '__main__':
    unittest.main()
