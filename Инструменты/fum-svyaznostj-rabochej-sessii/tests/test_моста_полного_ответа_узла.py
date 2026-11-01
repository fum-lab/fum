"""Полный поток, закрытый путь и один исход текущего API вместо ручных порций."""
import hashlib
import importlib
import io
import json
import os
import pty
from pathlib import Path
import select
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

СЦЕНАРИИ = Path(__file__).resolve().parents[1] / 'scripts'
ЦИКЛ = '6e1dd367-490c-4ffe-acbd-886cc5b2adc6'
ЗАДАЧА = '01a127bf-38dd-7fc0-8c7b-1d245d7706a5'
ЗАПРОС = {'threadId': ЗАДАЧА, 'hostId': 'local', 'turnLimit': 1,
          'includeOutputs': True, 'maxOutputCharsPerItem': 16000}


def строка(значение):
    return (json.dumps(значение, ensure_ascii=False, separators=(',', ':')) + '\n').encode()


def конверт(данные, **замены):
    заголовок = {'схема': 'fum.передача-полного-ответа.1', 'цикл': ЦИКЛ,
                 'задача': ЗАДАЧА, 'запрос': ЗАПРОС, 'байты': len(данные),
                 'sha256': hashlib.sha256(данные).hexdigest()}
    заголовок.update(замены)
    конец = {'схема': 'fum.конец-полного-ответа.1', 'цикл': ЦИКЛ,
             'задача': ЗАДАЧА, 'байты': заголовок['байты'], 'sha256': заголовок['sha256']}
    return строка(заголовок) + данные + b'\n' + строка(конец)


