"""Наполнение новой открытой карточки: полномочия, свежесть и откат пары."""
from pathlib import Path
import copy
import contextlib
import hashlib
import importlib
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import request_folder_layout


class ПроверкаНаполненияКарточки(unittest.TestCase):
    def setUp(сам):
        сам.модуль = importlib.import_module('наполнение_карточки')
        сам.временное = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временное.cleanup)
        сам.корень = Path(сам.временное.name).resolve() / 'repo'
        сам.корень.mkdir()
        сам.git('init', '-q', '-b', 'codex/napolnitj')
        (сам.корень / 'вход.txt').write_text('Открытый исходник с ё\n')
        for имя in ['Инструменты/реестр-системных-приложений-и-инструментов.md',
                    'Инструменты/fum-moskovskoye-vremya-rabochej-sessii/SKILL.md']:
            путь = сам.корень / имя
            путь.parent.mkdir(parents=True, exist_ok=True)
            путь.write_text('# Открытая фикстура цели ссылки\n')
        сам.git('add', '--', 'вход.txt', 'Инструменты')
        сам.git('-c', 'core.hooksPath=/dev/null', '-c', 'user.name=Проверяющий',
                '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'Исходное состояние фикстуры')
        сам.задача = '00000000-0000-0000-0000-000000000001'
        сам.метка = '2026-09-28_21-31-03_MSK_автоматизировать-наполнение-карточек'
        сам.каталог = сам.корень / 'Журнал' / сам.метка
        сам.каталог.mkdir(parents=True)
        сам.запрос = сам.каталог / 'запрос.md'
        сам.отчёт = сам.каталог / 'отчёт.md'
        сам.сырой = '## Повлиял на файлы\n<!-- FUM-КАРТОЧКА:НАЧАЛО состав -->\nНе менять ё\n'
        шаблон_запроса, шаблон_отчёта = request_folder_layout._прочитать_шаблоны()
        сам.запрос.write_bytes(request_folder_layout._request_document(
            сам.метка, 'Автоматизировать наполнение карточек', None, None,
            [сам.сырой], сам.задача, {}, шаблон_запроса).encode())
        сам.отчёт.write_bytes(request_folder_layout._report_document(
            'Автоматизировать наполнение карточек', сам.метка, шаблон_отчёта).encode())
        сам.разрешение = сам.корень.parent / 'разрешение.json'
        сам.цели = [сам.запрос.relative_to(сам.корень).as_posix(),
                    сам.отчёт.relative_to(сам.корень).as_posix(), 'вход.txt']
        сам.вход = {'схема': 'fum.наполнение-карточки.1', 'задача': сам.задача,
                   'запрос': сам.цели[0], 'разрешение': {}, 'ожидаемые_цели': [],
                   'инструменты': [{'имя': 'Python', 'слой': 'CLI', 'версия': None,
                                    'основание': 'Версия не наблюдалась в фикстуре'}],
                   'профиль': {'граница': 'Только конечная фикстура; ожидание не измерялось.',
                               'стадии': [{'имя': 'Рендер', 'длительность_нс': None, 'основание': 'Не измерено'},
                                          {'имя': 'Проверка', 'длительность_нс': 1500000,
                                           'основание': 'Значение открытой фикстуры, не замер продукта'}]},
                   'поля': {'итог': 'Создаётся проверяемый наполнитель.',
                            'проверки': 'Проверки фикстуры ещё не запускались.',
                            'решения_и_ограничения': 'Только собственная новая открытая карточка.'},
                   'вставки': [сам.событие(1)]}
        сам.задать_цели(сам.цели)

    def git(сам, *аргументы):
        return subprocess.check_output(['git', '-C', str(сам.корень), *аргументы],
                                       stderr=subprocess.PIPE, env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'})

    def событие(сам, номер):
        return {'идентификатор': hashlib.sha256(str(номер).encode()).hexdigest(),
                'источник': {'задача': сам.задача, 'начало': номер * 100, 'конец': номер * 100 + 90,
                             'sha256': hashlib.sha256(('событие' + str(номер)).encode()).hexdigest()},
                'роль': 'ассистент', 'текст': 'Содержательный ответ с ё'}

    def задать_цели(сам, цели):
        сам.разрешение.write_bytes(json.dumps(цели, ensure_ascii=False).encode())
        сам.вход['разрешение'] = {'путь': str(сам.разрешение),
                                  'sha256': hashlib.sha256(сам.разрешение.read_bytes()).hexdigest()}

    def снимок(сам):
        return (сам.запрос.read_bytes(), сам.отчёт.read_bytes(),
                сам.запрос.stat().st_mode, сам.отчёт.stat().st_mode,
                сам.git('rev-parse', 'HEAD'), сам.git('ls-files', '--stage', '-z'))

    def test_полный_рендер_сохраняет_дословный_ввод_и_чужой_блок_проверок(сам):
        до = сам.снимок()
        начало = до[1].index(b'<!-- FUM-CHECK-RUNS:BEGIN')
        конец = до[1].index(b'<!-- FUM-CHECK-RUNS:END -->') + len(b'<!-- FUM-CHECK-RUNS:END -->')
        блок_проверок = до[1][начало:конец]
        план = сам.модуль.подготовить(сам.корень, сам.вход)
        сам.assertEqual(сам.модуль.применить(сам.корень, сам.вход, план)['изменено'], 2)
        сам.assertIn(сам.сырой.encode(), сам.запрос.read_bytes())
        сам.assertIn(блок_проверок, сам.отчёт.read_bytes())
        сам.assertIn('Версия не наблюдалась'.encode(), сам.запрос.read_bytes())
        сам.assertIn('не измерено'.encode(), сам.отчёт.read_bytes())
        сам.assertEqual(сам.снимок()[4:], до[4:])

    def test_повтор_плана_не_пишет_файлы_и_не_повторяет_событие(сам):
        план = сам.модуль.подготовить(сам.корень, сам.вход)
        сам.модуль.применить(сам.корень, сам.вход, план)
        до = [(путь.stat().st_ino, путь.stat().st_mtime_ns, путь.read_bytes()) for путь in (сам.запрос, сам.отчёт)]
        сам.assertEqual(сам.модуль.применить(сам.корень, сам.вход, план)['изменено'], 0)
        сам.assertEqual(до, [(путь.stat().st_ino, путь.stat().st_mtime_ns, путь.read_bytes()) for путь in (сам.запрос, сам.отчёт)])
        сам.assertEqual(сам.модуль.подготовить(сам.корень, сам.вход)['файлы'], [])

    def test_новый_план_целиком_обновляет_блок_и_добавляет_вторую_запись(сам):
        сам.модуль.применить(сам.корень, сам.вход, сам.модуль.подготовить(сам.корень, сам.вход))
        сам.вход['инструменты'][0]['версия'] = '3.14.7 (значение фикстуры)'
        сам.вход['вставки'].append(сам.событие(2))
        сам.модуль.применить(сам.корень, сам.вход, сам.модуль.подготовить(сам.корень, сам.вход))
        сам.assertIn(b'3.14.7', сам.запрос.read_bytes())
        блоки = importlib.import_module('управляемые_блоки')
        сам.assertEqual(блоки.прочитать_журнал(сам.отчёт.read_bytes()), сам.вход['вставки'])

    def test_изменение_карточки_после_плана_отказывает_без_дополнительной_записи(сам):
        план = сам.модуль.подготовить(сам.корень, сам.вход)
        сам.отчёт.write_bytes(сам.отчёт.read_bytes() + 'Позднее уточнение\n'.encode())
        до = сам.снимок()
        with сам.assertRaises(ValueError):
            сам.модуль.применить(сам.корень, сам.вход, план)
        сам.assertEqual(сам.снимок(), до)

    def test_изменение_входа_разрешения_и_индекса_не_обходит_свежесть(сам):
        план = сам.модуль.подготовить(сам.корень, сам.вход)
        другое = copy.deepcopy(сам.вход)
        другое['поля']['итог'] = 'Другой результат'
        with сам.assertRaises(ValueError):
            сам.модуль.применить(сам.корень, другое, план)
        сам.разрешение.write_bytes(сам.разрешение.read_bytes() + b'\n')
        with сам.assertRaises(ValueError):
            сам.модуль.применить(сам.корень, сам.вход, план)
        сам.задать_цели(сам.цели)
        сам.git('add', '--', сам.цели[0])
        до = сам.снимок()
        with сам.assertRaises(ValueError):
            сам.модуль.применить(сам.корень, сам.вход, план)
        сам.assertEqual(сам.снимок(), до)

    def test_путь_из_статуса_не_становится_разрешением(сам):
        (сам.корень / 'постороннее.txt').write_text('Не включать автоматически\n')
        with сам.assertRaises(ValueError):
            сам.модуль.подготовить(сам.корень, сам.вход)
        сам.assertNotIn('постороннее'.encode(), сам.запрос.read_bytes())

    def test_каталоги_ссылки_выход_и_неоднозначные_имена_отклоняются(сам):
        (сам.корень / 'ссылка.txt').symlink_to('вход.txt')
        for цель in ['Журнал', '../внешнее.txt', 'ссылка.txt', 'ВХОД.txt', 'неоднозначное#имя.txt', 'неоднозначное?имя.txt']:
            сам.задать_цели(сам.цели + [цель])
            with сам.subTest(цель=цель), сам.assertRaises(ValueError):
                сам.модуль.подготовить(сам.корень, сам.вход)

    def test_переименование_требует_обеих_точных_целей(сам):
        сам.git('mv', '--', 'вход.txt', 'переименованный.txt')
        сам.задать_цели(сам.цели[:2] + ['переименованный.txt'])
        with сам.assertRaises(ValueError):
            сам.модуль.подготовить(сам.корень, сам.вход)
        сам.задать_цели(сам.цели + ['переименованный.txt'])
        план = сам.модуль.подготовить(сам.корень, сам.вход)
        сам.assertEqual(len(план['файлы']), 2)
        сам.модуль.применить(сам.корень, сам.вход, план)
        связность = сам.модуль._загрузить('охват').СВЯЗНОСТЬ
        сам.assertEqual(связность.validate_markdown_links({сам.запрос}, сам.корень), [])

    def test_будущий_результат_объявляется_точно_без_фиктивного_файла(сам):
        цель = (сам.каталог.relative_to(сам.корень) / 'материалы/запуски-проверок/1_00000000-0000-0000-0000-000000000002.json').as_posix()
        сам.вход['ожидаемые_цели'] = [цель]
        сам.задать_цели(сам.цели + [цель])
        сам.модуль.применить(сам.корень, сам.вход, сам.модуль.подготовить(сам.корень, сам.вход))
        сам.assertFalse((сам.корень / цель).exists())
        сам.assertIn('ожидаемый файл'.encode(), сам.запрос.read_bytes())
        сам.вход['ожидаемые_цели'] = ['вход.txt']
        with сам.assertRaises(ValueError):
            сам.модуль.подготовить(сам.корень, сам.вход)

    def test_сбой_второй_установки_откатывает_пару_и_курсор(сам):
        сам.запрос.chmod(0o640); сам.отчёт.chmod(0o600)
        до = сам.снимок()
        план = сам.модуль.подготовить(сам.корень, сам.вход)
        настоящий = request_folder_layout._install_prepared_file
        вызовы = []
        def установить(корень, файл):
            вызовы.append(файл.path)
            if len(вызовы) == 2:
                raise OSError('Проверяемый сбой второй установки')
            return настоящий(корень, файл)
        with mock.patch.object(request_folder_layout, '_install_prepared_file', side_effect=установить):
            with сам.assertRaises(ValueError):
                сам.модуль.применить(сам.корень, сам.вход, план)
        сам.assertEqual(сам.снимок(), до)

    def test_закоммиченная_или_закрытая_карточка_не_открывается(сам):
        сам.git('add', '--', сам.цели[0], сам.цели[1])
        сам.git('-c', 'core.hooksPath=/dev/null', '-c', 'user.name=Проверяющий',
                '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'Закрытая граница фикстуры')
        with сам.assertRaises(ValueError):
            сам.модуль.подготовить(сам.корень, сам.вход)
        сам.git('reset', '-q', 'HEAD~1')
        сам.отчёт.write_bytes(сам.отчёт.read_bytes().replace('состояние=открыт'.encode(), 'состояние=закрыт'.encode()))
        with сам.assertRaises(ValueError):
            сам.модуль.подготовить(сам.корень, сам.вход)

    def test_интерфейс_связывает_план_и_исходные_байты_входного_файла(сам):
        вход = сам.корень.parent / 'вход.json'
        вход.write_bytes(json.dumps(сам.вход, ensure_ascii=False).encode())
        план = сам.корень.parent / 'план.json'
        вывод = io.StringIO()
        with contextlib.redirect_stdout(вывод):
            код = request_folder_layout.main(['наполнение-план', '--repo-root', str(сам.корень),
                                             '--вход', str(вход), '--план', str(план)])
        сам.assertEqual(код, 0)
        описание = json.loads(вывод.getvalue())
        сам.assertEqual(описание['план_sha256'], hashlib.sha256(план.read_bytes()).hexdigest())
        аргументы = ['наполнение-применить', '--repo-root', str(сам.корень), '--вход', str(вход),
                     '--план', str(план), '--sha256', описание['план_sha256']]
        with contextlib.redirect_stdout(io.StringIO()):
            сам.assertEqual(request_folder_layout.main(аргументы), 0)
        до = сам.снимок()
        вход.write_bytes(вход.read_bytes() + b'\n')
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            сам.assertEqual(request_folder_layout.main(аргументы), 1)
        сам.assertEqual(сам.снимок(), до)

    def test_границы_аудита_журнал_внутри_заменяемого_тела_не_удаляется(сам):
        блоки = importlib.import_module('управляемые_блоки')
        журнал = блоки.дополнить_журнал(блоки.пустой_курсор(), [сам.событие(2)])
        сам.отчёт.write_bytes(сам.отчёт.read_bytes().replace('## Решения и ограничения\n'.encode(),
                                  '## Решения и ограничения\n'.encode() + журнал))
        сам.вход['вставки'] = []
        до = сам.снимок()
        with сам.assertRaises(ValueError):
            сам.модуль.подготовить(сам.корень, сам.вход)
        сам.assertEqual(сам.снимок(), до)

    def test_границы_аудита_подставной_uuid_в_другом_разделе_не_даёт_владения(сам):
        строка = ('Codex-Thread-ID: ' + сам.задача + '\n').encode()
        сам.запрос.write_bytes(сам.запрос.read_bytes().replace(строка,
                               b'Codex-Thread-ID: 00000000-0000-0000-0000-000000000099\n')
                              .replace('## Использованные инструменты\n'.encode(),
                                       '## Использованные инструменты\n'.encode() + строка))
        with сам.assertRaises(ValueError):
            сам.модуль.подготовить(сам.корень, сам.вход)

    def test_границы_аудита_изменение_сразу_после_свежей_подготовки_не_затирается(сам):
        план = сам.модуль.подготовить(сам.корень, сам.вход)
        настоящий = сам.модуль.подготовить
        def подготовить(корень, вход, **параметры):
            свежий = настоящий(корень, вход, **параметры)
            сам.запрос.write_bytes(сам.запрос.read_bytes() + 'Позднее изменение с ё\n'.encode())
            return свежий
        отчёт_до = сам.отчёт.read_bytes()
        with mock.patch.object(сам.модуль, 'подготовить', side_effect=подготовить):
            with сам.assertRaises(ValueError):
                сам.модуль.применить(сам.корень, сам.вход, план)
        сам.assertTrue(сам.запрос.read_bytes().endswith('Позднее изменение с ё\n'.encode()))
        сам.assertEqual(сам.отчёт.read_bytes(), отчёт_до)

    def test_границы_аудита_неверная_установка_откатывается_при_чтении(сам):
        план = сам.модуль.подготовить(сам.корень, сам.вход)
        до = сам.снимок()
        настоящий = request_folder_layout._install_prepared_file
        def установить(корень, файл):
            настоящий(корень, файл)
            if файл.path.name == 'отчёт.md':
                (корень / файл.path).write_bytes(b'corrupted\n')
        with mock.patch.object(request_folder_layout, '_install_prepared_file', side_effect=установить):
            with сам.assertRaises(ValueError):
                сам.модуль.применить(сам.корень, сам.вход, план)
        сам.assertEqual(сам.снимок(), до)

    def test_границы_аудита_новый_sha_файла_не_означает_новый_загруженный_код(сам):
        загрузка = importlib.import_module('отпечатки_загрузки')
        путь = сам.корень.parent / 'фикстура.py'
        путь.write_text('def значение():\n    return "старое"\n')
        модуль, отпечаток = загрузка.загрузить_исходник(путь, 'фикстура_загрузочного_отпечатка')
        сам.addCleanup(sys.modules.pop, 'фикстура_загрузочного_отпечатка', None)
        путь.write_text('def значение():\n    return "новое"\n')
        сам.assertEqual(модуль.значение(), 'старое')
        with сам.assertRaises(ValueError):
            загрузка.сверить_загрузку(путь.parent, {путь.name: отпечаток})

    def test_отказ_предусловия_транзакции_не_восстанавливает_поздние_байты(сам):
        отчёт_до = сам.отчёт.read_bytes()
        поздний = сам.запрос.read_bytes() + 'Позднее изменение после снимка\n'.encode()
        файл = request_folder_layout.PreparedFile(сам.запрос.relative_to(сам.корень), 'Не устанавливать\n'.encode(), 0o644)
        def проверить():
            сам.запрос.write_bytes(поздний)
            raise ValueError('Предусловие не выполнено')
        with mock.patch.object(request_folder_layout, '_install_prepared_file') as установка, \
                mock.patch.object(request_folder_layout, '_restore_path') as восстановление:
            with сам.assertRaises(ValueError):
                request_folder_layout._apply_prepared_transaction(сам.корень, [файл], проверить_исходники=проверить)
            установка.assert_not_called()
            восстановление.assert_not_called()
        сам.assertEqual(сам.запрос.read_bytes(), поздний)
        сам.assertEqual(сам.отчёт.read_bytes(), отчёт_до)

    def test_настоящий_cli_в_новых_процессах_проверяет_повтор_и_подмену(сам):
        вход = сам.корень.parent / 'вход-cli.json'
        вход.write_bytes(json.dumps(сам.вход, ensure_ascii=False).encode())
        план = сам.корень.parent / 'план-cli.json'
        cli = Path(__file__).resolve().parents[1] / 'scripts/struktura-papok-zaprosov.py'
        def вызвать(режим, *хвост):
            return subprocess.run([sys.executable, '-B', str(cli), режим, '--repo-root', str(сам.корень),
                                   '--вход', str(вход), '--план', str(план), *хвост], capture_output=True)
        до = сам.снимок()
        ответ = вызвать('наполнение-план')
        сам.assertEqual(ответ.returncode, 0, ответ.stderr.decode())
        сам.assertEqual(сам.снимок(), до)
        sha256 = json.loads(ответ.stdout)['план_sha256']
        сам.assertEqual(план.stat().st_mode & 0o777, 0o400)
        ответ = вызвать('наполнение-применить', '--sha256', sha256)
        сам.assertEqual(ответ.returncode, 0, ответ.stderr.decode())
        сам.assertEqual(json.loads(ответ.stdout)['изменено'], 2)
        после = сам.снимок()
        режимы = [(п.stat().st_ino, п.stat().st_mtime_ns) for п in (сам.запрос, сам.отчёт)]
        ответ = вызвать('наполнение-применить', '--sha256', sha256)
        сам.assertEqual(ответ.returncode, 0, ответ.stderr.decode())
        сам.assertEqual(json.loads(ответ.stdout)['изменено'], 0)
        сам.assertEqual(режимы, [(п.stat().st_ino, п.stat().st_mtime_ns) for п in (сам.запрос, сам.отчёт)])
        сам.assertEqual(вызвать('наполнение-применить', '--sha256', '0' * 64).returncode, 1)
        вход.write_bytes(вход.read_bytes() + b'\n')
        сам.assertEqual(вызвать('наполнение-применить', '--sha256', sha256).returncode, 1)
        план.chmod(0o600)
        план.write_bytes(план.read_bytes() + b'\n')
        сам.assertEqual(вызвать('наполнение-применить', '--sha256', sha256).returncode, 1)
        сам.assertEqual(сам.снимок(), после)

    def объявить_будущую_проверку(сам):
        идентификатор = '00000000-0000-0000-0000-000000000002'
        цель = (сам.каталог.relative_to(сам.корень) / ('материалы/запуски-проверок/1_' + идентификатор + '.json')).as_posix()
        сам.вход['ожидаемые_цели'] = [цель]
        сам.задать_цели(сам.цели + [цель])
        сам.модуль.применить(сам.корень, сам.вход, сам.модуль.подготовить(сам.корень, сам.вход))
        сам.assertFalse((сам.корень / цель).exists())
        связность = сам.модуль._загрузить('охват').СВЯЗНОСТЬ
        сам.assertTrue(связность.validate_markdown_links({сам.запрос}, сам.корень))
        return идентификатор, цель, связность

    def test_настоящая_обёртка_создаёт_точную_цель_до_проверки_ссылок(сам):
        идентификатор, цель, связность = сам.объявить_будущую_проверку()
        путь_связности = Path(связность.__file__)
        код = (
            'import json,importlib.util,sys; from pathlib import Path; '
            'корень,цель,запрос,uuid,модуль=map(str,sys.argv[1:]); '
            'запись=json.loads((Path(корень)/цель).read_bytes()); '
            'assert запись["схема"]=="fum.test-run.v4" and запись["сессия"]==запрос; '
            'assert запись["порядок"]==1 and запись["идентификатор"]==uuid and запись["состояние"]=="выполняется"; '
            'описание=importlib.util.spec_from_file_location("проверка_ссылки_в_дочерней_команде",модуль); '
            'связность=importlib.util.module_from_spec(описание); sys.modules[описание.name]=связность; '
            'описание.loader.exec_module(связность); '
            'assert связность.validate_markdown_links({Path(корень)/запрос},Path(корень))==[]'
        )
        отчёты = сам.модуль._загрузить('отчёты')
        код_запуска = отчёты.выполнить_запуск(сам.корень, сам.запрос, 'Проверить существующую активную запись',
            сам.задача, идентификатор, 20, [sys.executable, '-B', '-c', код, str(сам.корень), цель,
             сам.цели[0], идентификатор, str(путь_связности)], класс_проверки='адресная', приёмочные_раунды=True)
        сам.assertEqual(код_запуска, 0)
        сам.assertEqual(связность.validate_markdown_links({сам.запрос}, сам.корень), [])
        записи = отчёты.прочитать_историю_проверок(сам.каталог / 'материалы/запуски-проверок', сам.цели[0])
        сам.assertEqual(записи[0][1]['статус'], 'успешно')
        сам.assertEqual(записи[0][1]['состояние'], 'завершён')

    def test_иной_uuid_настоящего_запуска_не_разрешает_объявленную_ссылку(сам):
        _, цель, связность = сам.объявить_будущую_проверку()
        код = сам.модуль._загрузить('отчёты').выполнить_запуск(сам.корень, сам.запрос,
            'Запуск с другим UUID', сам.задача, '00000000-0000-0000-0000-000000000003',
            20, [sys.executable, '-B', '-c', 'pass'], класс_проверки='адресная', приёмочные_раунды=True)
        сам.assertEqual(код, 0)
        сам.assertFalse((сам.корень / цель).exists())
        сам.assertTrue(связность.validate_markdown_links({сам.запрос}, сам.корень))
        with сам.assertRaises(ValueError):
            сам.модуль.подготовить(сам.корень, сам.вход)

    def test_наличие_ссылки_не_превращает_отказ_проверки_в_успех(сам):
        идентификатор, цель, связность = сам.объявить_будущую_проверку()
        отчёты = сам.модуль._загрузить('отчёты')
        код = отчёты.выполнить_запуск(сам.корень, сам.запрос, 'Ненулевой исход проверки',
            сам.задача, идентификатор, 20, [sys.executable, '-B', '-c', 'raise SystemExit(7)'],
            класс_проверки='адресная', приёмочные_раунды=True)
        сам.assertEqual(код, 7)
        сам.assertTrue((сам.корень / цель).exists())
        сам.assertEqual(связность.validate_markdown_links({сам.запрос}, сам.корень), [])
        записи = отчёты.прочитать_историю_проверок(сам.каталог / 'материалы/запуски-проверок', сам.цели[0])
        сам.assertEqual(записи[0][1]['код_завершения'], 7)
        сам.assertEqual(записи[0][1]['статус'], 'неуспешно')

    def test_предзагруженная_зависимость_без_загрузочного_sha_не_принимает_новые_байты(сам):
        корень = сам.корень.parent / 'копия-исполнителя'
        каталог = корень / 'Инструменты/fum-struktura-papok-zaprosov/scripts'
        каталог.mkdir(parents=True)
        for путь in (Path(__file__).resolve().parents[1] / 'scripts').glob('*.py'):
            shutil.copyfile(путь, каталог / путь.name)
        зависимость = корень / 'Инструменты/fum-proyektnyiye-fajlyi/scripts'
        зависимость.mkdir(parents=True)
        файл = зависимость / 'project_files.py'
        файл.write_text('def значение():\n    return "старое"\n')
        код = (
            'import sys; from pathlib import Path; '
            'sys.path[:0]=sys.argv[1:3]; import project_files; '
            'assert project_files.значение()=="старое"; '
            'Path(project_files.__file__).write_text("def значение():\\n    return \\\"новое\\\"\\n"); '
            '\ntry:\n import наполнение_карточки as н\n н._сверить_код()\n'
            'except ValueError:\n print("ОТКАЗ_СТАРОГО_КОДА")\n'
            'else:\n raise SystemExit("Принят новый SHA при старом коде")\n'
        )
        ответ = subprocess.run([sys.executable, '-B', '-c', код, str(каталог), str(зависимость)], capture_output=True)
        сам.assertEqual(ответ.returncode, 0, ответ.stderr.decode())
        сам.assertIn('ОТКАЗ_СТАРОГО_КОДА'.encode(), ответ.stdout)

    def test_предзагруженный_каркас_из_другого_checkout_не_принимается(сам):
        другой = сам.корень.parent / 'другой-исполнитель'
        другой.mkdir()
        каталог = Path(__file__).resolve().parents[1] / 'scripts'
        shutil.copyfile(каталог / 'request_folder_layout.py', другой / 'request_folder_layout.py')
        код = ('import sys; sys.path.insert(0,sys.argv[1]); import request_folder_layout; '
               'sys.path.insert(0,sys.argv[2]); '
               '\ntry:\n import наполнение_карточки as н\n н._сверить_код()\n'
               'except ValueError:\n print("ОТКАЗ_ЧУЖОГО_КАРКАСА")\n'
               'else:\n raise SystemExit("Принят каркас другого checkout")\n')
        ответ = subprocess.run([sys.executable, '-B', '-c', код, str(другой), str(каталог)], capture_output=True)
        сам.assertEqual(ответ.returncode, 0, ответ.stderr.decode())
        сам.assertIn('ОТКАЗ_ЧУЖОГО_КАРКАСА'.encode(), ответ.stdout)


if __name__ == '__main__':
    unittest.main()
