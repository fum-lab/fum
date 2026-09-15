import sys,json,hashlib,subprocess,importlib.util
from pathlib import Path
корень=Path.cwd()
область='Инструменты/fum-proverka-mashinno-lokaljnyikh-putej'
sys.path.insert(0,str(корень/область/'scripts'))
путь=корень/область/'scripts/proveritj-mashinno-lokaljnyiye-puti.py'
спецификация=importlib.util.spec_from_file_location('сканер_сверки',путь);модуль=importlib.util.module_from_spec(спецификация);sys.modules[спецификация.name]=модуль;спецификация.loader.exec_module(модуль)
база='406c6ba1d0b3373403fefd14d5f7faf8e0665b7d';ведущая='a728283474931eda71cd581ca5429121124ba3f6'
def гит(*аргументы):return subprocess.check_output(['git',*аргументы],cwd=корень)
старая=json.loads(гит('show',база+':'+str(Path(область).joinpath('policy.json'))))
байты=гит('show',ведущая+':'+str(Path(область).joinpath('policy.json')));новая=json.loads(байты)
модуль.parse_policy(новая)
assert (корень/область/'policy-кандидата-слияния.json').read_bytes()==байты
прежние={з['id']:з for з in старая['exceptions']};новые={з['id']:з for з in новая['exceptions']}
assert len(прежние)==350 and len(новые)==419
assert all(новые[ключ]==значение for ключ,значение in прежние.items())
добавленные=[значение for ключ,значение in новые.items() if ключ not in прежние]
assert len(добавленные)==69
assert not {'message-processing-profile-disable-fixture-hooks','message-processing-test-disable-fixture-hooks'} & новые.keys()
кэш={};сверки=[]
for запись in новая['exceptions']:
    путь=запись['path']
    if путь not in кэш:кэш[путь]=модуль.scan_text(путь,гит('show',ведущая+':'+путь).decode())
    совпадения=[з for з in кэш[путь] if з.kind==запись['kind'] and з.line_sha256==запись['line_sha256'] and з.category.startswith('error.')]
    assert len(совпадения)==запись['count'],запись['id']
    if запись['id'] not in прежние:сверки.append({**запись,'строки_в_L':sorted({з.line for з in совпадения})})
происхождение=json.loads((корень/область/'происхождение-политики-слияния.json').read_bytes())
assert происхождение=={'ведущая_основа':ведущая,'дерево_основы':гит('rev-parse',ведущая+'^{tree}').decode().strip(),'прежних_исключений':350,'дополнительных_исключений':69,'принятие_слияния':False,'путь_политики':str(Path(область).joinpath('policy-кандидата-слияния.json')),'схема':'fum.политика-слияния.1','хэш_политики':'sha256:'+hashlib.sha256(байты).hexdigest()}
обычная=json.loads((корень/область/'policy.json').read_bytes())
assert len(обычная['exceptions'])==351
assert {з['id']:з for з in обычная['exceptions']}=={**прежние,'0176-projection-foreign-fixture':новые['0176-projection-foreign-fixture']}
итог=модуль.scan_repository(корень,Path(область).joinpath('policy.json'))
ошибки=[з.render() for з in итог.findings if з.category.startswith('error.')]
print(json.dumps({'проверено_исключений_L':419,'добавлено_в_обычную':1,'код_сканера':итог.exit_code,'ошибки':ошибки},ensure_ascii=False))
assert итог.exit_code==0
результат={'схема':'fum.сверка-политики-совместимости.1','M':база,'L':ведущая,'происхождение':происхождение,'исключений_обычной_политики':351,'полная_адресная_сверка':419,'добавления_кандидата':сверки,'обычная_политика_прошла_сканер':True}
Path("Журнал/2026-09-11_14-47-00_MSK_подготовить-совместимость-master-и-FUMA/материалы/сверка-политики.json").write_text(json.dumps(результат,ensure_ascii=False,indent=2)+'\n')
