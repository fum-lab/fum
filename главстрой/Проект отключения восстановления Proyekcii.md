# Проект отключения восстановления Proyekcii

Автор — Главстрой. Архив самостоятельного проекта; он не является принятым кодом или разрешением на запуск. Основа `1f54b13d4b6a9bdea916a65f2974c1c851f8ba2d`, отдельный кандидат удаления `4327961b02edd9c88600dee8b7ae6ec9b8b4fb90`. Устаревший smoke, который запускает генерацию, не выполнять: область удаляется по прямому указанию человека.

Предложенный diff ограничивает три верхних входа `применить` и исключает из сборки smoke два шага генерации и проверки проекции. Это НЕ системный запрет: нижние writer helpers, старые копии, импорт и конкурентные эффекты не исследованы. Пока не синхронизированы действующие правила, инвентарь, валидатор и семантика режимов smoke, исключение шагов может создать ложное впечатление полного успеха. Не применять отдельно.

Адресный синтетический прогон без настоящей генерации: AST-срез четырёх проверок — исходник 4 FAIL, кандидат 4 PASS; полный модуль генератора на подставных границах — writer/CLI/dispatch отказались до Path/profiler, исходник достиг trap; build_steps двух профилей с mocked file discovery — два шага проекции исключены, остальные 8 и 12 шагов совпали по имени, команде, detail и early flag. Это не общий smoke и не гарантия отсутствия других путей записи. Синхронизация правил требует допущенного владельца и полного применимого маршрута.

Ниже инертные цитаты исследовательского diff и фикстур; они не являются исполняемым допуском.

## Материал 1

~~~text
--- a/Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py
+++ b/Инструменты/fum-bratislavskaya-proyekciya-pamyati/scripts/братиславская_проекция_памяти.py
@@ -5338,7 +5338,6 @@
         )
 
 
-@профилировать("применение поколения")
 def применить_поколение(
     корень_репозитория: Path | str,
     политика: Mapping[str, Any],
@@ -5346,6 +5345,7 @@
     *,
     инъекция_сбоя: Callable[[str], None] | None = None,
 ) -> dict[str, Any]:
+    raise ОшибкаКонтракта("Создание проекции отключено")
     корень = Path(корень_репозитория).resolve()
     if str(
         выполнить_команду_контроля_версий(
@@ -6693,6 +6693,9 @@
 
 def главная(аргументы: Sequence[str] | None = None) -> int:
     разобранные = построить_анализатор().parse_args(аргументы)
+    if разобранные.команда == "применить":
+        print("Создание проекции отключено", file=sys.stderr)
+        return 2
     with сеанс_профилирования(
         разобранные.профилировать or os.environ.get("FUM_PROJECTION_PROFILE") == "1"
     ):
@@ -6700,6 +6703,9 @@
 
 
 def выполнить_команду(разобранные: argparse.Namespace) -> int:
+    if разобранные.команда == "применить":
+        print("Создание проекции отключено", file=sys.stderr)
+        return 2
     корень = Path(разобранные.корень_репозитория).resolve()
     try:
         политика = загрузить_политику(Path(разобранные.контракт))
--- a/Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py
+++ b/Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py
@@ -2637,48 +2637,7 @@
         )
     )
 
-    скрипт_проекции = проверочный_файл(СКРИПТ_БРАТИСЛАВСКОЙ_ПРОЕКЦИИ)
-    контракт_проекции = проверочный_файл(КОНТРАКТ_БРАТИСЛАВСКОЙ_ПРОЕКЦИИ)
-    начало_проекции = len(steps)
-    steps.append(
-        SmokeStep(
-            name="Применение братиславской проекции памяти",
-            command=(
-                python_cmd,
-                скрипт_проекции,
-                "применить",
-                "--корень-репозитория",
-                ".",
-                "--контракт",
-                контракт_проекции,
-            ),
-            ранняя_проверка=True,
-        )
-    )
-    steps.append(
-        SmokeStep(
-            name="Проверка братиславской проекции памяти",
-            command=(
-                python_cmd,
-                скрипт_проекции,
-                "проверить-манифест",
-                "--корень-репозитория",
-                ".",
-                "--контракт",
-                контракт_проекции,
-                "--манифест",
-                МАНИФЕСТ_БРАТИСЛАВСКОЙ_ПРОЕКЦИИ.as_posix(),
-            ),
-            ранняя_проверка=True,
-        )
-    )
-    if проекция == "отложена":
-        for индекс in range(начало_проекции, len(steps)):
-            steps[индекс] = SmokeStep(
-                name=steps[индекс].name, command=None,
-                detail="Отложено: " + основание_отложения_проекции,
-                ранняя_проверка=True, отложен=True,
-            )
+    # Производная область отключена прямым решением; не восстанавливать её.
 
     if профиль == ПОЛНЫЙ_ПРОФИЛЬ:
         automation_names_script = проверочный_файл(AUTOMATION_NAMES_CHECK_SCRIPT)

