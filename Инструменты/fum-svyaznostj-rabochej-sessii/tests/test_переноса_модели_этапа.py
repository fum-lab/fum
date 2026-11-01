"""Адресные границы композиции переноса модели ROOT этапа."""
import importlib
import copy
import cProfile
import json
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import история_модели as модель
import подготовка_этапа_коммита as фасад
import test_перенос_истории_модели as прежние_тесты
from test_подготовки_этапа_коммита import КорневаяФикстура


class ПереносМоделиЭтапа(unittest.TestCase):
    setUp = прежние_тесты.ПереносИсторииМодели.setUp
    добавить = прежние_тесты.ПереносИсторииМодели.добавить
    наблюдать = прежние_тесты.ПереносИсторииМодели.наблюдать

    def входы(self):
        self.основа.chmod(0o700)
        п = {'схема': 'fum.создание-коммита.5', 'режим': 'контрольная-точка',
            'корень': str(self.корень), 'задача': self.задача,
            'имя_автора': 'FUM Codex', 'источник_модели': str(self.источник),
            'кэш_модели': str(self.новый_кэш), 'история_модели': 'новый.json'}
        т = {к: {'путь': str(ф), 'sha256': модель.чтение._хэш(ф.read_bytes())}
            for к, ф in [('прежняя_история', self.старый_отчёт), ('прежний_кэш', self.старый_кэш)]}
        return п, т

    def test_новая_пара_совпадает_с_полным_импортом(self):
        перенос = importlib.import_module('перенос_модели_этапа')
        for _ in range(1200):
            self.добавить({'type': 'event_msg', 'payload': {'text': 'префикс' * 100}})
        модель.импортировать(self.источник, self.задача, корень_репозитория=self.корень,
            кэш=self.старый_кэш, история=self.старый_отчёт)
        п, т = self.входы()
        прежние = [ф.read_bytes() for ф in (self.старый_отчёт, self.старый_кэш)]
        self.наблюдать('gpt-6.1-sol', 'ultra')
        план = перенос.предварить(п, т)
        исходный = модель.чтение._разобрать
        строки = []
        def разбор(д):
            if д.startswith(b'{"type":') and д.endswith(b'\n'):
                строки.append(д)
            return исходный(д)
        with patch.object(модель.чтение, '_разобрать', side_effect=разбор):
            итог = перенос.выполнить(п, т, план)
        self.assertEqual(len(строки), 4)  # Наблюдение и хвост отдельно в dry и write.
        self.assertGreater(self.источник.stat().st_size, 1024*1024)
        self.assertEqual(итог['перенос']['профиль']['разобрано_строк'], 1)
        модель.импортировать(self.источник, self.задача, корень_репозитория=self.корень,
            кэш=self.основа/'полный-кэш.json', история=self.корень/'полный.json')
        self.assertEqual(self.новый_отчёт.read_bytes(), (self.корень/'полный.json').read_bytes())
        self.assertEqual(прежние, [ф.read_bytes() for ф in (self.старый_отчёт, self.старый_кэш)])

    def test_поле_принимается_обычным_ROOT_фасадом(self):
        ф = КорневаяФикстура(self, контур='обычный')
        старый = ф.корень/'старая-модель.json'
        кэш = ф.приватный/'старая-модель-кэш.json'
        модель.импортировать(ф.п['источник_модели'], ф.п['задача'],
            корень_репозитория=ф.корень, кэш=кэш, история=старый)
        т = {к: {'путь': str(п), 'sha256': фасад.хэш(п.read_bytes())}
            for к, п in [('прежняя_история', старый), ('прежний_кэш', кэш)]}
        ф.вход['перенос_модели'] = т
        ф.ф.гит('add', 'старая-модель.json'); ф.ф.гит('commit', '-qm', 'Старая модель открытой фикстуры')
        ф.п['исходный_коммит'] = ф.ф.гит('rev-parse', 'HEAD').strip(); ф.п['родители'] = [ф.п['исходный_коммит']]
        ф.сохранить('вход-root.json', ф.п)
        self.assertIn('перенос_модели', фасад.корневой_план(ф.вход))

    def test_штатный_ROOT_порядок_и_prepare_после_переноса(self):
        ф = КорневаяФикстура(self, контур='обычный')
        старый = ф.корень/'старая-модель.json'; кэш = ф.приватный/'старая-модель-кэш.json'
        модель.импортировать(ф.п['источник_модели'], ф.п['задача'], корень_репозитория=ф.корень,
            кэш=кэш, история=старый)
        ф.вход['перенос_модели'] = {к: {'путь': str(п), 'sha256': фасад.хэш(п.read_bytes())}
            for к, п in [('прежняя_история', старый), ('прежний_кэш', кэш)]}
        ф.ф.гит('add', 'старая-модель.json'); ф.ф.гит('commit', '-qm', 'Старая модель открытой фикстуры')
        ф.п['исходный_коммит'] = ф.ф.гит('rev-parse', 'HEAD').strip(); ф.п['родители'] = [ф.п['исходный_коммит']]
        ф.сохранить('вход-root.json', ф.п)
        план = фасад.корневой_план(ф.вход)
        р = фасад.выполнить_корневой(ф.вход, план, фасад.хэш(фасад.байты(план)))
        self.assertEqual(р['код'], 0, р)
        self.assertEqual([з['стадия'] for з in р['стадии']][:7], [
            'Создать каноническую пару ROOT', 'Создать родитель новой модели',
            'Сухой штатный перенос модели', 'Пересверить модель перед записью',
            'Штатный перенос модели', 'Пересверить завершённый перенос', 'Подготовить источники и модель'])

    def test_без_поля_и_границы_контуров(self):
        ф = КорневаяФикстура(self, контур='обычный')
        self.assertNotIn('перенос_модели', фасад.корневой_план(ф.вход))
        ф.вход.pop('контур'); ф.вход['перенос_модели'] = {}
        with self.assertRaisesRegex(ValueError, 'обычный ROOT'):
            фасад.корневой_план(ф.вход)
        with self.assertRaises(ValueError):
            фасад.построить_план({'перенос_модели': {}})  # Обычная .7 не расширена.

    def test_дописание_между_планом_и_сухим_переносом_разрешено(self):
        м = importlib.import_module('перенос_модели_этапа'); п, т = self.входы(); план = м.предварить(п, т)
        self.наблюдать('gpt-6.1-sol', 'ultra')
        self.assertEqual(м.выполнить(п, т, план)['перенос']['новых_наблюдений'], 1)

    def test_отказы_до_start_не_создают_назначений(self):
        м = importlib.import_module('перенос_модели_этапа')
        for случай in ('UUID', 'адрес', 'SHA', 'пара', 'подготовлено', 'замок', 'symlink'):
            with self.subTest(случай=случай):
                self.setUp(); п, т = self.входы()
                if случай == 'UUID': п['задача'] = '00000000-0000-0000-0000-000000000002'
                elif случай == 'адрес': п['история_модели'] = str(self.основа/'чужая.json')
                elif случай == 'SHA': т['прежний_кэш']['sha256'] = '0'*64
                elif случай == 'пара': self.старый_отчёт.unlink()
                elif случай == 'подготовлено':
                    д = json.loads(self.старый_кэш.read_bytes()); д['данные']['подготовлено'] = True
                    д['sha256'] = модель.чтение._хэш(модель.чтение._байты(д['данные']))
                    self.старый_кэш.write_bytes(модель.чтение._байты(д)); т['прежний_кэш']['sha256'] = м.хэш(self.старый_кэш.read_bytes())
                elif случай == 'замок': п['кэш_модели'] = str(self.старый_кэш)+'.lock'
                elif случай == 'symlink':
                    с = self.основа/'ссылка'; с.symlink_to(self.старый_кэш); т['прежний_кэш']['путь'] = str(с)
                with self.assertRaises((ValueError, OSError)): м.предварить(п, т)
                self.assertFalse(self.новый_кэш.exists()); self.assertFalse(self.новый_отчёт.exists())

    def test_плохой_префикс_хвост_и_неизвестная_модель_не_пишутся(self):
        м = importlib.import_module('перенос_модели_этапа')
        for случай in ('префикс', 'неполный хвост', 'unknown', 'небезопасное усилие'):
            with self.subTest(случай=случай):
                self.setUp(); п, т = self.входы(); план = м.предварить(п, т)
                if случай == 'префикс': self.источник.write_bytes(self.источник.read_bytes().replace(b'ultra', b'high '))
                elif случай == 'неполный хвост':
                    with self.источник.open('ab') as ф: ф.write(b'{')
                elif случай == 'unknown': self.наблюдать('unknown', 'ultra')
                else: self.наблюдать('gpt-6.1-sol', 'bad effort')
                with self.assertRaises(ValueError): м.выполнить(п, т, план)
                self.assertFalse(self.новый_кэш.exists()); self.assertFalse(self.новый_отчёт.exists())

    def test_дрейф_перед_write_запрещён(self):
        м = importlib.import_module('перенос_модели_этапа')
        for случай in ('источник', 'пара', 'код'):
            with self.subTest(случай=случай):
                self.setUp(); п, т = self.входы(); план = м.предварить(п, т)
                def вызов(имя, ф):
                    if имя == 'Пересверить модель перед записью':
                        if случай == 'источник': self.наблюдать('gpt-6.1-sol', 'ultra')
                        elif случай == 'пара': self.старый_отчёт.write_bytes(b'{}\n')
                        else:
                            with patch.object(м, 'замыкание_кода', return_value=[]): return ф()
                    return ф()
                with self.assertRaises(ValueError): м.выполнить(п, т, план, вызов=вызов)
                self.assertFalse(self.новый_кэш.exists()); self.assertFalse(self.новый_отчёт.exists())

    def частичный(self, номер):
        м = importlib.import_module('перенос_модели_этапа'); п, т = self.входы(); план = м.предварить(п, т)
        исходный = модель.чтение._установить; счётчик = 0
        def установка(ф, д):
            nonlocal счётчик
            счётчик += 1
            if счётчик == номер: raise OSError('Открытый сбой частичной установки')
            return исходный(ф, д)
        with patch.object(модель.чтение, '_установить', side_effect=установка):
            with self.assertRaises(OSError): м.выполнить(п, т, план)
        self.assertTrue(self.новый_кэш.exists())
        self.assertEqual(self.новый_отчёт.exists(), номер == 3)
        return м, п, т, план

    def test_обе_частичные_точки_восстанавливаются_без_второго_transfer(self):
        for номер in (2, 3):
            with self.subTest(точка=номер):
                self.setUp(); м, п, т, план = self.частичный(номер)
                self.наблюдать('gpt-6.1-sol', 'ultra')
                with patch.object(м.перенос, 'перенести', side_effect=AssertionError('Второй transfer')):
                    self.assertTrue(м._восстановить(п, т, план)['полнота'])
                self.assertEqual(json.loads(self.новый_отчёт.read_bytes())['число_наблюдений'], 2)
                with self.assertRaisesRegex(ValueError, 'уже существует'): м.выполнить(п, т, план)

    def test_потерянный_курсор_и_подмена_истории_не_открывают_fallback(self):
        for случай in ('потеря', 'курсор', 'история'):
            with self.subTest(случай=случай):
                self.setUp(); м, п, т, план = self.частичный(3)
                if случай == 'потеря': self.новый_кэш.unlink()
                elif случай == 'курсор': self.новый_кэш.write_bytes(b'{}\n')
                else: self.новый_отчёт.write_bytes(b'{}\n')
                before = self.новый_отчёт.read_bytes()
                with patch.object(м.перенос, 'перенести', side_effect=AssertionError('Второй transfer')):
                    with self.assertRaises(ValueError): м._восстановить(п, т, план)
                self.assertEqual(before, self.новый_отчёт.read_bytes())

    def test_поздний_дрейф_сохраняет_пару_и_требует_импорта(self):
        м = importlib.import_module('перенос_модели_этапа'); п, т = self.входы(); план = м.предварить(п, т)
        исходный = модель.чтение._установить; номер = 0
        def установка(ф, д):
            nonlocal номер
            исходный(ф, д); номер += 1
            if номер == 3: self.наблюдать('gpt-6.1-sol', 'ultra')
        with patch.object(модель.чтение, '_установить', side_effect=установка):
            with self.assertRaisesRegex(ValueError, 'дрейф источника при записи'): м.выполнить(п, т, план)
        self.assertTrue(self.новый_кэш.exists()); self.assertTrue(self.новый_отчёт.exists())
        with patch.object(м.перенос, 'перенести', side_effect=AssertionError('Второй transfer')):
            self.assertTrue(м._восстановить(п, т, план)['полнота'])

    def test_неполнота_и_unknown_при_recovery_не_меняют_пару(self):
        for случай in ('хвост', 'unknown'):
            with self.subTest(случай=случай):
                self.setUp(); м, п, т, план = self.частичный(3)
                if случай == 'хвост':
                    with self.источник.open('ab') as ф: ф.write(b'{')
                else: self.наблюдать('unknown', 'ultra')
                до = [ф.read_bytes() for ф in (self.новый_кэш, self.новый_отчёт)]
                with self.assertRaises(ValueError): м._восстановить(п, т, план)
                self.assertEqual(до, [ф.read_bytes() for ф in (self.новый_кэш, self.новый_отчёт)])

    def test_сбой_самого_recovery_повторяется_штатным_импортом(self):
        for точка in (2, 3):
            with self.subTest(точка=точка):
                self.setUp(); м, п, т, план = self.частичный(3)
                self.наблюдать('gpt-6.1-sol', 'ultra')
                исходный = модель.чтение._установить; номер = 0
                def установка(ф, д):
                    nonlocal номер
                    номер += 1
                    if номер == точка: raise OSError('Сбой самого восстановления')
                    return исходный(ф, д)
                with patch.object(модель.чтение, '_установить', side_effect=установка):
                    with self.assertRaises(OSError): м._восстановить(п, т, план)
                self.assertIsNotNone(json.loads(self.новый_кэш.read_bytes())['данные']['ожидаемый_sha256'])
                with patch.object(м.перенос, 'перенести', side_effect=AssertionError('Второй transfer')):
                    self.assertTrue(м._восстановить(п, т, план)['полнота'])
                self.assertEqual(json.loads(self.новый_отчёт.read_bytes())['число_наблюдений'], 2)

    def test_утрата_курсора_внутри_импорта_не_включает_полный_разбор(self):
        м, п, т, план = self.частичный(2)
        импорт = модель.импортировать
        def удалить(*а, **к):
            if not к.get('без_записи'): self.новый_кэш.unlink()
            return импорт(*а, **к)
        до = sys.getprofile()
        with patch.object(модель, 'импортировать', side_effect=удалить):
            with self.assertRaisesRegex(ValueError, 'полный fallback запрещён'): м._восстановить(п, т, план)
        self.assertIs(sys.getprofile(), до)
        self.assertFalse(self.новый_кэш.exists()); self.assertFalse(self.новый_отчёт.exists())

    def test_занятый_Python_и_C_profiler_отклоняются_без_смены_состояния(self):
        м, п, т, план = self.частичный(2)
        до = self.новый_кэш.read_bytes()
        def callback(*а): pass
        for вид in ('Python', 'C'):
            with self.subTest(вид=вид):
                # C-profiler до sys.monitoring возвращал непризываемый объект.
                # Фиксируем эту границу независимо от реализации cProfile версии Python.
                исходный = callback if вид == 'Python' else object()
                if вид == 'Python': sys.setprofile(callback)
                try:
                    if вид == 'C':
                        with patch.object(sys, 'getprofile', return_value=исходный), patch.object(sys, 'setprofile') as установка:
                            with self.assertRaisesRegex(ValueError, 'свободный profile hook'): м._восстановить(п, т, план)
                            установка.assert_not_called()
                    else:
                        with self.assertRaisesRegex(ValueError, 'свободный profile hook'): м._восстановить(п, т, план)
                        self.assertIs(sys.getprofile(), исходный)
                finally:
                    sys.setprofile(None)
                self.assertEqual(до, self.новый_кэш.read_bytes()); self.assertFalse(self.новый_отчёт.exists())

    def test_современный_cProfile_сохраняется_независимо_от_legacy_hook(self):
        м, п, т, план = self.частичный(2); профилировщик = cProfile.Profile()
        профилировщик.enable(); до = sys.getprofile()
        try:
            if до is None: self.assertTrue(м._восстановить(п, т, план)['полнота'])
            else:
                with self.assertRaisesRegex(ValueError, 'свободный profile hook'): м._восстановить(п, т, план)
            self.assertIs(sys.getprofile(), до)
        finally:
            профилировщик.disable()

    def test_замыкание_включает_reader_классификатор_и_поздний_модуль(self):
        м = importlib.import_module('перенос_модели_этапа')
        имена = {Path(з['путь']).name for з in м.замыкание_кода()}
        self.assertTrue({'перенос_модели_этапа.py', 'перенести_историю_модели.py', 'история_модели.py',
            'сообщения_задачи.py', 'происхождение_сообщений.py',
            'pereimenovatj-fajl-s-obnovleniyem-ssyilok.py'} <= имена, имена)

    def test_публичное_восстановление_сверяет_адресный_ROOT_допуск(self):
        м = importlib.import_module('перенос_модели_этапа'); ф = КорневаяФикстура(self, контур='обычный')
        старый = ф.корень/'старая-модель.json'; кэш = ф.приватный/'старый-кэш.json'
        модель.импортировать(ф.п['источник_модели'], ф.п['задача'], корень_репозитория=ф.корень, кэш=кэш, история=старый)
        ф.ф.гит('add', 'старая-модель.json'); ф.ф.гит('commit', '-qm', 'Старая модель открытой фикстуры')
        ф.п['исходный_коммит'] = ф.ф.гит('rev-parse', 'HEAD').strip(); ф.п['родители'] = [ф.п['исходный_коммит']]
        т = {к: {'путь': str(п), 'sha256': фасад.хэш(п.read_bytes())}
            for к, п in [('прежняя_история', старый), ('прежний_кэш', кэш)]}
        план = м.предварить(ф.п, т)
        фасад.каркас.start_session(ф.корень, ф.stem, ф.вход['начало']['метка'], ф.п['заголовок'], ф.п['задача'], ф.сообщения)
        (ф.корень/ф.п['история_модели']).parent.mkdir()
        исходный = модель.чтение._установить
        def частично(путь, д):
            if путь == ф.корень/ф.п['история_модели']: raise OSError('Частичная установка')
            return исходный(путь, д)
        with patch.object(модель.чтение, '_установить', side_effect=частично):
            with self.assertRaises(OSError): м.выполнить(ф.п, т, план)
        for случай in ('UUID', 'HEAD', 'ref', 'родители', 'цель', 'MERGE_HEAD'):
            with self.subTest(случай=случай):
                п = copy.deepcopy(ф.п)
                if случай == 'HEAD': п['исходный_коммит'] = '0'*40
                elif случай == 'ref': п['ветка'] = 'refs/heads/codex/чужая'
                elif случай == 'родители': п['родители'].append('0'*40)
                elif случай == 'цель': п['разрешённые_цели'].remove(п['история_модели'])
                elif случай == 'MERGE_HEAD':
                    merge = Path(ф.ф.гит('rev-parse', '--absolute-git-dir').strip())/'MERGE_HEAD'; merge.write_text('0'*40+'\n')
                with patch.object(модель, 'импортировать', side_effect=AssertionError('Импорт до допуска')):
                    if случай == 'UUID':
                        with patch.dict(os.environ, CODEX_THREAD_ID='00000000-0000-0000-0000-000000000099'):
                            with self.assertRaises(ValueError): м.восстановить(п, т, план)
                    else:
                        with self.assertRaises(ValueError): м.восстановить(п, т, план)
                if случай == 'MERGE_HEAD': merge.unlink()
        with patch.object(м.перенос, 'перенести', side_effect=AssertionError('Второй transfer')):
            self.assertTrue(м.восстановить(ф.п, т, план)['полнота'])


