"""Выбрать замены по синтаксической роли и лексическому владельцу Python.

Это ограниченный статический контракт, не вывод типов. Неизвестный владелец
собственного поля, смешанная привязка импорта, рефлексия и динамический вызов
с переименованными параметрами требуют отдельного явного решения.
"""
from __future__ import annotations

import ast
from bisect import bisect_left
from collections import Counter
from dataclasses import dataclass, field
import io
import re
import time
import tokenize


class ОтказПеревода(ValueError):
    pass


@dataclass(eq=False)
class Область:
    узел: ast.AST
    родитель: Область | None
    вид: str
    привязки: dict[str, list[tuple[str, ast.AST]]] = field(default_factory=dict)
    глобальные: set[str] = field(default_factory=set)
    нелокальные: set[str] = field(default_factory=set)
    получатель: str | None = None

    def объявить(сам, имя, вид, узел):
        сам.привязки.setdefault(имя, []).append((вид, узел))

    def владелец(сам, имя):
        текущая = сам
        while текущая is not None:
            if имя in текущая.глобальные:
                while текущая.родитель is not None:
                    текущая = текущая.родитель
                return текущая if имя in текущая.привязки else None
            if имя not in текущая.нелокальные and имя in текущая.привязки:
                return текущая
            следующая = текущая.родитель
            while следующая is not None and следующая.вид == "класс":
                следующая = следующая.родитель
            текущая = следующая
        return None


class ОбластиПитона(ast.NodeVisitor):
    def __init__(сам, дерево):
        сам.корень = Область(дерево, None, "модуль")
        сам.текущая = сам.корень
        сам.области = [сам.корень]
        сам.владельцы = {}
        сам.вложенные = {}
        сам.visit(дерево)
        # global/nonlocal действуют на всю область независимо от позиции.
        for область in сам.области:
            for имя in область.глобальные | область.нелокальные:
                записи = область.привязки.pop(имя, [])
                владелец = область.владелец(имя)
                if владелец is None and имя in область.глобальные:
                    владелец = сам.корень
                if владелец is None:
                    raise ОтказПеревода("Не найдено nonlocal-объявление")
                владелец.привязки.setdefault(имя, []).extend(записи)

    def visit(сам, узел):
        сам.владельцы[узел] = сам.текущая
        return super().visit(узел)

    def вложить(сам, узел, вид):
        область = Область(узел, сам.текущая, вид)
        сам.области.append(область)
        сам.вложенные[узел] = область
        return область

    def функцию(сам, узел):
        if not isinstance(узел, ast.Lambda):
            сам.текущая.объявить(узел.name, "функция", узел)
            for декоратор in узел.decorator_list:
                сам.visit(декоратор)
            if узел.returns:
                сам.visit(узел.returns)
        параметры = [*узел.args.posonlyargs, *узел.args.args, *узел.args.kwonlyargs]
        параметры += [п for п in (узел.args.vararg, узел.args.kwarg) if п]
        for параметр in параметры:
            if параметр.annotation:
                сам.visit(параметр.annotation)
        for значение in [*узел.args.defaults, *узел.args.kw_defaults]:
            if значение:
                сам.visit(значение)
        прежняя = сам.текущая
        область = сам.вложить(узел, "функция")
        if прежняя.вид == "класс" and параметры:
            декораторы = getattr(узел, "decorator_list", [])
            if not any(isinstance(д, ast.Name) and д.id == "staticmethod" for д in декораторы):
                область.получатель = параметры[0].arg
        сам.текущая = область
        for параметр in параметры:
            сам.владельцы[параметр] = область
            область.объявить(параметр.arg, "параметр", параметр)
        тело = [узел.body] if isinstance(узел, ast.Lambda) else узел.body
        for элемент in тело:
            сам.visit(элемент)
        сам.текущая = прежняя

    visit_FunctionDef = функцию
    visit_AsyncFunctionDef = функцию
    visit_Lambda = функцию

    def visit_ClassDef(сам, узел):
        сам.текущая.объявить(узел.name, "класс", узел)
        for элемент in [*узел.decorator_list, *узел.bases, *узел.keywords]:
            сам.visit(элемент)
        прежняя = сам.текущая
        сам.текущая = сам.вложить(узел, "класс")
        for элемент in узел.body:
            сам.visit(элемент)
        сам.текущая = прежняя

    def генератор(сам, узел):
        сам.visit(узел.generators[0].iter)
        прежняя = сам.текущая
        сам.текущая = сам.вложить(узел, "генератор")
        for номер, генератор in enumerate(узел.generators):
            if номер:
                сам.visit(генератор.iter)
            сам.visit(генератор.target)
            for условие in генератор.ifs:
                сам.visit(условие)
        if isinstance(узел, ast.DictComp):
            сам.visit(узел.key)
            сам.visit(узел.value)
        else:
            сам.visit(узел.elt)
        сам.текущая = прежняя

    visit_ListComp = генератор
    visit_SetComp = генератор
    visit_DictComp = генератор
    visit_GeneratorExp = генератор

    def visit_Name(сам, узел):
        if isinstance(узел.ctx, (ast.Store, ast.Del)):
            сам.текущая.объявить(узел.id, "имя", узел)

    def visit_Assign(сам, узел):
        if isinstance(узел.value, ast.Lambda) and len(узел.targets) == 1 and isinstance(узел.targets[0], ast.Name):
            цель = узел.targets[0]
            сам.владельцы[цель] = сам.текущая
            сам.текущая.объявить(цель.id, 'функция', узел.value)
            сам.visit(узел.value)
        else:
            сам.generic_visit(узел)

    def visit_Import(сам, узел):
        for псевдоним in узел.names:
            сам.владельцы[псевдоним] = сам.текущая
            сам.текущая.объявить(псевдоним.asname or псевдоним.name.split('.')[0],
                               "псевдоним" if псевдоним.asname else "внешнее", псевдоним)

    visit_ImportFrom = visit_Import

    def visit_ExceptHandler(сам, узел):
        if узел.name:
            сам.текущая.объявить(узел.name, "исключение", узел)
        сам.generic_visit(узел)

    def visit_Global(сам, узел):
        сам.текущая.глобальные.update(узел.names)

    def visit_Nonlocal(сам, узел):
        сам.текущая.нелокальные.update(узел.names)


