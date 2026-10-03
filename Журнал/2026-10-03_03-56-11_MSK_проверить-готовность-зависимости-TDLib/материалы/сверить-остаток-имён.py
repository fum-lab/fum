"""Сверка семантики латинских объявлений A8 с исходным Git-снимком, без записи в Git."""
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile

корень=Path(sys.argv[1]).resolve()
исходныйКоммит='16fbb601afa5fb05f9ae58a85791b11155b5ccee'
путьМодуля=корень/'Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/scripts/перевести-объявления-кода.py'
sys.path.insert(0,str(путьМодуля.parent))
спецификация=importlib.util.spec_from_file_location('сверка_остатка',путьМодуля)
модуль=importlib.util.module_from_spec(спецификация)
sys.modules[спецификация.name]=модуль
спецификация.loader.exec_module(модуль)
инвентарь=модуль.построить_инвентарь(корень)
изменённые=subprocess.run(['git','diff',исходныйКоммит,'--name-only','-z'],cwd=корень,check=True,capture_output=True).stdout.decode().split('\0')
изменённые={имя for имя in изменённые if имя}
исходные=[объявление for объявление in инвентарь['объявления'] if объявление['путь'] not in изменённые]
with tempfile.TemporaryDirectory(prefix='fum-a8-name-baseline-') as временный:
 for имя in sorted(изменённые):
  суффикс=Path(имя).suffix.lower()
  if суффикс not in ('.py','.swift','.md'): continue
  чтение=subprocess.run(['git','cat-file','-e',исходныйКоммит+':'+имя],cwd=корень,capture_output=True)
  if чтение.returncode: continue
  байты=subprocess.run(['git','show',исходныйКоммит+':'+имя],cwd=корень,check=True,capture_output=True).stdout
  файл=Path(временный)/Path(имя).name
  файл.write_bytes(байты)
  разбор={'.py':модуль.объявления_питона,'.swift':модуль.объявления_свифт,'.md':модуль.объявления_мермейд}[суффикс]
  исходные.extend(модуль.отфильтровать_аббревиатуры([запись.словарь() for запись in разбор(файл,имя)]))
исходные=[запись.словарь() for запись in sorted(модуль.Объявление(**запись) for запись in исходные)]
базовыйИнвентарь={'версия_схемы':инвентарь['версия_схемы'],'объявления':исходные}
снимок=json.loads((корень/'Инструменты/fum-perevod-obyyavlenij-koda-na-russkij-yazyik/остаток-объявлений-кода.json').read_bytes())

def семантика(объявления):
 return Counter(tuple(запись[ключ] for ключ in ('путь','язык','вид','имя')) for запись in объявления)

сейчас=семантика(инвентарь['объявления'])
раньше=семантика(исходные)
добавлены=list((сейчас-раньше).elements())
удалены=list((раньше-сейчас).elements())
# setUp — обязательное внешнее переопределение unittest.TestCase, правило000028.
import ast
внешниеПереопределения=[]
путьТестов='Приложения/FUMA/Packages/КлиентTelegram/Проверки/test_сборка_tdlib.py'
синтаксис=ast.parse((корень/путьТестов).read_text())
for узел in синтаксис.body:
 if isinstance(узел,ast.ClassDef) and узел.name=='ПроверкиГотовностиЗависимости' and any(isinstance(основа,ast.Attribute) and isinstance(основа.value,ast.Name) and основа.value.id=='unittest' and основа.attr=='TestCase' for основа in узел.bases):
  for метод in узел.body:
   if isinstance(метод,ast.FunctionDef) and метод.name=='setUp':
    запись=(путьТестов,'python','функция','setUp')
    if запись in добавлены:
     добавлены.remove(запись)
     внешниеПереопределения.append({'объявление':запись,'основание':'Внешний lifecycle unittest.TestCase.setUp, правило000028; проверен AST наследования и точный метод.'})

итог={'схема':'fum.сверка-семантического-остатка-имён.1','исход':'успех' if not добавлены else 'неуспех','исходныйКоммит':исходныйКоммит,'проверяющийИсходникШа256':hashlib.sha256(путьМодуля.read_bytes()).hexdigest(),'сохранённыйСнимок':снимок,'исходныйСнимок':модуль.сводка_снимка(базовыйИнвентарь),'текущийСнимок':модуль.сводка_снимка(инвентарь),'добавленныеОбъявления':добавлены,'удалённыеОбъявления':удалены,'новыеВнешниеПереопределения':внешниеПереопределения,'граница':'Позиции строк/столбцов сравниваются в точных снимках, но не определяют новизну объявления; общий снимок не изменяется; удаление прежних латинских переменных в заменённом контуре чтения учитывается отдельно.'}
print(json.dumps(итог,ensure_ascii=False,indent=2))
raise SystemExit(0 if итог['исход']=='успех' else 2)
