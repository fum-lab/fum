"""Настоящие subprocess и полный Git; native host всегда синтетический."""
import copy
import base64
import hashlib
import io
import json
import os
from pathlib import Path
import signal
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock
import uuid

КОРЕНЬ = Path(__file__).resolve().parents[3]
sys.path.insert(0,str(КОРЕНЬ/'Инструменты/fum-svyaznostj-rabochej-sessii/scripts'))
import сформировать_нативный_вызов as генератор
import наблюдать_подготовку_базиса as наблюдатель
import сверить_нативную_подготовку as читатель
import test_приёма_базиса_состояния_узла as фикстуры

def записать(путь, данные):
    путь.parent.mkdir(parents=True, exist_ok=True)
    with путь.open('xb') as поток: поток.write(данные)
    путь.chmod(0o400)

ЛАБОРАТОРНЫЙ_ХОСТ = r'''
const вход = JSON.parse(process.argv[1]);
const байты = Buffer.from(вход.JS, "base64");
const крипто = await import("node:crypto");
if (крипто.createHash("sha256").update(байты).digest("hex") !== вход.sha256) throw new Error("SHA harness");
const вызовы = [], ожидания = [], выводы = [], задержки = [];
const исходы = вход.события.map(э => Object.freeze(э));
let завершён = false;
globalThis.tools = {
  exec_command: параметры => {
    вызовы.push({вид:"exec",параметры:параметры});
    return new Promise(решить => ожидания.push(решить));
  },
  write_stdin: параметры => {
    вызовы.push({вид:"poll",параметры:параметры});
    return new Promise(решить => ожидания.push(решить));
  }
};
globalThis.text = данные => выводы.push(данные);
const шаг = () => new Promise(решить => setImmediate(решить));
const импорт = import("data:text/javascript;base64," + вход.JS).then(() => { завершён = true; });
for (let номер = 0; номер < исходы.length; номер += 1) {
  for (let попытка = 0; попытка < 100 && ожидания.length === 0; попытка += 1) await шаг();
  if (ожидания.length !== 1) throw new Error("не появился один ожидаемый вызов");
  await шаг(); await шаг();
  задержки.push(!завершён && выводы.length === 0);
  ожидания.shift()(исходы[номер]);
}
await импорт;
if (ожидания.length || выводы.length !== 1 || выводы[0].события.length !== исходы.length
  || !выводы[0].события.every((э,номер) => э === исходы[номер])) throw new Error("потеря host objects");
process.stdout.write(JSON.stringify({вызовы:вызовы,задержки:задержки,события:выводы[0].события}));
'''

