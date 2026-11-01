"""Настоящие новые процессы: служебный exec не разрешает проектную генерацию."""
from pathlib import Path
import unittest

import test_поздней_привязки_журнала as основа


class СлужебноеИсполнение(unittest.TestCase):
    def setUp(сам):
        сам.ф = основа.ИсполнениеПринятогоКода('runTest')
        сам.ф.setUp()
        сам.addCleanup(сам.ф.doCleanups)

    def test_настоящий_dataclass_после_установки_hooks(сам):
        сам.ф.сценарий('from dataclasses import dataclass\n@dataclass(frozen=True)\nclass Значение:\n    текст: str\nassert Значение("ё").текст == "ё"\n')
        сам.ф.запуск(подготовка='import dataclasses\n')

    def test_пять_настоящих_dataclass_каркаса_из_принятых_байтов(сам):
        путь = 'Инструменты/fum-struktura-papok-zaprosov/scripts/request_folder_layout.py'
        корень = Path(__file__).resolve().parents[3]
        сам.ф.сценарий('import request_folder_layout as к\nfrom dataclasses import fields\nassert [len(fields(getattr(к, n))) for n in ("Move","ProvenLinkRepair","PreparedFile","PathSnapshot","IndexSection")] == [2,3,3,3,4]\nа=к.Move(к.PurePosixPath("а"), к.PurePosixPath("б"))\nassert а.source.as_posix() == "а" and "source" in repr(а) and hash(а)==hash(а)\n')
        цель = сам.ф.дерево_принятого_кода / путь
        цель.parent.mkdir(parents=True)
        цель.write_bytes((корень / путь).read_bytes())
        сам.ф.вызвать_гит('add', '.')
        сам.ф.вызвать_гит('commit', '-qm', 'Принятый каркас')
        сам.ф.принятый_коммит = сам.ф.вызвать_гит('rev-parse', 'HEAD').strip()
        сам.ф.запуск(пути=['main.py', путь], имена={'request_folder_layout': путь})

    def test_проектный_exec_после_preload_отвергается_до_эффекта(сам):
        сам.ф.сценарий('exec("raise RuntimeError(\'эффект\')")\n')
        р = сам.ф.запуск(подготовка='import dataclasses,runpy\n', ожидается=1)
        сам.assertNotIn('RuntimeError: эффект', р.stderr)

    def test_spoof_динамического_filename_не_даёт_допуск(сам):
        for имя in ('<string>', '<unknown>'):
            with сам.subTest(имя=имя):
                сам.ф.сценарий(f'exec(compile("pass",{имя!r},"exec"))\n')
                сам.ф.запуск(подготовка='import dataclasses\n', ожидается=1)

    def test_trusted_runpy_без_native_pending_не_исполняет_чужой_код(сам):
        сам.ф.сценарий('import runpy\nrunpy._run_code(чужой_код,{})\n')
        for замена in ('', '.replace(co_consts=("изменено",None))'):
            with сам.subTest(замена=замена):
                р = сам.ф.запуск(подготовка='import runpy\ns.глобальные["чужой_код"]=compile("pass","<string>","exec")'+замена+'\n', ожидается=1)
                сам.assertIn('exec непривязанного', р.stderr)

    def test_чужой_audit_compile_во_время_verification_не_обходится(сам):
        сам.ф.сценарий('from dataclasses import dataclass\n@dataclass\nclass А:\n    x: int\n')
        подготовка = '''import sys
def вмешательство(событие, аргументы):
    if событие == 'compile' and any(к.f_code.co_name == '_проверить_native' for к in стек()):
        compile('pass', '<unknown>', 'exec')
def стек():
    к = sys._getframe(1)
    while к:
        yield к
        к = к.f_back
sys.addaudithook(вмешательство)
'''
        сам.ф.запуск(подготовка=подготовка, ожидается=1)

    def test_unicode_cookie_не_переинтерпретируется_как_bytes(сам):
        сам.ф.сценарий('import dataclasses\nclass А: pass\nб = dataclasses._FuncBuilder(globals())\nб.src = [" # coding: latin-1\\n def значение():\\n  return \'ё\'"]\nб.names=["значение"]\nб.add_fns_to_class(А)\nassert А.значение() == "ё"\n')
        сам.ф.запуск()

    def test_поддельный_stdlib_filename_функции_не_даёт_native_роль(сам):
        сам.ф.сценарий('поддельная()\n')
        сам.ф.запуск(подготовка='import dataclasses,types\nc=compile("def f():\\n exec(\\\"pass\\\")\\n","непринятый","exec");g={};exec(c,g)\ns.глобальные["поддельная"]=types.FunctionType(g["f"].__code__.replace(co_filename=dataclasses.__file__),{})\n', ожидается=1)

    def test_поддельный_кадр_движка_не_скрывается_под_pinned_кадром(сам):
        сам.ф.сценарий('from dataclasses import dataclass\n@dataclass\nclass А:\n x: int\n')
        подготовка = r'''import dataclasses,types
g={}
exec(compile('def подмена(*a):\n exec("raise RuntimeError(\\\"эффект\\\")")\n','непринятый','exec'),g)
dataclasses.exec=types.FunctionType(g['подмена'].__code__.replace(co_filename=путь_загрузчика),{})
'''
        р = сам.ф.запуск(подготовка=подготовка, ожидается=1)
        сам.assertNotIn('RuntimeError: эффект', р.stderr)

    def test_future_annotations_и_параллельные_кадры_не_смешиваются(сам):
        сам.ф.сценарий('from __future__ import annotations\nfrom dataclasses import dataclass\nimport threading\nошибки=[]\nзначения=[]\ndef выполнить():\n try:\n  for _ in range(8):\n   @dataclass(frozen=True)\n   class Значение:\n    x: int\n   значения.append(Значение(1).x)\n except BaseException as е:\n  ошибки.append(е)\nпотоки=[threading.Thread(target=выполнить) for _ in range(4)]\nfor п in потоки: п.start()\nfor п in потоки: п.join()\nassert not ошибки, repr(ошибки)\nassert значения == [1]*32\n')
        сам.ф.запуск()

    def test_native_code_не_получает_повторный_допуск(сам):
        сам.ф.сценарий('from dataclasses import dataclass\n@dataclass\nclass А:\n x: int\nexec(пойманный[0])\n')
        подготовка='import sys,dataclasses\nпойманный=[]\ns.глобальные["пойманный"]=пойманный\ndef поймать(е,а):\n if е=="exec" and а[0].co_filename=="<string>": пойманный.append(а[0])\nsys.addaudithook(поймать)\n'
        сам.ф.запуск(подготовка=подготовка, ожидается=1)


if __name__ == '__main__':
    unittest.main()
