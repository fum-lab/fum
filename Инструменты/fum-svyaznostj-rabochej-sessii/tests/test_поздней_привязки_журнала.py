"""Независимые границы LIVE и фактического дочернего времени новой .4."""
import copy
import contextlib
import importlib
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import unittest
from unittest import mock


class ИсполнениеПринятогоКода(unittest.TestCase):
    """Принятый K исполняется в новом процессе; чужой C остаётся данными."""

    def подготовить(сам):
        import tempfile
        сам.временное = tempfile.TemporaryDirectory()
        сам.addCleanup(сам.временное.cleanup)
        сам.папка = Path(сам.временное.name).resolve()
        сам.дерево_принятого_кода = сам.папка/'K'; сам.дерево_принятого_кода.mkdir()
        сам.дерево_исходного_коммита = сам.папка/'C'
        сам.вызвать_гит('init', '-q')
        сам.вызвать_гит('config', 'user.name', 'Фикстура')
        сам.вызвать_гит('config', 'user.email', 'fixture@example.invalid')
        (сам.дерево_принятого_кода/'worker.py').write_text('value = "C"\n')
        (сам.дерево_принятого_кода/'policy.json').write_text('{"роль":"данные"}\n')
        сам.вызвать_гит('add', '.'); сам.вызвать_гит('commit', '-qm', 'C')
        сам.исходный_коммит = сам.вызвать_гит('rev-parse', 'HEAD').strip()
        сам.вызвать_гит('worktree', 'add', '-q', '--detach', str(сам.дерево_исходного_коммита), сам.исходный_коммит)
        сам.загрузчик = Path(__file__).resolve().parents[1]/'scripts/исполнение_принятого_кода.py'

    def вызвать_гит(сам, *аргументы):
        return subprocess.check_output(['git', '--no-optional-locks', '-C', str(сам.дерево_принятого_кода), *аргументы], text=True)

    def сценарий(сам, текст):
        (сам.дерево_принятого_кода/'worker.py').write_text('value = "K"\n')
        (сам.дерево_принятого_кода/'main.py').write_text(текст)
        сам.вызвать_гит('add', '.'); сам.вызвать_гит('commit', '-qm', 'K')
        сам.принятый_коммит = сам.вызвать_гит('rev-parse', 'HEAD').strip()
        сам.цели_до = сам.состояние_исходного_дерева()

    def состояние_исходного_дерева(сам):
        вызвать_гит = lambda *а: subprocess.check_output(['git', '--no-optional-locks', '-C', str(сам.дерево_исходного_коммита), *а])
        return (вызвать_гит('rev-parse', 'HEAD'), вызвать_гит('status', '--porcelain=v1'),
                (Path(вызвать_гит('rev-parse', '--absolute-git-dir').decode().strip())/'index').read_bytes())

    def запуск(сам, подготовка='', после='', ожидается=0, пути=None, данные=True, меняет_исходные_данные=False, имена=None):
        код = 'import importlib.util,json,sys,time\nfrom pathlib import Path\nпуть_загрузчика,корень,принятый_коммит,дерево_исходного_коммита,исходный_коммит,пути,есть_данные,псевдонимы = json.loads(sys.argv[1])\nспецификация = importlib.util.spec_from_file_location("доверенный_bootstrap", путь_загрузчика)\nмодуль_загрузчика = importlib.util.module_from_spec(спецификация); спецификация.loader.exec_module(модуль_загрузчика)\nданные = {"корень":дерево_исходного_коммита,"коммит":исходный_коммит,"пути":["policy.json"]} if есть_данные else None\nначало_интервала=time.perf_counter_ns()\nконтур = модуль_загрузчика.захватить_источники(Path(корень), принятый_коммит, пути, данные)\nзахват_нс=time.perf_counter_ns()-начало_интервала\n\nsys.modules[\'__main__\'].__dict__.update({\'s\':контур,\'root\':корень,\'C\':дерево_исходного_коммита})\n# FUM-ПОДГОТОВКА\n\nначало_интервала=time.perf_counter_ns()\nконтур.исполнить("main.py", имена=псевдонимы)\nисполнение_нс=time.perf_counter_ns()-начало_интервала\n\n# FUM-ПОСЛЕ\n\nprint(json.dumps({"журнал":контур.журнал,"данные":{путь_данных:байты_данных.decode() for путь_данных,байты_данных in getattr(контур, \'данные_исходного_коммита\').items()},"профиль":{"захват_нс":захват_нс,"исполнение_нс":исполнение_нс}},ensure_ascii=False))\n'
        код = код.replace('# FUM-ПОДГОТОВКА', подготовка).replace('# FUM-ПОСЛЕ', после)
        арг = [str(сам.загрузчик), str(сам.дерево_принятого_кода), сам.принятый_коммит, str(сам.дерево_исходного_коммита), сам.исходный_коммит,
               пути if пути is not None else ['main.py','worker.py'], данные,
               имена if имена is not None else {"worker":"worker.py","особый":"worker.py"}]
        результат = subprocess.run([sys.executable, '-I', '-S', '-B', '-c', код, json.dumps(арг)],
                                   cwd=сам.дерево_исходного_коммита, text=True, capture_output=True, timeout=20)
        сам.assertEqual(результат.returncode, ожидается, результат.stdout + результат.stderr)
        if ожидается:
            сам.assertIn('ValueError:',результат.stderr)
        состояние = сам.состояние_исходного_дерева()
        if меняет_исходные_данные:
            сам.assertEqual((состояние[0],состояние[2]),(сам.цели_до[0],сам.цели_до[2]))
        else:
            сам.assertEqual(состояние, сам.цели_до)
        return результат

    def test_принятый_код_отличается_от_исходного_при_обычном_импорте(сам):
        сам.сценарий('import worker\nassert worker.value == "K"\n')
        р = сам.запуск()
        ж = json.loads(р.stdout)['журнал']
        сам.assertEqual([элемент_журнала['путь'] for элемент_журнала in ж if элемент_журнала['событие']=='exec'], ['main.py','worker.py'])
        сам.assertTrue(all(элемент_журнала['коммит']==сам.принятый_коммит for элемент_журнала in ж))
        сам.assertIn('policy.json',json.loads(р.stdout)['данные'])

    def test_спецификация_без_реестра_модулей_попадает_в_журнал(сам):
        сам.сценарий('import importlib.util,sys\nfrom pathlib import Path\ns=importlib.util.spec_from_file_location("особый",str(Path(__file__).with_name("worker.py")))\nm=importlib.util.module_from_spec(s)\ns.loader.exec_module(m)\nassert m.value == "K" and "особый" not in sys.modules\n')
        р = сам.запуск()
        сам.assertEqual(len([элемент_журнала for элемент_журнала in json.loads(р.stdout)['журнал'] if элемент_журнала['событие']=='exec']),2)

    def test_прямая_компиляция_и_исполнение_используют_захваченные_байты(сам):
        сам.сценарий('from pathlib import Path\np=Path(__file__).with_name("worker.py")\ng={}\nexec(compile(p.read_bytes(),str(p),"exec"),g)\nassert g["value"] == "K"\n')
        сам.запуск()

    def test_внешние_имена_аргументов_спецификации_сохраняются(сам):
        сам.сценарий('import importlib.util\nfrom pathlib import Path\nспецификация=importlib.util.spec_from_file_location(name="особый",location=str(Path(__file__).with_name("worker.py")))\nмодуль=importlib.util.module_from_spec(спецификация)\nспецификация.loader.exec_module(модуль)\nassert модуль.value == "K"\n')
        результат=сам.запуск()
        журнал=json.loads(результат.stdout)['журнал']
        сам.assertEqual([запись['путь'] for запись in журнал if запись['событие']=='exec'], ['main.py','worker.py'])

    def test_кэш_байткода_не_читается_даже_при_валидной_метке_времени(сам):
        сам.сценарий('import worker\nassert worker.value == "K"\n')
        сам.запуск(подготовка=r'''import py_compile
p=Path(root)/"worker.py"
old=p.stat()
p.write_text('value = "X"\n')
py_compile.compile(str(p),doraise=True)
p.write_text('value = "K"\n')
import os
os.utime(p,ns=(old.st_atime_ns,old.st_mtime_ns))
''')

    def test_правильное_имя_с_чужими_байтами_отвергается(сам):
        сам.сценарий('from pathlib import Path\np=Path(__file__).with_name("worker.py")\nexec(compile(b"value=999",str(p),"exec"))\n')
        сам.запуск(ожидается=1)

    def test_непривязанный_объект_кода_отвергается(сам):
        сам.сценарий('exec(чужой_код)\n')
        сам.запуск(подготовка='import builtins\ns.глобальные["чужой_код"]=compile("pass",str(Path(root)/"worker.py"),"exec")\n',ожидается=1)

    def test_необъявленный_исходник_не_исполняется(сам):
        сам.сценарий('import worker\n')
        р=сам.запуск(пути=['main.py'],ожидается=1,имена={})
        сам.assertIn('import отсутствует',р.stderr)

    def test_необъявленный_псевдоним_отвергается(сам):
        сам.сценарий('import importlib.util\ns=importlib.util.spec_from_file_location("чужой_alias",__file__)\n')
        сам.запуск(ожидается=1)

    def test_имя_стандартной_библиотеки_не_даёт_полномочий_динамическому_принятому_коду(сам):
        сам.сценарий('import os\nexec(compile("pass",os.__file__,"exec"))\n')
        сам.запуск(ожидается=1)

    def test_выход_по_пути_под_префиксом_стандартной_библиотеки_не_обходит_реестр_кода(сам):
        сам.сценарий('import os,importlib.util\nfrom pathlib import Path\nbase=str(Path(os.__file__).parent)\np=base+"/"+os.path.relpath(Path(__file__).with_name("worker.py"),base)\ns=importlib.util.spec_from_file_location("необъявленный",p)\nm=importlib.util.module_from_spec(s)\ns.loader.exec_module(m)\n')
        сам.запуск(ожидается=1)

    def test_чужой_загрузчик_для_объявленного_пути_отвергается(сам):
        сам.сценарий('import importlib.util,importlib.machinery\nfrom pathlib import Path\np=str(Path(__file__).with_name("worker.py"))\nimportlib.util.spec_from_file_location("особый",p,loader=importlib.machinery.SourceFileLoader("особый",p))\n')
        сам.запуск(ожидается=1)

    def test_путь_стандартной_библиотеки_не_разрешает_загрузчик_чужого_файла(сам):
        сам.сценарий('import os,importlib.util,importlib.machinery\nfrom pathlib import Path\np=str(Path(__file__).with_name("unknown.py"))\ns=importlib.util.spec_from_file_location("чужой",os.__file__,loader=importlib.machinery.SourceFileLoader("чужой",p))\nm=importlib.util.module_from_spec(s)\ns.loader.exec_module(m)\n')
        (сам.дерево_принятого_кода/'unknown.py').write_text('value=99\n')
        сам.запуск(ожидается=1)

    def test_прямой_файловый_загрузчик_не_выдаёт_роль_стандартной_библиотеки(сам):
        сам.сценарий('import importlib.machinery,types\nfrom pathlib import Path\np=str(Path(__file__).with_name("unknown.py"))\nimportlib.machinery.SourceFileLoader("чужой",p).exec_module(types.ModuleType("чужой"))\n')
        (сам.дерево_принятого_кода/'unknown.py').write_text('value=99\n')
        сам.запуск(ожидается=1)

    def test_дрейф_после_первого_эффекта_не_откатывает_и_не_повторяет_его(сам):
        сам.сценарий('from pathlib import Path\np=Path(__file__)\n(p.parent.parent/"эффект").write_text("один")\np.with_name("worker.py").write_text("value=99\\n")\nimport worker\n')
        сам.запуск(ожидается=1)
        сам.assertEqual((сам.папка/'эффект').read_text(),'один')

    def test_отсутствующие_исходные_данные_не_заменяются_принятыми(сам):
        сам.сценарий('pass\n')
        (сам.дерево_исходного_коммита/'policy.json').unlink();сам.цели_до=сам.состояние_исходного_дерева()
        сам.запуск(ожидается=1)

    def test_дрейф_кодовых_байт_и_режима_до_эффекта_отвергается(сам):
        сам.сценарий('pass\n')
        for действие in ['p.write_text("value=99\\n")','p.chmod(0o755)']:
            with сам.subTest(действие=действие):
                сам.запуск(подготовка='p=Path(root)/"worker.py"\n'+действие+'\n',ожидается=1)
            сам.вызвать_гит('restore','--worktree','worker.py')

    def test_дрейф_исходных_данных_и_отсутствующий_ресурс_отвергаются(сам):
        сам.сценарий('pass\n')
        путь_ресурса=сам.дерево_исходного_коммита/'policy.json'; до=путь_ресурса.read_bytes()
        for действие in ['p.write_text("{}\\n")','p.unlink()']:
            with сам.subTest(действие=действие):
                # C-данные намеренно меняет фикстура; исполнитель должен отказать до exec.
                путь_ресурса.write_bytes(до); сам.цели_до=сам.состояние_исходного_дерева()
                код='from pathlib import Path\np=Path(C)/"policy.json"\n'+действие+'\n'
                try:
                    р=сам.запуск(подготовка=код, ожидается=1, меняет_исходные_данные=True)
                    сам.assertIn('данные C',р.stderr)
                finally: путь_ресурса.write_bytes(до)
                сам.цели_до=сам.состояние_исходного_дерева()
        (сам.дерево_принятого_кода/'main.py').chmod(0o644)

    def test_полный_идентификатор_коммита_и_обычный_отслеживаемый_файл_обязательны(сам):
        сам.сценарий('pass\n')
        сохранённый=сам.принятый_коммит; сам.принятый_коммит=сам.принятый_коммит[:12]
        сам.запуск(ожидается=1); сам.принятый_коммит=сохранённый
        (сам.дерево_принятого_кода/'link.py').symlink_to('worker.py')
        сам.вызвать_гит('add','link.py'); сам.вызвать_гит('commit','-qm','link');сам.принятый_коммит=сам.вызвать_гит('rev-parse','HEAD').strip()
        сам.запуск(пути=['main.py','worker.py','link.py'],ожидается=1)

