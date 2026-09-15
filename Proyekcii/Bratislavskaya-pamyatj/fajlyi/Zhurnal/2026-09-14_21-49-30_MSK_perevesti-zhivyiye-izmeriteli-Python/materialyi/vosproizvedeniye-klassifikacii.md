# Vosproizvedeniye klassifikacii Python

Tri posledovateljnyikh scenariya izvlechenyi iz fakticheski vyipolnennyikh pryamyikh komand etogo etapa. Oni ispoljzuyut sokhranyonnyiye Git-obyyektyi i opublikovannyiye iskhodniki analizatora. Nuzhen otdeljnyij chistyij checkout itogovogo kommita s dostupnoj istoriyej; komandyi vyipolnyayutsya iz yego fizicheskogo kornya. Vyikhodnyiye JSON zamenyayutsya v nezavisimoj kopii, poetomu v iskhodnom dereve zakryitogo etapa komandyi ne zapuskayutsya. Rezuljtatyi ne razreshayut izmeneniye obsjhego snimka.

## Globaljno sopostavitj roli prezhnego i novogo Python-inventarizatora na odnikh bajtakh

```sh
python3 -B - <<'PY'
from pathlib import Path
import sys,json,hashlib,subprocess,importlib.util,types,collections,ast
корень=Path.cwd(); путь_скрипта='Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py'
sys.path.insert(0,str((корень/путь_скрипта).parent))
исходная_ревизия='436909208424595f7151f6febca75f89018c0bcb'; постановка='c93b0fbca8c5d676eecec7023bc6df1a19c25b91'
байты_старого=subprocess.check_output(['git','show',исходная_ревизия+':'+путь_скрипта],cwd=корень)
старый=types.ModuleType('исторический_сканер'); старый.__file__=str(корень/путь_скрипта); sys.modules[старый.__name__]=старый
exec(compile(байты_старого,'<исторический-сканер>','exec'),старый.__dict__)
спецификация=importlib.util.spec_from_file_location('нынешний_сканер',корень/путь_скрипта); новый=importlib.util.module_from_spec(спецификация);sys.modules[спецификация.name]=новый;спецификация.loader.exec_module(новый)
def дерево_гита(ревизия):
 результат={}
 for строка in subprocess.check_output(['git','ls-tree','-rz',ревизия],cwd=корень).split(b'\0'):
  if not строка: continue
  мета,имя=строка.split(b'\t'); режим,вид,объект=мета.split()
  if вид==b'blob': результат[имя.decode()]=объект.decode()
 return результат
история=дерево_гита(исходная_ревизия); база=дерево_гита(постановка)
файлы=[]; прибавлено=collections.Counter(); убрано=collections.Counter(); классы=collections.Counter(); всего_до=всего_после=0
for файл in новый.файлы_репозитория(корень):
 if файл.suffix.lower()!='.py': continue
 путь=файл.relative_to(корень).as_posix(); байты=файл.read_bytes(); объект=hashlib.sha1(b'blob '+str(len(байты)).encode()+b'\0'+байты).hexdigest()
 до=[з.словарь() for з in старый.объявления_питона(файл,путь)]; после=[з.словарь() for з in новый.объявления_питона(файл,путь)]
 ключ=lambda з:json.dumps(з,ensure_ascii=False,sort_keys=True)
 до_счёт=collections.Counter(map(ключ,до)); после_счёт=collections.Counter(map(ключ,после))
 добавления=[json.loads(з) for з in (после_счёт-до_счёт).elements()]; удаления=[json.loads(з) for з in (до_счёт-после_счёт).elements()]
 for з in добавления: прибавлено[з['вид']]+=1
 for з in удаления: убрано[з['вид']]+=1
 состояние='неизменён_от_снимка' if история.get(путь)==объект else 'неизменён_от_постановки' if база.get(путь)==объект else 'изменён_или_новый_в_0173'
 if добавления or удаления: классы[состояние]+=1
 файлы.append({'путь':путь,'sha256':hashlib.sha256(байты).hexdigest(),'blob':объект,'blob_снимка':история.get(путь),'blob_постановки':база.get(путь),'происхождение':состояние,'до':len(до),'после':len(после),'добавления':добавления,'удаления':удаления})
 всего_до+=len(до); всего_после+=len(после)
результат={'схема':'fum.эффект-python-сканера.1','снимок':исходная_ревизия,'постановка':постановка,'старый_сканер_sha256':hashlib.sha256(байты_старого).hexdigest(),'новый_сканер_sha256':hashlib.sha256((корень/путь_скрипта).read_bytes()).hexdigest(),'helper_sha256':hashlib.sha256((корень/путь_скрипта).with_name('безопасные_привязки_python.py').read_bytes()).hexdigest(),'метод':'Оба анализатора читают одни текущие байты всех Python-путей штатного инвентаря. Полный ключ включает путь, язык, вид, имя, строку, столбец. Историческое совпадение подтверждается Git blob; исходный общий снимок не заменён.','итог':{'файлов':len(файлы),'до':всего_до,'после':всего_после,'добавления_по_видам':dict(прибавлено),'удаления_по_видам':dict(убрано),'изменившиеся_файлы_по_происхождению':dict(классы)},'файлы':файлы}
Path('Журнал/2026-09-14_21-49-30_MSK_перевести-живые-измерители-Python/материалы/эффект-python-сканера.json').write_text(json.dumps(результат,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(результат['итог'],ensure_ascii=False))
PY
```

