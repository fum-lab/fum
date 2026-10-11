"""Три свежих процесса: настоящий мост и pipe, синтетический читающий адаптер."""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile


СЦЕНАРИЙ = r'''
const проверка = require('node:assert/strict');
const криптография = require('node:crypto');
const файлы = require('node:fs');
const процессы = require('node:child_process');
const [корень, каталог, питон] = process.argv.slice(1);
const путь = корень + '/Инструменты/fum-svyaznostj-rabochej-sessii/scripts/';
const {передать_полный_ответ} = require(путь + 'мост_полного_ответа_узла.cjs');
const {отпечаток_строки} = require(путь + 'хэш_полного_ответа_узла.cjs');
const цикл = криптография.randomUUID(), задача = '01a127bf-38dd-7fc0-8c7b-1d245d7706a5';
const запрос = {схема:'fum.запрос-внешнего-чтения.1',цикл,
    параметры:{threadId:задача,hostId:'local',turnLimit:1,includeOutputs:true,maxOutputCharsPerItem:16000}};
const ответ = {content:[{type:'text',text:'ё🙂\n'.repeat(1000)}],structuredContent:{источник:'синтетическая фикстура'}};
ответ.content[0].text += 'x'.repeat(2381548 - Buffer.byteLength(JSON.stringify(ответ)));
const сырые = Buffer.from(JSON.stringify(ответ)); проверка.equal(сырые.length, 2381548);
const хэш = криптография.createHash('sha256').update(сырые).digest('hex');
let процесс, конец, готовность, вывод='', остаток='', вызовов=0, описаний=0, порций=0, предел=0;
let хэш_нс=0, готовность_нс=0, ожидание_нс=0;
const память = new Map();
const среда = {
  сохранить:(к,з)=>память.set(к,з), загрузить:к=>память.get(к),
  хэш:текст=>{const начало=process.hrtime.bigint();const итог=отпечаток_строки(текст);хэш_нс+=Number(process.hrtime.bigint()-начало);return итог;},
  принять_описание:async описание=>{проверка.deepEqual(описание,{цикл,задача,файл:каталог+'/чтение-'+цикл+'.json'});описаний++;},
  инструменты:{
    mcp__codex_app__read_thread:async параметры=>{проверка.deepEqual(параметры,запрос.параметры);вызовов++;return ответ;},
    exec_command:async параметры=>{
      проверка.equal(параметры.tty,true);проверка.equal(параметры.workdir,корень);
      const начало=process.hrtime.bigint();
      процесс=процессы.spawn(питон,['-B',путь+'приём_полного_ответа_узла.py','--корень-контейнера',каталог,
        '--цикл',цикл,'--задача',задача,'--запрос',JSON.stringify(запрос.параметры)],{stdio:['pipe','pipe','pipe']});
      let ошибки='';процесс.stderr.on('data',блок=>{ошибки+=блок;});
      готовность=new Promise((решить,отказать)=>{
        процесс.stdout.on('data',блок=>{
          остаток+=блок.toString('utf8');
          if(вывод==='') {const граница=остаток.indexOf('\n');if(граница>=0){вывод=остаток.slice(0,граница+1);остаток=остаток.slice(граница+1);решить(вывод);}}
        });
        процесс.on('error',отказать);
        процесс.on('close',код=>{if(вывод==='')отказать(Error('Нет готовности: '+код+' '+ошибки));});
      });
      конец=new Promise((решить,отказать)=>{
        процесс.on('error',отказать);
        процесс.on('close',код=>решить({exit_code:код,output:остаток}));
      });
      const строка=await готовность;готовность_нс=Number(process.hrtime.bigint()-начало);
      return {session_id:7,output:строка};
    },
    write_stdin:async параметры=>{
      проверка.equal(параметры.session_id,7);const размер=Buffer.byteLength(JSON.stringify(параметры));
      проверка(размер<=262144);предел=Math.max(предел,размер);
      const начало=process.hrtime.bigint();
      if(параметры.chars){порций++;await new Promise((решить,отказать)=>процесс.stdin.write(параметры.chars,'utf8',ошибка=>ошибка?отказать(ошибка):решить()));
        ожидание_нс+=Number(process.hrtime.bigint()-начало);return {session_id:7,output:''};}
      const итог=await конец;ожидание_нс+=Number(process.hrtime.bigint()-начало);return итог;
    }
  }
};
(async()=>{
  const начало=process.hrtime.bigint();
  try {
    const итог=await передать_полный_ответ(среда,{корень,контейнер:каталог,запрос});
    const всего_нс=Number(process.hrtime.bigint()-начало);
    проверка.equal(итог.состояние,'полный ответ сохранён');проверка.equal(итог.доставка_описания,'не подтверждена');
    проверка.equal(вызовов,1);проверка.equal(описаний,1);проверка.equal(итог.порций,порций);
    const файл=итог.подтверждение.файл;проверка.deepEqual(файлы.readFileSync(файл),сырые);
    проверка.equal(файлы.statSync(файл).mode&511,384);проверка.equal(итог.подтверждение.sha256,хэш);
    проверка.deepEqual(JSON.parse(файлы.readFileSync(файл.replace(/\.json$/,'.ack.json'))),итог.подтверждение);
    проверка(файлы.existsSync(файл.replace(/\.json$/,'.claim.json')));
    process.stdout.write(JSON.stringify({схема:'fum.профиль-моста-полного-ответа.1',всего_нс,хэш_нс,готовность_нс,ожидание_нс,
      байты:сырые.length,sha256:хэш,порций,максимальный_аргумент_байты:предел,
      синтетических_вызовов:вызовов,реальных_вызовов:0,описаний,
      доставка_описания:итог.доставка_описания,версия:process.version,пик_памяти_киб:process.resourceUsage().maxRSS})+'\n');
  } finally {if(процесс&&процесс.exitCode===null)процесс.kill();}
})().catch(ошибка=>{console.error(ошибка);process.exitCode=1;});
'''