# Внешний протокол unittest и прежнее пространство дословных входов сохраняются.
setattr(ИсполнениеПринятогоКода, 'setUp', ИсполнениеПринятогоКода.подготовить)

import test_основания_двусторонней_координации as примеры
import test_подготовки_дочернего_поручения as композиции


def служебная_оболочка(событие):
    событие=copy.deepcopy(событие)
    событие.update(timestamp='2026-10-10T09:34:56Z',ordinal=1)
    данные=событие['payload']
    if событие['type']=='response_item' and данные.get('type')=='function_call_output' and 'call_id' in данные:
        данные.update(id='результат',internal_chat_message_metadata_passthrough={'turn_id':'ход'})
    if событие['type']=='event_msg' and данные.get('type')=='item_completed':
        данные.update(turn_id='ход',started_at_ms=1,completed_at_ms=2)
        данные['item'].setdefault('id','элемент')
    return событие


def событие_времени(команда,корень,исполнитель,вывод,код=0):
    return служебная_оболочка({'type':'event_msg','payload':{'type':'item_completed',
        'thread_id':исполнитель,'item':{'type':'CommandExecution','command':команда,'cwd':корень.as_uri(),
        'source':'unified_exec_startup','status':'completed','exit_code':код,'aggregated_output':вывод,
        'duration':{'secs':0,'nanos':1},'parsed_cmd':[],'process_id':'1'}}})