class ПроисхождениеПитона:
    """Конечные статические роли API; неизвестное происхождение — None."""

    def __init__(сам, дерево):
        сам.дерево = дерево
        сам.области = ОбластиПитона(дерево)
        сам.узлы = tuple(ast.walk(дерево))
        сам._неограниченный_импорт = any(isinstance(у, ast.ImportFrom) and any(п.name == '*' for п in у.names) for у in сам.узлы)
        сам.родители = {ч: у for у in сам.узлы for ч in ast.iter_child_nodes(у)}
        сам.импорты = {п: у for у in сам.узлы if isinstance(у, (ast.Import, ast.ImportFrom)) for п in у.names}
        сам.значения = {}
        сам._разбираемые_фабрики = set()
        for узел in сам.узлы:
            if isinstance(узел, ast.Assign) and len(узел.targets) == 1 and isinstance(узел.targets[0], ast.Name):
                сам.значения[узел.targets[0]] = (узел, узел.value)
            elif isinstance(узел, ast.AnnAssign) and узел.value is not None and isinstance(узел.target, ast.Name):
                сам.значения[узел.target] = (узел, узел.value)
        сам.мутации = []
        сам.мутации_объекта = set()
        for узел in сам.узлы:
            if isinstance(узел, ast.Attribute) and isinstance(узел.ctx, (ast.Store, ast.Del)):
                родитель = сам.родители.get(узел)
                if isinstance(родитель, ast.AnnAssign) and родитель.value is None:
                    continue
                путь = сам._сырой_путь(узел)
                if путь:
                    сам.мутации.append((путь[0], узел))
            elif isinstance(узел, ast.Name) and узел.id == '__builtins__' and isinstance(узел.ctx, (ast.Store, ast.Del)):
                сам.мутации.append((('builtins',), узел))
            elif isinstance(узел, ast.Call) and len(узел.args) >= 2 and сам._обычное_встроенное(узел.func, {'setattr', 'delattr'}):
                владелец = сам._сырой_путь(узел.args[0])
                if владелец:
                    имя = узел.args[1]
                    путь = владелец[0] + ((имя.value,) if isinstance(имя, ast.Constant) and isinstance(имя.value, str) else ())
                    сам.мутации.append((путь, узел))
            elif isinstance(узел, ast.Subscript) and isinstance(узел.ctx, (ast.Store, ast.Del)):
                владелец = сам._словарь_интерфейса(узел.value)
                if владелец:
                    путь = владелец + ((узел.slice.value,) if isinstance(узел.slice, ast.Constant) and isinstance(узел.slice.value, str) else ())
                    сам.мутации.append((путь, узел))
            if isinstance(узел, ast.Call):
                вызов_интерфейса = сам._сырой_путь(узел.func)
                if (вызов_интерфейса and вызов_интерфейса[0] == ('unittest', 'mock', 'patch', 'object') and len(узел.args) >= 2):
                    цель = сам._сырой_путь(узел.args[0])
                    имя = узел.args[1]
                    if цель:
                        путь = цель[0] + ((имя.value,) if isinstance(имя, ast.Constant) and isinstance(имя.value, str) else ())
                        сам.мутации.append((путь, узел))
                elif (вызов_интерфейса and вызов_интерфейса[0] == ('unittest', 'mock', 'patch') and узел.args
                        and isinstance(узел.args[0], ast.Constant) and isinstance(узел.args[0].value, str)):
                    сам.мутации.append((tuple(узел.args[0].value.split('.')), узел))
                if isinstance(узел.func, ast.Attribute):
                    словарь = сам._словарь_интерфейса(узел.func.value)
                    if словарь:
                        сам.мутации.append((словарь, узел))
                # Передача самого объекта API неизвестному коду лишает нас
                # доказательства неизменности; локальные значения не обобщаются.
                передаваемые = [*узел.args, *(к.value for к in узел.keywords)]
                while передаваемые:
                    аргумент = передаваемые.pop()
                    if isinstance(аргумент, (ast.List, ast.Tuple, ast.Set)):
                        передаваемые.extend(аргумент.elts)
                        continue
                    if isinstance(аргумент, ast.Dict):
                        передаваемые.extend(ч for ч in [*аргумент.keys, *аргумент.values] if ч is not None)
                        continue
                    if isinstance(аргумент, ast.Starred):
                        передаваемые.append(аргумент.value)
                        continue
                    переданный = сам._сырой_путь(аргумент)
                    if переданный:
                        путь = переданный[0]
                        сам.мутации.append((путь[:-1] if путь[-1] == '__dict__' else путь, узел))
            if isinstance(узел, ast.Attribute) and узел.attr == '__dict__':
                владелец = сам._сырой_путь(узел.value)
                if владелец:
                    сам.мутации.append((владелец[0], узел))
            if isinstance(узел, ast.Subscript) and isinstance(узел.slice, ast.Constant) and isinstance(узел.slice.value, str):
                контейнер = сам._сырой_путь(узел.value)
                имя = tuple(узел.slice.value.split('.'))
                if контейнер and контейнер[0] == ('sys', 'modules') and имя[0] in {'sys', 'builtins', 'importlib', 'ctypes', 'unittest'}:
                    сам.мутации.append((имя, узел))
            if isinstance(узел, ast.Attribute) and узел.attr.startswith('__') and узел.attr.endswith('__'):
                владелец = сам._сырой_путь(узел.value)
                if владелец:
                    # Внутренности callable изменяют сам сохранённый объект,
                    # поэтому ранний снимок его имени здесь не помогает.
                    сам.мутации.append((владелец[0], узел))
                    сам.мутации_объекта.add(узел)
            if not isinstance(узел, (ast.Name, ast.Attribute)) or not isinstance(узел.ctx, ast.Load):
                continue
            путь = сам._сырой_путь(узел)
            if путь is None:
                continue
            родитель = сам.родители.get(узел)
            if ((isinstance(родитель, ast.Attribute) and родитель.value is узел)
                    or (isinstance(родитель, ast.Call) and родитель.func is узел)
                    or (isinstance(родитель, ast.ClassDef) and узел in родитель.bases)
                    or (isinstance(родитель, ast.Subscript) and родитель.value is узел
                        and путь[0] == ('sys', 'modules'))):
                continue
            цель = None
            if isinstance(родитель, ast.Assign) and len(родитель.targets) == 1:
                цель = родитель.targets[0]
            elif isinstance(родитель, ast.AnnAssign):
                цель = родитель.target
            if isinstance(цель, ast.Name) and родитель.value is узел:
                область = сам.области.владельцы[родитель]
                if (родитель in getattr(область.узел, 'body', ())
                        and сам._привязки(цель) == [('имя', цель)]):
                    continue
            # Контейнеры, возврат и прочие непрозрачные передачи API могут
            # изменить его через ускользнувший объект. Полноту не угадываем.
            сам.мутации.append((путь[0], узел))
            сам.мутации_объекта.add(узел)

    def _привязки(сам, узел):
        if not isinstance(узел, ast.Name):
            return []
        область = сам.области.владельцы.get(узел)
        владелец = область.владелец(узел.id) if область else None
        return владелец.привязки.get(узел.id, []) if владелец else []

    def _сырой_путь(сам, узел, посещённые=frozenset()):
        if узел in посещённые:
            return None
        посещённые = посещённые | {узел}
        if isinstance(узел, ast.Attribute):
            начало = сам._сырой_путь(узел.value, посещённые)
            return (начало[0] + (узел.attr,), None) if начало else None
        if not isinstance(узел, ast.Name):
            return None
        записи = сам._привязки(узел)
        if not записи:
            return (('builtins', узел.id), None) if узел.id in {'getattr', 'setattr', 'delattr', 'hasattr', 'vars', 'list', 'exec', 'eval'} else None
        пути = set()
        for _, привязка in записи:
            импорт = сам.импорты.get(привязка)
            if импорт is None or импорт.lineno >= узел.lineno:
                break
            область_импорта = сам.области.владельцы[импорт]
            if импорт not in getattr(область_импорта.узел, 'body', ()):
                return None
            if область_импорта.вид == 'класс' and (область_импорта.узел.bases or область_импорта.узел.keywords or область_импорта.узел.decorator_list):
                return None
            if isinstance(импорт, ast.Import):
                путь = tuple(привязка.name.split('.'))
                пути.add(путь if привязка.asname else путь[:1])
            elif импорт.level == 0 and импорт.module and привязка.name != '*':
                пути.add((*импорт.module.split('.'), привязка.name))
            else:
                break
        else:
            return (next(iter(пути)), None) if len(пути) == 1 else None
        if len(записи) != 1:
            return None
        пара = сам.значения.get(записи[0][1])
        if пара is None:
            return None
        присваивание, значение = пара
        область = сам.области.владельцы[присваивание]
        if присваивание not in getattr(область.узел, 'body', ()) or присваивание.lineno >= узел.lineno:
            return None
        начало = сам._сырой_путь(значение, посещённые)
        return (начало[0], начало[1] or присваивание) if начало else None

    def _словарь_интерфейса(сам, узел):
        if isinstance(узел, ast.Name) and узел.id == '__builtins__':
            return ('builtins',)
        if isinstance(узел, ast.Attribute) and узел.attr == '__dict__':
            путь = сам._сырой_путь(узел.value)
            return путь[0] if путь else None
        if (isinstance(узел, ast.Call) and len(узел.args) == 1 and not узел.keywords
                and сам._обычное_встроенное(узел.func, {'vars'})):
            путь = сам._сырой_путь(узел.args[0])
            return путь[0] if путь else None
        return None

    def _снимок_раньше(сам, снимок, мутация):
        if (снимок not in сам.дерево.body or not isinstance(мутация, ast.Attribute)
                or not isinstance(мутация.ctx, (ast.Store, ast.Del))):
            return False
        верхний = мутация
        while сам.родители.get(верхний) is not сам.дерево:
            верхний = сам.родители.get(верхний)
            if верхний is None:
                return False
        return сам.дерево.body.index(снимок) < сам.дерево.body.index(верхний)

    def путь_внешнего_интерфейса(сам, узел):
        if сам._неограниченный_импорт:
            return None
        происхождение = сам._сырой_путь(узел)
        if происхождение is None:
            return None
        путь, снимок = происхождение
        for изменённый, мутация in сам.мутации:
            if путь[:len(изменённый)] == изменённый:
                if мутация in сам.мутации_объекта or снимок is None or not сам._снимок_раньше(снимок, мутация):
                    return None
        return путь

    def _обычное_встроенное(сам, узел, имена):
        путь = сам._сырой_путь(узел)
        return bool(путь and len(путь[0]) == 2 and путь[0][0] == 'builtins' and путь[0][1] in имена)

    def встроенное(сам, узел, имя):
        return сам._обычное_встроенное(узел, {имя}) and сам.путь_внешнего_интерфейса(узел) == ('builtins', имя)

    def _метод(сам, узел):
        if not isinstance(узел, ast.FunctionDef) or узел.decorator_list:
            return None
        область = сам.области.владельцы.get(узел)
        if область is None or область.вид != 'класс':
            return None
        класс = область.узел
        if len(класс.bases) != 1 or класс.decorator_list or класс.keywords or область.привязки.get(узел.name) != [('функция', узел)]:
            return None
        база = сам.путь_внешнего_интерфейса(класс.bases[0])
        допустимые = {('importlib', 'abc', 'Loader'): {'create_module', 'exec_module'},
            ('importlib', 'abc', 'MetaPathFinder'): {'find_spec'}}
        if узел.name not in допустимые.get(база, ()):
            return None
        параметры = узел.args
        if (параметры.posonlyargs or параметры.kwonlyargs or параметры.vararg or параметры.kwarg
                or len(параметры.args) != (4 if узел.name == 'find_spec' else 2)):
            return None
        return узел.name

    def внешний_метод(сам, узел):
        return сам._метод(узел) is not None

    def внешний_параметр(сам, узел):
        if not isinstance(узел, ast.arg):
            return False
        область = сам.области.владельцы.get(узел)
        функция = область.узел if область else None
        метод = сам._метод(функция)
        if метод is None:
            return False
        имена = {'create_module': ('spec',), 'exec_module': ('module',), 'find_spec': ('fullname', 'path', 'target')}[метод]
        return any(п is узел and п.arg == и for п, и in zip(функция.args.args[1:], имена))

    def _замкнутый_возврат(сам, возврат, вид):
        значение = возврат.value
        if not isinstance(значение, ast.Name):
            return isinstance(значение, ast.Call)
        область = сам.области.владельцы[значение].владелец(значение.id)
        for узел in сам.узлы:
            if (not isinstance(узел, ast.Name) or узел.id != значение.id or not isinstance(узел.ctx, ast.Load)
                    or сам.области.владельцы[узел].владелец(узел.id) is not область):
                continue
            родитель = сам.родители.get(узел)
            if родитель is возврат:
                continue
            if isinstance(родитель, ast.Attribute) and родитель.value is узел and not родитель.attr.startswith('__'):
                continue
            if isinstance(родитель, ast.Call) and узел in родитель.args:
                if (вид == 'описание' and родитель.args == [узел]
                        and сам.путь_внешнего_интерфейса(родитель.func) == ('importlib', 'util', 'module_from_spec')):
                    continue
                вызов = родитель.func
                if (вид == 'модуль' and родитель.args == [узел] and isinstance(вызов, ast.Attribute)
                        and вызов.attr == 'exec_module' and isinstance(вызов.value, ast.Attribute)
                        and вызов.value.attr == 'loader' and сам._тип(вызов.value.value) == 'описание'):
                    continue
            if (вид == 'модуль' and isinstance(родитель, ast.Assign) and родитель.value is узел
                    and len(родитель.targets) == 1 and isinstance(родитель.targets[0], ast.Subscript)
                    and сам.путь_внешнего_интерфейса(родитель.targets[0].value) == ('sys', 'modules')):
                continue
            return False
        return True

    def _замкнутая_библиотека(сам, получатель, символ):
        if not isinstance(получатель, ast.Name):
            return isinstance(получатель, ast.Call)
        область = сам.области.владельцы[получатель].владелец(получатель.id)
        for узел in сам.узлы:
            if (not isinstance(узел, ast.Name) or узел.id != получатель.id or not isinstance(узел.ctx, ast.Load)
                    or сам.области.владельцы[узел].владелец(узел.id) is not область):
                continue
            родитель = сам.родители.get(узел)
            if isinstance(родитель, ast.Attribute) and родитель.value is узел and not родитель.attr.startswith('__'):
                continue
            if isinstance(родитель, ast.Call) and родитель.args and родитель.args[0] is узел:
                if (сам.встроенное(родитель.func, 'hasattr') and len(родитель.args) == 2
                        and isinstance(родитель.args[1], ast.Constant) and isinstance(родитель.args[1].value, str)):
                    continue
                if (сам._обычное_встроенное(родитель.func, {'setattr', 'delattr'}) and len(родитель.args) >= 2
                        and isinstance(родитель.args[1], ast.Constant) and родитель.args[1].value != символ):
                    continue
            return False
        return True

    def _тип(сам, узел, посещённые=frozenset()):
        if узел in посещённые:
            return None
        посещённые = посещённые | {узел}
        if isinstance(узел, ast.Name):
            записи = сам._привязки(узел)
            if not записи:
                return None
            if all(привязка in сам.значения for _, привязка in записи):
                типы = {сам._тип(сам.значения[п][1], посещённые) for _, п in записи}
                тип = next(iter(типы)) if len(типы) == 1 else None
                if тип == 'библиотека' and any(not isinstance(сам.значения[п][1], ast.Call)
                        or сам.путь_внешнего_интерфейса(сам.значения[п][1].func) != ('ctypes', 'CDLL') for _, п in записи):
                    return None
                return тип
            if len(записи) != 1:
                return None
            вид, привязка = записи[0]
            if вид == 'параметр':
                функция = сам.области.владельцы[привязка].узел
                if сам._метод(функция) == 'exec_module' and функция.args.args[1] is привязка:
                    return 'модуль'
            цель = сам.родители.get(привязка)
            цикл = сам.родители.get(цель)
            if (isinstance(цель, ast.Tuple) and len(цель.elts) == 2 and all(isinstance(э, ast.Name) for э in цель.elts)
                    and цель.elts[1] is привязка and isinstance(цикл, ast.For) and цикл.target is цель):
                итератор = цикл.iter
                if (isinstance(итератор, ast.Call) and len(итератор.args) == 1 and not итератор.keywords
                        and сам.встроенное(итератор.func, 'list')):
                    итератор = итератор.args[0]
                if (isinstance(итератор, ast.Call) and not итератор.args and not итератор.keywords
                        and isinstance(итератор.func, ast.Attribute) and итератор.func.attr == 'items'
                        and сам.путь_внешнего_интерфейса(итератор.func.value) == ('sys', 'modules')):
                    return 'модуль'
        elif isinstance(узел, ast.Subscript):
            if (сам.путь_внешнего_интерфейса(узел.value) == ('sys', 'modules') and isinstance(узел.slice, ast.Constant)
                    and isinstance(узел.slice.value, str)):
                return 'модуль'
        elif isinstance(узел, ast.Call):
            путь = сам.путь_внешнего_интерфейса(узел.func)
            if путь in {('importlib', 'util', 'spec_from_file_location'), ('importlib', 'machinery', 'PathFinder', 'find_spec')}:
                return 'описание'
            if (путь == ('importlib', 'util', 'module_from_spec') and len(узел.args) == 1 and not узел.keywords
                    and сам._тип(узел.args[0], посещённые) == 'описание'):
                return 'модуль'
            if (путь == ('ctypes', 'CDLL') and len(узел.args) == 1 and isinstance(узел.args[0], ast.Constant)
                    and узел.args[0].value is None):
                return 'библиотека'
            if isinstance(узел.func, ast.Name):
                записи = сам._привязки(узел.func)
                if len(записи) == 1 and записи[0][0] == 'функция':
                    функция = записи[0][1]
                    if isinstance(функция, ast.FunctionDef) and not функция.decorator_list and функция not in сам._разбираемые_фабрики:
                        область = сам.области.вложенные[функция]
                        возвраты = [э for э in ast.walk(функция) if isinstance(э, ast.Return) and сам.области.владельцы.get(э) is область]
                        if len(возвраты) == 1:
                            сам._разбираемые_фабрики.add(функция)
                            try:
                                тип = сам._тип(возвраты[0].value, посещённые)
                                if тип in {'модуль', 'описание'} and not сам._замкнутый_возврат(возвраты[0], тип):
                                    return None
                                return тип
                            finally:
                                сам._разбираемые_фабрики.remove(функция)
        elif isinstance(узел, ast.Attribute):
            if узел.attr in {'renamex_np', 'renameatx_np', 'renameat2'} and сам._тип(узел.value, посещённые) == 'библиотека':
                if not сам._замкнутая_библиотека(узел.value, узел.attr):
                    return None
                for часть in сам.узлы:
                    if (isinstance(часть, ast.Attribute) and часть.attr == узел.attr and isinstance(часть.ctx, (ast.Store, ast.Del))
                            and сам._тип(часть.value, посещённые) == 'библиотека'):
                        return None
                    if (isinstance(часть, ast.Call) and len(часть.args) >= 2 and сам._обычное_встроенное(часть.func, {'setattr', 'delattr'})
                            and сам._тип(часть.args[0], посещённые) == 'библиотека'):
                        имя = часть.args[1]
                        if not isinstance(имя, ast.Constant) or имя.value == узел.attr:
                            return None
                return 'функция_C'
        return None

    def модуль(сам, узел):
        return сам._тип(узел) == 'модуль'

    def внешний_атрибут(сам, узел):
        if not isinstance(узел, ast.Attribute):
            return False
        путь = сам.путь_внешнего_интерфейса(узел.value)
        if путь == ('sys',) and узел.attr == 'dont_write_bytecode':
            return True
        if путь == ('importlib', 'util') and узел.attr == 'spec_from_file_location':
            return True
        тип = сам._тип(узел.value)
        return ((тип == 'описание' and узел.attr == 'loader') or (тип == 'функция_C' and узел.attr in {'argtypes', 'restype'}))


