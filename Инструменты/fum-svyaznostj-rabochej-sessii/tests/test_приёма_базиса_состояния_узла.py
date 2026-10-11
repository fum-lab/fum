"""Адресный базис: действительные Git-объекты, состав и сохранность R."""
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import приём_базиса_состояния_узла as базис


def гит(корень, *аргументы, успешно=True):
    среда = {к: в for к, в in os.environ.items() if not к.startswith('GIT_')}
    среда.update(GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull,
        GIT_CONFIG_SYSTEM=os.devnull, GIT_NO_LAZY_FETCH='1')
    п = subprocess.run(['git', '--no-replace-objects', '--no-optional-locks',
        '-c', 'core.hooksPath=' + os.devnull, '-c', 'core.fsmonitor=false',
        '-C', str(корень), *аргументы], capture_output=True, text=True, env=среда, timeout=30)
    if успешно and п.returncode:
        raise AssertionError(п.stderr)
    return п.stdout.strip() if успешно else п


class ПримерБазиса:
    def __init__(сам, каталог):
        сам.корень = Path(каталог) / 'узел'; сам.корень.mkdir()
        гит(сам.корень, 'init', '-q', '-b', 'codex/основа')
        гит(сам.корень, 'config', 'user.name', 'FUM Test')
        гит(сам.корень, 'config', 'user.email', 'test@example.invalid')
        гит(сам.корень, 'config', 'core.hooksPath', os.devnull)
        гит(сам.корень, 'config', 'core.precomposeUnicode', 'false')
        сам.индекс = 'Индексы/markdown-файлы-по-времени-редактирования.md'
        сам.записать(сам.индекс, b'X\n'); сам.записать('ожидания.json', '{"поколение":0}\n'.encode())
        сам.X = сам.коммит('Общий предок')
        гит(сам.корень, 'switch', '-c', 'fum-lab/узел')
        сам.записать(сам.индекс, b'R\n'); сам.записать('ожидания.json', '{"поколение":1}\n'.encode())
        for имя in ('запрос.md', 'отчёт.md', 'материалы/старый-RAW.json'):
            сам.записать('Журнал/первый/' + имя, ('Сохранённый ' + имя + '\n').encode())
        сам.R = сам.коммит('Первое состояние')
        гит(сам.корень, 'switch', '-c', 'codex/принятый-код', сам.X)
        сам.записать(сам.индекс, b'K\n')
        сам.записать('Инструменты/новый-код.py', b'print("accepted")\n')
        сам.K = сам.коммит('Независимо принятый код')
        п = гит(сам.корень, 'merge', '--no-ff', '--no-commit', сам.R, успешно=False)
        if п.returncode != 1:
            raise AssertionError('Фикстура обязана иметь настоящий конфликт индекса')
        сам.записать(сам.индекс, 'B: объединены строки R и K\n'.encode())
        сам.B = сам.коммит('Базис с двумя родителями')

    def записать(сам, имя, данные):
        п = сам.корень / имя; п.parent.mkdir(parents=True, exist_ok=True); п.write_bytes(данные)

    def коммит(сам, сообщение):
        гит(сам.корень, 'add', '-A'); гит(сам.корень, 'commit', '-qm', сообщение)
        return гит(сам.корень, 'rev-parse', 'HEAD')

    def состав(сам):
        return базис.состав_базиса(сам.корень, сам.R, сам.B, сам.K)


