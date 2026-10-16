"""Два точных компонента потока; побитовый синтаксис не скрывает объявлений."""
from pathlib import Path
import json
import os
import tempfile
import unittest
from unittest import mock

from test_сценарий_ответа import модуль, учёт

КОРЕНЬ = Path(__file__).resolve().parents[3]
ПУТИ = ('Инструменты/fum-svyaznostj-rabochej-sessii/scripts/мост_полного_ответа_узла.cjs',
        'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/хэш_полного_ответа_узла.cjs')
МОСТ = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/мост_живого_восстановления_писателя.cjs'
ХОСТ = 'Инструменты/fum-svyaznostj-rabochej-sessii/tests/test_живое_восстановление_писателя.py'
МЕТОДЫ = ('test_полный_мост_порции_подтверждение_повтор_и_крах',
          'test_мост_отклоняет_раннюю_отправку_и_повтор_фазы')


def хост(первый='const old = 1; old();', второй='function old() {return "old";} old();', перевод='\n'):
    строки = ['# ё🙂 — позиции Python и JS различаются', 'class ПроверкиФиксированногоМоста:']
    for метод, тело in zip(МЕТОДЫ, (первый, второй)):
        строки += ['    def ' + метод + '(сам):', "        код = r'''", тело, "'''", '        return код']
    строки += ['    def test_посторонний(сам):', "        код = r'''const old = 777;'''", '        return код', '']
    return перевод.join(строки)


def подготовить(корень, исходники, переводы):
    записи = []
    for имя, текст in исходники.items():
        файл = корень / имя
        файл.parent.mkdir(parents=True, exist_ok=True)
        файл.write_bytes(текст.encode('utf-8'))
        записи.append({'путь': имя, 'ожидаемый_хэш': учёт.вычислить_хэш(файл.read_bytes()),
                       'переименования': переводы[имя]})
    карта = корень / 'карта.json'
    карта.write_text(json.dumps({'версия_схемы': 1, 'файлы': записи}, ensure_ascii=False), encoding='utf-8')
    return учёт.прочитать_карту(карта)


