"""Ограниченный инвентарь C++ через физические координаты libclang."""

import ctypes
import os
from pathlib import Path
import re
import stat


class ОшибкаРазбораСи(ValueError):
    pass


class СтрокаСи(ctypes.Structure):
    pass


class КурсорСи(ctypes.Structure):
    pass


class МестоСи(ctypes.Structure):
    pass


class НесохранённыйФайлСи(ctypes.Structure):
    pass


class ДиапазонСи(ctypes.Structure):
    pass


class ДиапазоныСи(ctypes.Structure):
    pass


# Точное имя поля задаёт ctypes; оно не является собственным именем FUM.
setattr(СтрокаСи, "_fields_", [("данные", ctypes.c_void_p), ("флаги", ctypes.c_uint)])
setattr(КурсорСи, "_fields_", [("вид", ctypes.c_uint), ("добавочные_данные", ctypes.c_int),
                            ("указатели", ctypes.c_void_p * 3)])
setattr(МестоСи, "_fields_", [("указатели", ctypes.c_void_p * 2), ("данные", ctypes.c_uint)])
setattr(НесохранённыйФайлСи, "_fields_", [("имя", ctypes.c_char_p),
                                      ("содержимое", ctypes.c_char_p), ("длина", ctypes.c_ulong)])
setattr(ДиапазонСи, "_fields_", [("указатели", ctypes.c_void_p * 2),
                              ("начало", ctypes.c_uint), ("конец", ctypes.c_uint)])
setattr(ДиапазоныСи, "_fields_", [("число", ctypes.c_uint),
                               ("диапазоны", ctypes.POINTER(ДиапазонСи))])


обратный_вызов = ctypes.CFUNCTYPE(ctypes.c_uint, КурсорСи, КурсорСи, ctypes.c_void_p)
обратный_вызов_включений = ctypes.CFUNCTYPE(None, ctypes.c_void_p,
    ctypes.POINTER(МестоСи), ctypes.c_uint, ctypes.c_void_p)
библиотека_си = None
допущенные_виды = frozenset({2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 21, 22,
                            24, 25, 27, 28, 29, 30, 31, 32, 36})


def загрузить_библиотеку():
    global библиотека_си
    if библиотека_си is not None:
        return библиотека_си
    путь = Path("/Library/Developer/CommandLineTools/usr/lib/libclang.dylib")
    try:
        библиотека = ctypes.CDLL(str(путь))
    except OSError as ошибка:
        raise ОшибкаРазбораСи("libclang Command Line Tools недоступен") from ошибка
    указатель = ctypes.c_void_p
    беззнаковое = ctypes.c_uint
    целое = ctypes.c_int
    строка = ctypes.c_char_p
    адрес = ctypes.POINTER
    контракты = {
        "clang_createIndex": ([целое, целое], указатель),
        "clang_disposeIndex": ([указатель], None),
        "clang_parseTranslationUnit2": ([указатель, строка, адрес(строка), целое,
            указатель, беззнаковое, беззнаковое, адрес(указатель)], целое),
        "clang_disposeTranslationUnit": ([указатель], None),
        "clang_getTranslationUnitCursor": ([указатель], КурсорСи),
        "clang_getCursorSpelling": ([КурсорСи], СтрокаСи),
        "clang_getCursorLocation": ([КурсорСи], МестоСи),
        "clang_isDeclaration": ([беззнаковое], беззнаковое),
        "clang_getSpellingLocation": ([МестоСи, адрес(указатель), адрес(беззнаковое),
            адрес(беззнаковое), адрес(беззнаковое)], None),
        "clang_getExpansionLocation": ([МестоСи, адрес(указатель), адрес(беззнаковое),
            адрес(беззнаковое), адрес(беззнаковое)], None),
        "clang_getFileName": ([указатель], СтрокаСи),
        "clang_getCString": ([СтрокаСи], строка),
        "clang_disposeString": ([СтрокаСи], None),
        "clang_visitChildren": ([КурсорСи, обратный_вызов, указатель], беззнаковое),
        "clang_getNumDiagnostics": ([указатель], беззнаковое),
        "clang_getDiagnostic": ([указатель, беззнаковое], указатель),
        "clang_getDiagnosticSeverity": ([указатель], беззнаковое),
        "clang_formatDiagnostic": ([указатель, беззнаковое], СтрокаСи),
        "clang_defaultDiagnosticDisplayOptions": ([], беззнаковое),
        "clang_disposeDiagnostic": ([указатель], None),
        "clang_getFile": ([указатель, строка], указатель),
        "clang_getSkippedRanges": ([указатель, указатель], адрес(ДиапазоныСи)),
        "clang_disposeSourceRangeList": ([адрес(ДиапазоныСи)], None),
        "clang_getInclusions": ([указатель, обратный_вызов_включений, указатель], None),
    }
    try:
        for имя, (аргументы, результат) in контракты.items():
            функция = getattr(библиотека, имя)
            setattr(функция, "argtypes", аргументы)
            setattr(функция, "restype", результат)
    except AttributeError as ошибка:
        raise ОшибкаРазбораСи("libclang не предоставляет требуемый C API") from ошибка
    библиотека_си = библиотека
    return библиотека