class ПриёмБазиса(unittest.TestCase):
    def setUp(сам):
        к = tempfile.TemporaryDirectory(prefix='fum-basis-'); сам.addCleanup(к.cleanup)
        сам.ф = ПримерБазиса(к.name)

    def test_полный_входящий_состав_и_оба_родителя(сам):
        ф = сам.ф; до = гит(ф.корень, 'status', '--porcelain=v1'); с = ф.состав()
        сам.assertEqual(с['схема'], 'fum.состав-базиса-узла.1')
        сам.assertEqual(с['родители'], [ф.K, ф.R]); сам.assertEqual(с['общий_предок'], ф.X)
        сам.assertEqual({э['путь'] for э in с['входящий_состав']},
            {ф.индекс, 'Инструменты/новый-код.py'})
        сам.assertEqual(до, гит(ф.корень, 'status', '--porcelain=v1'))
        сам.assertEqual(с, ф.состав())
        сам.assertNotIn('разрешение_записи', с)

    def test_индекс_R_K_B_не_объявляется_одними_байтами(сам):
        ф = сам.ф; с = ф.состав(); сам.assertEqual(len(с['пересечения']), 1)
        э = с['пересечения'][0]; сам.assertEqual(э['путь'], ф.индекс)
        сам.assertEqual(len({э[к]['blob'] for к in ('X', 'R', 'K', 'B')}), 4)
        сам.assertEqual(э['R']['sha256'], hashlib.sha256(b'R\n').hexdigest())
        сам.assertEqual(э['B']['sha256'], hashlib.sha256('B: объединены строки R и K\n'.encode()).hexdigest())

    def test_сохраняются_expected_пара_и_RAW_из_R(сам):
        ф = сам.ф; с = ф.состав(); по_пути = {э['путь']: э for э in с['сохранённые']}
        сам.assertEqual(set(по_пути), {'ожидания.json', 'Журнал/первый/запрос.md',
            'Журнал/первый/отчёт.md', 'Журнал/первый/материалы/старый-RAW.json'})
        for э in по_пути.values():
            сам.assertEqual(э['R'], э['B'])
        сам.assertEqual(по_пути['ожидания.json']['B']['режим'], '100644')

    def test_линейный_потомок_не_заменяет_адресный_B(сам):
        ф = сам.ф; ф.записать('лишнее.txt', b'late\n'); поздний = ф.коммит('Поздний')
        with сам.assertRaisesRegex(ValueError, 'родител'):
            базис.состав_базиса(ф.корень, ф.R, поздний, ф.K)

    def test_обратный_порядок_родителей_отклоняется(сам):
        ф = сам.ф; tree = гит(ф.корень, 'rev-parse', ф.B + '^{tree}')
        другой = гит(ф.корень, 'commit-tree', tree, '-p', ф.R, '-p', ф.K, '-m', 'Другой порядок')
        with сам.assertRaisesRegex(ValueError, 'родител'):
            базис.состав_базиса(ф.корень, ф.R, другой, ф.K)

    def test_потеря_старого_RAW_в_дереве_B_отклоняется(сам):
        ф = сам.ф; гит(ф.корень, 'rm', 'Журнал/первый/материалы/старый-RAW.json')
        tree = гит(ф.корень, 'write-tree')
        другой = гит(ф.корень, 'commit-tree', tree, '-p', ф.K, '-p', ф.R, '-m', 'Потеря RAW')
        with сам.assertRaisesRegex(ValueError, 'сохран'):
            базис.состав_базиса(ф.корень, ф.R, другой, ф.K)

    def test_подмена_режима_expected_отклоняется(сам):
        ф = сам.ф; гит(ф.корень, 'update-index', '--chmod=+x', 'ожидания.json')
        tree = гит(ф.корень, 'write-tree')
        другой = гит(ф.корень, 'commit-tree', tree, '-p', ф.K, '-p', ф.R, '-m', 'Другой режим')
        with сам.assertRaisesRegex(ValueError, 'сохран'):
            базис.состав_базиса(ф.корень, ф.R, другой, ф.K)

    def test_входящая_symlink_не_является_обычным_файлом(сам):
        ф = сам.ф; п = ф.корень/'Инструменты/новый-код.py'; п.unlink(); п.symlink_to(ф.корень.parent / 'чужой')
        гит(ф.корень, 'add', '-A'); tree = гит(ф.корень, 'write-tree')
        другой = гит(ф.корень, 'commit-tree', tree, '-p', ф.K, '-p', ф.R, '-m', 'Ссылка')
        with сам.assertRaisesRegex(ValueError, 'режим'):
            базис.состав_базиса(ф.корень, ф.R, другой, ф.K)

    def test_symlink_принесённая_K_также_отклоняется(сам):
        ф = сам.ф
        гит(ф.корень, 'read-tree', ф.K)
        blob = гит(ф.корень, 'rev-parse', ф.K + ':Инструменты/новый-код.py')
        гит(ф.корень, 'update-index', '--cacheinfo', '120000', blob, 'Инструменты/новый-код.py')
        tree = гит(ф.корень, 'write-tree')
        K = гит(ф.корень, 'commit-tree', tree, '-p', ф.X, '-m', 'K со ссылкой')
        гит(ф.корень, 'read-tree', ф.B)
        гит(ф.корень, 'update-index', '--cacheinfo', '120000', blob, 'Инструменты/новый-код.py')
        tree = гит(ф.корень, 'write-tree')
        B = гит(ф.корень, 'commit-tree', tree, '-p', K, '-p', ф.R, '-m', 'B со ссылкой K')
        with сам.assertRaisesRegex(ValueError, 'режим'):
            базис.состав_базиса(ф.корень, ф.R, B, K)

    def test_коллизии_компонентов_и_Unicode_в_объектах_Git(сам):
        ф = сам.ф; blob = гит(ф.корень, 'rev-parse', ф.K + ':Инструменты/новый-код.py')
        for имена in [('Вклад/первый.txt', 'вклад/второй.txt'), ('ёлка.txt', 'е\u0308лка.txt')]:
            with сам.subTest(имена=имена):
                гит(ф.корень, 'read-tree', ф.K)
                for имя in имена:
                    гит(ф.корень, 'update-index', '--add', '--cacheinfo', '100644', blob, имя)
                K = гит(ф.корень, 'commit-tree', гит(ф.корень, 'write-tree'), '-p', ф.X, '-m', 'K с коллизией')
                гит(ф.корень, 'read-tree', ф.B)
                for имя in имена:
                    гит(ф.корень, 'update-index', '--add', '--cacheinfo', '100644', blob, имя)
                B = гит(ф.корень, 'commit-tree', гит(ф.корень, 'write-tree'), '-p', K, '-p', ф.R, '-m', 'B с коллизией')
                with сам.assertRaisesRegex(ValueError, 'коллиз|Unicode'):
                    базис.состав_базиса(ф.корень, ф.R, B, K)

    def test_replace_ref_не_подменяет_родителей_и_состав(сам):
        ф = сам.ф; с = ф.состав(); гит(ф.корень, 'replace', ф.B, ф.R)
        сам.assertEqual(с, ф.состав())

    def test_сокращённый_OID_и_выражение_вместо_OID_отклоняются(сам):
        ф = сам.ф
        for B in (ф.B[:10], 'HEAD', ф.B + '^{commit}'):
            with сам.subTest(B=B), сам.assertRaises(ValueError):
                базис.состав_базиса(ф.корень, ф.R, B, ф.K)

    def test_независимая_приёмка_требует_полного_точного_состава(сам):
        с = сам.ф.состав()
        принят = {'состав': copy.deepcopy(с), 'решения': [{'путь': сам.ф.индекс,
            'описание': 'Пересобраны обе принятые хронологии; ни один исходный индекс не выбран целиком.'}]}
        сам.assertEqual(базис.сверить_состав(с, принят), с)
        for поле in ('входящий_состав', 'пересечения', 'сохранённые'):
            другой = copy.deepcopy(принят); другой['состав'][поле].pop()
            with сам.subTest(поле=поле), сам.assertRaises(ValueError):
                базис.сверить_состав(с, другой)
        другой = copy.deepcopy(принят); другой['полномочие'] = True
        with сам.assertRaises(ValueError): базис.сверить_состав(с, другой)

    def test_пересечение_требует_явного_решения_ROOT(сам):
        с = сам.ф.состав()
        for решения in ([], [{'путь': сам.ф.индекс, 'описание': ''}],
                [{'путь': 'чужой.md', 'описание': 'Выбор'}]):
            with сам.subTest(решения=решения), сам.assertRaises(ValueError):
                базис.сверить_состав(с, {'состав': с, 'решения': решения})

    def test_выбор_R_не_скрывает_отвергнутый_вклад_K(сам):
        ф = сам.ф; ф.записать(ф.индекс, b'R\n'); гит(ф.корень, 'add', '-A')
        tree = гит(ф.корень, 'write-tree')
        другой = гит(ф.корень, 'commit-tree', tree, '-p', ф.K, '-p', ф.R, '-m', 'Выбран R')
        с = базис.состав_базиса(ф.корень, ф.R, другой, ф.K)
        сам.assertNotIn(ф.индекс, {э['путь'] for э in с['входящий_состав']})
        э = с['пересечения'][0]; сам.assertEqual(э['R'], э['B']); сам.assertNotEqual(э['K'], э['B'])
        with сам.assertRaises(ValueError): базис.сверить_состав(с, {'состав': с, 'решения': []})

    def test_непересекающийся_вклад_K_нельзя_потерять(сам):
        ф = сам.ф; гит(ф.корень, 'rm', 'Инструменты/новый-код.py')
        tree = гит(ф.корень, 'write-tree')
        другой = гит(ф.корень, 'commit-tree', tree, '-p', ф.K, '-p', ф.R, '-m', 'Потеря K')
        with сам.assertRaisesRegex(ValueError, 'сохран'):
            базис.состав_базиса(ф.корень, ф.R, другой, ф.K)

    def test_дополнительные_байты_B_вне_обоих_вкладов_отклоняются(сам):
        ф = сам.ф; ф.записать('непринято.txt', 'Вне обоих вкладов\n'.encode())
        гит(ф.корень, 'add', '-A'); tree = гит(ф.корень, 'write-tree')
        другой = гит(ф.корень, 'commit-tree', tree, '-p', ф.K, '-p', ф.R, '-m', 'Лишнее B')
        with сам.assertRaisesRegex(ValueError, 'сохран'):
            базис.состав_базиса(ф.корень, ф.R, другой, ф.K)

    def test_состав_не_читает_грязные_рабочие_байты(сам):
        ф = сам.ф; до = ф.состав()
        ф.записать('ожидания.json', 'Поздняя рабочая подмена\n'.encode())
        ф.записать('Журнал/первый/материалы/старый-RAW.json', 'Поздний RAW\n'.encode())
        сам.assertEqual(ф.состав(), до)

    def test_служебный_Git_и_одиночное_NFD_имя_не_каноничны(сам):
        for имя in ('.GIT/данные.txt', 'а/.Git/данные.txt', 'е\u0308лка.txt'):
            with сам.subTest(имя=имя), сам.assertRaises(ValueError):
                базис.точное_имя(имя)

    def test_защищённые_байты_из_R_сверяются_независимо(сам):
        ф = сам.ф; с = ф.состав()
        защищённые = [{'путь': э['путь'], **э['R']} for э in с['сохранённые']]
        сам.assertEqual(базис.сверить_защищённые(ф.корень, ф.R, ф.B, защищённые), защищённые)
        for изменение in ('SHA', 'поля', 'повтор', 'пусто'):
            другой = copy.deepcopy(защищённые)
            if изменение == 'SHA': другой[0]['sha256'] = '0'*64
            if изменение == 'поля': другой[0]['подмена'] = True
            if изменение == 'повтор': другой.append(copy.deepcopy(другой[0]))
            if изменение == 'пусто': другой.clear()
            with сам.subTest(изменение=изменение), сам.assertRaises(ValueError):
                базис.сверить_защищённые(ф.корень, ф.R, ф.B, другой)

    def test_expected_защищён_даже_при_пересечении(сам):
        ф = сам.ф; с = ф.состав()
        защищённый = next(э for э in с['сохранённые'] if э['путь'] == 'ожидания.json')
        селектор = {'путь': защищённый['путь'], **защищённый['R']}
        гит(ф.корень, 'read-tree', ф.K)
        ф.записать('ожидания.json', '{"поколение":99}\n'.encode())
        гит(ф.корень, 'add', 'ожидания.json')
        K = гит(ф.корень, 'commit-tree', гит(ф.корень, 'write-tree'), '-p', ф.X, '-m', 'K меняет expected')
        blob = гит(ф.корень, 'rev-parse', K + ':ожидания.json')
        гит(ф.корень, 'read-tree', ф.B)
        гит(ф.корень, 'update-index', '--cacheinfo', '100644', blob, 'ожидания.json')
        B = гит(ф.корень, 'commit-tree', гит(ф.корень, 'write-tree'), '-p', K, '-p', ф.R, '-m', 'B выбирает K expected')
        состав = базис.состав_базиса(ф.корень, ф.R, B, K)
        сам.assertIn('ожидания.json', {э['путь'] for э in состав['пересечения']})
        with сам.assertRaisesRegex(ValueError, 'защищ'):
            базис.сверить_защищённые(ф.корень, ф.R, B, [селектор])

    def test_неполная_история_grafts_и_promisor_отклоняются(сам):
        ф = сам.ф; gitdir = ф.корень/'.git'
        grafts = gitdir/'info/grafts'; grafts.write_text(ф.R + '\n')
        with сам.assertRaises(ValueError): ф.состав()
        grafts.unlink()
        shallow = gitdir/'shallow'; shallow.write_text(ф.R + '\n')
        with сам.assertRaises(ValueError): ф.состав()
        shallow.unlink()
        гит(ф.корень, 'config', 'remote.fixture.promisor', 'true')
        with сам.assertRaises(ValueError): ф.состав()


if __name__ == '__main__':
    unittest.main()