class НаблюдённыеСлужебныеФормы(unittest.TestCase):
    def test_наблюдённые_метаданные_закрыты_по_виду_и_типам(сам):
        for вид in ('function_call','custom_tool_call_output','function_call_output'):
            данные={'type':вид,'id':'элемент','call_id':'вызов',
                'internal_chat_message_metadata_passthrough':{'turn_id':'ход'}}
            if вид=='function_call': данные.update(name='инструмент',arguments='{}')
            else: данные['output']='Данные инструмента.'
            мета={'client_authored':False,
                **({'user_input_order':1} if вид=='function_call' else {'fallback_token_limit_override':12000})}
            событие=служебная_оболочка({'type':'response_item','payload':данные,'metadata':мета})
            with сам.subTest(вид=вид):
                сам.assertTrue(примеры.основание.известный_служебный_хвост(событие,'корень'))
            for поле,значение in [('client_authored',True),('client_authored',0),('неизвестное',1),
                    (next(к for к in мета if к!='client_authored'),True),
                    (next(к for к in мета if к!='client_authored'),None)]:
                подмена=copy.deepcopy(событие);подмена['metadata'][поле]=значение
                сам.assertFalse(примеры.основание.известный_служебный_хвост(подмена,'корень'))
            подмена=copy.deepcopy(событие);подмена['payload']['role']='user'
            сам.assertFalse(примеры.основание.известный_служебный_хвост(подмена,'корень'))
            подмена=copy.deepcopy(событие);подмена['metadata']={'client_authored':False,
                **({'fallback_token_limit_override':12000} if вид=='function_call' else {'user_input_order':1})}
            сам.assertFalse(примеры.основание.известный_служебный_хвост(подмена,'корень'))

    def test_наблюдённая_пара_лимита_не_разрешает_другие_сочетания(сам):
        счётчики=dict.fromkeys(('input_tokens','cached_input_tokens','cache_write_input_tokens',
            'output_tokens','reasoning_output_tokens','total_tokens'),0)
        лимиты={'credits':{'balance':'0','has_credits':False,'unlimited':False},
            'individual_limit':None,'limit_id':'лимит','limit_name':'Название','plan_type':None,
            'primary':{'resets_at':1,'used_percent':0.0,'window_minutes':300},
            'rate_limit_reached_type':None,'secondary':None,'spend_control_reached':None}
        событие=служебная_оболочка({'type':'event_msg','payload':{'type':'token_count',
            'info':{'last_token_usage':счётчики,'total_token_usage':счётчики,'model_context_window':100},
            'rate_limits':лимиты}})
        сам.assertTrue(примеры.основание.известный_служебный_хвост(событие,'корень'))
        for план,имя in [('План','Название'),(False,'Название'),(None,False)]:
            подмена=copy.deepcopy(событие);подмена['payload']['rate_limits'].update(plan_type=план,limit_name=имя)
            сам.assertFalse(примеры.основание.известный_служебный_хвост(подмена,'корень'))
        подмена=copy.deepcopy(событие);подмена['payload']['rate_limits'].update(plan_type='План',limit_name=None)
        сам.assertTrue(примеры.основание.известный_служебный_хвост(подмена,'корень'))
        for поле,значение in [('role','user'),('неизвестное',True)]:
            подмена=copy.deepcopy(событие);подмена['payload'][поле]=значение
            сам.assertFalse(примеры.основание.известный_служебный_хвост(подмена,'корень'))


class ИсторическоеОснование(примеры.ОснованиеКоординации):
    def позднее(сам):
        return примеры.основание.проверить_историческое(сам.корень, сам.решение, сам.вход)

    def дописать(сам, событие):
        with сам.источник.open('ab') as поток:
            поток.write(примеры.байты(служебная_оболочка(событие)))

    def test_известный_служебный_хвост_принимается_только_новым_основанием(сам):
        до = сам.проверить()
        сам.дописать({'type':'response_item','payload':{
            'type':'function_call_output','call_id':'call_1','output':'Получено.'}})
        with сам.assertRaises(ValueError): сам.проверить()
        после = сам.позднее()
        сам.assertEqual(до, после)
        сам.assertEqual(после, сам.позднее())

    def test_человеческий_неизвестный_и_повторённый_ввод_требуют_рассмотрения(сам):
        исходный = сам.источник.read_bytes()
        for событие in [примеры.сообщение('Отмена.',3),
                примеры.сообщение('Координируй дочерние чаты.\n',3),
                примеры.сообщение('Неизвестный ввод.',3,['unknown']),
                {'type':'event_msg','payload':{'type':'user_message','message':'Отмена.'}},
                {'type':'неизвестный','payload':{}},
                {'type':'response_item','payload':{'type':'message','role':'developer','content':[]}},
                {'type':'compacted','payload':{'replacement_history':[примеры.сообщение('Отмена.',3)]}}]:
            with сам.subTest(тип=событие['type']):
                сам.источник.write_bytes(исходный)
                сам.дописать(событие)
                with сам.assertRaises(ValueError): сам.позднее()

    def test_дрейф_префикса_порядка_корня_и_оригиналов_не_лечится_служебным_хвостом(сам):
        исходный = сам.источник.read_bytes()
        решение = copy.deepcopy(сам.решение)
        for вид in ['префикс','порядок','ROOT','RAW']:
            with сам.subTest(вид=вид):
                сам.источник.write_bytes(исходный)
                сам.решение = copy.deepcopy(решение)
                сам.дописать({'type':'response_item','payload':{
                    'type':'function_call_output','call_id':'call_1','output':'Получено.'}})
                if вид == 'префикс':
                    сам.источник.write_bytes(сам.источник.read_bytes().replace('Координируй'.encode(),'Не координируй'.encode()))
                elif вид == 'порядок': сам.решение['координация']['контекст']['экземпляры'].reverse()
                elif вид == 'ROOT': сам.решение['координатор']='00000000-0000-0000-0000-000000000178'
                else: Path(сам.вход['основание_координации']['оригиналы'][0]['путь']).write_bytes(b'{}\n')
                with сам.assertRaises(ValueError): сам.позднее()

    def test_незавершённый_хвост_не_разрешает_эффект(сам):
        with сам.источник.open('ab') as поток: поток.write(b'{"type":"response_item"')
        with сам.assertRaises(ValueError): сам.позднее()

    def test_противоречащая_человеческая_роль_и_скрытая_история_сжатия_отказывают(сам):
        исходный=сам.источник.read_bytes()
        for элемент in [
                {'type':'AgentMessage','role':'user','content':[{'type':'input_text','text':'Отмена.'}]},
                {'type':'ContextCompaction','replacement_history':[примеры.сообщение('Отмена.',3)]}]:
            with сам.subTest(вид=элемент['type']):
                сам.источник.write_bytes(исходный)
                сам.дописать({'type':'event_msg','payload':{'type':'item_completed','thread_id':примеры.КОРЕНЬ,'item':элемент}})
                with сам.assertRaises(ValueError): сам.позднее()

    def test_тип_без_закрытой_транспортной_оболочки_не_даёт_допуск(сам):
        исходный=сам.источник.read_bytes()
        for событие in [
                {'type':'response_item','payload':{'type':'function_call_output'}},
                {'type':'response_item','payload':{'type':'function_call_output','call_id':'x','output':'Цитата человека.', 'replacement_history':[]}},
                {'type':'event_msg','payload':{'type':'token_count','role':'user'}},
                {'type':'event_msg','payload':{'type':'token_count','неизвестное':True}}]:
            with сам.subTest(событие=событие):
                сам.источник.write_bytes(исходный);сам.дописать(событие)
                with сам.assertRaises(ValueError): сам.позднее()