class Пример:
    def __init__(сам, каталог):
        сам.основа = каталог.resolve()
        место = сам.основа/'первичный'/'узел'; место.mkdir(parents=True)
        сам.ф = фикстуры.ПримерИсполняемогоПриёма(место)
        сам.корень = сам.ф.корень.resolve()
        сам.доказательства = сам.основа/'доказательства'; сам.доказательства.mkdir(mode=0o700)
        сам.код = сам.основа/'код'; сам.код.mkdir()
        генератор.гит(сам.код,'init','-q')
        записи = []
        for имя in генератор.СОСТАВ:
            путь = сам.код/имя; путь.parent.mkdir(parents=True,exist_ok=True)
            данные = (КОРЕНЬ/имя).read_bytes()
            путь.write_bytes(данные); путь.chmod(0o644)
        генератор.гит(сам.код,'add','--',*генератор.СОСТАВ)
        генератор.гит(сам.код,'-c','user.name=Фикстура','-c','user.email=fixture@local',
            '-c','commit.gpgsign=false','commit','-qm','Синтетический принятый код')
        сам.коммит = генератор.гит(сам.код,'rev-parse','HEAD').decode().strip()
        for имя in генератор.СОСТАВ:
            данные = (сам.код/имя).read_bytes()
            записи.append({'путь':имя,'blob':генератор.гит(сам.код,'rev-parse','HEAD:'+имя).decode().strip(),
                'sha256':генератор.хэш(данные),'байты':len(данные)})
        вход = сам.ф.вход_приёма(); вход['схема'] = 'fum.вход-приёма-базиса-узла.2'
        сам.вход = сам.доказательства/'вход.json'
        записать(сам.вход,генератор.байты(вход))
        приёмка = фикстуры.запуск.разобрать(фикстуры.запуск.прочитать_источник(
            сам.корень, вход['приёмка']))
        контур = фикстуры.запуск.разобрать(фикстуры.запуск.прочитать_источник(
            сам.корень, вход['контур']))
        ключ = фикстуры.запуск._ключ_долговечного_приёма(приёмка)
        сам.поколение = {'R':ключ['R'],'A':вход['приёмка']['коммит'],'ACT':вход['акт']['коммит'],
            'G':генератор.хэш('синтетическое поколение'.encode()),'nonce':str(uuid.uuid4()),'пауза':False}
        сам.генерация = сам.доказательства/'поколение.json'
        записать(сам.генерация,генератор.байты(сам.поколение))
        постоянные = {имя:ключ[имя] for имя in ('владелец','хэш_корня','ветка')}
        база = сам.корень.parent/('fum-приватная-нативная-подготовка-'+генератор.хэш(генератор.байты(постоянные)))
        база.mkdir(mode=0o700)
        сам.слот = база/ключ['R']
        питон = Path(sys.executable).resolve()
        сам.выбор = {'схема':'fum.выбор-нативной-подготовки.1','версия':генератор.ВЕРСИЯ,
            'исполнитель':str(uuid.uuid4()),'корень_кода':str(сам.код),'корень':str(сам.корень),
            'коммит_кода':сам.коммит,'файлы':записи,
            'Python':{'путь':str(питон),'sha256':генератор.хэш(питон.read_bytes()),
                'личность':list(генератор.отпечаток(питон.stat()))},
            'вход':{'путь':str(сам.вход),'sha256':генератор.хэш(сам.вход.read_bytes()),'личность':list(генератор.отпечаток(сам.вход.stat()))},
            'поколение':{'путь':str(сам.генерация),'sha256':генератор.хэш(сам.генерация.read_bytes()),'личность':list(генератор.отпечаток(сам.генерация.stat()))},
            'ожидаемое_поколение':сам.поколение,'ключ':ключ,'K':контур['K'],'слот':str(сам.слот),
            'операция':'--подготовить-запуск',
            'бюджет':{'подготовка_мс':40000,'exec_мс':1000,'ожиданий':10,'ожидание_мс':5000,'токенов':8000}}
        сам.номер = 0; сам.закрепить()

    def закрепить(сам):
        сам.номер += 1
        сам.путь = сам.доказательства/('выбор-'+str(сам.номер)+'.json')
        записать(сам.путь,генератор.байты(сам.выбор))
        сам.хэш = генератор.хэш(сам.путь.read_bytes())

    def команда(сам):
        # Получаем неизменённый cmd утверждённого JS, без исполнения JS.
        сценарий = генератор.сформировать(str(сам.путь),сам.хэш)
        строка = next(э for э in сценарий.splitlines() if 'const команда = ' in э)
        return сценарий,json.loads(строка.split(' = ',1)[1][:-1])

    def выполнить(сам):
        сценарий,команда = сам.команда()
        начало = time.monotonic_ns()
        р = subprocess.run(['/bin/sh','-c',команда],cwd=сам.корень,capture_output=True,timeout=60)
        сам.внешний = р
        события = [{'output':р.stdout.decode()+р.stderr.decode(),'exit_code':р.returncode,
            'wall_time_seconds':(time.monotonic_ns()-начало)/1e9}]
        return сам.нативный(сценарий,события)

    def нативный(сам,сценарий,события):
        # Явно синтетический носитель: это не native исполнение Codex.
        ход = str(uuid.uuid4()); вызов = 'call_'+uuid.uuid4().hex
        метаданные = {'turn_id':ход,'create_time':1.0}
        записи = [
            {'type':'session_meta','ordinal':0,'payload':{'id':сам.выбор['исполнитель'],'cwd':str(сам.код)}},
            {'type':'turn_context','ordinal':1,'payload':{'turn_id':ход,'cwd':str(сам.код)}},
            {'type':'response_item','ordinal':2,'payload':{'type':'custom_tool_call','id':'fixture-вызов','call_id':вызов,
                'status':'completed','name':'exec','input':сценарий,'internal_chat_message_metadata_passthrough':метаданные}},
            {'type':'response_item','ordinal':3,'payload':{'type':'custom_tool_call_output','id':'fixture-output',
                'call_id':вызов,'output':[{'type':'input_text','text':'Script completed\nWall time 0.0 seconds\nOutput:\n'},
                    {'type':'input_text','text':генератор.байты({'схема':'fum.нативные-события-подготовки.1','события':события}).decode()}],
                'internal_chat_message_metadata_passthrough':метаданные},'metadata':{'client_authored':False}}]
        сам.записи = записи; сам.выбранный_вызов = вызов
        return сам.сохранить_нативный(ход,вызов)

    def сохранить_нативный(сам,ход=None,вызов=None):
        if ход is None: ход=сам.записи[1]['payload']['turn_id']
        if вызов is None: вызов=сам.выбранный_вызов
        номер_вызова = next(н for н,э in enumerate(сам.записи) if э.get('payload',{}).get('type') == 'custom_tool_call'
            and э['payload'].get('call_id') == вызов)
        сырые = [генератор.байты(dict(э, timestamp=э.get('timestamp','2026-01-01T00:00:00.000Z'))) for э in сам.записи]
        начало = 0; места = []
        for б in сырые:
            места.append({'начало':начало,'конец':начало+len(б),'sha256':генератор.хэш(б)})
            начало += len(б)
        сам.номер += 1; путь = сам.доказательства/('синтетический-native-'+str(сам.номер)+'.jsonl')
        записать(путь,b''.join(сырые))
        return {'схема':'fum.ожидание-нативной-подготовки.1','выбор':str(сам.путь),
            'выбор_sha256':сам.хэш,'JS_sha256':генератор.хэш(сам.записи[номер_вызова]['payload']['input'].encode()),
            'исполнитель':сам.выбор['исполнитель'],'turn_id':ход,'call_id':вызов,
            'корень_контекста':str(сам.код),'источник':{'путь':str(путь),
                'личность':list(генератор.отпечаток(путь.stat())),'мета':места[0],
                'интервал':{'начало':места[1]['начало'],'конец':места[-1]['конец'],
                    'sha256':генератор.хэш(b''.join(сырые[1:]))},
                'вызов':места[номер_вызова],'исход':места[-1]}}