~~~

## Материал 2

~~~text
import ast,sys,types,unittest
from unittest.mock import Mock
source,smoke=sys.argv[1:]
g=ast.parse(open(source,encoding='utf8').read(),filename=source)
s=ast.parse(open(smoke,encoding='utf8').read(),filename=smoke)
class ContractError(Exception): pass
class Checks(unittest.TestCase):
 def setUp(self):
  self.trap=Mock(side_effect=AssertionError('effect boundary reached'))
  self.args=types.SimpleNamespace(команда='применить',корень_репозитория='/fake',контракт='/fake',профилировать=False)
  self.parser=types.SimpleNamespace(parse_args=lambda _:self.args)
  self.ns={"сеанс_профилирования":self.trap,'ОшибкаКонтракта':ContractError,'Path':self.trap,'построить_анализатор':lambda:self.parser,'print':lambda *a,**k:None,'sys':types.SimpleNamespace(stderr=object()),'os':types.SimpleNamespace(environ=self.trap)}
  nodes=[]
  for item in g.body:
   if isinstance(item,ast.FunctionDef) and item.name in ('применить_поколение','главная','выполнить_команду'):
    item.decorator_list=[]; item.returns=None
    for a in item.args.posonlyargs+item.args.args+item.args.kwonlyargs:a.annotation=None
    nodes.append(item)
  self.assertEqual(len(nodes),3)
  exec(compile(ast.Module(body=nodes,type_ignores=[]),source,'exec'),self.ns)
 def test_direct_writer(self):
  with self.assertRaises(ContractError):self.ns['применить_поколение']('/fake',{},lambda x:x)
  self.trap.assert_not_called()
 def test_direct_dispatch(self):
  self.assertEqual(self.ns['выполнить_команду'](self.args),2)
  self.trap.assert_not_called()
 def test_cli_dispatch(self):
  self.assertEqual(self.ns['главная']([]),2)
  self.trap.assert_not_called()
 def test_smoke_steps_removed(self):
  f=next(x for x in s.body if isinstance(x,ast.FunctionDef) and x.name=='build_steps')
  names={x.value for x in ast.walk(f) if isinstance(x,ast.Constant) and isinstance(x.value,str)}
  self.assertNotIn('Применение братиславской проекции памяти',names)
  self.assertNotIn('Проверка братиславской проекции памяти',names)
unittest.main(argv=['check'],verbosity=1)

~~~

## Материал 3

~~~text
import sys,types,io,contextlib
from unittest.mock import Mock
p=sys.argv[1]; m=types.ModuleType('fum_projection_fixture'); m.__file__=p; sys.modules[m.__name__]=m
exec(compile(open(p,'rb').read(),p,'exec'),m.__dict__)
trap=Mock(side_effect=AssertionError('effect boundary reached'))
m.Path=trap; m.сеанс_профилирования=trap
try: m.применить_поколение('/synthetic',{},lambda x:x)
except m.ОшибкаКонтракта: pass
else: raise AssertionError('writer accepted')
with contextlib.redirect_stderr(io.StringIO()):
 assert m.главная(['применить','--корень-репозитория','/synthetic','--контракт','/synthetic'])==2
 assert m.выполнить_команду(types.SimpleNamespace(команда='применить',корень_репозитория='/synthetic'))==2
trap.assert_not_called()
print('writer=refused cli=refused dispatch=refused boundary=not_called')

~~~

## Материал 4

~~~text
import sys,types
from unittest.mock import Mock
mods=[]
for i,p in enumerate(sys.argv[1:]):
 m=types.ModuleType('fum_smoke_%s'%i); m.__file__=p; sys.modules[m.__name__]=m
 exec(compile(open(p,'rb').read(),p,'exec'),m.__dict__)
 m.validate_project_skill_isolation=Mock()
 m.разрешить_документационные_наборы_тестов=Mock(return_value=[])
 m.discover_test_dirs=Mock(return_value=[]); m.build_swift_steps=Mock(return_value=[])
 m.require_file=Mock(side_effect=lambda root,p:str(p))
 mods.append(m)
removed={'Применение братиславской проекции памяти','Проверка братиславской проекции памяти'}
for profile in ('документационный','полный'):
 allsteps=[m.build_steps('/private/tmp',None,include_session=False,python='/usr/bin/false',swift='/usr/bin/false',профиль=profile) for m in mods]
 base,candidate=allsteps
 assert {x.name for x in base if x.name in removed}==removed
 assert not any(x.name in removed for x in candidate)
 def summary(xs):return [(x.name,x.command,x.detail,x.ранняя_проверка) for x in xs if x.name not in removed]
 assert summary(base)==summary(candidate)
 print('profile=%s removed=2 unchanged=%s' % (profile,len(candidate)))

~~~