class ДописываниеПриЧтении(ИсторическоеОснование):
    def служебное(сам):
        return {'type':'response_item','payload':{
            'type':'function_call_output','call_id':'call_1','output':'Получено.'}}

    def во_время_разбора(сам, действие, проверка):
        читать=примеры.читатель._прочитать_поток
        вызвано=False
        def с_дописыванием(*аргументы, **параметры):
            nonlocal вызвано
            результат=читать(*аргументы, **параметры)
            if not вызвано:
                вызвано=True; действие()
            return результат
        with mock.patch.object(примеры.читатель,'_прочитать_поток',side_effect=с_дописыванием):
            return проверка()

    def test_служебное_дописывание_в_разборе_сохраняет_основание(сам):
        прежнее=сам.позднее()
        после=сам.во_время_разбора(lambda:сам.дописать(сам.служебное()),сам.позднее)
        сам.assertEqual(прежнее,после)
        with сам.assertRaises(ValueError): сам.проверить()

    def test_рассмотренный_префикс_не_присваивает_себе_поздний_человеческий_ввод(сам):
        прежнее=примеры.основание.проверить_рассмотренный_префикс(сам.корень,сам.решение,сам.вход)
        после=сам.во_время_разбора(lambda:сам.дописать(примеры.сообщение('Уточнение.',3)),
            lambda:примеры.основание.проверить_рассмотренный_префикс(сам.корень,сам.решение,сам.вход))
        сам.assertEqual(прежнее,после)
        with сам.assertRaises(ValueError): сам.позднее()

    def test_дописанное_неизвестное_человеческое_и_неполное_отказывают(сам):
        исходное=сам.источник.read_bytes()
        for данные in [примеры.байты(примеры.сообщение('Отмена.',3)),
                примеры.байты({'type':'неизвестный','payload':{}}),b'{']:
            with сам.subTest(данные=данные):
                сам.источник.write_bytes(исходное)
                def дописать():
                    with сам.источник.open('ab') as поток: поток.write(данные)
                with сам.assertRaises(ValueError): сам.во_время_разбора(дописать,сам.позднее)

    def test_подмена_префикса_усечение_и_замена_дескриптора_отказывают(сам):
        исходное=сам.источник.read_bytes()
        for вид in ['подмена','усечение','inode','ссылка','метаданные']:
            with сам.subTest(вид=вид):
                if сам.источник.is_symlink(): сам.источник.unlink()
                сам.источник.write_bytes(исходное)
                def изменить():
                    if вид=='подмена': сам.источник.write_bytes(исходное.replace('Координируй'.encode(),'Не разрешу'.encode()))
                    elif вид=='усечение': сам.источник.write_bytes(исходное[:-1])
                    elif вид=='inode':
                        другой=сам.папка/'замена';другой.write_bytes(исходное);os.replace(другой,сам.источник)
                    elif вид=='ссылка':
                        другой=сам.папка/'оригинал';другой.write_bytes(исходное);сам.источник.unlink();сам.источник.symlink_to(другой)
                    else:
                        с=сам.источник.stat();os.utime(сам.источник,ns=(с.st_atime_ns,с.st_mtime_ns+1))
                with сам.assertRaises((ValueError,OSError)): сам.во_время_разбора(изменить,сам.позднее)

    def test_служебное_дописывание_при_сверке_оригиналов_не_ломает_основание(сам):
        прежнее=сам.позднее();сверить=примеры.обработка.сверить_экземпляры;вызвано=False
        def с_дописыванием(*аргументы,**параметры):
            nonlocal вызвано
            результат=сверить(*аргументы,**параметры)
            if not вызвано:
                вызвано=True;сам.дописать(сам.служебное())
            return результат
        with mock.patch.object(примеры.обработка,'сверить_экземпляры',side_effect=с_дописыванием):
            сам.assertEqual(прежнее,сам.позднее())

    def test_изменение_проверенного_хвоста_и_человек_при_сверке_оригиналов_отказывают(сам):
        исходное=сам.источник.read_bytes();сверить=примеры.обработка.сверить_экземпляры
        for вид in ['хвост','префикс','человек']:
            with сам.subTest(вид=вид):
                сам.источник.write_bytes(исходное);сам.дописать(сам.служебное());вызвано=False
                def изменить(*аргументы,**параметры):
                    nonlocal вызвано
                    результат=сверить(*аргументы,**параметры)
                    if not вызвано:
                        вызвано=True
                        if вид=='человек': сам.дописать(примеры.сообщение('Отмена.',3))
                        else:
                            сырые=сам.источник.read_bytes()
                            старое,новое=('Получено.','Отменено.') if вид=='хвост' else ('Координируй','Не разрешу')
                            сам.источник.write_bytes(сырые.replace(старое.encode(),новое.encode()))
                            сам.дописать(сам.служебное())
                    return результат
                with mock.patch.object(примеры.обработка,'сверить_экземпляры',side_effect=изменить):
                    with сам.assertRaises(ValueError): сам.позднее()

    def test_догоняющее_чтение_конечно_и_не_повторяет_разбор_объектов(сам):
        контекст=сам.смысл['контекст'];читать=примеры.основание._сырой_хэш
        исходное=сам.источник.read_bytes()
        for непрерывно in [False,True]:
            with сам.subTest(непрерывно=непрерывно):
                сам.источник.write_bytes(исходное);вызовов=0;разобрать=примеры.читатель._прочитать_поток
                def при_хэше(поток,начало,конец,*аргументы):
                    nonlocal вызовов
                    итог=читать(поток,начало,конец,*аргументы)
                    if начало==0:
                        вызовов+=1
                        if непрерывно or вызовов==1: сам.дописать(сам.служебное())
                    return итог
                with mock.patch.object(примеры.основание,'_сырой_хэш',side_effect=при_хэше),\
                        mock.patch.object(примеры.читатель,'_прочитать_поток',wraps=разобрать) as разбор:
                    if непрерывно:
                        with сам.assertRaisesRegex(ValueError,'трёх'):
                            примеры.основание.прочитать_живой_префикс(сам.источник,примеры.КОРЕНЬ,контекст)
                        сам.assertEqual(3,вызовов)
                    else:
                        _,наблюдение=примеры.основание.прочитать_живой_префикс(сам.источник,примеры.КОРЕНЬ,контекст)
                        сам.assertEqual(2,наблюдение['попытки'])
                        сам.assertEqual(1,наблюдение['строки_хвоста'])
                        сам.assertGreaterEqual(наблюдение['сырых_байтов'],2*контекст['граница'])
                    сам.assertEqual(1,разбор.call_count)

    def test_дописывание_между_конечными_метками_дескриптора_и_пути_догоняется(сам):
        читать=примеры.основание._сырой_хэш;состояние=Path.lstat;готово=False;дописано=False
        def после_хэша(*аргументы,**параметры):
            nonlocal готово
            итог=читать(*аргументы,**параметры);готово=True;return итог
        def с_дописыванием(путь,*аргументы,**параметры):
            nonlocal дописано
            if путь==сам.источник and готово and not дописано:
                дописано=True;сам.дописать(сам.служебное())
            return состояние(путь,*аргументы,**параметры)
        with mock.patch.object(примеры.основание,'_сырой_хэш',side_effect=после_хэша),\
                mock.patch.object(Path,'lstat',new=с_дописыванием):
            _,наблюдение=примеры.основание.прочитать_живой_префикс(
                сам.источник,примеры.КОРЕНЬ,сам.смысл['контекст'])
        сам.assertTrue(дописано);сам.assertEqual(2,наблюдение['попытки'])

    def test_повторный_хэш_не_берёт_старый_префикс_из_буфера(сам):
        читать=примеры.основание._сырой_хэш;изменено=False;исходное=сам.источник.read_bytes()
        def после_хэша(поток,начало,конец,*аргументы):
            nonlocal изменено
            итог=читать(поток,начало,конец,*аргументы)
            if начало==0 and not изменено:
                изменено=True
                сам.источник.write_bytes(исходное.replace('Координируй'.encode(),'Не разрешу'.encode()))
                сам.дописать(сам.служебное())
            return итог
        with mock.patch.object(примеры.основание,'_сырой_хэш',side_effect=после_хэша):
            with сам.assertRaises(ValueError):
                примеры.основание.проверить_рассмотренный_префикс(сам.корень,сам.решение,сам.вход)
        сам.assertTrue(изменено)


