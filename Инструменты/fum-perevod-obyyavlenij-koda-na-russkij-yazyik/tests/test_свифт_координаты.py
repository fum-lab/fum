"""Координатная миграция конечного Swift-проекта сохраняет внешние контракты."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

сценарий = Path(__file__).resolve().parents[1] / 'scripts/перевести-объявления-кода.py'


class ПроверкиКоординат(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временный.cleanup)
        сам.корень = Path(сам.временный.name)
        сам.область = 'Проекты/ВиртуальнаяМашина'
        сам.тексты = {'тип.swift': 'struct Old { var argv = 1, envp = 2; func дать<T>(_ число: T) -> T { число } }\r\n',
                     'вызов.swift': 'let ёж = Old(); let строка = "Old argv" // envp\r\n'}
        сам.имена = {'Old': 'Прежний', 'argv': 'Аргументы', 'envp': 'Окружение', 'T': 'Значение'}
        сам.карта = {'версия_схемы': 2, 'адаптер': 'свифт-координаты.1', 'область': сам.область,
                     'файлы': [], 'символы': сам.имена, 'вхождения': [], 'контракты': []}
        for имя, текст in сам.тексты.items():
            путь = сам.область + '/' + имя
            файл = сам.корень / путь; файл.parent.mkdir(parents=True, exist_ok=True); файл.write_bytes(текст.encode())
            сам.карта['файлы'].append({'путь': путь, 'ожидаемый_хэш': 'sha256:' + hashlib.sha256(текст.encode()).hexdigest()})
            for совпадение in re.finditer(r'\b(?:Old|argv|envp|T)\b', текст):
                начало = len(текст[:совпадение.start()].encode())
                роль = 'объявление' if имя == 'тип.swift' and (совпадение.group() != 'T' or текст[совпадение.start()-1] == '<') else 'употребление'
                if имя == 'вызов.swift' and совпадение.start() > текст.index('"'): роль = 'буквальное'
                сам.карта['вхождения'].append({'путь': путь, 'начало': начало, 'конец': начало + len(совпадение.group().encode()),
                    'имя': совпадение.group(), 'роль': роль, 'основание': 'Проверенная открытая фикстура'})

    def вызвать(сам, команда, карта=None, отпечаток=None):
        путь = сам.корень / 'карта.json'; путь.write_text(json.dumps(карта or сам.карта, ensure_ascii=False))
        аргументы = [sys.executable, '-B', str(сценарий), команда, '--корень-репозитория', str(сам.корень), '--карта', str(путь)]
        if отпечаток: аргументы += ['--отпечаток-плана', отпечаток]
        return subprocess.run(аргументы, capture_output=True, text=True)

    def добавить_исходник(сам, имя, текст, символы, сохранять=()):
        путь = сам.область + '/' + имя
        файл = сам.корень / путь; файл.parent.mkdir(parents=True, exist_ok=True); файл.write_bytes(текст.encode())
        сам.карта['символы'].update(символы)
        сам.карта['файлы'].append({'путь': путь, 'ожидаемый_хэш': 'sha256:' + hashlib.sha256(текст.encode()).hexdigest()})
        for прежнее in символы:
            объявлен = False
            for совпадение in re.finditer(r'(?<!\w)' + re.escape(прежнее) + r'(?!\w)', текст):
                роль = 'внешнее' if совпадение.start() in сохранять else 'употребление' if объявлен else 'объявление'
                if роль == 'объявление': объявлен = True
                сам.карта['вхождения'].append({'путь': путь, 'начало': len(текст[:совпадение.start()].encode()),
                    'конец': len(текст[:совпадение.end()].encode()), 'имя': прежнее, 'роль': роль, 'основание': 'Внешний label либо собственное поле открытой фикстуры'})

    def test_ключ_внешнего_формата_и_метка_стандартной_библиотеки_сохраняются(сам):
        текст = 'struct Сведения: Decodable {\n var format: String\n enum CodingKeys: String, CodingKey { case format, размер = "virtual-size" }\n}\nlet число = сведения.format\nlet строка = String(format: "%02x", 1)\n'
        сам.добавить_исходник('Sources/ЯдроМашины/ПодготовкаUbuntu.swift', текст, {'format': 'форматОбраза'}, [текст.index('format:', текст.index('String('))])
        сам.карта['контракты'] = ['сохранить-ключ-формата']
        результат = сам.вызвать('план'); сам.assertEqual(результат.returncode, 0, результат.stderr)
        результат = сам.вызвать('применить', отпечаток=json.loads(результат.stdout)['отпечаток_плана'])
        сам.assertEqual(результат.returncode, 0, результат.stderr)
        итог = (сам.корень / сам.область / 'Sources/ЯдроМашины/ПодготовкаUbuntu.swift').read_text()
        сам.assertIn('case форматОбраза = "format", размер = "virtual-size"', итог)
        сам.assertIn('String(format: "%02x", 1)', итог)
        сам.assertIn('сведения.форматОбраза', итог)

    def test_полный_набор_ключей_запуска_фиксируется_без_смены_контракта(сам):
        текст = '''public struct ЗапускМашины: Codable {
    public var схема = "fum.запуск-машины.1"
    public var машина: String
    public var план: String
    public var запуск: String
    public var токен: String
    public var портSSH: UInt16
    public var портУправления: UInt16
    public var фаза: String
    public var причина: String?
    public init() {}
}
'''
        сам.добавить_исходник('Sources/ЯдроМашины/Управление.swift', текст, {'портSSH': 'портДоступаКГостю'})
        сам.карта['контракты'] = ['сохранить-ключи-запуска']
        результат = сам.вызвать('план'); сам.assertEqual(результат.returncode, 0, результат.stderr)
        результат = сам.вызвать('применить', отпечаток=json.loads(результат.stdout)['отпечаток_плана'])
        сам.assertEqual(результат.returncode, 0, результат.stderr)
        итог = (сам.корень / сам.область / 'Sources/ЯдроМашины/Управление.swift').read_text()
        сам.assertIn('case портДоступаКГостю = "портSSH"', итог)
        for имя in ['схема', 'машина', 'план', 'запуск', 'токен', 'портУправления', 'фаза', 'причина']:
            сам.assertIn('case ' + имя + ' = "' + имя + '"', итог)

    def test_интерполяция_не_разрешает_запись(сам):
        сам.добавить_исходник('строка.swift', 'let value = 1; let строка = "\\(value)"\n', {'value': 'значение'})
        сам.assertNotEqual(сам.вызвать('план').returncode, 0)

    def test_символическая_ссылка_не_разрешает_запись(сам):
        файл = сам.корень / сам.область / 'тип.swift'; файл.unlink(); файл.symlink_to('/неизвестная-фикстура')
        результат = сам.вызвать('план')
        сам.assertNotEqual(результат.returncode, 0)
        сам.assertIn('символическая ссылка', результат.stderr)

    def test_ошибка_обхода_не_скрывает_поддерево(сам):
        описание = importlib.util.spec_from_file_location('координаты', сценарий.parent / 'свифт_по_координатам.py')
        модуль = importlib.util.module_from_spec(описание)
        описание.loader.exec_module(модуль)
        def отказ(*аргументы, **параметры):
            параметры['onerror'](PermissionError('Недоступное поддерево'))
            return iter(())
        with mock.patch.object(модуль.os, 'walk', side_effect=отказ):
            with сам.assertRaisesRegex(PermissionError, 'Недоступное поддерево'):
                модуль.прочитать_область(сам.корень, сам.область)

    def test_заявленный_контракт_без_изменяемого_исходника_отклоняется(сам):
        сам.добавить_исходник('Sources/ЯдроМашины/ПодготовкаUbuntu.swift', 'struct Сведения {}\n', {})
        сам.карта['контракты'] = ['сохранить-ключ-формата']
        результат = сам.вызвать('план')
        сам.assertNotEqual(результат.returncode, 0)
        сам.assertIn('не выполнена ровно один раз', результат.stderr)

    def test_переименование_поля_не_обходит_обязательный_ключ(сам):
        сам.добавить_исходник('Sources/ЯдроМашины/ПодготовкаUbuntu.swift',
            'struct Сведения: Decodable { var format: String; enum CodingKeys: String, CodingKey { case format, размер = "virtual-size" } }',
            {'format': 'форматОбраза'})
        сам.assertNotEqual(сам.вызвать('план').returncode, 0)

    def test_шаблон_кодирования_в_комментарии_не_является_контрактом(сам):
        сам.добавить_исходник('Sources/ЯдроМашины/ПодготовкаUbuntu.swift',
            'struct Сведения: Decodable { var format: String }\n// enum CodingKeys: String, CodingKey { case форматОбраза, размер = "virtual-size" }\n',
            {'format': 'форматОбраза'})
        сам.карта['контракты'] = ['сохранить-ключ-формата']
        сам.assertNotEqual(сам.вызвать('план').returncode, 0)

    def test_ссылочный_файл_обобщение_и_второе_объявление_переводятся(сам):
        результат = сам.вызвать('план'); сам.assertEqual(результат.returncode, 0, результат.stderr)
        план = json.loads(результат.stdout)
        сам.assertEqual((сам.корень / сам.область / 'тип.swift').read_bytes(), сам.тексты['тип.swift'].encode())
        результат = сам.вызвать('применить', отпечаток=план['отпечаток_плана'])
        сам.assertEqual(результат.returncode, 0, результат.stderr)
        сам.assertEqual((сам.корень / сам.область / 'тип.swift').read_bytes(),
            'struct Прежний { var Аргументы = 1, Окружение = 2; func дать<Значение>(_ число: Значение) -> Значение { число } }\r\n'.encode())
        сам.assertEqual((сам.корень / сам.область / 'вызов.swift').read_bytes(),
            'let ёж = Прежний(); let строка = "Old argv" // envp\r\n'.encode())

    def test_нельзя_пропустить_вхождение_или_объявление(сам):
        for номер in (0, len(сам.карта['вхождения']) - 1):
            карта = copy.deepcopy(сам.карта); del карта['вхождения'][номер]
            сам.assertNotEqual(сам.вызвать('план', карта).returncode, 0)

    def test_строка_не_становится_кодом_от_пометки_карты(сам):
        карта = copy.deepcopy(сам.карта); карта['вхождения'][-1]['роль'] = 'употребление'
        сам.assertNotEqual(сам.вызвать('применить', карта, 'sha256:' + '0'*64).returncode, 0)
        сам.assertEqual((сам.корень / сам.область / 'тип.swift').read_bytes(), сам.тексты['тип.swift'].encode())

    def test_неверные_байтовые_координаты_и_коллизия_отклоняются(сам):
        for значение in (True, -1, 1):
            карта = copy.deepcopy(сам.карта); карта['вхождения'][0]['начало'] = значение
            сам.assertNotEqual(сам.вызвать('план', карта).returncode, 0)
        карта = copy.deepcopy(сам.карта); карта['символы']['Old'] = 'число'
        сам.assertNotEqual(сам.вызвать('план', карта).returncode, 0)

    def test_новый_файл_подмена_и_сдвиг_плана_останавливают_запись(сам):
        результат = сам.вызвать('план'); сам.assertEqual(результат.returncode, 0, результат.stderr)
        отпечаток = json.loads(результат.stdout)['отпечаток_плана']
        файл = сам.корень / сам.область / 'новый.swift'; файл.write_text('let новый = 1')
        сам.assertNotEqual(сам.вызвать('применить', отпечаток=отпечаток).returncode, 0)
        файл.unlink()
        сам.assertNotEqual(сам.вызвать('применить', отпечаток='sha256:' + '0'*64).returncode, 0)
        исходный = сам.корень / сам.область / 'тип.swift'; исходный.write_bytes(исходный.read_bytes() + b'\n')
        сам.assertNotEqual(сам.вызвать('применить', отпечаток=отпечаток).returncode, 0)


if __name__ == '__main__': unittest.main()