class НативнаяПодготовка(unittest.TestCase):
    def setUp(сам):
        сам.временный = tempfile.TemporaryDirectory(prefix='fum-native-fixture-')
        сам.addCleanup(сам.временный.cleanup)
        сам.ф = Пример(Path(сам.временный.name))

    def test_отказ_синхронизации_родителя_слота_не_запускает_процесс(сам):
        выбор, удержанные = генератор.удержать_выбор(str(сам.ф.путь), сам.ф.хэш)
        родитель = сам.ф.слот.parent.stat()
        исходная = наблюдатель.синхронизировать
        def синхронизировать(фд):
            состояние = os.fstat(фд)
            if (состояние.st_dev, состояние.st_ino) == (родитель.st_dev, родитель.st_ino):
                raise OSError('синтетический отказ fsync родителя')
            исходная(фд)
        try:
            with mock.patch.object(наблюдатель, 'синхронизировать', синхронизировать), \
                    mock.patch.object(наблюдатель.subprocess, 'Popen', wraps=subprocess.Popen) as запуск, \
                    mock.patch.object(наблюдатель.sys, 'stdout', new=type('Вывод', (), {'buffer':io.BytesIO()})()):
                with сам.assertRaisesRegex(OSError, 'fsync родителя'):
                    наблюдатель.наблюдать(выбор, удержанные)
                сам.assertFalse(any(э.kwargs.get('start_new_session') is True for э in запуск.call_args_list))
            сам.assertTrue(сам.ф.слот.is_dir())
            сам.assertFalse((сам.ф.слот/'процесс.json').exists())
        finally:
            for файл in удержанные.values(): файл.закрыть()

    def test_ошибка_после_настоящего_запуска_останавливает_и_собирает_группу(сам):
        # Настоящая группа с дочерним sleeper; bootstrap здесь явно синтетический.
        маркер = сам.ф.доказательства/'дочерний-pid.txt'
        код = 'import subprocess,sys,time\n' \
            + 'п=subprocess.Popen([sys.executable,"-I","-S","-B","-c","import time;time.sleep(30)"])\n' \
            + 'open(' + repr(str(маркер)) + ',"x").write(str(п.pid))\n' \
            + 'time.sleep(30)\n'
        выбор, удержанные = генератор.удержать_выбор(str(сам.ф.путь), сам.ф.хэш)
        исходная = наблюдатель.сохранить
        процессы = []
        настоящий = subprocess.Popen
        def запуск(*аргументы, **параметры):
            процесс = настоящий(*аргументы, **параметры)
            if параметры.get('start_new_session') is True: процессы.append(процесс)
            return процесс
        def сохранить(каталог, имя, данные, атомарно=False):
            if имя == 'процесс.json':
                предел = time.monotonic() + 5
                while not маркер.exists() and time.monotonic() < предел: time.sleep(0.01)
                сам.assertTrue(маркер.exists(), 'реальный потомок не появился')
                raise OSError('синтетический отказ процесс.json')
            return исходная(каталог, имя, данные, атомарно)
        try:
            with mock.patch.object(наблюдатель, 'ДОЧЕРНИЙ_ЗАГРУЗЧИК', код), \
                    mock.patch.object(наблюдатель, 'сохранить', сохранить), \
                    mock.patch.object(наблюдатель.subprocess, 'Popen', запуск), \
                    mock.patch.object(наблюдатель.sys, 'stdout', new=type('Вывод', (), {'buffer':io.BytesIO()})()):
                сам.assertEqual(наблюдатель.наблюдать(выбор, удержанные), 2)
            сам.assertEqual(len(процессы), 1)
            процесс = процессы[0]
            with сам.assertRaises(ProcessLookupError): os.killpg(процесс.pid, 0)
            with сам.assertRaises(ChildProcessError): os.waitpid(процесс.pid, os.WNOHANG)
            квитанция = генератор.разобрать((сам.ф.слот/'квитанция.json').read_bytes())
            сам.assertTrue(квитанция['завершён'])
            сам.assertIn('процесс.json', квитанция['ошибка'])
            сам.assertEqual(квитанция['сигнал'], signal.SIGKILL)
            намерение = (сам.ф.слот/'намерение.json').read_bytes()
            with сам.assertRaises(FileExistsError): наблюдатель.наблюдать(выбор, удержанные)
            сам.assertEqual((сам.ф.слот/'намерение.json').read_bytes(), намерение)
        finally:
            # Даже RED не оставляет синтетическую группу за пределами теста.
            for процесс in процессы:
                try: os.killpg(процесс.pid, signal.SIGKILL)
                except ProcessLookupError: pass
                процесс.wait(timeout=5)
            for файл in удержанные.values(): файл.закрыть()

    def test_настоящий_сценарий_полные_каналы_и_сохранность_гита(сам):
        до = генератор.гит(сам.ф.корень,'rev-parse','HEAD')
        о = сам.ф.выполнить()
        сам.assertEqual(сам.ф.внешний.returncode,0,сам.ф.внешний.stderr.decode())
        р = читатель.сверить(о)
        сам.assertTrue(р['подготовка_подтверждена']); сам.assertFalse(р['разрешение_эффекта'])
        сам.assertEqual(генератор.гит(сам.ф.корень,'rev-parse','HEAD'),до)
        сам.assertEqual(р['каналы']['stderr']['байты'],0)

    def test_никакого_повтора_с_новым_одноразовым_значением(сам):
        сам.ф.выполнить()
        старое = (сам.ф.слот/'намерение.json').read_bytes()
        сам.ф.поколение['nonce']=str(uuid.uuid4())
        сам.ф.генерация.chmod(0o600); сам.ф.генерация.write_bytes(генератор.байты(сам.ф.поколение)); сам.ф.генерация.chmod(0o400)
        сам.ф.выбор['поколение']['sha256']=генератор.хэш(сам.ф.генерация.read_bytes());сам.ф.выбор['поколение']['личность']=list(генератор.отпечаток(сам.ф.генерация.stat()));сам.ф.закрепить()
        сам.ф.выполнить()
        сам.assertNotEqual(сам.ф.внешний.returncode,0)
        сам.assertEqual((сам.ф.слот/'намерение.json').read_bytes(),старое)

    def test_закрытая_операция_и_поля(сам):
        for имя,значение in [('операция','--вход'),('argv',[]),('eval','код')]:
            исходный=copy.deepcopy(сам.ф.выбор);сам.ф.выбор[имя]=значение;сам.ф.закрепить()
            with сам.subTest(имя=имя),сам.assertRaises((ValueError,KeyError)):
                сам.ф.команда()
            сам.ф.выбор=исходный

    def test_подмена_кода_входа_и_интерпретатора(сам):
        for путь in [сам.ф.код/генератор.ШАБЛОН,сам.ф.вход]:
            старое=путь.read_bytes();режим=путь.stat().st_mode
            путь.chmod(0o600);путь.write_bytes(старое+b' ');путь.chmod(режим&0o777)
            with сам.subTest(путь=путь),сам.assertRaises(ValueError): сам.ф.команда()
            путь.chmod(0o600);путь.write_bytes(старое);путь.chmod(режим&0o777)
        сам.ф.выбор['вход']['личность']=list(генератор.отпечаток(сам.ф.вход.stat()))
        сам.ф.выбор['Python']['личность'][1]+=1;сам.ф.закрепить()
        with сам.assertRaises(ValueError): сам.ф.команда()

    def test_устаревшее_поколение_и_пауза(сам):
        о=сам.ф.выполнить()
        for поле,значение in [('G','0'*64),('пауза',True)]:
            старое=сам.ф.генерация.read_bytes();п=генератор.разобрать(старое);п[поле]=значение
            сам.ф.генерация.chmod(0o600);сам.ф.генерация.write_bytes(генератор.байты(п));сам.ф.генерация.chmod(0o400)
            with сам.subTest(поле=поле),сам.assertRaises(ValueError): читатель.сверить(о)
            сам.ф.генерация.chmod(0o600);сам.ф.генерация.write_bytes(старое);сам.ф.генерация.chmod(0o400)

    def test_внешний_ноль_не_скрывает_внутреннюю_ошибку(сам):
        сам.ф.выбор['K']='0'*40;сам.ф.закрепить()
        о=сам.ф.выполнить()
        сам.assertNotEqual(сам.ф.внешний.returncode,0)
        тело=генератор.разобрать(сам.ф.записи[-1]['payload']['output'][1]['text'].encode())
        тело['события'][-1]['exit_code']=0
        сам.ф.записи[-1]['payload']['output'][1]['text']=генератор.байты(тело).decode()
        with сам.assertRaises(ValueError): читатель.сверить(сам.ф.сохранить_нативный())

    def test_настоящий_тайм_аут_сохраняет_намерение(сам):
        сам.ф.выбор['бюджет']['подготовка_мс']=1;сам.ф.закрепить();о=сам.ф.выполнить()
        сам.assertNotEqual(сам.ф.внешний.returncode,0)
        сам.assertTrue((сам.ф.слот/'намерение.json').is_file())
        кв=генератор.разобрать((сам.ф.слот/'квитанция.json').read_bytes())
        сам.assertTrue(кв['тайм_аут']);сам.assertEqual(кв['сигнал'],signal.SIGKILL)
        with сам.assertRaises(ValueError): читатель.сверить(о)

    def test_настоящий_сигнал_не_становится_успешной_подготовкой(сам):
        выбор, удержанные = генератор.удержать_выбор(str(сам.ф.путь), сам.ф.хэш)
        исходная = наблюдатель.сохранить
        def сохранить(каталог, имя, данные, атомарно=False):
            исходная(каталог, имя, данные, атомарно)
            if имя == 'процесс.json': os.killpg(генератор.разобрать(данные)['pid'], signal.SIGTERM)
        try:
            with mock.patch.object(наблюдатель, 'сохранить', сохранить), \
                    mock.patch.object(наблюдатель.sys, 'stdout', new=type('Вывод', (), {'buffer':io.BytesIO()})()):
                сам.assertEqual(наблюдатель.наблюдать(выбор, удержанные), 2)
            кв = генератор.разобрать((сам.ф.слот/'квитанция.json').read_bytes())
            сам.assertEqual(кв['сигнал'], signal.SIGTERM)
            сам.assertFalse(кв['тайм_аут']); сам.assertTrue(кв['завершён'])
        finally:
            for файл in удержанные.values(): файл.закрыть()

    def test_одного_напечатанного_сообщения_недостаточно(сам):
        выбор, удержанные = генератор.удержать_выбор(str(сам.ф.путь), сам.ф.хэш)
        печать = генератор.байты({'схема':'fum.подготовленный-запуск-приёма-базиса.1',
            'вход_sha256':выбор['вход']['sha256'],'ключ':выбор['ключ'],
            'процесс':{'код':0,'исполнение_завершено':True,'тайм_аут':False,'прерывание':None}})
        код = 'import sys;sys.stdout.buffer.write(' + repr(печать) + ')'
        try:
            with mock.patch.object(наблюдатель, 'ДОЧЕРНИЙ_ЗАГРУЗЧИК', код), \
                    mock.patch.object(наблюдатель.sys, 'stdout', new=type('Вывод', (), {'buffer':io.BytesIO()})()):
                сам.assertEqual(наблюдатель.наблюдать(выбор, удержанные), 2)
            кв = генератор.разобрать((сам.ф.слот/'квитанция.json').read_bytes())
            сам.assertEqual(кв['подготовка_код'], 0)
            сам.assertIsNotNone(кв['ошибка'])
            сам.assertEqual(кв['каналы']['аудит']['байты'], 0)
        finally:
            for файл in удержанные.values(): файл.закрыть()

    def test_удержанный_вход_не_становится_ссылкой_перед_запуском(сам):
        выбор, удержанные = генератор.удержать_выбор(str(сам.ф.путь), сам.ф.хэш)
        прежний = сам.ф.вход.with_suffix('.прежний')
        сам.ф.вход.rename(прежний); сам.ф.вход.symlink_to(прежний)
        try:
            with сам.assertRaises(ValueError): наблюдатель.наблюдать(выбор, удержанные)
            сам.assertFalse(сам.ф.слот.exists())
        finally:
            сам.ф.вход.unlink(); прежний.rename(сам.ф.вход)
            for файл in удержанные.values(): файл.закрыть()

    def test_дополнительная_жёсткая_ссылка_закрывает_вход(сам):
        os.link(сам.ф.вход, сам.ф.доказательства/'другая-ссылка')
        with сам.assertRaises(ValueError): сам.ф.команда()
        сам.assertFalse(сам.ф.слот.exists())

    def test_точный_сценарий_исполняется_в_явно_синтетическом_хосте(сам):
        узел = shutil.which('node')
        сам.assertIsNotNone(узел, 'для лабораторного JS требуется Node.js с ESM')
        живой = {'output':'','session_id':73,'wall_time_seconds':0}
        конец = {'output':'{}','exit_code':0,'wall_time_seconds':0}
        случаи = [(10,[конец]), (10,[живой,живой,конец]),
            (10,[живой,dict(живой,session_id=74)]), (0,[живой]), (10,[живой]*11),
            (10,[dict(живой,session_id='73')]), (10,[dict(живой,session_id=True)]),
            (10,[dict(конец,exit_code=2)])]
        for предел, события in случаи:
            сам.ф.выбор['бюджет']['ожиданий'] = предел; сам.ф.закрепить()
            сценарий, команда = сам.ф.команда()
            for убрать_ожидание in (False, True) if события == [конец] else (False,):
                проверяемый = сценарий.replace('await ', '', 1) if убрать_ожидание else сценарий
                вход = {'JS':base64.b64encode(проверяемый.encode()).decode(),
                    'sha256':генератор.хэш(проверяемый.encode()),'события':события}
                р = subprocess.run([узел,'--input-type=module','-e',ЛАБОРАТОРНЫЙ_ХОСТ,
                    генератор.байты(вход).decode()], capture_output=True, timeout=10)
                with сам.subTest(предел=предел,события=события,убрать_await=убрать_ожидание):
                    сам.assertEqual(р.returncode, 0, р.stderr.decode())
                    результат = генератор.разобрать(р.stdout)
                    сам.assertEqual(результат['задержки'][0], not убрать_ожидание)
                    if not убрать_ожидание: сам.assertTrue(all(результат['задержки']))
                    сам.assertEqual(результат['события'], события)
                    сам.assertEqual(результат['вызовы'][0], {'вид':'exec','параметры':{
                        'cmd':команда,'workdir':str(сам.ф.корень),'shell':'/bin/sh','login':False,
                        'max_output_tokens':8000,'yield_time_ms':1000}})
                    сам.assertEqual(len(результат['вызовы']), len(события))
                    for вызов in результат['вызовы'][1:]:
                        сам.assertEqual(вызов, {'вид':'poll','параметры':{
                            'session_id':73,'chars':'','max_output_tokens':8000,'yield_time_ms':5000}})

    def test_чужие_владелец_ход_вызов_и_внешний_сеанс(сам):
        о=сам.ф.выполнить()
        изменения=[
            lambda:сам.ф.записи[0]['payload'].update(id=str(uuid.uuid4())),
            lambda:сам.ф.записи[1]['payload'].update(turn_id=str(uuid.uuid4())),
            lambda:сам.ф.записи[-1]['payload'].update(call_id='call_foreign'),
            lambda:сам.ф.записи[-1]['payload']['output'][0].update(text='Script running with cell ID abc'),
            lambda:сам.ф.записи[-1]['payload']['output'].append({'type':'input_text','text':'extra'}),
            lambda:сам.ф.записи[-1]['payload'].update(output=[])]
        старое=copy.deepcopy(сам.ф.записи)
        for действие in изменения:
            сам.ф.записи=copy.deepcopy(старое);действие()
            with сам.subTest(действие=действие),сам.assertRaises((ValueError,KeyError)):
                читатель.сверить(сам.ф.сохранить_нативный(о['turn_id'],о['call_id']))

    def test_полная_композиция_обязательно_включает_внешнее_ожидание(сам):
        сам.ф.выполнить();старое=copy.deepcopy(сам.ф.записи)
        for замена in [('await ','',1),('();\n','()();\n',1),('/bin/sh','/bin/bash',1),
                ('login: false','login: true',1), ('"10"','"9"',1),
                ('"1000"','"250"',1), ('"5000"','"1000"',1),
                ('"8000"','"1000"',1), ('session_id: сеанс','session_id: 74',1)]:
            сам.ф.записи=copy.deepcopy(старое)
            исходный=сам.ф.записи[2]['payload']['input']
            сам.ф.записи[2]['payload']['input']=исходный.replace(*замена)
            сам.assertNotEqual(сам.ф.записи[2]['payload']['input'], исходный)
            with сам.subTest(замена=замена),сам.assertRaises(ValueError):
                читатель.сверить(сам.ф.сохранить_нативный())

    def test_повреждённые_промежуточные_рамки_и_клиентский_вызов_закрыты(сам):
        сценарий, _ = сам.ф.команда()
        сам.ф.нативный(сценарий, [{'output':'{}','exit_code':0,'wall_time_seconds':0}])
        старое = copy.deepcopy(сам.ф.записи)
        для_вставки = [
            {'type':'неизвестный_вид','ordinal':3,'payload':{}},
            {'type':'event_msg','ordinal':3,'payload':None},
            {'type':'response_item','ordinal':3,'payload':{'type':'неизвестный_вид','call_id':'call_other'}}]
        for рамка in для_вставки:
            сам.ф.записи = copy.deepcopy(старое)
            сам.ф.записи[-1]['ordinal'] = 4
            сам.ф.записи.insert(3, рамка)
            with сам.subTest(рамка=рамка), сам.assertRaises(ValueError):
                читатель.прочитать_нативный(сам.ф.сохранить_нативный())
        сам.ф.записи = copy.deepcopy(старое)
        сам.ф.записи[2]['metadata'] = {'client_authored':True}
        with сам.assertRaises(ValueError):
            читатель.прочитать_нативный(сам.ф.сохранить_нативный())

    def test_повреждённые_тела_известных_рамок_не_пропускаются(сам):
        сценарий, _ = сам.ф.команда()
        сам.ф.нативный(сценарий, [{'output':'{}','exit_code':0,'wall_time_seconds':0}])
        старое = copy.deepcopy(сам.ф.записи)
        рамки = [
            {'type':'event_msg','payload':{'type':'неизвестный_вид'}},
            {'type':'token_usage_record','payload':{}},
            {'type':'response_item','payload':{'type':'message','content':False}}]
        for рамка in рамки:
            сам.ф.записи = copy.deepcopy(старое)
            сам.ф.записи.insert(3, dict(рамка,ordinal=3))
            сам.ф.записи[-1]['ordinal'] = 4
            with сам.subTest(рамка=рамка), сам.assertRaises(ValueError):
                читатель.прочитать_нативный(сам.ф.сохранить_нативный())

    def test_обычный_транспорт_и_иная_предшествующая_пара_допустимы(сам):
        сценарий, _ = сам.ф.команда()
        сам.ф.нативный(сценарий, [{'output':'{}','exit_code':0,'wall_time_seconds':0}])
        ход = сам.ф.записи[1]['payload']['turn_id']
        посторонний = copy.deepcopy(сам.ф.записи[2])
        посторонний['payload'].update(call_id='call_other', id='fixture-other', input='text("лабораторная предыдущая пара");')
        завершение = copy.deepcopy(сам.ф.записи[-1]); завершение['payload'].update(call_id='call_other', id='fixture-other-output')
        событие = {'type':'event_msg','payload':{'type':'item_completed',
            'thread_id':сам.ф.выбор['исполнитель'],'turn_id':ход,'started_at_ms':1,'completed_at_ms':2,
            'item':{'type':'AgentMessage','id':'fixture-transport','phase':'commentary',
                'content':[{'type':'Text','text':'Явно синтетическая транспортная копия'}]}}}
        счётчики = {имя:0 for имя in ('input_tokens','cached_input_tokens','cache_write_input_tokens',
            'output_tokens','reasoning_output_tokens','total_tokens')}
        токены = {'type':'token_usage_record','payload':{'thread_id':сам.ф.выбор['исполнитель'],
            'session_id':сам.ф.выбор['исполнитель'],'turn_id':ход,'root_turn_id':ход,
            'response_id':'fixture-response','usage':счётчики,'turn_token_usage':счётчики,'thread_token_usage':счётчики}}
        сам.ф.записи[2:2] = [посторонний, завершение]
        сам.ф.записи[-1:-1] = [событие, токены]
        for номер,запись in enumerate(сам.ф.записи): запись['ordinal'] = номер
        ожидание = сам.ф.сохранить_нативный()
        пара = читатель.прочитать_нативный(ожидание)
        сам.assertEqual(пара['вызов']['payload']['call_id'], сам.ф.выбранный_вызов)
        сам.assertEqual(пара['исход']['payload']['call_id'], сам.ф.выбранный_вызов)
        # Та же primary-пара внутри выбранного исполнения уже не нейтральна.
        сам.ф.записи[2:4] = []; сам.ф.записи[-1:-1] = [посторонний, завершение]
        for номер,запись in enumerate(сам.ф.записи): запись['ordinal'] = номер
        with сам.assertRaises(ValueError): читатель.прочитать_нативный(сам.ф.сохранить_нативный())

    def test_повтор_пары_усечение_и_дрейф_байтов_закрыты(сам):
        сценарий, _ = сам.ф.команда()
        сам.ф.нативный(сценарий, [{'output':'{}','exit_code':0,'wall_time_seconds':0}])
        старое = copy.deepcopy(сам.ф.записи)
        for номер in (2, 3):
            сам.ф.записи = copy.deepcopy(старое)
            сам.ф.записи.insert(номер, copy.deepcopy(сам.ф.записи[номер]))
            for н,запись in enumerate(сам.ф.записи): запись['ordinal'] = н
            with сам.subTest(номер=номер), сам.assertRaises(ValueError):
                читатель.прочитать_нативный(сам.ф.сохранить_нативный())
        сам.ф.записи = старое; ожидание = сам.ф.сохранить_нативный()
        путь = Path(ожидание['источник']['путь']); байты = путь.read_bytes()
        for изменённое in (байты[:-1], байты.replace(b'fixture-output', b'fixture-tamper', 1)):
            путь.chmod(0o600); путь.write_bytes(изменённое); путь.chmod(0o400)
            ожидание['источник']['личность'] = list(генератор.отпечаток(путь.stat()))
            with сам.assertRaises(ValueError): читатель.прочитать_нативный(ожидание)

    def test_неполные_каналы_и_квитанция(сам):
        о=сам.ф.выполнить()
        for имя in ['stderr.bin','квитанция.json']:
            п=сам.ф.слот/имя;сохранённый=п.with_suffix('.сохранённый');п.rename(сохранённый)
            with сам.subTest(имя=имя),сам.assertRaises(OSError): читатель.сверить(о)
            сохранённый.rename(п)