class ПолныйОтвет(unittest.TestCase):
    def модуль(сам):
        sys.path.insert(0, str(СЦЕНАРИИ))
        return importlib.import_module('приём_полного_ответа_узла')

    def test_прерывание_после_готовности_не_разрешает_повтор(сам):
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный).resolve()
            команда = [sys.executable, '-B', str(СЦЕНАРИИ / 'приём_полного_ответа_узла.py'),
                       '--корень-контейнера', str(каталог), '--цикл', ЦИКЛ,
                       '--задача', ЗАДАЧА, '--запрос', json.dumps(ЗАПРОС)]
            процесс = subprocess.Popen(команда, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            try:
                сам.assertEqual(json.loads(процесс.stdout.readline())['цикл'], ЦИКЛ)
                намерение = каталог / ('чтение-' + ЦИКЛ + '.claim.json')
                сам.assertTrue(намерение.is_file())
                исходник = намерение.read_bytes()
                сам.assertEqual(намерение.stat().st_mode & 0o777, 0o600)
            finally:
                процесс.kill(); процесс.wait()
                for поток in (процесс.stdin, процесс.stdout, процесс.stderr):
                    поток.close()
            повтор = subprocess.run(команда, input=b'', capture_output=True, timeout=10)
            сам.assertEqual(повтор.returncode, 2)
            сам.assertEqual(повтор.stdout, b'')
            сам.assertEqual(намерение.read_bytes(), исходник)

    def test_терминальный_вход_не_эхоит_и_не_буферизует_кадр(сам):
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный).resolve()
            главный, дочерний = pty.openpty()
            процесс = subprocess.Popen([sys.executable, '-B', str(СЦЕНАРИИ / 'приём_полного_ответа_узла.py'),
                '--корень-контейнера', str(каталог), '--цикл', ЦИКЛ, '--задача', ЗАДАЧА,
                '--запрос', json.dumps(ЗАПРОС)], stdin=дочерний, stdout=дочерний, stderr=subprocess.PIPE)
            os.close(дочерний)
            def прочитать_строку():
                результат = b''
                while not результат.endswith(b'\n'):
                    сам.assertTrue(select.select([главный], [], [], 10)[0])
                    результат += os.read(главный, 1)
                    сам.assertLess(len(результат), 16384)
                return результат
            try:
                сам.assertEqual(json.loads(прочитать_строку())['цикл'], ЦИКЛ)
                данные = json.dumps({'текст': 'ё🙂\r\n\0' * 100}, ensure_ascii=False).encode()
                сам.модуль().захват.записать(главный, конверт(данные))
                подтверждение = json.loads(прочитать_строку())
                сам.assertEqual(подтверждение['схема'], 'fum.ACK-полного-ответа.1')
                сам.assertEqual(Path(подтверждение['файл']).read_bytes(), данные)
                сам.assertEqual(процесс.wait(timeout=10), 0)
            finally:
                if процесс.poll() is None:
                    процесс.kill(); процесс.wait()
                процесс.stderr.close(); os.close(главный)

    def test_большой_поток_без_закрытия_ввода_и_точные_байты(сам):
        данные = json.dumps({'текст': 'ё\n🙂\0' * 190000}, ensure_ascii=False).encode()
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный).resolve()
            процесс = subprocess.Popen([sys.executable, '-B', str(СЦЕНАРИИ / 'приём_полного_ответа_узла.py'),
                '--корень-контейнера', str(каталог), '--цикл', ЦИКЛ, '--задача', ЗАДАЧА,
                '--запрос', json.dumps(ЗАПРОС)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            try:
                готовность = json.loads(процесс.stdout.readline())
                сам.assertEqual(готовность['схема'], 'fum.готовность-приёма-ответа.1')
                кадр = конверт(данные)
                for начало in range(0, len(кадр), 317):
                    процесс.stdin.write(кадр[начало:начало + 317])
                процесс.stdin.flush()
                # stdin остаётся открытым: завершение обеспечивает кадр, а не EOF.
                сам.assertEqual(процесс.wait(timeout=20), 0)
                подтверждение = json.loads(процесс.stdout.read())
                сам.assertEqual(подтверждение['байты'], len(данные))
                сам.assertEqual(подтверждение['sha256'], hashlib.sha256(данные).hexdigest())
                путь = Path(подтверждение['файл'])
                сам.assertEqual(путь.read_bytes(), данные)
                сам.assertEqual(путь.stat().st_mode & 0o777, 0o600)
                сам.assertEqual(json.loads((каталог / ('чтение-' + ЦИКЛ + '.ack.json')).read_text()), подтверждение)
            finally:
                if процесс.poll() is None:
                    процесс.kill()
                    процесс.wait()
                for поток in (процесс.stdin, процесс.stdout, процесс.stderr):
                    поток.close()

    def test_короткая_запись_и_ошибка_синхронизации(сам):
        модуль = сам.модуль()
        данные = 'ё🙂'.encode() * 100
        запись = os.write
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный).resolve()
            with mock.patch.object(модуль.захват.os, 'write', side_effect=lambda ручка, блок: запись(ручка, блок[:7])):
                подтверждение = модуль.принять(io.BytesIO(конверт(данные)), каталог, ЦИКЛ, ЗАДАЧА, ЗАПРОС)
            сам.assertEqual(Path(подтверждение['файл']).read_bytes(), данные)
        for причина in ('нулевая запись', 'fsync'):
            with сам.subTest(причина=причина), tempfile.TemporaryDirectory() as временный:
                каталог = Path(временный).resolve()
                подмена = mock.patch.object(модуль.захват.os, 'write', return_value=0) if причина == 'нулевая запись' else mock.patch.object(модуль.os, 'fsync', side_effect=OSError('fsync'))
                with подмена, сам.assertRaises(OSError):
                    модуль.принять(io.BytesIO(конверт(данные)), каталог, ЦИКЛ, ЗАДАЧА, ЗАПРОС)
                сам.assertFalse((каталог / ('чтение-' + ЦИКЛ + '.ack.json')).exists())

    def test_чужой_контекст_повреждение_и_закрытый_путь(сам):
        модуль = сам.модуль()
        данные = b'{"answer":1}'
        варианты = [('digest', конверт(данные, sha256='0' * 64)),
                    ('контекст', конверт(данные, задача='01a07d3d-d376-7ad2-aafc-67e4c25a67eb')),
                    ('обрыв', конверт(данные)[:-15]),
                    ('кадр', конверт(данные).replace(b'fum.' + 'конец'.encode(), b'fum.' + 'отказ'.encode())),
                    ('предел', конверт(данные, байты=67108865))]
        for имя, поток in варианты:
            with сам.subTest(имя=имя), tempfile.TemporaryDirectory() as временный:
                каталог = Path(временный).resolve()
                with сам.assertRaises((ValueError, OSError)):
                    модуль.принять(io.BytesIO(поток), каталог, ЦИКЛ, ЗАДАЧА, ЗАПРОС)
                сам.assertFalse((каталог / ('чтение-' + ЦИКЛ + '.ack.json')).exists())
        with tempfile.TemporaryDirectory() as временный:
            каталог = Path(временный).resolve()
            цель = каталог / ('чтение-' + ЦИКЛ + '.json')
            цель.write_bytes(b'original')
            with сам.assertRaises(FileExistsError):
                модуль.принять(io.BytesIO(конверт(данные)), каталог, ЦИКЛ, ЗАДАЧА, ЗАПРОС)
            сам.assertEqual(цель.read_bytes(), b'original')
            ссылка = каталог / 'ссылка'
            ссылка.symlink_to(каталог, target_is_directory=True)
            with сам.assertRaises((ValueError, OSError)):
                модуль.принять(io.BytesIO(конверт(данные)), ссылка, ЦИКЛ, ЗАДАЧА, ЗАПРОС)

    def test_один_вызов_сырой_исторический_ответ_и_неизвестный_исход(сам):
        сценарий = r'''
const проверка = require('node:assert/strict');
const криптография = require('node:crypto');
const {передать_полный_ответ} = require(process.argv[1] + '/мост_полного_ответа_узла.cjs');
const {отпечаток_строки} = require(process.argv[1] + '/хэш_полного_ответа_узла.cjs');
for (const текст of ['', 'abc', 'ё🙂\0', 'a'.repeat(100000), '😀'.repeat(1000)]) {
  const ожидаемый = Buffer.from(текст, 'utf8');
  проверка.deepEqual(отпечаток_строки(текст), {байты:ожидаемый.length, sha256:криптография.createHash('sha256').update(ожидаемый).digest('hex')});
}
async function проверить(сбой) {
  const цикл = '6e1dd367-490c-4ffe-acbd-886cc5b2adc6', задача = '01a127bf-38dd-7fc0-8c7b-1d245d7706a5';
  const запрос = {схема:'fum.запрос-внешнего-чтения.1',цикл,параметры:{threadId:задача,hostId:'local',turnLimit:1,includeOutputs:true,maxOutputCharsPerItem:16000}};
  const параметры = {корень:'/repo',контейнер:'/private/container',запрос,лимит_аргумента:4096};
  const файл = '/private/container/чтение-' + цикл + '.json';
  let вызовов=0, записей=0, описаний=0, кадр='';const память=new Map();
  const ответ={content:[{type:'text',text:'ё🙂\n'.repeat(10000)}]};
  const среда={хэш:отпечаток_строки,сохранить:(к,з)=>память.set(к,з),загрузить:к=>память.get(к),
    инструменты:{exec_command:async()=>({session_id:7,output:JSON.stringify({схема:'fum.готовность-приёма-ответа.1',цикл,задача,файл})+'\n'}),
      mcp__codex_app__read_thread:async п=>{проверка.deepEqual(п,запрос.параметры);вызовов++;return ответ;},
      write_stdin:async п=>{записей++;if(сбой==='unknown'&&записей===2)throw Error('неизвестный исход');кадр+=п.chars;
        проверка(Buffer.byteLength(JSON.stringify(п))<=4096);
        const раздел=кадр.indexOf('\n'),заголовок=JSON.parse(кадр.slice(0,раздел));
        const всё=Buffer.from(кадр.slice(раздел+1));
        if(всё.length<заголовок.байты+2)return {session_id:7,output:''};
        const сырые=всё.subarray(0,заголовок.байты);
        проверка.equal(сырые.toString(),JSON.stringify(ответ));
        const конец=JSON.parse(всё.subarray(заголовок.байты+1).toString());проверка.equal(конец.цикл,цикл);
        return {exit_code:0,output:JSON.stringify({схема:'fum.ACK-полного-ответа.1',цикл,задача,файл,байты:сырые.length,sha256:криптография.createHash('sha256').update(сырые).digest('hex')})+'\n'};
      }}, принять_описание:async п=>{проверка.deepEqual(п,{цикл,задача,файл});описаний++;}};
  if(сбой==='история')параметры.сырой_ответ=JSON.stringify(ответ);
  const результат=await передать_полный_ответ(среда,параметры);
  if(сбой){проверка.equal(результат.состояние,'не принят');проверка.equal(описаний,0);проверка.equal(вызовов,сбой==='история'?0:1);}
  else {
    проверка.equal(результат.состояние,'полный ответ сохранён');
    проверка.equal(результат.доставка_описания,'не подтверждена');
    проверка.equal(вызовов,1);проверка.equal(описаний,1);проверка(записей>2);
    for (const новые of [{...параметры,корень:'/other'}, {...параметры,контейнер:'/other'},
      {...параметры,запрос:{...запрос,параметры:{...запрос.параметры,cursor:'иной'}}}]) {
      const повтор = await передать_полный_ответ(среда,новые);
      проверка.equal(повтор.состояние,'не принят');проверка.equal(вызовов,1);проверка.equal(описаний,1);
    }
  }
  await передать_полный_ответ(среда,параметры);проверка.equal(вызовов,сбой==='история'?0:1);проверка.equal(описаний,сбой?0:1);
}
(async()=>{await проверить(null);await проверить('unknown');await проверить('история');process.stdout.write('ok\n');})().catch(ошибка=>{console.error(ошибка);process.exit(1)});
'''
        итог = subprocess.run(['/opt/homebrew/bin/node', '-e', сценарий, str(СЦЕНАРИИ)], capture_output=True, text=True, timeout=30)
        сам.assertEqual(итог.returncode, 0, итог.stderr)
        сам.assertEqual(итог.stdout, 'ok\n')


if __name__ == '__main__':
    unittest.main()