def проверить(корень):
    результаты = []
    for каталог, шаблон in [('fum-svyaznostj-rabochej-sessii', 'test_моста_полного_ответа_узла.py'),
                            ('fum-perevod-obyyavlenij-koda-na-russkij-yazyik', 'test_сценари*.py')]:
        итог = subprocess.run([sys.executable, '-B', '-m', 'unittest', 'discover', '-s',
            str(корень / 'Инструменты' / каталог / 'tests'), '-p', шаблон],
            capture_output=True, text=True, timeout=60, cwd=корень)
        if итог.returncode != 0:
            raise RuntimeError(итог.stderr)
        результаты.append({'набор': каталог, 'код': итог.returncode,
                           'stdout_sha256': hashlib.sha256(итог.stdout.encode()).hexdigest(),
                           'stderr_sha256': hashlib.sha256(итог.stderr.encode()).hexdigest(),
                           'итог': итог.stderr.strip()})
    return результаты


def измерить(корень, узел):
    измерения = []
    for _ in range(3):
        with tempfile.TemporaryDirectory() as временный:
            итог = subprocess.run([узел, '-e', СЦЕНАРИЙ, str(корень), str(Path(временный).resolve()),
                                  sys.executable], capture_output=True, text=True, timeout=30)
            if итог.returncode != 0:
                raise RuntimeError(итог.stderr)
            измерения.append(json.loads(итог.stdout))
    исходники = {}
    for имя in ('мост_полного_ответа_узла.cjs', 'хэш_полного_ответа_узла.cjs',
                'приём_полного_ответа_узла.py', 'захват_вывода.py'):
        путь = корень / 'Инструменты/fum-svyaznostj-rabochej-sessii/scripts' / имя
        исходники[имя] = hashlib.sha256(путь.read_bytes()).hexdigest()
    return {'схема': 'fum.профиль-моста-полного-ответа.1', 'измерения': измерения,
            'медиана_нс': statistics.median(э['всего_нс'] for э in измерения),
            'исходники': исходники, 'питон': sys.version, 'реальных_вызовов': 0,
            'граница': 'Локальные callback и pipe; latency настоящих tools и Swift не измерена'}


def главная():
    разбор = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    разбор.add_argument('--корень-репозитория', type=Path, required=True)
    разбор.add_argument('--узел', default='/opt/homebrew/bin/node')
    разбор.add_argument('--проверить', action='store_true')
    параметры = разбор.parse_args()
    корень = параметры.корень_репозитория.resolve()
    проверки = проверить(корень) if параметры.проверить else []
    итог = измерить(корень, параметры.узел)
    итог['проверки'] = проверки
    print(json.dumps(итог, ensure_ascii=False, sort_keys=True))


if __name__ == '__main__':
    главная()