def прочитать_строку(библиотека, значение):
    try:
        данные = библиотека.clang_getCString(значение)
        return данные.decode("utf-8") if данные else ""
    finally:
        библиотека.clang_disposeString(значение)


def координаты(библиотека, место, функция):
    файл = ctypes.c_void_p()
    строка = ctypes.c_uint()
    столбец = ctypes.c_uint()
    смещение = ctypes.c_uint()
    функция(место, ctypes.byref(файл), ctypes.byref(строка),
            ctypes.byref(столбец), ctypes.byref(смещение))
    имя = прочитать_строку(библиотека, библиотека.clang_getFileName(файл)) if файл.value else ""
    return (Path(имя).resolve() if имя else None, строка.value, столбец.value, смещение.value)


def признаки_файла(сведения):
    return (сведения.st_dev, сведения.st_ino, сведения.st_mode, сведения.st_size,
            сведения.st_mtime_ns, сведения.st_ctime_ns)


def снимок_исходника(файл):
    файл = Path(файл)
    if any(часть.is_symlink() for часть in (файл, *файл.parents)) or not файл.is_file():
        raise ОшибкаРазбораСи("исходник C++ должен быть обычным файлом без ссылок")
    дескриптор = os.open(файл, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        сведения = os.fstat(дескриптор)
        if not stat.S_ISREG(сведения.st_mode):
            raise ОшибкаРазбораСи("исходник C++ не является обычным файлом")
        if сведения.st_size > 4 * 1024 * 1024:
            raise ОшибкаРазбораСи("исходник C++ превышает 4 МиБ")
        части = []
        осталось = сведения.st_size
        while True:
            часть = os.read(дескриптор, min(65536, осталось + 1))
            if not часть:
                break
            if len(часть) > осталось:
                raise ОшибкаРазбораСи("исходник C++ вырос при чтении")
            части.append(часть)
            осталось -= len(часть)
        if осталось or признаки_файла(os.fstat(дескриптор)) != признаки_файла(сведения):
            raise ОшибкаРазбораСи("исходник C++ изменился при чтении")
        if any(часть.is_symlink() for часть in (файл, *файл.parents)):
            raise ОшибкаРазбораСи("путь исходника C++ подменён ссылкой")
        if признаки_файла(файл.stat()) != признаки_файла(сведения):
            raise ОшибкаРазбораСи("файл C++ подменён при чтении")
        return b"".join(части), признаки_файла(сведения)
    finally:
        os.close(дескриптор)


def проверить_аргументы(аргументы):
    номер = 0
    парные = {"-I", "-D", "-U", "-isystem", "-iquote", "-isysroot", "-target", "-resource-dir"}
    одиночные = {"-std=c++17", "-std=c++20", "-stdlib=libc++", "-pthread",
                "-fexceptions", "-fno-exceptions", "-frtti", "-fno-rtti"}
    while номер < len(аргументы):
        значение = аргументы[номер]
        if значение in парные:
            номер += 1
            if номер >= len(аргументы) or not аргументы[номер] or аргументы[номер].startswith(("-", "@")):
                raise ОшибкаРазбораСи("недопущенный аргумент компилятора: отсутствует явное значение")
        elif значение not in одиночные and not any(
            значение.startswith(префикс) and len(значение) > len(префикс)
            for префикс in ("-I", "-D", "-U", "-isystem", "-iquote")):
            raise ОшибкаРазбораСи(f"недопущенный аргумент компилятора: {значение}")
        номер += 1


def разобрать_объявления(файл, аргументы=(), корень=None):
    проверить_аргументы(аргументы)
    файл = Path(файл)
    корень = Path(корень if корень is not None else файл.parent).resolve()
    данные, признаки = снимок_исходника(файл)
    файл = файл.resolve()
    текст = данные.decode("utf-8")
    if re.search(r"(?m)^[ \t]*#[ \t]*(?:if|ifdef|ifndef|elif|else|endif)\b", текст):
        raise ОшибкаРазбораСи("условные ветки C++ ещё не поддержаны полным инвентарём")
    библиотека = загрузить_библиотеку()
    индекс = библиотека.clang_createIndex(0, 0)
    единица = ctypes.c_void_p()
    if not индекс:
        raise ОшибкаРазбораСи("libclang не создал индекс")
    параметры = ["-x", "c++", "-std=c++20", *аргументы]
    закодированные = [значение.encode("utf-8") for значение in параметры]
    массив = (ctypes.c_char_p * len(закодированные))(*закодированные)
    несохранённый = НесохранённыйФайлСи(str(файл).encode("utf-8"), данные, len(данные))
    найденные = []
    отказы = []
    try:
        код = библиотека.clang_parseTranslationUnit2(индекс, str(файл).encode("utf-8"),
            массив, len(массив), ctypes.byref(несохранённый), 1, 1, ctypes.byref(единица))
        if код != 0 or not единица.value:
            raise ОшибкаРазбораСи(f"libclang отказал в разборе C++: код {код}")
        for номер in range(библиотека.clang_getNumDiagnostics(единица)):
            диагностика = библиотека.clang_getDiagnostic(единица, номер)
            try:
                if библиотека.clang_getDiagnosticSeverity(диагностика) >= 3:
                    пояснение = прочитать_строку(библиотека,
                        библиотека.clang_formatDiagnostic(диагностика,
                            библиотека.clang_defaultDiagnosticDisplayOptions()))
                    raise ОшибкаРазбораСи(пояснение)
            finally:
                библиотека.clang_disposeDiagnostic(диагностика)

        основной = библиотека.clang_getFile(единица, str(файл).encode("utf-8"))
        if not основной:
            raise ОшибкаРазбораСи("libclang не подтвердил основной файл C++")

        @обратный_вызов_включений
        def проверить_включение(включённый, цепочка, число, контекст):
            try:
                имя = прочитать_строку(библиотека, библиотека.clang_getFileName(включённый))
                путь = Path(имя)
                физический = путь.resolve()
                if путь.is_relative_to(корень) or физический.is_relative_to(корень):
                    if any(часть.is_symlink() for часть in (путь, *путь.parents)):
                        raise ОшибкаРазбораСи("собственное включение C++ содержит символическую ссылку")
                    if физический.suffix.lower() not in {".cpp", ".cc", ".cxx", ".hpp", ".hh", ".hxx", ".h"}:
                        raise ОшибкаРазбораСи("собственное включение C++ имеет неподдержанный формат")
            except Exception as ошибка:
                отказы.append(ошибка)

        библиотека.clang_getInclusions(единица, проверить_включение, None)
        if отказы:
            raise ОшибкаРазбораСи(str(отказы[0])) from отказы[0]
        пропущенные = библиотека.clang_getSkippedRanges(единица, основной)
        if пропущенные:
            try:
                if пропущенные.contents.число:
                    raise ОшибкаРазбораСи("инвентарь C++ не принимает пропущенные препроцессором диапазоны")
            finally:
                библиотека.clang_disposeSourceRangeList(пропущенные)

        @обратный_вызов
        def посетить(курсор, родитель, контекст):
            try:
                место = библиотека.clang_getCursorLocation(курсор)
                написание = координаты(библиотека, место, библиотека.clang_getSpellingLocation)
                раскрытие = координаты(библиотека, место, библиотека.clang_getExpansionLocation)
                if написание[0] != файл and раскрытие[0] != файл:
                    return 2
                if курсор.вид in {501, 502}:
                    raise ОшибкаРазбораСи("собственные определения и раскрытия макросов пока не поддержаны")
                if курсор.вид == 201:
                    raise ОшибкаРазбораСи("метки переходов C++ пока не поддержаны инвентарём")
                if not библиотека.clang_isDeclaration(курсор.вид):
                    return 2
                имя = прочитать_строку(библиотека, библиотека.clang_getCursorSpelling(курсор))
                if not имя:
                    return 2
                if курсор.вид not in допущенные_виды:
                    raise ОшибкаРазбораСи(f"неподдержанный вид именованного объявления C++: {курсор.вид}")
                if написание != раскрытие or написание[0] != файл:
                    raise ОшибкаРазбораСи("происхождение объявления C++ неоднозначно")
                проверяемое_имя = имя.removeprefix("~") if курсор.вид == 25 else имя
                байты_имени = проверяемое_имя.encode("utf-8")
                смещение = написание[3] + (1 if курсор.вид == 25 else 0)
                if данные[смещение:смещение + len(байты_имени)] != байты_имени:
                    raise ОшибкаРазбораСи("имя C++ не совпадает с физическими байтами исходника")
                найденные.append((проверяемое_имя, написание[1], написание[2], str(курсор.вид)))
                return 2
            except Exception as ошибка:
                отказы.append(ошибка)
                return 0

        библиотека.clang_visitChildren(библиотека.clang_getTranslationUnitCursor(единица), посетить, None)
        if отказы:
            raise ОшибкаРазбораСи(str(отказы[0])) from отказы[0]
        итоговые_данные, итоговые_признаки = снимок_исходника(файл)
        if итоговые_данные != данные or итоговые_признаки != признаки:
            raise ОшибкаРазбораСи("исходник C++ изменился во время разбора")
        return найденные
    finally:
        if единица.value:
            библиотека.clang_disposeTranslationUnit(единица)
        библиотека.clang_disposeIndex(индекс)
