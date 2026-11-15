"""Чистый контракт имени без догадок о неизвестной модели."""
from pathlib import Path
import sys
import unittest
import ast
import json
import hashlib
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from автор_коммита import составить_имя, проверить_формат, проверить_назначение_автора


class ИмяАвтора(unittest.TestCase):
    def test_reader_act_5_изолированно(сам):
        """Тело reader реально; внешнее чтение и проверка источников заменены заглушками."""
        файл = Path(__file__).resolve().parents[1] / 'scripts/обычное_поручение.py'
        дерево = ast.parse(файл.read_text())
        функции = [узел for узел in дерево.body if isinstance(узел, ast.FunctionDef)
                   and узел.name in {'прочитать_акт', 'сверить_авторство_акта', 'сверить_выбор_в_нативном_тексте'}]
        модуль = ast.fix_missing_locations(ast.Module(body=функции, type_ignores=[]))
        def поля(данные, ожидаемые):
            if type(данные) is not dict or set(данные) != ожидаемые:
                raise ValueError('поля')
        def требовать(условие, сообщение):
            if not условие:
                raise ValueError(сообщение)
        a, b = 'a' * 40, 'b' * 64
        выбор = {'координатор': 'root', 'исполнитель': 'child', 'коммит': a, 'путь': 'act', 'sha256': b}
        акт = {'схема': 'fum.поручение-дочерней-контрольной-точки.5', 'координатор': 'root',
               'исполнитель': 'child', 'ветка': 'refs/heads/codex/test', 'область': ['x'],
               'постановка': {'коммит': a, 'путь': 'task', 'sha256': b},
               'авторство': {'роль': 'Ustranitelj problem komand', 'основа': a, 'операция': 'контрольная-точка'}}
        закреплённые = json.dumps(акт).encode()
        pin = hashlib.sha256(закреплённые).hexdigest()
        выбор['sha256'] = pin
        def источник(_корень, селектор):
            if селектор['путь'] == 'act':
                if селектор['sha256'] != pin or hashlib.sha256(json.dumps(акт).encode()).hexdigest() != pin:
                    raise ValueError('pin')
                return json.dumps(акт).encode()
            return 'постановка'.encode()
        import re
        область = {'выбор': lambda _: None, 'путь': lambda *_: None,
                   'делегация': SimpleNamespace(сверить_источник=источник),
                   'контракт': SimpleNamespace(разобрать_байты=json.loads, поля=поля),
                   'требовать': требовать, 're': re}
        exec(compile(модуль, str(файл), 'exec'), область)
        reader = область['прочитать_акт']
        сам.assertEqual(акт, reader(None, выбор))
        блок = '<fum-act-selector-v1>\n' + json.dumps(выбор) + '\n</fum-act-selector-v1>'
        сверить_выбор = область['сверить_выбор_в_нативном_тексте']
        сам.assertEqual(выбор, сверить_выбор(блок, выбор))
        with сам.assertRaises(ValueError):
            сверить_выбор(блок, {**выбор, 'sha256': 'c' * 64})
        with сам.assertRaises(ValueError):
            сверить_выбор(блок + блок, выбор)
        with сам.assertRaises(ValueError):
            сверить_выбор('нет блока', выбор)
        параметры = {'режим': 'контрольная-точка', 'исполнитель': 'child',
                     'ветка': 'refs/heads/codex/test', 'исходный_коммит': a,
                     'имя_автора': 'Ustranitelj problem komand'}
        сверить = область['сверить_авторство_акта']
        сам.assertEqual(акт['авторство'], сверить(акт, параметры))
        with сам.assertRaises(ValueError):
            сверить(акт, {**параметры, 'имя_автора': 'Drugoj'})
        with сам.assertRaises(ValueError):
            reader(None, {**выбор, 'sha256': 'c' * 64})
        акт['авторство']['роль'] = 'Root'
        with сам.assertRaises(ValueError):
            reader(None, выбор)
        with сам.assertRaises(ValueError):
            reader(None, {**выбор, 'sha256': hashlib.sha256(json.dumps(акт).encode()).hexdigest()})

        # Заглушка источника позволяет отдельно проверить прежние формы reader,
        # но не доказывает полный исторический replay стадий.
        for версия in ('1', '4'):
            прежний = {к: v for к, v in акт.items() if к != 'авторство'}
            прежний['схема'] = 'fum.поручение-дочерней-контрольной-точки.' + версия
            прежний['хэш_нативного_поручения'] = b
            if версия == '4':
                прежний['слияние'] = {}
            область['делегация'] = SimpleNamespace(сверить_источник=lambda *_: json.dumps(прежний).encode())
            сам.assertEqual(прежний, reader(None, выбор, новый_эффект=False))

    def test_сравнение_полей_не_доказывает_происхождение(сам):
        назначение = {"схема": "fum.назначение-автора.1", "исполнитель": "agent-1",
                      "ветка": "refs/heads/codex/example", "основа": "a" * 40,
                      "роль": "Upravlyayusjhij"}
        запрос = {"исполнитель": "agent-1", "ветка": "refs/heads/codex/example",
                  "основа": "a" * 40, "роль": "Upravlyayusjhij"}
        сам.assertTrue(проверить_назначение_автора(назначение, запрос))
        роль = "Ustranitelj problem komand"
        сам.assertTrue(проверить_назначение_автора({**назначение, "роль": роль}, {**запрос, "роль": роль}))
        for ключ, значение in (("роль", "Drugoj"), ("исполнитель", "agent-2"),
                               ("основа", "b" * 40), ("ветка", "refs/heads/codex/other")):
            with сам.subTest(ключ=ключ):
                сам.assertFalse(проверить_назначение_автора(назначение, {**запрос, ключ: значение}))
        сам.assertFalse(проверить_назначение_автора(None, запрос))
        сам.assertFalse(проверить_назначение_автора(назначение, {**запрос, "роль": "UNKNOWN"}))

    def test_точная_роль_из_имени_инструмента(сам):
        имя = составить_имя("FUM Codex", {"модель": "gpt-6-sol", "усилие": "ultra"})
        сам.assertEqual("FUM Codex [gpt-6-sol; effort=ultra]", имя)
        сам.assertTrue(проверить_формат(имя))
        сам.assertTrue(проверить_формат("FUM Codex"))

    def test_произвольная_латинская_роль_и_искажённое_имя_инструмента_отклоняются(сам):
        for роль in ("FUM Agent", "FUM codex", "FUM CODEX", "FUM Codex Writer", "FUM  Codex", "FUM Codex\n"):
            with сам.subTest(роль=роль):
                сам.assertFalse(проверить_формат(роль))
                with сам.assertRaises(ValueError):
                    составить_имя(роль, {"модель": "gpt-6-sol", "усилие": "ultra"})

    def test_модель_и_усилие_сохраняются_буквально(сам):
        for модель, усилие in (("gpt-6-astra", "max"), ("gpt-5.6-luna", "high"), ("model_1.2", "none")):
            with сам.subTest(модель=модель, усилие=усилие):
                имя = составить_имя("FUM Писатель", {"модель": модель, "усилие": усилие})
                сам.assertEqual(f"FUM Писатель [{модель}; effort={усилие}]", имя)
                сам.assertTrue(проверить_формат(имя))

    def test_неполные_неизвестные_и_опасные_данные_отклоняются(сам):
        for ключ in ("модель", "усилие"):
            for значение in (None, "", "unknown", "Unknown", "unavailable", "null", "unset", " x", "x ", "x\n", "x;y", "x]", "<x>", "x=y", "x/1", "a" * 129, 1):
                with сам.subTest(ключ=ключ, значение=значение):
                    данные = {"модель": "gpt-6-astra", "усилие": "max", ключ: значение}
                    with сам.assertRaises(ValueError):
                        составить_имя("FUM Писатель", данные)
            with сам.assertRaises(ValueError):
                составить_имя("FUM Писатель", {})

    def test_роль_не_подменяется_готовым_именем(сам):
        for роль in (None, "FUM  Писатель", "FUM писатель", "FUM Писатель [gpt-6-astra; effort=max]"):
            with сам.assertRaises(ValueError):
                составить_имя(роль, {"модель": "gpt-6-astra", "усилие": "max"})

    def test_историческое_имя_читается_без_выдуманного_суффикса(сам):
        сам.assertTrue(проверить_формат("FUM Интегратор"))
        сам.assertFalse(проверить_формат(None))