def подготовить_замены(текст, переименования, выбранные_области=None, измерения=None,
                       разрешённые_передачи=None, имена_областей=None, разрешённые_исполнения=None, разрешённые_внешние_вызовы=None,
                       связанные_атрибуты=None):
    """Вернуть текст и проверяемые диапазоны; необязательный выбор — по области.

    выбранные_области содержит (строка, байтовый столбец, старое имя).
    (0, 0) обозначает модуль. Хэш всего исходника закрепляет координаты снаружи.
    """
    отметка = time.perf_counter_ns()

    def стадия(название):
        nonlocal отметка
        сейчас = time.perf_counter_ns()
        if измерения is not None:
            измерения.append({"стадия": название, "длительность_наносекунды": сейчас - отметка})
        отметка = сейчас

    дерево = ast.parse(текст)
    compile(дерево, '<исходник>', 'exec', dont_inherit=True)
    стадия("разбор_исходника")
    области = ОбластиПитона(дерево)
    стадия("лексические_области")
    строки = текст.splitlines(keepends=True)
    смещения = [0]
    for строка in строки:
        смещения.append(смещения[-1] + len(строка))
    токены = list(tokenize.generate_tokens(io.StringIO(текст).readline))
    позиции_токенов = [смещения[т.start[0] - 1] + т.start[1] for т in токены]
    правки = {}
    выбранные = set()
    разрешённые_передачи = set(разрешённые_передачи or ())
    учтённые_передачи = set()
    разрешённые_исполнения = set(разрешённые_исполнения or ())
    учтённые_исполнения = set()
    разрешённые_внешние_вызовы = set(разрешённые_внешние_вызовы or ())
    учтённые_внешние_вызовы = set()
    имена_областей = dict(имена_областей or {})

    def начало(узел):
        return смещения[узел.lineno - 1] + len(строки[узел.lineno - 1].encode()[:узел.col_offset].decode())

    def конец(узел):
        return смещения[узел.end_lineno - 1] + len(строки[узел.end_lineno - 1].encode()[:узел.end_col_offset].decode())

    связанные_диапазоны = set()
    допустимые_атрибуты = set()
    if связанные_атрибуты:
        for узел in ast.walk(дерево):
            if isinstance(узел, ast.Attribute):
                до = конец(узел)
                от = до - len(узел.attr)
                if текст[от:до] == узел.attr:
                    допустимые_атрибуты.add((от, до))
        for диапазон in связанные_атрибуты:
            if (not isinstance(диапазон, (tuple, list)) or len(диапазон) != 2
                    or any(type(число) is not int for число in диапазон)):
                raise ОтказПеревода('Неверный диапазон связанного атрибута')
            ключ = tuple(диапазон)
            if ключ not in допустимые_атрибуты or ключ in связанные_диапазоны:
                raise ОтказПеревода('Неизвестный или повторный связанный атрибут')
            связанные_диапазоны.add(ключ)
    все_имена = {т.string for т, позиция in zip(токены, позиции_токенов)
                 if т.type == tokenize.NAME and (позиция, позиция + len(т.string)) not in связанные_диапазоны}
    все_имена.update(у.id for у in ast.walk(дерево) if isinstance(у, ast.Name))
    все_имена.update(имя for область in области.области for имя in область.привязки)
    все_имена.update(узел.attr for узел in ast.walk(дерево) if isinstance(узел, ast.Attribute)
                     and (конец(узел) - len(узел.attr), конец(узел)) not in связанные_диапазоны)

    def ключ_области(область, имя):
        return (getattr(область.узел, "lineno", 0), getattr(область.узел, "col_offset", 0), имя)

    for область in области.области:
        for имя, записи in область.привязки.items():
            if имя not in переименования:
                continue
            if выбранные_области is not None and ключ_области(область, имя) not in выбранные_области:
                continue
            виды = {в for в, _ in записи}
            if виды == {"внешнее"}:
                continue
            if "внешнее" in виды or ("псевдоним" in виды and виды != {"псевдоним"}):
                raise ОтказПеревода(f"Смешанная импортная привязка: {имя}")
            новое = имена_областей.get(ключ_области(область, имя), переименования[имя])
            if новое in все_имена and новое != имя:
                raise ОтказПеревода(f"коллизия: {имя} → {новое}")
            выбранные.add((область, имя))

    if имена_областей.keys() - {ключ_области(о, и) for о, и in выбранные}:
        raise ОтказПеревода('Неизвестная область отдельного имени')

    def выбрано(область, имя):
        владелец = область.владелец(имя)
        return владелец if (владелец, имя) in выбранные else None

    def добавить(от, до, имя, область, роль):
        if текст[от:до] != имя:
            raise ОтказПеревода(f"Диапазон не совпал с исходным именем: {имя}")
        запись = {"начало": от, "конец": до, "старое": имя, "новое": имена_областей.get(ключ_области(область, имя), переименования[имя]),
                  "область": list(ключ_области(область, имя)[:2]), "роль": роль}
        if (от, до) in правки and правки[от, до] != запись:
            raise ОтказПеревода("Несогласованные роли диапазона")
        правки[от, до] = запись

    def токен_имени(узел, имя, после=None, последний=False):
        от, до = начало(узел), конец(узел)
        кандидаты = []
        разрешён = после is None
        for номер in range(bisect_left(позиции_токенов, от), bisect_left(позиции_токенов, до)):
            токен = токены[номер]
            позиция = позиции_токенов[номер]
            if токен.string == после:
                разрешён = True
                continue
            if разрешён and токен.type == tokenize.NAME and токен.string == имя:
                кандидаты.append((позиция, позиция + len(имя)))
                if not последний:
                    break
        if not кандидаты:
            raise ОтказПеревода(f"Не найден токен объявления: {имя}")
        return кандидаты[-1]

    def класс_получателя(узел, область):
        if not isinstance(узел, ast.Name):
            return None
        владелец = область.владелец(узел.id)
        if владелец is None:
            return None
        if владелец.получатель == узел.id:
            записи = владелец.привязки[узел.id]
            if len(записи) != 1 or записи[0][0] != "параметр":
                raise ОтказПеревода("Получатель метода перепривязан")
            if any(not isinstance(д, ast.Name) or д.id not in {"classmethod", "property"}
                   for д in getattr(владелец.узел, "decorator_list", [])):
                raise ОтказПеревода("Неизвестный декоратор получателя метода")
            return владелец.родитель
        записи = владелец.привязки[узел.id]
        if len(записи) == 1 and записи[0][0] == "класс":
            return области.вложенные[записи[0][1]]
        return None

    # Поля учитываются лишь у непосредственного получателя собственного класса.
    поля = set()
    стадия("выбор_привязок")
    for узел in ast.walk(дерево):
        if isinstance(узел, ast.Attribute) and isinstance(узел.ctx, ast.Store) and узел.attr in переименования:
            класс = класс_получателя(узел.value, области.владельцы[узел])
            if класс is None:
                raise ОтказПеревода(f"Неизвестный владелец записываемого поля: {узел.attr}")
            if выбранные_области is None or ключ_области(класс, узел.attr) in выбранные_области:
                поля.add((класс, узел.attr))
    for область, имя in выбранные:
        if область.вид == "класс":
            поля.add((область, имя))
    if выбранные_области is not None:
        найденные = {ключ_области(о, и) for о, и in выбранные | поля}
        if выбранные_области - найденные:
            raise ОтказПеревода("Неизвестная или внешняя координата выбранной области")

    именованные_привязки = {
        (область, имя) for область, имя in выбранные
        if any(вид == 'параметр' and узел in [*область.узел.args.args, *область.узел.args.kwonlyargs]
               for вид, узел in область.привязки[имя])
    }
    изменённые_сигнатуры = {о for о, _ in именованные_привязки}
    изменённые_параметры = {и for _, и in именованные_привязки}
    родители = {ребёнок: родитель for родитель in ast.walk(дерево) for ребёнок in ast.iter_child_nodes(родитель)}

    def передача_разрешена(узел, имя):
        родитель = родители.get(узел)
        позиционный = isinstance(родитель, ast.Call) and узел in родитель.args
        вызов = родители.get(родитель)
        именованный = (isinstance(родитель, ast.keyword) and родитель.value is узел
                       and isinstance(вызов, ast.Call) and родитель in вызов.keywords)
        значение_по_умолчанию = (isinstance(узел, ast.Lambda) and isinstance(родитель, ast.arguments)
                                and узел in [*родитель.defaults, *родитель.kw_defaults])
        координата = (узел.lineno, узел.col_offset, имя)
        if координата not in разрешённые_передачи or not (позиционный or именованный or значение_по_умолчанию):
            return False
        учтённые_передачи.add(координата)
        return True

    for узел in ast.walk(дерево):
        if isinstance(узел, ast.Lambda) and области.вложенные[узел] in изменённые_сигнатуры:
            родитель = родители.get(узел)
            единственная = False
            if isinstance(родитель, ast.Assign) and len(родитель.targets) == 1 and isinstance(родитель.targets[0], ast.Name):
                цель = родитель.targets[0]
                владелец = области.владельцы[цель].владелец(цель.id)
                единственная = владелец is not None and владелец.привязки[цель.id] == [('функция', узел)]
            if not единственная and not (isinstance(родитель, ast.Call) and родитель.func is узел):
                if not передача_разрешена(узел, '<lambda>'):
                    raise ОтказПеревода('Непрямое употребление lambda требует явного потребителя')
        if isinstance(узел, ast.ImportFrom) and any(п.name == "*" for п in узел.names):
            raise ОтказПеревода("Неограниченный импорт требует отдельного допуска")
        if isinstance(узел, ast.JoinedStr):
            имена = {у.id for у in ast.walk(узел) if isinstance(у, ast.Name)}
            if имена & переименования.keys() and re.search(r"=\s*[!}:]", текст[начало(узел):конец(узел)]):
                raise ОтказПеревода("Отладочная форматная строка меняет выводимую метку")
        аннотации = []
        if isinstance(узел, ast.arg) and узел.annotation:
            аннотации.append(узел.annotation)
        if isinstance(узел, (ast.FunctionDef, ast.AsyncFunctionDef)) and узел.returns:
            аннотации.append(узел.returns)
        if isinstance(узел, ast.AnnAssign):
            аннотации.append(узел.annotation)
        for аннотация in аннотации:
            for часть in ast.walk(аннотация):
                if isinstance(часть, ast.Constant) and isinstance(часть.value, str):
                    if set(re.findall(r"[^\W\d]\w*", часть.value)) & переименования.keys():
                        raise ОтказПеревода("Строковая аннотация требует явной миграции")
        if isinstance(узел, ast.Name) and isinstance(узел.ctx, ast.Load):
            владелец = области.владельцы[узел].владелец(узел.id)
            if (владелец, узел.id) in выбранные and владелец.вид == "класс":
                raise ОтказПеревода("Порядок вычисления пространства класса требует отдельного допуска")
            записи = владелец.привязки.get(узел.id, []) if владелец else []
            if any(вид == "функция" and области.вложенные[определение] in изменённые_сигнатуры for вид, определение in записи):
                родитель = родители.get(узел)
                if not isinstance(родитель, ast.Call) or родитель.func is not узел:
                    if not передача_разрешена(узел, узел.id):
                        raise ОтказПеревода("Передача функции с изменённой сигнатурой требует явного потребителя")

    if разрешённые_передачи != учтённые_передачи:
        raise ОтказПеревода("Неизвестная координата передачи функции")

    for узел in ast.walk(дерево):
        область = области.владельцы.get(узел)
        if область is None:
            continue
        if isinstance(узел, (ast.Match, ast.NamedExpr)):
            имена = {у.id for у in ast.walk(узел) if isinstance(у, ast.Name)}
            имена.update(getattr(у, "name", None) for у in ast.walk(узел))
            for часть in ast.walk(узел):
                if isinstance(часть, ast.MatchClass):
                    имена.update(часть.kwd_attrs)
                if isinstance(часть, ast.MatchMapping):
                    имена.add(часть.rest)
            if имена & переименования.keys():
                raise ОтказПеревода("Сопоставление образца или присваивание в выражении требует отдельного допуска")
        if isinstance(узел, ast.Name):
            владелец = выбрано(область, узел.id)
            if владелец:
                добавить(начало(узел), конец(узел), узел.id, владелец, "употребление")
        elif isinstance(узел, ast.arg):
            if (область, узел.arg) in выбранные:
                добавить(начало(узел), начало(узел) + len(узел.arg), узел.arg, область, "параметр")
        elif isinstance(узел, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            if (область, узел.name) in выбранные:
                от, до = токен_имени(узел, узел.name, "class" if isinstance(узел, ast.ClassDef) else "def")
                добавить(от, до, узел.name, область, "объявление")
        elif isinstance(узел, ast.alias) and узел.asname and (область, узел.asname) in выбранные:
            от, до = токен_имени(узел, узел.asname, "as")
            добавить(от, до, узел.asname, область, "псевдоним")
        elif isinstance(узел, ast.ExceptHandler) and узел.name:
            владелец = выбрано(область, узел.name)
            if владелец:
                от, до = токен_имени(узел, узел.name, "as")
                добавить(от, до, узел.name, владелец, "исключение")
        elif isinstance(узел, (ast.Global, ast.Nonlocal)):
            for имя in узел.names:
                владелец = выбрано(область, имя)
                if владелец:
                    от, до = токен_имени(узел, имя)
                    добавить(от, до, имя, владелец, "связь_областей")
        elif isinstance(узел, ast.Attribute) and узел.attr in переименования:
            класс = класс_получателя(узел.value, область)
            if (класс, узел.attr) in поля:
                добавить(конец(узел) - len(узел.attr), конец(узел), узел.attr, класс, "своё_поле")
            elif any(имя == узел.attr for _, имя in поля):
                raise ОтказПеревода(f"Не доказан владелец употребления своего поля: {узел.attr}")
        if isinstance(узел, ast.Call):
            имя_вызова = узел.func.id if isinstance(узел.func, ast.Name) else getattr(узел.func, "attr", "")
            явный_объект = имя_вызова == 'vars' and len(узел.args) == 1 and not узел.keywords and not поля
            координата = (узел.lineno, узел.col_offset)
            отдельное_исполнение = координата in разрешённые_исполнения
            if отдельное_исполнение:
                if (not isinstance(узел.func, ast.Name) or имя_вызова not in {'exec', 'eval'}
                        or len(узел.args) not in {2, 3} or узел.keywords
                        or not all(isinstance(а, ast.Name) or isinstance(а, ast.Dict) and not а.keys
                                   or isinstance(а, ast.Attribute) and isinstance(а.value, ast.Name) and а.attr == '__dict__'
                                   for а in узел.args[1:])):
                    raise ОтказПеревода('Явное исполнение требует прямого вызова и отдельной среды')
                учтённые_исполнения.add(координата)
            if имя_вызова in {"eval", "exec", "locals", "globals", "vars"} and выбранные and not (явный_объект or отдельное_исполнение):
                raise ОтказПеревода("Динамическое пространство имён требует отдельного допуска")
            if имя_вызова in {"getattr", "setattr", "delattr", "hasattr", "object"}:
                if any(isinstance(а, ast.Constant) and isinstance(а.value, str) and а.value in переименования for а in узел.args):
                    raise ОтказПеревода("Строковая связь имени требует явной миграции потребителя")
            if координата in разрешённые_внешние_вызовы:
                if not isinstance(узел.func, ast.Name):
                    raise ОтказПеревода('Явный внешний вызов требует простого имени')
                учтённые_внешние_вызовы.add(координата)
                continue
            функция = None
            владелец = None
            имя = None
            if isinstance(узел.func, ast.Lambda):
                функция = области.вложенные[узел.func]
            elif isinstance(узел.func, ast.Name):
                имя = узел.func.id
                владелец = область.владелец(имя)
            elif isinstance(узел.func, ast.Attribute):
                имя = узел.func.attr
                владелец = класс_получателя(узел.func.value, область)
            if владелец and имя in владелец.привязки:
                записи = владелец.привязки[имя]
                if len(записи) == 1 and записи[0][0] == "функция":
                    функция = области.вложенные[записи[0][1]]
                elif len(записи) == 1 and записи[0][0] == "класс":
                    класс = области.вложенные[записи[0][1]]
                    методы = класс.привязки.get("__init__", [])
                    if len(методы) == 1 and методы[0][0] == "функция" and not класс.узел.bases and not класс.узел.keywords and not класс.узел.decorator_list and "__new__" not in класс.привязки:
                        функция = области.вложенные[методы[0][1]]
                    elif any((а.arg is None and изменённые_сигнатуры) or а.arg in изменённые_параметры for а in узел.keywords):
                        raise ОтказПеревода("Неподдержанный конструктор с именованными аргументами")
                elif any((а.arg is None and изменённые_сигнатуры) or а.arg in изменённые_параметры for а in узел.keywords) and any(в not in {"внешнее", "псевдоним"} for в, _ in записи):
                    raise ОтказПеревода("Динамический вызов с именованными аргументами")
            if функция is None and isinstance(узел.func, ast.Attribute):
                if any(о.вид == "функция" and getattr(о.узел, "name", None) == узел.func.attr for о in изменённые_сигнатуры):
                    if any(а.arg is None or а.arg in переименования for а in узел.keywords):
                        raise ОтказПеревода("Неизвестный получатель метода с изменённой сигнатурой")
            if функция:
                if функция in изменённые_сигнатуры and getattr(функция.узел, 'decorator_list', []):
                    raise ОтказПеревода("Декоратор не доказывает сигнатуру вызываемой функции")
                if any(а.arg is None for а in узел.keywords) and функция in изменённые_сигнатуры:
                    raise ОтказПеревода("Распаковка ключевых аргументов своей функции")
                именованные = {п.arg for п in [*функция.узел.args.args, *функция.узел.args.kwonlyargs]}
                for аргумент in узел.keywords:
                    if аргумент.arg in именованные and (функция, аргумент.arg) in выбранные:
                        добавить(начало(аргумент), начало(аргумент) + len(аргумент.arg), аргумент.arg, функция, "аргумент_своей_функции")
        if isinstance(узел, (ast.Assign, ast.AnnAssign)):
            цели = узел.targets if isinstance(узел, ast.Assign) else [узел.target]
            if any(isinstance(ц, ast.Name) and ц.id in {"__all__", "__slots__", "__match_args__"} for ц in цели):
                if any(isinstance(у, ast.Constant) and isinstance(у.value, str) and у.value in переименования for у in ast.walk(узел)):
                    raise ОтказПеревода("Специальный строковый перечень имён требует явной миграции")

    if разрешённые_исполнения != учтённые_исполнения:
        raise ОтказПеревода('Неизвестная координата явного исполнения')
    if разрешённые_внешние_вызовы != учтённые_внешние_вызовы:
        raise ОтказПеревода('Неизвестная координата внешнего вызова')
    новые_имена = {}
    for правка in правки.values():
        прежнее = новые_имена.setdefault(правка['новое'], правка['старое'])
        if прежнее != правка['старое']:
            raise ОтказПеревода('Коллизия эффективных имён после выбора области')

    стадия("проверка_употреблений")
    план = sorted(правки.values(), key=lambda п: п["начало"])
    части = []
    позиция = 0
    for правка in план:
        if правка["начало"] < позиция:
            raise ОтказПеревода("Пересечение диапазонов")
        части.extend((текст[позиция:правка["начало"]], правка["новое"]))
        позиция = правка["конец"]
    части.append(текст[позиция:])
    итог = "".join(части)
    ast.parse(итог)
    compile(итог, '<результат>', 'exec', dont_inherit=True)
    стадия("сборка_и_повторный_разбор")
    return итог, план, все_имена


def заменить_привязки(текст, переименования):
    итог, план, имена = подготовить_замены(текст, переименования)
    количества = Counter(п["старое"] for п in план)
    return итог, {имя: количества[имя] for имя in переименования}, имена