## Svyazatj kazhdoye novoye nablyudeniye Python so strokami tochnyikh iskhodnyikh Git-obyyektov

```sh
python3 -B - <<'PY'
from pathlib import Path
import sys,json,hashlib,subprocess,importlib.util,tempfile,difflib,collections
корень=Path.cwd(); скрипт=корень/'Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py';sys.path.insert(0,str(скрипт.parent))
спецификация=importlib.util.spec_from_file_location('сканер_происхождения',скрипт);модуль=importlib.util.module_from_spec(спецификация);sys.modules[спецификация.name]=модуль;спецификация.loader.exec_module(модуль)
материалы=корень/'Журнал/2026-09-14_21-49-30_MSK_перевести-живые-измерители-Python/материалы'; эффект=json.loads((материалы/'эффект-python-сканера.json').read_text())
свидетельства=[]; итог=collections.Counter()
with tempfile.TemporaryDirectory() as каталог:
 временный=Path(каталог)/'вход.py'
 for файл in эффект['файлы']:
  if not файл['добавления']: continue
  нынешний=(корень/файл['путь']).read_text(); сопоставления=[]
  for тип,ревизия,объект in [('до_снимка',эффект['снимок'],файл['blob_снимка']),('до_постановки',эффект['постановка'],файл['blob_постановки'])]:
   if объект is None: continue
   исходник=subprocess.check_output(['git','cat-file','blob',объект],cwd=корень).decode(); временный.write_text(исходник)
   строки={}
   for блок in difflib.SequenceMatcher(None,исходник.splitlines(),нынешний.splitlines(),autojunk=False).get_matching_blocks():
    for сдвиг in range(блок.size): строки[блок.a+сдвиг+1]=блок.b+сдвиг+1
   записи={}
   for з in модуль.объявления_питона(временный,файл['путь']):
    if з.строка in строки: записи[(строки[з.строка],з.столбец,з.вид,з.имя)]=з.строка
   сопоставления.append((тип,ревизия,объект,записи))
  for запись in файл['добавления']:
   ключ=tuple(запись[к] for к in ['строка','столбец','вид','имя']); доказательство=None
   for тип,ревизия,объект,записи in сопоставления:
    if ключ in записи:
     доказательство={'класс':тип,'ревизия':ревизия,'blob':объект,'исходная_строка':записи[ключ],'метод':'Та же строка исходных байтов по SequenceMatcher; совпали байтовый столбец, вид и имя нового анализатора.'};break
   if доказательство is None: доказательство={'класс':'не_доказано'}
   итог[доказательство['класс']]+=1;свидетельства.append({'наблюдение':запись,'происхождение':доказательство})
результат={'схема':'fum.происхождение-расширения-python.1','эффект_sha256':hashlib.sha256((материалы/'эффект-python-сканера.json').read_bytes()).hexdigest(),'итог':dict(итог),'добавления':свидетельства}
(материалы/'происхождение-расширения-python.json').write_text(json.dumps(результат,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(результат['итог'],ensure_ascii=False))
for з in свидетельства:
 if з['происхождение']['класс']!='до_снимка': print(з)
PY
```

## Klassificirovatj udalyonnyiye vneshniye AST-roli i konechnyij ostatok 22 Python-putej

