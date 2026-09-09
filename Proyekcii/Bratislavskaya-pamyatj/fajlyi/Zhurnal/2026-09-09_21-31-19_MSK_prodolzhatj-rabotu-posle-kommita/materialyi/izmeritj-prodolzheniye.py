import ast, hashlib, json, statistics, subprocess, time, tempfile
from pathlib import Path
корень=Path.cwd()
путь="Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py"
старый=subprocess.check_output(["git","show","84d10f885fb8b837f4d99f25b09f408753b4b6df:"+путь]).decode()
новый=Path(путь).read_text()
функции={}
for версия,текст in (("до",старый),("после",новый)):
 дерево=ast.parse(текст)
 узел=next(x for x in дерево.body if isinstance(x,ast.FunctionDef) and x.name=="действует_ручная_последовательная_схема")
 среда={"Path":Path,"МАРКЕР_РУЧНОЙ_ПОСЛЕДОВАТЕЛЬНОЙ_СХЕМЫ":"<!-- FUM-WRITING-MODE: manual-sequential-v1 -->","РУЧНЫЕ_ПОСЛЕДОВАТЕЛЬНЫЕ_РЕЖИМЫ":("manual-sequential-v1","manual-sequential-v2")}
 exec(compile(ast.Module(body=[узел],type_ignores=[]),путь,"exec"),среда)
 функции[версия]=среда[узел.name]
результаты=[]
with tempfile.TemporaryDirectory() as временный:
 стенд=Path(временный)
 вход=Path("AGENTS.md").read_text().replace("manual-sequential-v2","manual-sequential-v1")
 (стенд/"AGENTS.md").write_text(вход)
 for прогон in range(6):
  for версия in (("до","после") if прогон%2==0 else ("после","до")):
   начало=time.perf_counter_ns()
   for номер in range(3000):assert функции[версия](стенд)
   результаты.append({"версия":версия,"прогон":прогон+1,"вызовов":3000,"наносекунд":time.perf_counter_ns()-начало})
итог={"схема":"fum.профиль-продолжения.1","сравниваемая_граница":"Чтение AGENTS.md и распознавание ручного режима; одинаковый вход v1, 6 чередующихся пар по 3000 вызовов, без Git-процессов внутри функции","sha256_входа":hashlib.sha256(вход.encode()).hexdigest(),"sha256_до":hashlib.sha256(старый.encode()).hexdigest(),"sha256_после":hashlib.sha256(новый.encode()).hexdigest(),"прогоны":результаты,"медиана_наносекунд_на_вызов":{v:statistics.median(x["наносекунд"]/x["вызовов"] for x in результаты if x["версия"]==v) for v in функции}}
путь_валидатора="Инструменты/fum-dekompoziciya-pravil-agentov/scripts/проверить-декомпозицию-правил.py"
манифест=json.loads(Path("Правила/агентов/инвентарь-правил.json").read_text())
проверяющие={}
for версия in ("до","после"):
 текст=(subprocess.check_output(["git","show","84d10f885fb8b837f4d99f25b09f408753b4b6df:"+путь_валидатора]).decode() if версия=="до" else Path(путь_валидатора).read_text())
 среда={"__name__":"профиль_валидатора","__file__":str(корень/путь_валидатора)}
 exec(compile(текст,путь_валидатора,"exec"),среда)
 проверяющие[версия]=среда["проверить_структуру"]
итог["валидатор"]={"граница":"Полная структура одного текущего корня и инвентаря, 6 чередующихся пар по 3 вызова","прогоны":[]}
эталон=проверяющие["до"](корень,манифест)
for прогон in range(6):
 for версия in (("до","после") if прогон%2==0 else ("после","до")):
  начало=time.perf_counter_ns()
  for номер in range(3):assert проверяющие[версия](корень,манифест)==эталон
  итог["валидатор"]["прогоны"].append({"версия":версия,"прогон":прогон+1,"вызовов":3,"наносекунд":time.perf_counter_ns()-начало})
итог["валидатор"]["медиана_наносекунд_на_вызов"]={v:statistics.median(x["наносекунд"]/x["вызовов"] for x in итог["валидатор"]["прогоны"] if x["версия"]==v) for v in проверяющие}
выход=Path("Журнал/2026-09-09_21-31-19_MSK_продолжать-работу-после-коммита/материалы/профиль-продолжения.json")
выход.write_text(json.dumps(итог,ensure_ascii=False,indent=2)+"\n")
print(json.dumps({"распознавание":итог["медиана_наносекунд_на_вызов"],"валидатор":итог["валидатор"]["медиана_наносекунд_на_вызов"]},ensure_ascii=False))
