# Проект частичного smoke без восстановления Proyekcii

Автор — Главстрой. Проект на основе `1f54b13d4b6a9bdea916a65f2974c1c851f8ba2d`, не интеграция и не допуск на восстановление проекции. Это отдельное дополнение к прежней личной записке.

Кандидат v6 добавляет прямой отказ верхних входов генератора до Path и профилирования. В smoke предложен режим `отключена`: вместо двух шагов восстановления и проверки — явный неполный marker, normal run и list возвращают 4; прежние режимы `активна` и `отложена` и контур слияния отказывают. Это намеренный HOLD полной приёмки. Нижние writer helpers, иные копии, действие при других гонках и полная совместимость не подтверждены. Обязательна отдельная согласованная синхронизация правил, инвентаря и валидаторов.

На собственных фикстурах: полный модуль генератора с подставными границами отказал до Path/profiler; два synthetic профиля build_steps сохранили остальные шаги, marker run_steps и list вернули 4, старые режимы и контур слияния — 2. Полный smoke и настоящую генерацию не запускали. Ниже инертные цитаты diff и трёх фикстур; они не являются разрешением на исполнение или приёмкой.

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
@@ -921,8 +921,8 @@
     parser.add_argument("--источник-проверок", help="Полный OID принятого master для проверки слияния.")
     parser.add_argument("--ведущая-основа", help="Полный OID ведущей основы слияния.")
     parser.add_argument("--свидетельство-контура", help="Заранее индексированное происхождение полного запуска.")
-    parser.add_argument("--проекция", choices=("активна", "отложена"), default="активна",
-                        help="Отложенная проекция даёт только частичную адресную проверку и код 4.")
+    parser.add_argument("--проекция", choices=("активна", "отложена", "отключена"), default="отключена",
+                        help="Проекция отключена; результат проверки остаётся частичным (код 4).")
     parser.add_argument("--основание-отложения-проекции",
                         help="Непустое основание явной приостановки проекции.")
     for флаг in ("--проекция", "--основание-отложения-проекции"):
@@ -2490,19 +2490,12 @@
     изменённые_пути: Sequence[str] | None = None,
     *,
     корень_проверок: Path | None = None,
-    проекция: str = "активна",
+    проекция: str = "отключена",
     основание_отложения_проекции: str | None = None,
 ) -> list[SmokeStep]:
+    if проекция != "отключена" or основание_отложения_проекции is not None:
+        raise ValueError("Старые режимы проекции недоступны; нужен новый профиль")
     root = Path(repo_root).resolve()
-    if проекция not in ("активна", "отложена"):
-        raise ValueError("неизвестный режим проекции")
-    if проекция == "отложена":
-        if not isinstance(основание_отложения_проекции, str) or not основание_отложения_проекции.strip():
-            raise ValueError("отложенная проекция требует непустое основание")
-        if корень_проверок is not None:
-            raise ValueError("контур слияния не допускает отложенную проекцию")
-    elif основание_отложения_проекции is not None:
-        raise ValueError("основание отложения нельзя задавать для активной проекции")
     источник = root if корень_проверок is None else Path(корень_проверок).resolve(strict=True)
     if корень_проверок is not None and (not include_session or профиль != ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ):
         raise ValueError("контур слияния требует полного документационного плана со связностью сессии")
@@ -2637,48 +2630,9 @@
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
+    steps.append(SmokeStep(name="Проекция отключена", command=None,
+                           detail="Проекция не проверялась; полный результат не подтверждён.",
+                           ранняя_проверка=True, отложен=True))
 
     if профиль == ПОЛНЫЙ_ПРОФИЛЬ:
         automation_names_script = проверочный_файл(AUTOMATION_NAMES_CHECK_SCRIPT)
@@ -2989,7 +2943,7 @@
             return result.returncode
     есть_отложенные = any(шаг.отложен for шаг in steps)
     if есть_отложенные:
-        print(f"Комплексная проверка не завершена: проекция отложена; {total} шагов")
+        print(f"Комплексная проверка не завершена: проекция отключена; {total} шагов")
     else:
         print(f"smoke-check passed: {total} step(s)")
     print_timing(
@@ -3021,8 +2975,7 @@
 
     try:
         if any((args.источник_проверок, args.ведущая_основа, args.свидетельство_контура)):
-            if getattr(args, "проекция", "активна") == "отложена":
-                raise ValueError("контур слияния не допускает отложенную проекцию")
+            raise ValueError("контур слияния недоступен при отключённой проекции")
             путь_контура = Path(__file__).resolve().with_name("контур_слияния.py")
             контур = types.ModuleType("контур_слияния")
             exec(compile(путь_контура.read_bytes(), str(путь_контура), "exec"), контур.__dict__)
@@ -3062,7 +3015,7 @@
             профиль=args.профиль,
             изменённые_пути=изменённые_пути,
             корень_проверок=источник,
-            проекция=getattr(args, "проекция", "активна"),
+            проекция=getattr(args, "проекция", "отключена"),
             основание_отложения_проекции=getattr(args, "основание_отложения_проекции", None),
         )
         статистика = (
@@ -3107,14 +3060,15 @@
                 print(f"{step.name}: {step.detail}")
             else:
                 print(f"{step.name}: {shlex.join(step.command)}")
+        есть_отложенные = any(шаг.отложен for шаг in steps)
         print_timing(
             timing_record(
                 "total",
                 timer() - overall_started_at,
-                "passed",
+                "отложено" if есть_отложенные else "passed",
             )
         )
-        return 0
+        return 4 if есть_отложенные else 0
 
     код = run_steps(
         steps,

~~~

## Материал 2

~~~text
import sys,types,io,contextlib
from unittest.mock import Mock
p=sys.argv[1]; m=types.ModuleType('fum_smoke_fixture'); m.__file__=p; sys.modules[m.__name__]=m
exec(compile(open(p,'rb').read(),p,'exec'),m.__dict__)
m.создать_сборщик_наблюдений_из_окружения=lambda:None
m.validate_project_skill_isolation=Mock()
m.разрешить_документационные_наборы_тестов=Mock(return_value=[])
m.discover_test_dirs=Mock(return_value=[]); m.build_swift_steps=Mock(return_value=[])
m.require_file=Mock(side_effect=lambda root,p:str(p))
m.загрузить_статистику_закрытых_запусков=Mock(return_value={})
for profile in ('документационный','полный'):
 sys.argv=['fixture','--repo-root','/private/tmp','--skip-session-coherence','--list','--профиль',profile]
 with contextlib.redirect_stdout(io.StringIO()),contextlib.redirect_stderr(io.StringIO()): code=m.main()
 assert code==4,(profile,code)
 print('profile=%s list_exit=4'%profile)
for mode in ('активна','отложена'):
 sys.argv=['fixture','--repo-root','/private/tmp','--skip-session-coherence','--list','--проекция',mode]
 if mode=='отложена':sys.argv+=['--основание-отложения-проекции','fixture']
 with contextlib.redirect_stdout(io.StringIO()),contextlib.redirect_stderr(io.StringIO()):code=m.main()
 assert code==2,(mode,code)
 print('legacy=%s exit=2'%mode)
sys.argv=['fixture','--repo-root','/private/tmp','--skip-session-coherence','--list','--источник-проверок','fixture']
with contextlib.redirect_stdout(io.StringIO()),contextlib.redirect_stderr(io.StringIO()):code=m.main()
assert code==2,code
print('merge_context=refused exit=2')

~~~

## Материал 3

~~~text
import sys,types,io,contextlib
from unittest.mock import Mock
from pathlib import Path
p=sys.argv[1]; m=types.ModuleType('fum_smoke_fixture'); m.__file__=p; sys.modules[m.__name__]=m
exec(compile(open(p,'rb').read(),p,'exec'),m.__dict__)
m.validate_project_skill_isolation=Mock()
m.разрешить_документационные_наборы_тестов=Mock(return_value=[])
m.discover_test_dirs=Mock(return_value=[]); m.build_swift_steps=Mock(return_value=[])
m.require_file=Mock(side_effect=lambda root,p:str(p))
for profile in (m.ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ,m.ПОЛНЫЙ_ПРОФИЛЬ):
 steps=m.build_steps('/private/tmp',None,include_session=False,python='/usr/bin/false',swift='/usr/bin/false',профиль=profile)
 names=[x.name for x in steps]
 assert 'Проверка структуры папок запросов' in names
 assert 'Проверка двунаправленности вопросов' in names
 assert 'Применение братиславской проекции памяти' not in names
 assert 'Проверка братиславской проекции памяти' not in names
 marker=[x for x in steps if x.name=='Проекция отключена']
 assert len(marker)==1 and marker[0].отложен and marker[0].command is None
 with contextlib.redirect_stdout(io.StringIO()): assert m.run_steps(marker,Path('/private/tmp'))==4
 for mode in ('активна','отложена'):
  try:m.build_steps('/private/tmp',None,include_session=False,проекция=mode,основание_отложения_проекции='fixture' if mode=='отложена' else None)
  except ValueError:pass
  else:raise AssertionError('legacy mode accepted')
 print('profile=%s marker=partial exit4 legacy=refused'%profile)

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
 def summary(xs):return [(x.name,x.command,x.detail,x.ранняя_проверка) for x in xs if x.name not in removed and x.name != "Проекция отключена"]
 assert summary(base)==summary(candidate)
 print('profile=%s removed=2 unchanged=%s' % (profile,len(summary(candidate))))

~~~

## Уточнение: версионированные профили и узкий merge

Предыдущий вариант постоянного кода 4 не принят как целевой: Направляющий требует работающих проверок, а не постоянной частичности. Последующий проект v11 задаёт отдельные версионированные документационный, полный и адресный профили без проекции; успех относится только к выбранному новому профилю. Для изменения Proyekcii адресный вход временно отказывает до доказательства точного дерева. Отдельная metadata-проба отличила отсутствие в candidate, присутствие в parent и неизвестный неверный OID; доверенный bounded reader ещё не подключён.

При ослаблении gate полного merge фактический код достигает вычисления Swift manifest из candidate, что не доказано безопасным. Поэтому проектный merge-adapter допускает только новый документационный профиль и требует его явного имени; доверенный принимающий контур должен быть предварительно принят в M. Полная интеграция, транзитивные writer-входы, source-pinned проверки и синхронизация правил/инвентаря/валидатора остаются открытыми.

Ниже — инертные цитаты частных кандидатов и синтетических фикстур; это не разрешение на исполнение и не свидетельство приёмки.

### Материал 1

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
@@ -122,13 +122,14 @@
 ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ = "документационный"
 ПОЛНЫЙ_ПРОФИЛЬ = "полный"
 АДРЕСНЫЙ_ПРОФИЛЬ = "адресный"
-ПРОФИЛИ_ПРОВЕРКИ = (
-    ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ,
-    АДРЕСНЫЙ_ПРОФИЛЬ,
-    ПОЛНЫЙ_ПРОФИЛЬ,
-)
+ПРОФИЛЬ_БЕЗ_ПРОЕКЦИИ = "fum.smoke-документационный-без-проекции.1"
+ПОЛНЫЙ_БЕЗ_ПРОЕКЦИИ = "fum.smoke-полный-без-проекции.1"
+АДРЕСНЫЙ_БЕЗ_ПРОЕКЦИИ = "fum.smoke-адресный-без-проекции.1"
+ПРОФИЛИ_ПРОВЕРКИ = (ПРОФИЛЬ_БЕЗ_ПРОЕКЦИИ, ПОЛНЫЙ_БЕЗ_ПРОЕКЦИИ, АДРЕСНЫЙ_БЕЗ_ПРОЕКЦИИ)
+СООТВЕТСТВИЕ_ПРОФИЛЕЙ = {ПРОФИЛЬ_БЕЗ_ПРОЕКЦИИ: ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ,
+                        ПОЛНЫЙ_БЕЗ_ПРОЕКЦИИ: ПОЛНЫЙ_ПРОФИЛЬ,
+                        АДРЕСНЫЙ_БЕЗ_ПРОЕКЦИИ: АДРЕСНЫЙ_ПРОФИЛЬ}
 ДОКУМЕНТАЦИОННЫЕ_НАБОРЫ_ТЕСТОВ = (
-    Path("Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests"),
     Path("Инструменты/fum-proyektnyiye-fajlyi/tests"),
     Path("Инструменты/fum-moskovskoye-vremya-rabochej-sessii/tests"),
     Path("Инструменты/fum-struktura-papok-zaprosov/tests"),
@@ -884,12 +885,11 @@
     parser.add_argument(
         "--профиль",
         choices=ПРОФИЛИ_ПРОВЕРКИ,
-        default=ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ,
+        default=ПРОФИЛЬ_БЕЗ_ПРОЕКЦИИ,
         help=(
-            "Проверочный профиль: документационный положительный перечень "
-            "используется по умолчанию; адресный профиль выбирает наборы по "
-            "явно переданному diff; полный профиль явно включает все тесты "
-            "автоматизаций и SwiftPM-контуры."
+            "Только версионированные профили без проекции: документационный, "
+            "адресный или полный. Успех относится к выбранному новому профилю; "
+            "прежние профили не выполняются."
         ),
     )
     parser.add_argument(
@@ -921,8 +921,8 @@
     parser.add_argument("--источник-проверок", help="Полный OID принятого master для проверки слияния.")
     parser.add_argument("--ведущая-основа", help="Полный OID ведущей основы слияния.")
     parser.add_argument("--свидетельство-контура", help="Заранее индексированное происхождение полного запуска.")
-    parser.add_argument("--проекция", choices=("активна", "отложена"), default="активна",
-                        help="Отложенная проекция даёт только частичную адресную проверку и код 4.")
+    parser.add_argument("--проекция", choices=("активна", "отложена", "отключена"), default="отключена",
+                        help="Версионированные профили работают без проекции; старые режимы недоступны.")
     parser.add_argument("--основание-отложения-проекции",
                         help="Непустое основание явной приостановки проекции.")
     for флаг in ("--проекция", "--основание-отложения-проекции"):
@@ -1162,9 +1162,8 @@
                 )
             выбранные.update(кандидаты)
             continue
-        if путь.startswith("Proyekcii/"):
-            выбранные.add("Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests")
-            continue
+        if путь == "Proyekcii" or путь.startswith("Proyekcii/"):
+            raise ValueError("Удаление Proyekcii требует проверки точного дерева; адресный reader пока недоступен")
         if путь.startswith("Журнал/"):
             выбранные.update(
                 ключ for ключ in _АДРЕСНЫЕ_НАБОРЫ_ЖУРНАЛА if ключ in доступные
@@ -2486,23 +2485,20 @@
     codex_thread_id: str | None = None,
     clock: Clock | None = None,
     timing_sink: TimingSink | None = None,
-    профиль: str = ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ,
+    профиль: str = ПРОФИЛЬ_БЕЗ_ПРОЕКЦИИ,
     изменённые_пути: Sequence[str] | None = None,
     *,
     корень_проверок: Path | None = None,
-    проекция: str = "активна",
+    проекция: str = "отключена",
     основание_отложения_проекции: str | None = None,
 ) -> list[SmokeStep]:
+    if профиль not in СООТВЕТСТВИЕ_ПРОФИЛЕЙ:
+        raise ValueError("Старый профиль проверки недоступен")
+    открытый_профиль = профиль
+    профиль = СООТВЕТСТВИЕ_ПРОФИЛЕЙ[профиль]
+    if проекция != "отключена" or основание_отложения_проекции is not None:
+        raise ValueError("Старые режимы проекции недоступны; нужен новый профиль")
     root = Path(repo_root).resolve()
-    if проекция not in ("активна", "отложена"):
-        raise ValueError("неизвестный режим проекции")
-    if проекция == "отложена":
-        if not isinstance(основание_отложения_проекции, str) or not основание_отложения_проекции.strip():
-            raise ValueError("отложенная проекция требует непустое основание")
-        if корень_проверок is not None:
-            raise ValueError("контур слияния не допускает отложенную проекцию")
-    elif основание_отложения_проекции is not None:
-        raise ValueError("основание отложения нельзя задавать для активной проекции")
     источник = root if корень_проверок is None else Path(корень_проверок).resolve(strict=True)
     if корень_проверок is not None and (not include_session or профиль != ДОКУМЕНТАЦИОННЫЙ_ПРОФИЛЬ):
         raise ValueError("контур слияния требует полного документационного плана со связностью сессии")
@@ -2511,8 +2507,7 @@
         относительный = require_file(источник, путь)
         return относительный if корень_проверок is None else str(источник / относительный)
 
-    if профиль not in ПРОФИЛИ_ПРОВЕРКИ:
-        raise ValueError(f"неизвестный smoke-профиль: {профиль}")
+
     if профиль == АДРЕСНЫЙ_ПРОФИЛЬ and корень_проверок is not None:
         raise ValueError("контур слияния не допускает адресный smoke-профиль")
     if профиль == АДРЕСНЫЙ_ПРОФИЛЬ and изменённые_пути is None:
@@ -2556,6 +2551,8 @@
         )
     else:
         каталоги_тестов = разрешить_документационные_наборы_тестов(источник)
+    исключённый = источник / "Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests"
+    каталоги_тестов = [п for п in каталоги_тестов if п != исключённый and not п.is_relative_to(исключённый)]
     for test_dir in каталоги_тестов:
         tool_name = test_dir.parent.name
         путь_набора = repo_relative(test_dir, источник)
@@ -2637,48 +2634,9 @@
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
+    steps.append(SmokeStep(name=открытый_профиль, command=None,
+                           detail="Версионированный профиль без проекции; старый smoke не выполнялся.",
+                           ранняя_проверка=True))
 
     if профиль == ПОЛНЫЙ_ПРОФИЛЬ:
         automation_names_script = проверочный_файл(AUTOMATION_NAMES_CHECK_SCRIPT)
@@ -2876,6 +2834,9 @@
             raise ValueError("корень проверяемой реализации должен быть каталогом")
         env["FUM_CHECKED_CODE_ROOT"] = str(выбранный_корень)
     total = len(steps)
+    версии_профиля = [шаг.name for шаг in steps if шаг.name in СООТВЕТСТВИЕ_ПРОФИЛЕЙ]
+    if len(версии_профиля) > 1:
+        raise ValueError("Неоднозначная версия smoke-профиля")
     for index, step in enumerate(steps, start=1):
         print(f"[{index}/{total}] {step.name}", flush=True)
         step_started_at = timer()
@@ -2989,9 +2950,10 @@
             return result.returncode
     есть_отложенные = any(шаг.отложен for шаг in steps)
     if есть_отложенные:
-        print(f"Комплексная проверка не завершена: проекция отложена; {total} шагов")
+        print(f"Комплексная проверка не завершена: проекция отключена; {total} шагов")
     else:
-        print(f"smoke-check passed: {total} step(s)")
+        область = f" [{версии_профиля[0]}]" if версии_профиля else ""
+        print(f"smoke-check passed{область}: {total} step(s)")
     print_timing(
         timing_record(
             "total",
@@ -3012,6 +2974,7 @@
         print(str(exc), file=sys.stderr)
         return 2
     args = parse_args()
+    внутренний_профиль = СООТВЕТСТВИЕ_ПРОФИЛЕЙ[args.профиль]
     root = args.repo_root.resolve()
     include_session = not args.skip_session_coherence
     preparation_started_at = timer()
@@ -3021,8 +2984,7 @@
 
     try:
         if any((args.источник_проверок, args.ведущая_основа, args.свидетельство_контура)):
-            if getattr(args, "проекция", "активна") == "отложена":
-                raise ValueError("контур слияния не допускает отложенную проекцию")
+            raise ValueError("контур слияния недоступен при отключённой проекции")
             путь_контура = Path(__file__).resolve().with_name("контур_слияния.py")
             контур = types.ModuleType("контур_слияния")
             exec(compile(путь_контура.read_bytes(), str(путь_контура), "exec"), контур.__dict__)
@@ -3030,7 +2992,7 @@
             контур.проверить_запуск(источник, root, команда_контура, str(args.request), os.environ.get(ПЕРЕМЕННАЯ_ИДЕНТИФИКАТОРА_ЗАПУСКА, ""))
         изменения_аргумента = getattr(args, "изменения", None)
         изменения_из_git = bool(getattr(args, "изменения_из_git", False))
-        if args.профиль == АДРЕСНЫЙ_ПРОФИЛЬ:
+        if внутренний_профиль == АДРЕСНЫЙ_ПРОФИЛЬ:
             if изменения_аргумента is not None and изменения_из_git:
                 raise ValueError(
                     "адресный профиль принимает либо --изменения, либо "
@@ -3062,12 +3024,12 @@
             профиль=args.профиль,
             изменённые_пути=изменённые_пути,
             корень_проверок=источник,
-            проекция=getattr(args, "проекция", "активна"),
+            проекция=getattr(args, "проекция", "отключена"),
             основание_отложения_проекции=getattr(args, "основание_отложения_проекции", None),
         )
         статистика = (
             загрузить_статистику_закрытых_запусков(root)
-            if args.профиль == ПОЛНЫЙ_ПРОФИЛЬ
+            if внутренний_профиль == ПОЛНЫЙ_ПРОФИЛЬ
             else {}
         )
         steps[:] = упорядочить_тестовые_шаги(steps, статистика)
@@ -3107,14 +3069,15 @@
                 print(f"{step.name}: {step.detail}")
             else:
                 print(f"{step.name}: {shlex.join(step.command)}")
+        есть_отложенные = any(шаг.отложен for шаг in steps)
         print_timing(
             timing_record(
                 "total",
                 timer() - overall_started_at,
-                "passed",
+                "отложено" if есть_отложенные else "passed",
             )
         )
-        return 0
+        return 4 if есть_отложенные else 0
 
     код = run_steps(
         steps,

~~~

### Материал 2

~~~text
import subprocess
base='/private/tmp/fum-proyekcii-removal-20261114-c2/worktree'
env={'PATH':'/usr/bin:/bin','LC_ALL':'C','GIT_OPTIONAL_LOCKS':'0','GIT_NO_LAZY_FETCH':'1','GIT_NO_REPLACE_OBJECTS':'1','GIT_CONFIG_NOSYSTEM':'1','GIT_CONFIG_GLOBAL':'/dev/null','GIT_TERMINAL_PROMPT':'0','GIT_OBJECT_DIRECTORY':'/private/tmp/fum-proyekcii-removal-20261114-c2/objects','GIT_ALTERNATE_OBJECT_DIRECTORIES':'/Users/fum/Projects/FUM/.git/objects'}
def probe(oid):
 r=subprocess.run(['/usr/bin/git','-C',base,'--no-optional-locks','--no-replace-objects','-c','core.fsmonitor=false','ls-tree','-z',oid,'--','Proyekcii'],env=env,stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=5)
 if r.returncode!=0:return 'unknown'
 if len(r.stdout)>512:return 'unknown'
 return 'absent' if r.stdout==b'' else 'present'
assert probe('4327961b02edd9c88600dee8b7ae6ec9b8b4fb90')=='absent'
assert probe('1f54b13d4b6a9bdea916a65f2974c1c851f8ba2d')=='present'
assert probe('0000000000000000000000000000000000000000')=='unknown'
print('candidate=absent parent=present invalid=unknown')

~~~

### Материал 3

~~~text
--- a/Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py
+++ b/Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py
@@ -2984,7 +2984,8 @@
 
     try:
         if any((args.источник_проверок, args.ведущая_основа, args.свидетельство_контура)):
-            raise ValueError("контур слияния недоступен при отключённой проекции")
+            if args.профиль != ПРОФИЛЬ_БЕЗ_ПРОЕКЦИИ:
+                raise ValueError("контур слияния требует документационный профиль без проекции")
             путь_контура = Path(__file__).resolve().with_name("контур_слияния.py")
             контур = types.ModuleType("контур_слияния")
             exec(compile(путь_контура.read_bytes(), str(путь_контура), "exec"), контур.__dict__)
--- a/Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/контур_слияния.py
+++ b/Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/контур_слияния.py
@@ -65,8 +65,8 @@
         if ключ not in обязательные | {"--профиль"} or ключ in значения:
             raise ValueError("неизвестный или повторный параметр контура слияния")
         значения[ключ] = значение
-    if not обязательные <= значения.keys() or значения.get("--профиль", "документационный") != "документационный":
-        raise ValueError("контур слияния требует полный документационный план")
+    if not обязательные <= значения.keys() or значения.get("--профиль") != "fum.smoke-документационный-без-проекции.1":
+        raise ValueError("контур слияния требует версионированный документационный профиль без проекции")
     if значения["--repo-root"] != str(кандидат):
         raise ValueError("команда указывает другой корень кандидата")
     if запрос is not None and значения["--request"] != запрос:

~~~

### Материал 4

~~~text
import ast,sys,re
from pathlib import Path
p=sys.argv[1];t=ast.parse(open(p,encoding='utf8').read(),filename=p)
nodes=[]
for n in t.body:
 if isinstance(n,ast.FunctionDef) and n.name in ('путь_свидетельства','параметры_полного_запуска'):
  n.returns=None
  for a in n.args.posonlyargs+n.args.args+n.args.kwonlyargs:a.annotation=None
  nodes.append(n)
assert len(nodes)==2
ns={'Path':Path,'sys':sys,'re':re,'ПОЛНЫЙ_ИДЕНТИФИКАТОР_ОБЪЕКТА':re.compile(r'(?:[0-9a-f]{40}|[0-9a-f]{64})\Z'),'СКРИПТ_КОМПЛЕКСНОЙ_ПРОВЕРКИ':Path('Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py')}
exec(compile(ast.Module(body=nodes,type_ignores=[]),p,'exec'),ns)
source=Path('/private/tmp/source-fixture');candidate=Path('/private/tmp/candidate-fixture');request='Журнал/2026-11-14_10-00-00_MSK_test/запрос.md'
proof=ns['путь_свидетельства'](request); oid='1'*40
args=[sys.executable,'-B',str(source/ns['СКРИПТ_КОМПЛЕКСНОЙ_ПРОВЕРКИ']),'--repo-root',str(candidate),'--request',request,'--commit-message-file','/private/tmp/message.DATA','--codex-thread-id','00112233-4455-4677-8899-aabbccddeeff','--источник-проверок',oid,'--ведущая-основа',oid,'--свидетельство-контура',proof,'--профиль','fum.smoke-документационный-без-проекции.1']
f=ns['параметры_полного_запуска'];assert f(source,candidate,args,request)==(oid,oid,proof)
variants=[]
a=args.copy();a[-1]='документационный';variants.append(a)
a=args[:-2];variants.append(a)
a=args.copy();a[-1]='fum.smoke-полный-без-проекции.1';variants.append(a)
a=args.copy();a[a.index('--ведущая-основа')+1]='not-an-oid';variants.append(a)
a=args.copy();a[a.index('--repo-root')+1]='/private/tmp/wrong';variants.append(a)
a=args+['--профиль',args[-1]];variants.append(a)
for case in variants:
 try:f(source,candidate,case,request)
 except ValueError:pass
 else:raise AssertionError('invalid merge input accepted')
print('versioned_doc=accepted old_missing_full_oid_root_duplicate=refused')

~~~

### Материал 5

~~~text
import sys,types
from pathlib import Path
from unittest.mock import Mock
p=sys.argv[1];m=types.ModuleType('fum_merge_fixture');m.__file__=p;sys.modules[m.__name__]=m
exec(compile(open(p,'rb').read(),p,'exec'),m.__dict__)
m.validate_project_skill_isolation=Mock();m.request_session_match=Mock(return_value=True);m.request_requires_codex_commit_context=Mock(return_value=False)
m.разрешить_документационные_наборы_тестов=Mock(return_value=[])
m.require_file=Mock(side_effect=lambda root,p:str(p))
m.build_swift_steps=Mock(side_effect=AssertionError('candidate Swift manifests invoked'))
candidate=Path('/private/tmp/fum-projection-guard-20261114-p2');source=Path('/private/tmp');request='Журнал/2026-11-14_10-00-00_MSK_test/запрос.md'
steps=m.build_steps(candidate,request,include_session=True,python='/usr/bin/false',профиль=m.ПРОФИЛЬ_БЕЗ_ПРОЕКЦИИ,корень_проверок=source)
assert any(x.name==m.ПРОФИЛЬ_БЕЗ_ПРОЕКЦИИ for x in steps)
assert all(call.args[0]==source.resolve() for call in m.require_file.call_args_list)
m.build_swift_steps.assert_not_called()
for profile in (m.ПОЛНЫЙ_БЕЗ_ПРОЕКЦИИ,m.АДРЕСНЫЙ_БЕЗ_ПРОЕКЦИИ):
 try:m.build_steps(candidate,request,include_session=True,профиль=profile,корень_проверок=source,изменённые_пути=['file.txt'])
 except ValueError:pass
 else:raise AssertionError('unsupported merge profile accepted')
print('merge_doc=accepted trusted_file_root=true candidate_manifest=not_called merge_full_address=refused')

~~~