class СобственноеВремя(unittest.TestCase):
    def свидетельство(сам):
        модуль = importlib.import_module('поздняя_привязка_журнала')
        корень = Path(__file__).resolve().parents[3]
        команда = ['python3','-B','Инструменты/fum-moskovskoye-vremya-rabochej-sessii/scripts/get-session-time.py','--format','both']
        событие = событие_времени(команда,корень,'00000000-0000-0000-0000-000000000178',
            'prefix=2026-10-10_12-34-56_MSK\nlabel=2026-10-10 12:34:56 MSK\n')
        return модуль,корень,событие

    def test_только_собственный_прямой_вызов_без_подстановки_даты(сам):
        модуль,корень,событие = сам.свидетельство()
        исполнитель = событие['payload']['thread_id']
        результат = модуль.проверить_время(событие,корень,исполнитель)
        сам.assertEqual(('2026-10-10_12-34-56_MSK','2026-10-10 12:34:56 MSK'),результат)
        for вид in ['ROOT','at','shell','чужой_cwd','выход','неуспех']:
            with сам.subTest(вид=вид):
                изменённое = copy.deepcopy(событие); элемент=изменённое['payload']['item']
                if вид == 'ROOT': изменённое['payload']['thread_id']=примеры.КОРЕНЬ
                elif вид == 'at': элемент['command'] += ['--at','2026-10-10T09:34:56Z']
                elif вид == 'shell': элемент['command']=['/bin/zsh','-lc','python3 '+ ' '.join(элемент['command'][2:])+'; date']
                elif вид == 'чужой_cwd': элемент['cwd']=корень.parent.as_uri()
                elif вид == 'выход': элемент['aggregated_output']+='дополнительный вывод\n'
                else: элемент['exit_code']=1
                with сам.assertRaises(ValueError): модуль.проверить_время(изменённое,корень,исполнитель)

    def test_нативная_обёртка_единственного_точного_вызова_времени(сам):
        модуль,корень,событие=сам.свидетельство()
        событие['payload']['item']['command']=['/bin/zsh','-lc', ' '.join(событие['payload']['item']['command'])]
        сам.assertEqual(('2026-10-10_12-34-56_MSK','2026-10-10 12:34:56 MSK'),
            модуль.проверить_время(событие,корень,событие['payload']['thread_id']))
        for позиция,аргумент in [(0,'zsh'),(1,'-c'),
                (2,событие['payload']['item']['command'][2]+' --at 2026-10-10T09:34:56Z')]:
            подмена=copy.deepcopy(событие);подмена['payload']['item']['command'][позиция]=аргумент
            with сам.assertRaises(ValueError):
                модуль.проверить_время(подмена,корень,событие['payload']['thread_id'])


