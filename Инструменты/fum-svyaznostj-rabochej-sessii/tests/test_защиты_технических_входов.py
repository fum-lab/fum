"""Регрессии двух наблюдённых ошибок частной композиции ROOT."""
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import защита_технических_входов as защита


class ЗащитаТехническихВходов(unittest.TestCase):
    def test_интерпретатор_существует_и_исполняем_до_процесса(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            сценарий = корень / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-продолжение-задачи.py'
            сценарий.parent.mkdir(parents=True); сценарий.write_bytes(b'pass\n')
            исходник = корень / 'нативный.jsonl'; исходник.write_bytes(b'{}\n')
            кэш = корень / 'кэш.json'; кэш.write_bytes(b'{}\n')
            неисполняемый = корень / 'неисполняемый'; неисполняемый.write_bytes(b'pass\n'); неисполняемый.chmod(0o600)
            параметры = {'задача': '00000000-0000-0000-0000-000000000001',
                'исходник': исходник, 'кэш': кэш}
            сам.assertEqual(sys.executable, защита.команда_продолжения(
                корень, sys.executable, **параметры)[0])
            for интерпретатор in (str(корень / 'нет'), str(неисполняемый), 'python'):
                with сам.subTest(интерпретатор=интерпретатор), сам.assertRaises(ValueError):
                    защита.команда_продолжения(корень, интерпретатор, **параметры)

    def test_снимок_штатного_API_на_настоящей_открытой_паре(сам):
        import test_первой_подготовки_открытого_этапа as открытый
        import test_создание_коммита as база
        from test_план_начала import снимок as снимок_файлов
        помощник = открытый.ПерваяПодготовкаОткрытогоЭтапа()
        сам.addCleanup(помощник.doCleanups)
        _, рабочий, вход, _, _, _ = помощник.открытый_стенд()
        import установка_принятого_состава_журнала as установщик
        план = json.loads(Path(вход['контракт_журнала']).read_bytes())['открытая']
        до = снимок_файлов(рабочий.ф.каталог)
        with mock.patch.dict(os.environ, CODEX_THREAD_ID=база.ЗАДАЧА):
            значение = установщик.снять_открытую_пару(рабочий.ф.корень, план)
            сам.assertEqual(значение, защита.проверить_снимок_открытой_пары(значение))
        сам.assertEqual(до, снимок_файлов(рабочий.ф.каталог))

    def test_штатный_снимок_сохраняется_а_двойная_обёртка_отказывает(сам):
        снимок = {'план': {'журнал': 'собственная-пара'}, 'файлы': [
            {'путь': 'Журнал/собственная-пара/запрос.md', 'тип': 'файл',
                'режим': 0o644, 'sha256': 'a' * 64}]}
        до = copy.deepcopy(снимок)
        сам.assertEqual(снимок, защита.проверить_снимок_открытой_пары(снимок))
        сам.assertEqual(до, снимок)
        двойной = {'план': снимок['план'], 'файлы': снимок}
        with сам.assertRaises(ValueError):
            защита.проверить_снимок_открытой_пары(двойной)

    def test_команда_передаёт_явный_кэш_и_не_меняет_код_guard(сам):
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            сценарий = корень / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-продолжение-задачи.py'
            сценарий.parent.mkdir(parents=True)
            сценарий.write_text('import json,sys;print(json.dumps(sys.argv[1:]));print("профиль",file=sys.stderr);raise SystemExit(3)\n')
            исходник = корень / 'нативный.jsonl'; исходник.write_bytes(b'{}\n')
            кэш = корень / 'кэш.json'; кэш.write_bytes(b'{}\n')
            до = {п: п.read_bytes() for п in (сценарий, исходник, кэш)}
            команда = защита.команда_продолжения(корень, sys.executable,
                задача='00000000-0000-0000-0000-000000000001',
                исходник=исходник, кэш=кэш, профиль=True)
            процесс = subprocess.run(команда, capture_output=True, cwd=корень)
            сам.assertEqual(3, процесс.returncode)
            сам.assertEqual('профиль\n'.encode(), процесс.stderr)
            аргументы = json.loads(процесс.stdout)
            сам.assertIn('--кэш', аргументы)
            сам.assertEqual(str(кэш), аргументы[аргументы.index('--кэш') + 1])
            сам.assertIn('--перед-завершением', аргументы)
            сам.assertIn('--профиль', аргументы)
            сам.assertEqual(до, {п: п.read_bytes() for п in до})

    def test_пропущенный_или_пустой_кэш_отказывает_до_процесса(сам):
        with сам.assertRaises(TypeError):
            защита.команда_продолжения(Path.cwd(), sys.executable,
                задача='00000000-0000-0000-0000-000000000001', исходник=Path(__file__).resolve())
        with tempfile.TemporaryDirectory() as временный:
            корень = Path(временный).resolve()
            сценарий = корень / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/проверить-продолжение-задачи.py'
            сценарий.parent.mkdir(parents=True); сценарий.write_bytes(b'pass\n')
            исходник = корень / 'нативный.jsonl'; исходник.write_bytes(b'{}\n')
            for кэш in (None, '', Path('относительный-кэш')):
                with сам.subTest(кэш=кэш), сам.assertRaisesRegex(ValueError, 'файл входа'):
                    защита.команда_продолжения(корень, sys.executable,
                        задача='00000000-0000-0000-0000-000000000001',
                        исходник=исходник, кэш=кэш)