class ПолныйСценарий(unittest.TestCase):
    def test_живой_мост_учитывает_продолжение_и_не_открывает_соседей(сам):
        текст = 'while (true) { let first = 1; if (++first > 2) continue; const second = 2; }'
        сам.assertEqual({'first', 'second'}, {э.имя for э in учёт.объявления_сценария(текст, МОСТ)})
        for сосед in (МОСТ.upper(), 'вложено/' + МОСТ, МОСТ.replace('мост_', 'сосед_')):
            with сам.subTest(сосед=сосед), сам.assertRaises(учёт.ОшибкаКонтракта):
                учёт.объявления_сценария(текст, сосед)
        for неверный in ('while(true){continue метка;}', 'continue;', 'while(true){continue extra();}'):
            with сам.subTest(неверный=неверный), сам.assertRaises(учёт.ОшибкаКонтракта):
                учёт.объявления_сценария(неверный, МОСТ)

    def test_две_вставки_переводятся_с_точными_байтами_и_прежней_схемой(сам):
        for перевод in ('\n', '\r\n'):
            исходный = хост('/* ё🙂 */ const old = 1; old(); // old ё🙂\\n',
                            'function old() {return "old\\u0003";} old();', перевод)
            ожидаемый = исходный.replace('const old = 1; old();', 'const новое = 1; новое();').replace(
                'function old()', 'function новое()').replace(';} old();', ';} новое();')
            with сам.subTest(перевод=repr(перевод)), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                карта = подготовить(корень, {ХОСТ: исходный}, {ХОСТ: {'old': 'новое'}})
                изменения = учёт.подготовить_изменения(корень, карта)
                сам.assertEqual(ожидаемый.encode(), изменения[0].новый_текст.encode())
                план = учёт.описание_плана(изменения, 'план')
                сам.assertEqual(1, план['версия_схемы'])
                сам.assertEqual(исходный.encode(), (корень / ХОСТ).read_bytes())
                учёт.атомарно_применить(изменения)
                сам.assertEqual(ожидаемый.encode(), (корень / ХОСТ).read_bytes())

    def test_неоднозначный_локатор_и_склейка_закрывают_весь_план(сам):
        исходный = хост()
        варианты = [исходный.replace(МЕТОДЫ[1], 'test_соседний'),
            исходный.replace('код = r', 'код = другой = r', 1),
            исходный.replace("код = r'''", "код = f'''", 1),
            исходный.replace("код = r'''", "код = r'' r'''", 1),
            исходный.replace("код = r'''", "код: str = r'''", 1),
            исходный.replace("код = r'''", "код = '''", 1),
            исходный.replace("код = r'''", "код = rb'''", 1),
            исходный.replace('        return код', '        код = 1\n        return код', 1),
            исходный.replace('        код =', '        if True:\n            код =', 1),
            исходный.replace('        код =', '        def вложенная():\n            код =', 1),
            исходный.replace(МЕТОДЫ[1], МЕТОДЫ[0]),
            исходный + исходный]
        for текст in варианты:
            with сам.subTest(текст=текст[:90]), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                карта = подготовить(корень, {ХОСТ: текст}, {ХОСТ: {'old': 'новое'}})
                with сам.assertRaises(учёт.ОшибкаКонтракта):
                    учёт.подготовить_изменения(корень, карта)
                сам.assertEqual(текст.encode(), (корень / ХОСТ).read_bytes())

    def test_соседний_хост_не_переводит_строки_и_совпавшие_тела_различаются(сам):
        for путь in (ХОСТ.upper(), 'вложено/' + ХОСТ, ХОСТ.replace('писателя.py', 'соседа.py')):
            with сам.subTest(путь=путь), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                карта = подготовить(корень, {путь: хост()}, {путь: {'old': 'новое'}})
                with сам.assertRaises(учёт.ОшибкаКонтракта):
                    учёт.подготовить_изменения(корень, карта)
                сам.assertEqual(хост().encode(), (корень / путь).read_bytes())
        исходный = хост(второй='const old = 1; old();')
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            карта = подготовить(корень, {ХОСТ: исходный}, {ХОСТ: {'old': 'новое'}})
            итог = учёт.подготовить_изменения(корень, карта)[0].новый_текст
            сам.assertEqual(исходный.replace('const old = 1; old();', 'const новое = 1; новое();'), итог)

    def test_объявление_одной_вставки_не_переименовывает_глобал_другой(сам):
        исходный = хост('function ф(Buffer) {return Buffer;}', 'Buffer.from("данные");')
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            карта = подготовить(корень, {ХОСТ: исходный}, {ХОСТ: {'Buffer': 'буфер'}})
            итог = учёт.подготовить_изменения(корень, карта)[0].новый_текст
            сам.assertEqual(исходный.replace('ф(Buffer) {return Buffer;', 'ф(буфер) {return буфер;'), итог)

    def test_свободное_имя_внутри_сегмента_закрывает_весь_план(сам):
        смешанный = 'function ф(Buffer){return Buffer;} Buffer.from("данные");'
        for путь, текст in ((МОСТ, смешанный), (ХОСТ, хост(первый=смешанный)),
                            (ХОСТ, хост(второй=смешанный))):
            with сам.subTest(путь=путь, текст=текст), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                карта = подготовить(корень, {путь: текст}, {путь: {'Buffer': 'буфер'}})
                with сам.assertRaisesRegex(учёт.ОшибкаКонтракта, 'свобод|область'):
                    учёт.подготовить_изменения(корень, карта)
                сам.assertEqual(текст.encode(), (корень / путь).read_bytes())

    def test_локальные_области_не_прикрывают_свободное_имя(сам):
        варианты = (
            'const ф = Buffer => Buffer; Buffer.from("x");',
            'const ф = (Buffer = 1) => {return Buffer;}; Buffer.from("x");',
            '{let Buffer = 1; Buffer;} Buffer.from("x");',
            '{const Buffer = 1; Buffer;} Buffer.from("x");',
            'try {throw 1;} catch (Buffer) {Buffer;} Buffer.from("x");',
            'try {throw 1;} catch ({message: Buffer}) {Buffer;} Buffer.from("x");',
            'for (let Buffer = 0; Buffer < 1; ++Buffer) {Buffer;} Buffer.from("x");',
            'for (const Buffer of список) {Buffer;} Buffer.from("x");',
            'const ф = function Buffer(){return Buffer;}; Buffer.from("x");',
            'function ф(п = Buffer.from("x")){const Buffer=1;return Buffer;}',
            'function ф(){const Buffer=1;return ()=>Buffer;} function г(){return Buffer;}',
            'function ф(Buffer){return Buffer;} const объект={...{},Buffer};',
            'function ф(Buffer){return Buffer;} Buffer=1;',
            'function ф(Buffer){return Buffer;} ++Buffer;',
        )
        for текст in варианты:
            for путь, исходный in ((МОСТ, текст), (ХОСТ, хост(первый=текст)),
                                   (ХОСТ, хост(второй=текст))):
                with сам.subTest(путь=путь, текст=текст), tempfile.TemporaryDirectory() as каталог:
                    корень = Path(каталог)
                    карта = подготовить(корень, {путь: исходный}, {путь: {'Buffer': 'буфер'}})
                    with сам.assertRaisesRegex(учёт.ОшибкаКонтракта, 'Свободное имя'):
                        учёт.подготовить_изменения(корень, карта)
                    сам.assertEqual(исходный.encode(), (корень / путь).read_bytes())

    def test_доказанные_области_переводятся_с_сохранением_ролей(сам):
        варианты = (
            ('function ф(Buffer){return ()=>Buffer;}',
             'function ф(буфер){return ()=>буфер;}'),
            ('function ф(Buffer,п=Buffer){return Buffer;}',
             'function ф(буфер,п=буфер){return буфер;}'),
            ('const ф=Buffer=>Buffer; const г=(Buffer=1)=>{return Buffer;};',
             'const ф=буфер=>буфер; const г=(буфер=1)=>{return буфер;};'),
            ('const ф=function Buffer(){return ()=>Buffer;};',
             'const ф=function буфер(){return ()=>буфер;};'),
            ('Buffer(); function Buffer(){return 1;}',
             'буфер(); function буфер(){return 1;}'),
            ('function ф(){Buffer;let Buffer=1;return Buffer;}',
             'function ф(){буфер;let буфер=1;return буфер;}'),
            ('function ф(Buffer){return {Buffer};}',
             'function ф(буфер){return {Buffer:буфер};}'),
            ('function ф({ключ:Buffer=1}){return объект.Buffer+объект?.Buffer+Buffer;}',
             'function ф({ключ:буфер=1}){return объект.Buffer+объект?.Buffer+буфер;}'),
            ('const {Buffer:значение}=источник; function ф(Buffer){return Buffer;}',
             'const {Buffer:значение}=источник; function ф(буфер){return буфер;}'),
            ('try {throw 1;} catch(Buffer){const ф=()=>Buffer;} ',
             'try {throw 1;} catch(буфер){const ф=()=>буфер;} '),
            ('for(let Buffer=0;Buffer<1;++Buffer){const ф=()=>Buffer;}',
             'for(let буфер=0;буфер<1;++буфер){const ф=()=>буфер;}'),
            ('for(const Buffer of список){const ф=()=>Buffer;}',
             'for(const буфер of список){const ф=()=>буфер;}'),
        )
        for текст, ожидаемый in варианты:
            with сам.subTest(текст=текст):
                новый, _, _ = учёт.замены_сценария(текст, {'Buffer': 'буфер'}, живой=True)
                сам.assertEqual(ожидаемый, новый)

    def test_особые_имена_и_неизвестная_роль_закрывают_перевод(сам):
        for имя in ('arguments', 'undefined'):
            with сам.subTest(имя=имя), сам.assertRaisesRegex(учёт.ОшибкаКонтракта, 'Особая область'):
                учёт.замены_сценария('function ф(' + имя + '){return ' + имя + ';}',
                                    {имя: 'значение'}, живой=True)
        with mock.patch.object(модуль.Разбор, 'прочитать', return_value=None):
            with сам.assertRaisesRegex(учёт.ОшибкаКонтракта, 'роль токена'):
                учёт.замены_сценария('const Buffer=1;Buffer;', {'Buffer': 'буфер'}, живой=True)

    def test_особый_сокращённый_ключ_не_становится_установкой_прототипа(сам):
        текст = 'const __proto__={значение:1};const объект={__proto__};'
        for путь, исходный in ((МОСТ, текст), (ХОСТ, хост(первый=текст)),
                               (ХОСТ, хост(второй=текст))):
            with сам.subTest(путь=путь), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                карта = подготовить(корень, {путь: исходный}, {путь: {'__proto__': 'прототип'}})
                with сам.assertRaisesRegex(учёт.ОшибкаКонтракта, 'прототип'):
                    учёт.подготовить_изменения(корень, карта)
                сам.assertEqual(исходный.encode(), (корень / путь).read_bytes())
        новый, _, _ = учёт.замены_сценария('const {__proto__}=источник;__proto__;',
                                        {'__proto__': 'прототип'}, живой=True)
        сам.assertEqual('const {__proto__:прототип}=источник;прототип;', новый)

    def test_отказ_позднего_сегмента_не_пишет_ни_одну_цель(сам):
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            исходники = {МОСТ: 'const Buffer=1;Buffer;',
                         ХОСТ: хост(второй='function ф(Buffer){return Buffer;} Buffer.from("x");')}
            карта = подготовить(корень, исходники, {п: {'Buffer': 'буфер'} for п in исходники})
            def снимок():
                результат = {}
                for путь in исходники:
                    файл = корень / путь; сведения = файл.stat()
                    результат[путь] = (файл.read_bytes(), сведения.st_mode,
                                       сведения.st_mtime_ns, сведения.st_ino)
                return результат
            прежде = снимок()
            with сам.assertRaisesRegex(учёт.ОшибкаКонтракта, 'Свободное имя'):
                учёт.атомарно_применить(учёт.подготовить_изменения(корень, карта))
            сам.assertEqual(прежде, снимок())

    def test_прямое_вычисление_не_скрывает_употребление_в_строке(сам):
        варианты = (
            'function ф(){const value=1;return eval("value");}',
            'function ф(){const value=1;return ((eval)) /* ё */\r\n("value");}',
            'function ф(){const value=1;return eval("val"+"ue");}',
            'function ф(){const value=1;return eval(...список);}',
            'function ф(eval,value){return eval("value")+value;}',
            'function ф(){eval("value");} const value=1;value;',
        )
        for текст in варианты:
            for путь, исходный in ((МОСТ, текст), (ХОСТ, хост(первый=текст)),
                                   (ХОСТ, хост(второй=текст))):
                with сам.subTest(путь=путь, текст=текст), tempfile.TemporaryDirectory() as каталог:
                    корень = Path(каталог)
                    карта = подготовить(корень, {путь: исходный}, {путь: {'value': 'значение'}})
                    with сам.assertRaisesRegex(учёт.ОшибкаКонтракта, 'eval'):
                        учёт.подготовить_изменения(корень, карта)
                    сам.assertEqual(исходный.encode(), (корень / путь).read_bytes())

    def test_непрямой_и_неизменяемый_вызов_не_расширяет_отказ(сам):
        текст = 'function ф(value){return объект.eval("value")+eval.call(null,"value")+value;}'
        ожидаемый = 'function ф(значение){return объект.eval("value")+eval.call(null,"value")+значение;}'
        новый, _, _ = учёт.замены_сценария(текст, {'value': 'значение'}, живой=True)
        сам.assertEqual(ожидаемый, новый)
        исходный = хост('function ф(value){return value;}', 'eval("value");')
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            карта = подготовить(корень, {ХОСТ: исходный}, {ХОСТ: {'value': 'значение'}})
            итог = учёт.подготовить_изменения(корень, карта)[0].новый_текст
            сам.assertEqual(исходный.replace('ф(value){return value;', 'ф(значение){return значение;'), итог)

    def test_невыбранная_строка_и_повреждённая_вторая_не_получают_перевод(сам):
        for текст, имя in ((хост().replace('old = 777', 'thirdOnly = 777'), 'thirdOnly'),
                           (хост(второй='class Unknown {}'), 'old')):
            with сам.subTest(имя=имя), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог)
                карта = подготовить(корень, {ХОСТ: текст}, {ХОСТ: {имя: 'новое'}})
                with сам.assertRaises(учёт.ОшибкаКонтракта):
                    учёт.подготовить_изменения(корень, карта)
                сам.assertEqual(текст.encode(), (корень / ХОСТ).read_bytes())

    def test_локальная_переменная_сохраняет_ключ_сокращённого_результата(сам):
        исходный = 'let output = "output"; const r = инструмент(); const ответ = {...r,output};'
        ожидаемый = 'let вывод = "output"; const r = инструмент(); const ответ = {...r,output:вывод};'
        with tempfile.TemporaryDirectory() as каталог:
            корень = Path(каталог)
            карта = подготовить(корень, {МОСТ: исходный}, {МОСТ: {'output': 'вывод'}})
            изменения = учёт.подготовить_изменения(корень, карта)
            сам.assertEqual(ожидаемый, изменения[0].новый_текст)
            сам.assertEqual(исходный.encode(), (корень / МОСТ).read_bytes())

    def test_поздний_режим_или_ссылка_второй_цели_не_меняет_первую(сам):
        for подмена in ('режим', 'ссылка'):
            with сам.subTest(подмена=подмена), tempfile.TemporaryDirectory() as каталог:
                корень = Path(каталог); исходники = {МОСТ: 'const old = 1; old();', ХОСТ: хост()}
                карта = подготовить(корень, исходники, {п: {'old': 'новое'} for п in исходники})
                изменения = учёт.подготовить_изменения(корень, карта)
                цель = корень / ХОСТ
                if подмена == 'режим':
                    os.chmod(цель, 0o600)
                else:
                    данные = цель.read_bytes(); цель.unlink()
                    внешняя = корень / 'сторонний.py'; внешняя.write_bytes(данные); цель.symlink_to(внешняя)
                with сам.assertRaises(учёт.ОшибкаКонтракта):
                    учёт.атомарно_применить(изменения)
                сам.assertEqual(исходники[МОСТ].encode(), (корень / МОСТ).read_bytes())

    def test_нативный_шаблон_только_по_точному_пути(сам):
        путь = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/вызов_нативной_подготовки.cjs'
        сам.assertIn(путь, модуль.пути_сценариев)
        сам.assertEqual(учёт.объявления_сценария((КОРЕНЬ / путь).read_text(), путь), [])
        for сосед in (путь.replace('вызов_', 'сосед_'), путь.upper(), 'вложено/' + путь):
            with сам.subTest(сосед=сосед), сам.assertRaises(учёт.ОшибкаКонтракта):
                учёт.объявления_сценария('const имя = 1;', сосед)

    def test_нативная_форма_внешнего_интерфейса_и_соседние_формы(сам):
        точный = 'const команда = {cmd:"",workdir:"",shell:"/bin/sh",login:false,max_output_tokens:1,yield_time_ms:1};'
        поля = [э for э in модуль.разобрать(точный)['объявления'] if э['вид'] == 'поле']
        сам.assertEqual({(э['имя'], э['класс']) for э in поля},
            {(имя, 'внешнее') for имя in ('cmd','workdir','shell','login','max_output_tokens','yield_time_ms')})
        сам.assertEqual(len(поля), 6)
        for текст in (точный.replace(',login:false',''), точный.replace(',shell:"/bin/sh"',''),
                точный.replace('};',',argv:[]};'), точный.replace('};',',env:{} };'),
                точный.replace('};',',...добавка};'), точный.replace('};',',shell:"/bin/sh"};'),
                'const сосед = {shell:"/bin/sh"};', 'const сосед = {login:false};',
                'const shell = 1;', 'function функция(login) { return login; }'):
            with сам.subTest(текст=текст):
                путь = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/вызов_нативной_подготовки.cjs'
                сам.assertTrue(учёт.объявления_сценария(текст, путь), 'потеряно латинское собственное объявление')

    def test_латинская_привязка_внутри_фактического_нативного_шаблона(сам):
        путь = 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts/вызов_нативной_подготовки.cjs'
        текст = (КОРЕНЬ / путь).read_text().replace('const команда =', 'const hiddenCommand =', 1)
        сам.assertTrue(учёт.объявления_сценария(текст, путь))

    def test_точные_пути_и_полное_чтение(сам):
        for путь in ПУТИ:
            сам.assertIn(путь, модуль.пути_сценариев)
            текст = (КОРЕНЬ / путь).read_text()
            сам.assertEqual(учёт.объявления_сценария(текст, путь), [])
        with сам.assertRaises(учёт.ОшибкаКонтракта):
            учёт.объявления_сценария('const x = 1;', 'произвольный.cjs')

    def test_побитовые_операторы_сохраняют_связывания(сам):
        текст = 'const badValue = (1 << 2) | (4 & 7) ^ (8 >>> 1); let badOther = ~badValue >> 1;'
        результат = модуль.разобрать(текст)['объявления']
        сам.assertEqual({э['имя'] for э in результат if э['класс'] == 'собственное'}, {'badValue', 'badOther'})
        for путь in ПУТИ:
            сам.assertTrue(учёт.объявления_сценария(текст, путь))

    def test_новые_поля_внешнего_интерфейса_узко_отделены(сам):
        текст = 'const команда = {cmd: "", workdir: "", tty: false, yield_time_ms: 1, max_output_tokens: 1}; const отпечаток = {байты: 1, sha256: ""}; const сосед = {tty: false};'
        результат = модуль.разобрать(текст)['объявления']
        поля = [э for э in результат if э['вид'] == 'поле']
        сам.assertEqual([э['класс'] for э in поля if э['имя'] == 'tty'], ['внешнее', 'собственное'])
        сам.assertEqual([э['класс'] for э in поля if э['имя'] == 'sha256'], ['внешнее'])

    def test_неизвестная_конструкция_не_исполняется(сам):
        for текст in ('const x = `template`;', 'class Hidden {}', 'let value = 1; value &&= 2;'):
            with сам.subTest(текст=текст), сам.assertRaises(модуль.ОшибкаСценария):
                модуль.разобрать(текст)


if __name__ == '__main__':
    unittest.main()