class КомпозицияПозднегоЖурнала(unittest.TestCase):
    def фикстура(сам):
        п=композиции.ПодготовкаПоручения('runTest'); п.__getattribute__('setUp')(); сам.addCleanup(п.doCleanups)
        п.сохранить_координацию()
        п.решение['акт']['область']=['Компонент/']
        п.решение['координация']['решение']['область']=['Компонент/']
        п.решение.update(схема='fum.смысл-дочернего-поручения.3',поздний_журнал={
            'схема':'fum.политика-позднего-журнала.1','метка':'проверить-ребёнка','заголовок':'Проверить ребёнка',
            'служебные_цели':['Журнал/README.md','Индексы/markdown-файлы-по-времени-редактирования.md']})
        р=copy.deepcopy(п.решение['подготовка']['корень'])
        р.pop('журнал'); р.pop('время'); р['роль']='Разработчик'
        р['заголовок']='Проверить ребёнка'
        р['цели']=['Компонент/результат.py']
        р['проверки']=[{'название':'Проверка результата','наборы':['Компонент/проверка.py']}]
        п.решение['подготовка']['исполнитель']=р
        файл=п.ф.корень/'Планирование/решение.json'; файл.write_bytes(п.м.байты(п.решение))
        время=Path(__file__).resolve().parents[2]/'fum-moskovskoye-vremya-rabochej-sessii/scripts/get-session-time.py'
        копия=п.ф.корень/время.relative_to(Path(__file__).resolve().parents[3]);копия.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(время,копия)
        шаблоны=[]
        for имя in ('запрос.md.шаблон','отчёт.md.шаблон'):
            путь='Инструменты/fum-struktura-papok-zaprosov/шаблоны/'+имя
            цель=п.ф.корень/путь;цель.parent.mkdir(parents=True,exist_ok=True)
            shutil.copyfile(п.м.этап.каркас.КАТАЛОГ_ШАБЛОНОВ/имя,цель);шаблоны.append(путь)
        п.ф.ф.гит('add','Планирование/решение.json',копия.relative_to(п.ф.корень).as_posix(),*шаблоны)
        п.ф.ф.гит('commit','-qm','Сохранить политику одной поздней папки')
        п.вход['решение'].update(коммит=п.ф.ф.гит('rev-parse','HEAD').strip(),sha256=п.м.хэш(файл.read_bytes()))
        живой=п.вход['источники'][0]['путь']
        снимок=п.ф.приватный/'исторические-команды.jsonl'
        with Path(живой).open('rb') as откуда, снимок.open('xb') as куда:
            shutil.copyfileobj(откуда,куда,1024*1024)
        снимок.chmod(0o400)
        кэш=п.ф.приватный/'исторические-команды-кэш.json'
        п.м.этап.коммит.сообщения.прочитать_сообщения(снимок,п.решение['координатор'],корень_репозитория=п.ф.корень,кэш=кэш)
        п.вход['источники'][0].update(путь=str(снимок),кэш=str(кэш))
        п.вход.update(схема='fum.подготовка-дочернего-поручения.4',живой_источник=живой,
            поздняя_привязка=None,позднее_решение=None)
        return п

    def применить(сам,п,вход,имя):
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']):
            план=п.м.построить_план(вход)
            файл=Path(вход['каталог_выходов'])/(имя+'.json');файл.write_bytes(п.м.байты(план));файл.chmod(0o400)
            итог=п.м.применить(вход,файл,п.м.хэш(файл.read_bytes()))
        return план,итог,файл

    def до_начала(сам,п):
        план,_,_=сам.применить(п,п.вход,'план-постановки')
        п.ф.ф.гит('add',п.решение['постановка']['путь']);п.ф.ф.гит('commit','-qm','Коммит первоначальной постановки')
        пост={'коммит':п.ф.ф.гит('rev-parse','HEAD').strip(),'путь':п.решение['постановка']['путь'],
            'sha256':п.м.хэш((п.ф.корень/п.решение['постановка']['путь']).read_bytes())}
        приглашение=п.м.составить_приглашение(п.ф.корень,п.вход['решение'],пост,п.вход)
        сам.assertNotIn('2026-10-10_',приглашение['текст'])
        ребёнок=п.ф.приватный/'новый-ребёнок'
        п.ф.ф.гит('worktree','add','-b',п.решение['акт']['ветка'].removeprefix('refs/heads/'),str(ребёнок),пост['коммит'])
        исполнитель='00000000-0000-0000-0000-000000000022'
        источник=п.ф.приватный/'новый-ребёнок.jsonl'
        события=[{'type':'session_meta','payload':{'id':исполнитель,'cwd':str(ребёнок),
            'thread_source':'agent_created_thread','git':{'commit_hash':пост['коммит']}}},
            {'type':'turn_context','payload':{'cwd':str(ребёнок),'model':п.решение['модель'],'effort':п.решение['усилие']}},
            {'type':'response_item','payload':{'type':'function_call_output','name':'create_thread',
                'output':'<codex_delegation>\n  <source_thread_id>'+п.решение['координатор']+'</source_thread_id>\n  <input>'+приглашение['текст']+'</input>\n</codex_delegation>'}}]
        команда=['python3','-B','Инструменты/fum-moskovskoye-vremya-rabochej-sessii/scripts/get-session-time.py','--format','both']
        процесс=subprocess.run(команда,cwd=ребёнок,check=True,capture_output=True)
        начало=len(b''.join(примеры.байты(э) for э in события))
        событие=событие_времени(команда,ребёнок,исполнитель,процесс.stdout.decode(),процесс.returncode)
        сырые=примеры.байты(событие);источник.write_bytes(b''.join(примеры.байты(э) for э in события)+сырые)
        каталог=п.ф.приватный/'начало';каталог.mkdir(mode=0o700)
        вход=copy.deepcopy(п.вход);вход.update(фаза='начало',корень=str(ребёнок),писатель=исполнитель,
            источник_модели=str(источник),постановка=пост,исполнитель={'задача':исполнитель,'корень':str(ребёнок),'источник_модели':str(источник)},
            каталог_выходов=str(каталог),область_писателя=['Компонент/'],
            поздняя_привязка={'начало':начало,'конец':начало+len(сырые),'sha256':п.м.хэш(сырые)})
        return вход

    def поздний_обзор(сам,п,вход,план,свидетельство):
        живой=Path(п.вход['живой_источник']);начало=живой.stat().st_size
        уточнение=примеры.байты(примеры.сообщение('Прими фактическую собственную папку; область компонента прежняя.\n',99))
        with живой.open('ab') as поток: поток.write(уточнение)
        кэш=п.ф.приватный/'новый-живой-кэш.json'
        индекс=п.м.этап.коммит.сообщения.прочитать_сообщения(живой,п.решение['координатор'],корень_репозитория=п.ф.корень,кэш=кэш)
        смысл=copy.deepcopy(п.решение['координация'])
        смысл['контекст']=примеры.обработка.контекст_снимка(индекс)
        новый=индекс['сообщения'][-1]['экземпляр'];смысл['решение']['поздние'].append(новый)
        оригинал=п.ф.приватный/'поздний-оригинал.raw';оригинал.write_bytes(уточнение);оригинал.chmod(0o600)
        частный=copy.deepcopy(п.вход['основание_координации'])
        частный['оригиналы'].append({'экземпляр':новый,'путь':str(оригинал),'sha256':п.м.хэш(уточнение)})
        снимок=п.ф.приватный/'команды-B1.jsonl'
        with живой.open('rb') as откуда,снимок.open('xb') as куда: shutil.copyfileobj(откуда,куда,1024*1024)
        снимок.chmod(0o400);кэш_снимка=п.ф.приватный/'команды-B1-кэш.json'
        п.м.этап.коммит.сообщения.прочитать_сообщения(снимок,п.решение['координатор'],корень_репозитория=п.ф.корень,кэш=кэш_снимка)
        источники=copy.deepcopy(п.вход['источники'])
        источники[0].update(путь=str(снимок),кэш=str(кэш_снимка),граница_снимка={
            'граница':индекс['граница'],'sha256':индекс['sha256'],'неоднозначные_экземпляры':[]})
        позднее={'схема':'fum.решение-поздней-привязки.1','решение':п.вход['решение'],
            'постановка':вход['постановка'],'координатор':п.решение['координатор'],
            'свидетельство_sha256':свидетельство['sha256'],'актуальность':'актуально',
            'основание':'ROOT рассмотрел фактическое собственное время, start и весь поздний LIVE-контекст.',
            'координация':смысл, 'область':план['эффективная_область']}
        позднее['координация']['решение']['область']=план['эффективная_область']
        файл=п.ф.корень/'Планирование/позднее-решение.json';файл.write_bytes(п.м.байты(позднее))
        п.ф.ф.гит('add',файл.relative_to(п.ф.корень).as_posix());п.ф.ф.гит('commit','-qm','Рассмотреть поздний собственный Журнал')
        ссылка={'коммит':п.ф.ф.гит('rev-parse','HEAD').strip(),'путь':файл.relative_to(п.ф.корень).as_posix(),'sha256':п.м.хэш(файл.read_bytes())}
        каталог=п.ф.приватный/'поздний-акт';каталог.mkdir(mode=0o700)
        акт=copy.deepcopy(п.вход);акт.update(фаза='акт',постановка=вход['постановка'],исполнитель=вход['исполнитель'],
            поздняя_привязка=свидетельство,позднее_решение=ссылка,каталог_выходов=str(каталог),
            источники=источники,основание_координации=частный)
        служебный=служебная_оболочка({'type':'response_item','payload':{'type':'function_call_output','call_id':'x','output':'Обзор сохранён.'}})
        with живой.open('ab') as поток: поток.write(примеры.байты(служебный))
        сам.assertLess(п.решение['координация']['контекст']['граница'],смысл['контекст']['граница'])
        сам.assertLess(смысл['контекст']['граница'],живой.stat().st_size)
        return акт

    def test_настоящая_композиция_от_приглашения_до_штатного_входа_и_повтора(сам):
        п=сам.фикстура();вход=сам.до_начала(п)
        план,итог,план_начала=сам.применить(п,вход,'план-начала')
        свидетельство=итог['свидетельство']; ребёнок=Path(вход['корень'])
        данные=п.м.этап.прочитать(свидетельство['путь'],режим=0o400); папка=данные['журнал']
        сам.assertTrue((ребёнок/папка/'запрос.md').is_file())
        сам.assertEqual(вход['писатель'],данные['исполнитель'])
        акт=сам.поздний_обзор(п,вход,план,свидетельство)
        план_акта,_,_=сам.применить(п,акт,'план-акта')
        п.ф.ф.гит('add',п.решение['акт']['путь']);п.ф.ф.гит('commit','-qm','Независимый ACT после review')
        выбор=п.м.выбрать_акт(п.ф.корень,п.ф.ф.гит('rev-parse','HEAD').strip(),п.решение['акт']['путь'],п.решение['координатор'],вход['писатель'])
        каталог=п.ф.приватный/'поздний-вход';каталог.mkdir(mode=0o700)
        дочерний=copy.deepcopy(вход);дочерний.update(фаза='входы',поздняя_привязка=свидетельство,
            позднее_решение=акт['позднее_решение'],выбор_акта=выбор,каталог_выходов=str(каталог),
            область_писателя=план['эффективная_область'],источники=акт['источники'],основание_координации=акт['основание_координации'])
        результат,_,неизменный=сам.применить(п,дочерний,'план-входов')
        сам.assertEqual('fum.создание-коммита.7',результат['технические_входы']['коммит']['схема'])
        сам.assertEqual(выбор,результат['выбор_акта'])
        параметры=результат['технические_входы']['коммит']
        команды=п.м.этап.коммит.команды(параметры)
        сам.assertEqual(план['команды'],[э['текст'] for э in команды])
        сам.assertEqual(Path(дочерний['источники'][0]['путь']).read_bytes(),Path(параметры['источники'][0]['путь']).read_bytes())
        запрос=ребёнок/папка/'запрос.md';отчёт=ребёнок/папка/'отчёт.md'
        запрос.write_bytes(запрос.read_bytes()+b'\n');отчёт.write_bytes(отчёт.read_bytes()+b'\n')
        до=(запрос.read_bytes(),отчёт.read_bytes(),Path(результат['технические_входы']['фасад']['вход_коммита']).read_bytes())
        with contextlib.redirect_stdout(io.StringIO()):
            код=п.м.этап.коммит.отчёты.выполнить_запуск(ребёнок,запрос,'Проверка сохранённой пары','Фикстура',
                результат['технические_входы']['фасад']['проверки'][0]['идентификатор'],15,[sys.executable,'-B','-c',
                "from pathlib import Path; assert len(list(Path('Журнал').glob('*/отчёт.md'))) >= 1"],
                класс_проверки='адресная',приёмочные_раунды=True)
        сам.assertEqual(0,код)
        до=(запрос.read_bytes(),отчёт.read_bytes(),до[2])
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']):
            повтор=п.м.применить(дочерний,неизменный,п.м.хэш(неизменный.read_bytes()))
        сам.assertTrue(повтор['повтор'])
        сам.assertEqual(до,(запрос.read_bytes(),отчёт.read_bytes(),Path(результат['технические_входы']['фасад']['вход_коммита']).read_bytes()))

    def test_повтор_начала_сохраняет_заполненную_пару(сам):
        п=сам.фикстура();вход=сам.до_начала(п)
        план,итог,файл=сам.применить(п,вход,'план-начала')
        папка=Path(вход['корень'])/план['свидетельство']['журнал']
        for имя in ('запрос.md','отчёт.md'):
            цель=папка/имя;цель.write_bytes(цель.read_bytes()+b'\n')
        до=[(папка/и).read_bytes() for и in ('запрос.md','отчёт.md')]
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']):
            сам.assertTrue(п.м.применить(вход,файл,п.м.хэш(файл.read_bytes()))['повтор'])
        сам.assertEqual(до,[(папка/и).read_bytes() for и in ('запрос.md','отчёт.md')])

    def test_каждая_установка_начала_отказывает_до_следующего_эффекта(сам):
        for вид in ('человек','неизвестный','неполный'):
            with сам.subTest(вид=вид):
                п=сам.фикстура();вход=сам.до_начала(п);поздний=importlib.import_module('поздняя_привязка_журнала')
                with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']): план=п.м.построить_план(вход)
                файл=Path(вход['каталог_выходов'])/'план-начала.json';файл.write_bytes(п.м.байты(план));файл.chmod(0o400)
                штатный=п.м.этап.каркас._install_prepared_file;записано=[]
                def установка(корень,элемент):
                    штатный(корень,элемент);записано.append(элемент.path)
                    if len(записано)==1:
                        хвост=примеры.байты(примеры.сообщение('Останови запись.',99)) if вид=='человек' else (b'{}\n' if вид=='неизвестный' else b'{')
                        with Path(вход['живой_источник']).open('ab') as поток: поток.write(хвост)
                with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']),mock.patch.object(п.м.этап.каркас,'_install_prepared_file',side_effect=установка):
                    with сам.assertRaises(ValueError): п.м.применить(вход,файл,п.м.хэш(файл.read_bytes()))
                сам.assertEqual(1,len(записано))
                with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']):
                    with сам.assertRaisesRegex(ValueError,'частичный'): п.м.применить(вход,файл,п.м.хэш(файл.read_bytes()))

    def test_служебное_дописывание_между_установками_начала_допускается(сам):
        п=сам.фикстура();вход=сам.до_начала(п)
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']): план=п.м.построить_план(вход)
        файл=Path(вход['каталог_выходов'])/'план-начала.json';файл.write_bytes(п.м.байты(план));файл.chmod(0o400)
        штатный=п.м.этап.каркас._install_prepared_file;записано=[]
        хвост=примеры.байты(служебная_оболочка({'type':'response_item','payload':{
            'type':'function_call_output','call_id':'call_1','output':'Получено.'}}))
        def установка(корень,элемент):
            штатный(корень,элемент);записано.append(элемент.path)
            if len(записано)==1:
                with Path(вход['живой_источник']).open('ab') as поток: поток.write(хвост)
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']),\
                mock.patch.object(п.м.этап.каркас,'_install_prepared_file',side_effect=установка):
            п.м.применить(вход,файл,п.м.хэш(файл.read_bytes()))
        сам.assertGreater(len(записано),1)
        for элемент in план['установка']:
            сам.assertEqual(элемент['sha256'],п.м.хэш(Path(элемент['путь']).read_bytes()))

    def test_конечные_границы_не_затирают_новую_штатную_цель(сам):
        п=сам.фикстура();вход=сам.до_начала(п)
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']): план=п.м.построить_план(вход)
        файл=Path(вход['каталог_выходов'])/'план-начала.json';файл.write_bytes(п.м.байты(план));файл.chmod(0o400)
        штатный=п.м.этап.каркас._install_prepared_file;записано=[]
        цель=Path(план['установка'][1]['путь']);новые=b'late writer bytes\n'
        def установка(корень,элемент):
            штатный(корень,элемент);записано.append(элемент.path)
            if len(записано)==1: цель.write_bytes(новые)
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']),mock.patch.object(п.м.этап.каркас,'_install_prepared_file',side_effect=установка):
            with сам.assertRaises(ValueError): п.м.применить(вход,файл,п.м.хэш(файл.read_bytes()))
        сам.assertEqual(1,len(записано));сам.assertEqual(новые,цель.read_bytes())

    def test_конечные_границы_согласованная_подмена_плана_не_самоподтверждается(сам):
        п=сам.фикстура();вход=сам.до_начала(п);план,итог,файл_плана=сам.применить(п,вход,'план-начала')
        модуль=importlib.import_module('поздняя_привязка_журнала')
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']): нативный=модуль._исходное(вход)[-1]
        файл=Path(итог['свидетельство']['путь']);каталог=файл.parent
        исходное=json.loads(файл.read_bytes());проверка=copy.deepcopy(вход)
        for вид in ('команды','начальный_HEAD','установка'):
            with сам.subTest(вид=вид):
                изменённый=copy.deepcopy(план);данные=copy.deepcopy(исходное)
                if вид=='команды':
                    изменённый['команды']=['Выдуманная команда.\n']
                    _,описания=модуль._штатный_снимок_постановки(Path(вход['корень']),вход['постановка']['коммит'],Path(данные['журнал']).name,
                        п.решение['поздний_журнал']['заголовок'],п.решение['координатор'],изменённый['команды'])
                    данные['файлы']=описания;изменённый['свидетельство']['файлы']=описания
                elif вид=='начальный_HEAD': изменённый['снимок']['HEAD']='0'*40
                else: изменённый['установка'][0]['sha256']='0'*64
                сырые=п.м.байты(изменённый);файл_плана.chmod(0o600);файл_плана.write_bytes(сырые);файл_плана.chmod(0o400)
                данные['план_начала']['sha256']=п.м.хэш(сырые)
                сырые=п.м.байты(данные);файл.chmod(0o600);файл.write_bytes(сырые);файл.chmod(0o400)
                ссылка={'путь':str(файл),'sha256':п.м.хэш(сырые)};проверка['поздняя_привязка']=ссылка
                (каталог/'завершённое-начало.json').write_bytes(п.м.байты({'свидетельство_sha256':ссылка['sha256'],'файлы':данные['файлы']}))
                (каталог/'завершённая-поздняя-привязка.json').write_bytes(п.м.байты({'план_sha256':данные['план_начала']['sha256'],
                    'вход_sha256':план['вход_sha256'],'результат':{'свидетельство':ссылка,'повтор':False}}))
                with сам.assertRaises(ValueError): модуль._свидетельство(проверка,п.решение,нативный)

    def test_конечные_границы_каждая_приватная_квитанция_проверяет_живой_источник(сам):
        п=сам.фикстура();вход=сам.до_начала(п);модуль=importlib.import_module('поздняя_привязка_журнала')
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']): план=п.м.построить_план(вход)
        файл=Path(вход['каталог_выходов'])/'план-начала.json';файл.write_bytes(п.м.байты(план));файл.chmod(0o400)
        штатный=модуль._установить
        def установка(цель,данные,режим):
            штатный(цель,данные,режим)
            if цель.name=='свидетельство-журнала.json':
                with Path(вход['живой_источник']).open('ab') as поток: поток.write(примеры.байты(примеры.сообщение('Останови запись.',101)))
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']),mock.patch.object(модуль,'_установить',side_effect=установка):
            with сам.assertRaises(ValueError): п.м.применить(вход,файл,п.м.хэш(файл.read_bytes()))
        сам.assertFalse((файл.parent/'завершённое-начало.json').exists())

    def test_новый_человек_после_позднего_рассмотрения_требует_нового_обзора_до_акта(сам):
        п=сам.фикстура();вход=сам.до_начала(п);план,итог,_=сам.применить(п,вход,'план-начала')
        акт=сам.поздний_обзор(п,вход,план,итог['свидетельство'])
        with Path(акт['живой_источник']).open('ab') as поток: поток.write(примеры.байты(примеры.сообщение('Отмена.',100)))
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=акт['писатель']):
            with сам.assertRaises(ValueError): п.м.построить_план(акт)
        сам.assertFalse((п.ф.корень/п.решение['акт']['путь']).exists())

    def test_самоподтверждённая_подмена_свидетельства_не_даёт_допуск(сам):
        п=сам.фикстура();вход=сам.до_начала(п);план,итог,_=сам.применить(п,вход,'план-начала')
        модуль=importlib.import_module('поздняя_привязка_журнала')
        with mock.patch.dict(os.environ,CODEX_THREAD_ID=вход['писатель']): нативный=модуль._исходное(вход)[-1]
        проверка=copy.deepcopy(вход);проверка['поздняя_привязка']=итог['свидетельство']
        файл=Path(итог['свидетельство']['путь']);исходные=файл.read_bytes()
        квитанция=файл.parent/'завершённое-начало.json';исходная_квитанция=квитанция.read_bytes()
        модуль._свидетельство(проверка,п.решение,нативный)
        for вид in ('время','RAW','область','сосед','штатный_состав'):
            with сам.subTest(вид=вид):
                данные=json.loads(исходные)
                if вид=='время': данные['время']['метка']='2026-10-10 00:00:00 MSK'
                elif вид=='RAW': данные['исходник_времени']['sha256']='0'*64
                elif вид=='область': данные['эффективная_область'].append('Чужая-область/')
                elif вид=='сосед': данные['файлы'].append({'путь':'Журнал/чужой-запрос/запрос.md','до_sha256':None,'после_sha256':'0'*64,'режим':0o644})
                else: данные['штатное_начало']['mode']='нештатное'
                сырые=п.м.байты(данные);файл.chmod(0o600);файл.write_bytes(сырые);файл.chmod(0o400)
                проверка['поздняя_привязка']['sha256']=п.м.хэш(сырые)
                квитанция.write_bytes(п.м.байты({'свидетельство_sha256':п.м.хэш(сырые),'файлы':данные['файлы']}))
                with сам.assertRaises(ValueError): модуль._свидетельство(проверка,п.решение,нативный)
        файл.chmod(0o600);файл.write_bytes(исходные);файл.chmod(0o400);квитанция.write_bytes(исходная_квитанция)