class ЦепьСессии(unittest.TestCase):
    def test_слишком_глубокий_вход_даёт_контролируемый_отказ(сам):
        with сам.assertRaisesRegex(ValueError, 'глубина JSON'):
            генератор.разобрать(b'['*2000 + b'0' + b']'*2000)
        внутри_строки = {'строка':'{'*2000 + '\\"'*2000 + '}'*2000}
        сам.assertEqual(генератор.разобрать(генератор.байты(внутри_строки)), внутри_строки)
        генератор.разобрать(b'['*генератор.ПРЕДЕЛ_ГЛУБИНЫ + b'0' + b']'*генератор.ПРЕДЕЛ_ГЛУБИНЫ)
        with сам.assertRaisesRegex(ValueError, 'глубина JSON'):
            генератор.разобрать(b'['*(генератор.ПРЕДЕЛ_ГЛУБИНЫ+1) + b'0' + b']'*(генератор.ПРЕДЕЛ_ГЛУБИНЫ+1))
    def test_истинная_цепь_и_чужой_сеанс(сам):
        б={'ожиданий':3,'токенов':8000}
        живой={'output':'','session_id':73,'wall_time_seconds':1}
        конец={'output':'{}','exit_code':0,'wall_time_seconds':1}
        сам.assertEqual(читатель.проверить_события([живой,живой,конец],б),'{}')
        for события in [[живой], [конец,конец], [живой,dict(живой,session_id=74),конец],
                [dict(живой,exit_code=0),конец], [dict(конец,original_token_count=8001)]]:
            with сам.subTest(события=события),сам.assertRaises(ValueError):
                читатель.проверить_события(события,б)

if __name__ == '__main__':
    unittest.main()