class ГенераторПереноса(unittest.TestCase):
    def setUp(self):
        import test_подготовки_дочернего_поручения as т
        self.т = т.ПодготовкаПоручения(); self.т.setUp(); self.addCleanup(self.т.doCleanups)

    def test_обе_ROOT_фазы_передают_поле_и_проверяют_старую_пару(self):
        for фаза in ('постановка', 'акт'):
            with self.subTest(фаза=фаза):
                if фаза == 'акт': self.т.подготовить_акт()
                т = self.т; ф = т.ф; старый = ф.корень/'старый.json'; кэш = ф.приватный/'старый-кэш.json'
                if старый.exists(): старый.unlink(); кэш.unlink()
                модель.импортировать(т.вход['источник_модели'], т.вход['писатель'], корень_репозитория=ф.корень,
                    кэш=кэш, история=старый)
                т.вход['перенос_модели'] = {к: {'путь': str(п), 'sha256': фасад.хэш(п.read_bytes())}
                    for к, п in [('прежняя_история', старый), ('прежний_кэш', кэш)]}
                план = т.м.построить_план(т.вход)
                self.assertEqual(план['технические_входы']['фасад']['перенос_модели'], т.вход['перенос_модели'])
                т.вход['перенос_модели']['прежний_кэш']['sha256'] = '0'*64
                with self.assertRaisesRegex(ValueError, 'SHA'): т.м.построить_план(т.вход)

    def test_фаза_ребёнка_не_расширена(self):
        т = self.т; т.вход['фаза'] = 'входы'; т.вход['перенос_модели'] = {}
        with self.assertRaisesRegex(ValueError, 'только ROOT'): т.м.построить_план(т.вход)


if __name__ == '__main__':
    unittest.main()