class ПустыеИменаНаблюдённойКвоты(unittest.TestCase):
    def test_пустые_имена_наблюдённой_квоты(сам):
        счётчики=dict.fromkeys(('input_tokens','cached_input_tokens','cache_write_input_tokens',
            'output_tokens','reasoning_output_tokens','total_tokens'),0)
        событие=служебная_оболочка({'type':'event_msg','payload':{'type':'token_count',
            'info':{'last_token_usage':счётчики,'total_token_usage':счётчики,'model_context_window':100},
            'rate_limits':{'credits':{'balance':'0','has_credits':False,'unlimited':False},
                'individual_limit':None,'limit_id':'лимит','limit_name':None,'plan_type':None,
                'primary':{'resets_at':1,'used_percent':0.0,'window_minutes':300},
                'rate_limit_reached_type':None,'secondary':None,'spend_control_reached':None}}})
        сам.assertTrue(примеры.основание.известный_служебный_хвост(событие,'корень'))
        for план,имя in [('План','Название'),(False,None),(None,False),({},None),(None,[])]:
            подмена=copy.deepcopy(событие);подмена['payload']['rate_limits'].update(plan_type=план,limit_name=имя)
            сам.assertFalse(примеры.основание.известный_служебный_хвост(подмена,'корень'))
        for раздел,поле,значение in [('info','model_context_window',True),
                ('rate_limits','неизвестное',None),('rate_limits','limit_id',None)]:
            подмена=copy.deepcopy(событие);подмена['payload'][раздел][поле]=значение
            сам.assertFalse(примеры.основание.известный_служебный_хвост(подмена,'корень'))
        for поле,значение in [('role','user'),('неизвестное',True)]:
            подмена=copy.deepcopy(событие);подмена['payload'][поле]=значение
            сам.assertFalse(примеры.основание.известный_служебный_хвост(подмена,'корень'))
        подмена=copy.deepcopy(событие);подмена['metadata']={
            'client_authored':False,'user_input_order':1,'sender_user_messages':[]}
        сам.assertFalse(примеры.основание.известный_служебный_хвост(подмена,'корень'))


if __name__ == '__main__': unittest.main()
