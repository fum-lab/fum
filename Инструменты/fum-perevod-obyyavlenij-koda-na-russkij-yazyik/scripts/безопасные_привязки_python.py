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


def подготовить_замены(текст, переименования, выбранные_области=None, измерения=None,
                       разрешённые_передачи=None, имена_областей=None, разрешённые_исполнения=None):
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
    все_имена = {т.string for т in токены if т.type == tokenize.NAME}
    все_имена.update(у.id for у in ast.walk(дерево) if isinstance(у, ast.Name))
    правки = {}
    выбранные = set()
    разрешённые_передачи = set(разрешённые_передачи or ())
    учтённые_передачи = set()
    разрешённые_исполнения = set(разрешённые_исполнения or ())
    учтённые_исполнения = set()
    имена_областей = dict(имена_областей or {})

    def начало(узел):
        return смещения[узел.lineno - 1] + len(строки[узел.lineno - 1].encode()[:узел.col_offset].decode())

    def конец(узел):
        return смещения[узел.end_lineno - 1] + len(строки[узел.end_lineno - 1].encode()[:узел.end_col_offset].decode())

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

    изменённые_сигнатуры = {
        область for область, имя in выбранные
        if any(вид == "параметр" for вид, _ in область.привязки[имя])
    }
    изменённые_параметры = {и for о, и in выбранные if any(в == 'параметр' for в, _ in о.привязки[и])}
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
                        or not all(isinstance(а, ast.Name) or isinstance(а, ast.Dict) and not а.keys for а in узел.args[1:])):
                    raise ОтказПеревода('Явное исполнение требует прямого вызова и отдельной среды')
                учтённые_исполнения.add(координата)
            if имя_вызова in {"eval", "exec", "locals", "globals", "vars"} and выбранные and not (явный_объект or отдельное_исполнение):
                raise ОтказПеревода("Динамическое пространство имён требует отдельного допуска")
            if имя_вызова in {"getattr", "setattr", "delattr", "hasattr", "object"}:
                if any(isinstance(а, ast.Constant) and isinstance(а.value, str) and а.value in переименования for а in узел.args):
                    raise ОтказПеревода("Строковая связь имени требует явной миграции потребителя")
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