```sh
python3 -B - <<'PY'
from pathlib import Path
import sys,json,hashlib,subprocess,importlib.util,tempfile,ast,collections
корень=Path.cwd(); скрипт=корень/'Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py';sys.path.insert(0,str(скрипт.parent))
с=importlib.util.spec_from_file_location('итоговый_сканер',скрипт); м=importlib.util.module_from_spec(с);sys.modules[с.name]=м;с.loader.exec_module(м)
материалы=корень/'Журнал/2026-09-14_21-49-30_MSK_перевести-живые-измерители-Python/материалы'
эффект=json.loads((материалы/'эффект-python-сканера.json').read_text()); удаления=[]
for файл in эффект['файлы']:
 if not файл['удаления']:continue
 текст=(корень/файл['путь']).read_text();дерево=ast.parse(текст);родители={ребёнок:родитель for родитель in ast.walk(дерево) for ребёнок in ast.iter_child_nodes(родитель)}
 assert any(isinstance(у,ast.Import) and any(п.name=='ast' and not п.asname for п in у.names) for у in дерево.body)
 for запись in файл['удаления']:
  узлы=[у for у in ast.walk(дерево) if getattr(у,'lineno',None)==запись['строка'] and getattr(у,'col_offset',-2)+1==запись['столбец'] and (getattr(у,'name',None)==запись['имя'] or getattr(у,'id',None)==запись['имя'])]
  assert len(узлы)==1,запись
  класс=родители[узлы[0]]
  while not isinstance(класс,ast.ClassDef): класс=родители[класс]
  assert any(isinstance(б,ast.Attribute) and isinstance(б.value,ast.Name) and б.value.id=='ast' and б.attr in {'NodeVisitor','NodeTransformer'} for б in класс.bases)
  assert запись['имя'] in м.контекстные_имена_посетителя
  удаления.append({'наблюдение':запись,'класс':'внешний_API_ast','владелец':класс.name,'базы':[ast.unparse(б) for б in класс.bases],'строка_класса':класс.lineno,'исходная_строка':текст.splitlines()[запись['строка']-1].strip(),'sha256':файл['sha256']})
прежний=json.loads((корень/'Журнал/2026-09-14_20-41-53_MSK_перевести-унаследованные-привязки-Python/материалы/сверка-унаследованной-дельты.json').read_text())
пути=[ф['путь'] for ф in прежний['файлы']]
префикс='Журнал/2026-09-10_20-23-26_MSK_проверить-слияние-после-допуска/материалы/'
пути += [префикс+имя for имя in ['продвижение-до-оптимизации.py','измерить-продвижение.py','измерить-совместимость-подготовки.py']]
итог=[]; остаток=collections.Counter()
with tempfile.TemporaryDirectory() as каталог:
 временный=Path(каталог)/'вход.py'
 for путь in пути:
  файл=корень/путь; байты=файл.read_bytes()
  старое=subprocess.run(['git','show',эффект['снимок']+':'+путь],cwd=корень,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
  временный.write_bytes(старое.stdout if старое.returncode==0 else b'')
  до=м.объявления_питона(временный,путь); после=м.объявления_питона(файл,путь)
  счёт_до=collections.Counter((з.вид,з.имя) for з in до);счёт_после=collections.Counter((з.вид,з.имя) for з in после)
  добавления=счёт_после-счёт_до; записи=[]
  for (вид,имя),число in добавления.items():
   if путь.endswith('/продвижение-до-оптимизации.py'):
    assert hashlib.sha256(байты).hexdigest()=='c8695da01383f3c131d8eb82dc9df90d43adbe7ebcbf54661349ec6199002fce'
    класс='защищённый_исторический_before'
   elif имя in {'setUp','handle_starttag','handle_endtag','Popen'}: класс='внешний_API'
   elif (имя=='env' and путь.endswith('/run-smoke-check.py')) or (имя=='body_bytes' and путь.endswith('/source_archive.py')):класс='повтор_старой_привязки'
   else:класс='необоснованный_остаток'
   остаток[класс]+=число
   записи.append({'вид':вид,'имя':имя,'число':число,'класс':класс,'координаты_текущих_записей':[[з.строка,з.столбец] for з in после if (з.вид,з.имя)==(вид,имя)]})
  итог.append({'путь':путь,'sha256':hashlib.sha256(байты).hexdigest(),'до':len(до),'после':len(после),'добавления':записи,'удаления':[{'вид':в,'имя':и,'число':ч} for (в,и),ч in (счёт_до-счёт_после).items()]})
результат={'схема':'fum.конечная-классификация-python.1','снимок':эффект['снимок'],'постановка':эффект['постановка'],'эффект_sha256':hashlib.sha256((материалы/'эффект-python-сканера.json').read_bytes()).hexdigest(),'удаления_ролей':удаления,'итог':dict(остаток),'файлы':итог}
(материалы/'конечная-классификация-python.json').write_text(json.dumps(результат,ensure_ascii=False,indent=2)+'\n')
print('Внешних AST-ролей',len(удаления),'путей',len(итог),json.dumps(результат['итог'],ensure_ascii=False))
assert not остаток['необоснованный_остаток']
PY
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-14 22:10:02 MSK -->
<!-- content-sha256: sha256:a00bd3cf37f1861dab35199ce159eb89aecc91503ef1536813fa3284c6626c65 -->
<!-- FUM-MD-RECENCY:END -->
