# Инструменты репозитория

Этот каталог хранит канонические инструменты и рабочие инструкции, которые нужны именно для репозитория FUM.

В задачах FUM используются только локальные навыки `Инструменты/*/SKILL.md`. Навыки за пределами текущего checkout не открываются и не сравниваются с локальными; проектная настройка `skills.include_instructions = false` исключает общий каталог навыков среды из агентского контекста. Если подходящего локального навыка нет, работа продолжается непосредственно по `AGENTS.md`, обязательным тематическим маршрутам в `Правила/агентов/` и материалам репозитория.

Локальные автоматизации в этом каталоге должны сопровождаться тестами, которые можно запустить без секретов и сетевых зависимостей по умолчанию.

Действующий маршрут работы — ручная последовательность: пользователь запускает одну пишущую сессию в первичном checkout `refs/heads/master`, она выполняет один запрос, создаёт не более одного итогового коммита и завершается. Continuation, FIFO/pool, worktree-писатели, reviewer/integrator/candidate, branch-next-step, heartbeat, dispatcher, autostart и автоматическая публикация не запускаются. Их инструменты ниже сохраняются только как исторические контракты и регрессионная наработка без разрешения живых host- или Git-эффектов.

## Реестры

- [Реестр системных приложений и инструментов](реестр-системных-приложений-и-инструментов.md) - фиксирует повторно используемые приложения, CLI-команды, инструменты среды агента, MCP-инструменты и способы проверки их версий.
- [Реестр названий автоматизаций](реестр-названий-автоматизаций.json) - хранит кириллические источники, точные результаты LinguisticKit, технические slug, отображаемые имена и эталоны; наличие исторического имени или slug в этом реестре не означает эксплуатационный статус автоматизации.

## Навыки

- [fum-dispetcher-avtomatizacij-fum](fum-dispetcher-avtomatizacij-fum/SKILL.md) - исторический контракт снятого универсального диспетчера; не разрешает выбор запуска, резервацию, создание задачи или иной живой host-эффект.
- [fum-analitika-zavershyonnyikh-shagov](fum-analitika-zavershyonnyikh-shagov/SKILL.md) - исторический контракт снятой периодической аналитики; прежние события и курсоры читаются для происхождения и регрессионной совместимости, но порог больше не создаёт задание.
- [fum-pochinka-avtozapuska](fum-pochinka-avtozapuska/SKILL.md) - исторический контракт снятой починки автозапуска; не разрешает создавать ремонтную задачу или менять host-автоматизацию.
- [fum-sleduyusjhij-shag-vetki](fum-sleduyusjhij-shag-vetki/SKILL.md) - хранит исторический selector и его тесты; в ручной последовательной схеме `show` не вызывается.
- [fum-sborka-svodnoj-dokumentacii](fum-sborka-svodnoj-dokumentacii/SKILL.md) - создаёт и проверяет каркас сводных статей документации из нескольких опорных материалов.
- [fum-ocenki](fum-ocenki/SKILL.md) - создаёт и проверяет принадлежащие запросу оценочные материалы в `материалы/оценки/` со снимком репозитория, методикой, диапазонами, допущениями, ограничениями точности и оформлением результата.
- [fum-glossarij](fum-glossarij/SKILL.md) - поддерживает глоссарий FUM по локальным правилам именования и ссылок.
- [fum-svezhestj-markdown](fum-svezhestj-markdown/SKILL.md) - обновляет служебные метки последнего содержательного редактирования во всех Markdown-файлах и собирает индекс `.md`-файлов от свежих к старым.
- [fum-ocheredj-zadach-git-vetki](fum-ocheredj-zadach-git-vetki/SKILL.md) - хранит исторические FIFO/pool/CAS-протоколы, квитанции и регрессионные тесты; обычная ручная сессия их не вызывает. Единственная уже созданная bridge-задача переходного коммита может выполнить `ack-head` и `finish-clean`.
- [fum-svezhestj-grafa-obsidian](fum-svezhestj-grafa-obsidian/SKILL.md) - обновляет группы цвета графа Obsidian как тепловую карту Markdown-узлов по времени последнего содержательного редактирования.
- [fum-reyestr-planirovaniya](fum-reyestr-planirovaniya/SKILL.md) - собирает и проверяет машинно читаемый JSON-реестр и безопасно переименовывает карточки шагов с обновлением живых текстовых путей.
- [fum-proyektnyiye-fajlyi](fum-proyektnyiye-fajlyi/SKILL.md) - задаёт общий воспроизводимый инвентарь проектных Markdown-файлов и безопасные границы выходных путей служебных автоматизаций.
- [fum-bratislavskaya-proyekciya-pamyati](fum-bratislavskaya-proyekciya-pamyati/SKILL.md) - строит полный детерминированный сухой план братиславской проекции канонической памяти и валидирует происхождение готового производного поколения.
- [fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok](fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/SKILL.md) - планирует и применяет Git-переименование обычного файла с разрешением и пересчётом входящих и исходящих локальных Markdown-ссылок без глобальной замены имени.
- [fum-proverka-git-zavisimostej](fum-proverka-git-zavisimostej/SKILL.md) - добавляет Git submodule из форка рядом с актуальным FUM, инициализирует уже зарегистрированную зависимость после свежего клонирования и автономно проверяет отдельный upstream, достижимость выбранной ревизии из локально полученных refs форка и точный gitlink.
- [fum-proverka-nazvanij-avtomatizacij](fum-proverka-nazvanij-avtomatizacij/SKILL.md) - проверяет точную транслитерацию репозиторных и отображаемых имён, slug, отсутствие канонических legacy-исключений, коллизии и явное состояние зависимости LinguisticKit.
- [fum-dekompoziciya-pravil-agentov](fum-dekompoziciya-pravil-agentov/SKILL.md) - проверяет компактность всегда загружаемого `AGENTS.md`, локальность и хэши тематических маршрутов и полное однозначное покрытие исходного инвентаря правил.
- [fum-zapusk-prototipov](fum-zapusk-prototipov/SKILL.md) - проверяет корневую POSIX-панель `prototipyi.sh` и обязательные `запустить.sh` у всех устойчивых прототипов.
- [fum-obratnyiye-ssyilki-voprosov](fum-obratnyiye-ssyilki-voprosov/SKILL.md) - проверяет двунаправленность локальных ссылок между открытыми или частично прояснёнными вопросами и заявленной затронутой документацией.
- [fum-audit-pokryitiya-voprosov-i-otvetov](fum-audit-pokryitiya-voprosov-i-otvetov/SKILL.md) - извлекает вопросительные предложения из дословных блоков запросов, сопоставляет их с source-ссылками карточек и оставляет смысловой отбор ручным.
- [fum-indeks-readme](fum-indeks-readme/SKILL.md) - проверяет компактную корневую инструкцию текущего использования FUM и полный тематический индекс в `Документация/README.md`.
- [fum-materialyi-zaprosov](fum-materialyi-zaprosov/SKILL.md) - архивирует устойчивые HTML-URL через общий вход `fum source archive`, сохраняет общие [прикрепляемые материалы](../Глоссарий/прикрепляемый-материал.md) в `Источники/URL/`, принадлежащие одному запросу материалы — в его `материалы/источники/`, и поддерживает специализированное извлечение расшаренных чатов ChatGPT.
- [fum-struktura-papok-zaprosov](fum-struktura-papok-zaprosov/SKILL.md) - строит детерминированный план, пакетно переносит прежние запросы, отчёты и собственные материалы в папки запросов, создаёт новую папку с навигацией и валидирует каноническую структуру.
- [fum-moskovskoye-vremya-rabochej-sessii](fum-moskovskoye-vremya-rabochej-sessii/SKILL.md) - формирует согласованные имя и заголовочную метку рабочей сессии в зоне `Europe/Moscow` независимо от зоны хоста.
- [fum-svyaznostj-rabochej-sessii](fum-svyaznostj-rabochej-sessii/SKILL.md) - проверяет связность [рабочей сессии](../Глоссарий/рабочая-сессия.md): навигацию запросов, журнальный профиль со всеми прямыми проверочными вызовами и их арифметической суммой, корневой Codex-Thread-ID в запросе и теле коммита, использование канонического MSK-времени, квалифицированную запись инструментов, Markdown-ссылки, регистр путей, формальный конечный `?` материалов `Вопросы и ответы/`, сигналы мета-запросов, нижнее расположение справочных блоков и Git-состояние.
- [fum-otchyotyi-o-zapuskakh-proverok](fum-otchyotyi-o-zapuskakh-proverok/SKILL.md) - ведёт профилированный машинный учёт прямых проверочных вызовов, связывает их с Git-отпечатком, выявляет дублирование полного охвата, атомарно формирует, проверяет, закрывает и при допустимом отказе возобновляет детерминированную таблицу запусков.
- [fum-kompleksnaya-proverka-repozitoriya](fum-kompleksnaya-proverka-repozitoriya/SKILL.md) - запускает единый локальный smoke-check с длительностями подготовки, каждого шага и полного процесса: сохранность настройки изоляции и локальность путей навыков, тесты автоматизаций, пересборку проверяемых реестров, контракт корневой инструкции и отдельного индекса документации, двунаправленность вопросов, recency-проверку и связность выбранной рабочей сессии.
- [fum-proverka-trassyi-agentskogo-cikla](fum-proverka-trassyi-agentskogo-cikla/SKILL.md) - валидирует локальные трассы версии `3` с независимыми состояниями эпизода, модельной ветви, ожидающего перехода и внешнего исполнения без сети, секретов, живой LLM и физических эффектов.
- [fum-revjyu-prodelannoj-rabotyi](fum-revjyu-prodelannoj-rabotyi/SKILL.md) - создаёт и проверяет сохранённые ревью проделанной работы: Git-срез, находки, проверки, остаточные риски и вывод.

## Проверки

- `python3 Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py --request Журнал/<YYYY-MM-DD_HH-MM-SS_MSK_краткое-название>/запрос.md --commit-message-file <путь> --codex-thread-id <UUID>` - единый локальный smoke-check репозитория для выбранной рабочей сессии и её подготовленного сообщения коммита.
- `python3 Инструменты/fum-zapusk-prototipov/scripts/check-prototype-launchers.py` - проверка корневой панели `prototipyi.sh` и обязательных точек входа `запустить.sh` всех устойчивых прототипов.
- `python3 Инструменты/fum-obratnyiye-ssyilki-voprosov/scripts/check-question-backlinks.py` - автономная проверка существования, регистра и обратных ссылок всех локальных целей активных вопросов.
- `python3 Инструменты/fum-audit-pokryitiya-voprosov-i-otvetov/scripts/audit-question-answer-coverage.py --repo-root .` - детерминированный список вопросительных кандидатов, их ссылочного покрытия и обязательных ручных смысловых проверок.
- `python3 Инструменты/fum-indeks-readme/scripts/check-readme-index.py --repo-root .` - автономная проверка компактности корневой инструкции и полноты тематического индекса `Документация/README.md`.
- `python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init --repo-root . --path Зависимости/LinguisticKit` - сетевая инициализация уже зарегистрированного submodule из отслеживаемой `.gitmodules` и gitlink после свежего клонирования FUM.
- `python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py check --repo-root . --fork-url https://github.com/fum-lab/LinguisticKit.git --upstream-url https://github.com/Roman-Kerimov/LinguisticKit.git --path Зависимости/LinguisticKit --revision 837e2ce107b97ee7b9d3344c9fe99142281fe393` - автономная проверка подключённого submodule LinguisticKit без получения remote.
- `python3 Инструменты/fum-proverka-nazvanij-avtomatizacij/scripts/proveritj-nazvaniya-avtomatizacij.py --repo-root . --registry Инструменты/реестр-названий-автоматизаций.json` - автономная структурная либо живая проверка реестра названий автоматизаций.
- `python3 Инструменты/fum-dekompoziciya-pravil-agentov/scripts/проверить-декомпозицию-правил.py --корень-репозитория . проверить` - автономная проверка корня, тематических маршрутов и машинного инвентаря правил агентов.
- `python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . status --json` - read-only-диагностика сохранённой исторической FIFO; не является входом обычной ручной сессии.
- `./sbrositj.sh` - ручной аварийный сброс exact текущих именованной ветки и `HEAD`; выполнять только человеку при настоящих TTY одновременно на stdin и stdout после чтения полного плана; не использовать как диагностическую или агентскую команду.
- `python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py validate --repo-root . --json` - структурная регрессия исторических рабочих наборов; обычную следующую задачу не выбирает и не запускает.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-dispetcher-avtomatizacij-fum/tests -p 'test_*.py'` - локальная историческая регрессия форматов снятого диспетчера; тесты не разрешают его эксплуатационный запуск.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-analitika-zavershyonnyikh-shagov/tests -p 'test_*.py'` - локальная историческая регрессия прежних аналитических событий, курсоров и претензий без периодического запуска.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-pochinka-avtozapuska/tests -p 'test_*.py'` - локальная историческая регрессия прежнего repair-fence без создания задач и изменения host-автоматизаций.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-sleduyusjhij-shag-vetki/tests -p 'test_*.py'` - локальные тесты `validate`/`show` прямого веточного выбора и историческая регрессия legacy claim-состояний.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-ocheredj-zadach-git-vetki/tests -p 'test_*.py'` - локальные тесты FIFO, exact waiting-билета продолжения, атомарного `commit+handoff`, исторических reset/claim-состояний, человеческого break-glass и отдельно авторизуемого транспорта.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-sborka-svodnoj-dokumentacii/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-sborka-svodnoj-dokumentacii`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-ocenki/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-ocenki`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-svezhestj-markdown/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-svezhestj-markdown`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-svezhestj-grafa-obsidian/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-svezhestj-grafa-obsidian`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-reyestr-planirovaniya`.
- `python3 Инструменты/fum-reyestr-planirovaniya/scripts/rename-step-card.py --card-id FUM-STEP-NNNN --status <active|completed|absorbed|withdrawn> [--description <краткое-название>]` - Git-переименование карточки шага с синхронизацией статуса, индекса и живых текстовых путей.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-proyektnyiye-fajlyi/tests -p 'test_*.py'` - локальные тесты общей политики проектных файлов.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-bratislavskaya-proyekciya-pamyati/tests -p 'test_*.py'` - автономные фикстуры инвентаря, путей, коллизий, закреплённого LinguisticKit и манифеста братиславской проекции.
- `python3 Инструменты/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/scripts/pereimenovatj-fajl-s-obnovleniyem-ssyilok.py plan --source <старый-путь> --destination <новый-путь> --repo-root .` - полный read-only-план обычного переименования с проверкой ссылок, защищённых зон и переносимых коллизий.
- `python3 Инструменты/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/scripts/pereimenovatj-fajl-s-obnovleniyem-ssyilok.py apply --source <старый-путь> --destination <новый-путь> --repo-root .` - повторная проверка плана, `git mv` и согласованная установка обновлённых Markdown-файлов с откатом при перехватываемой ошибке.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-pereimenovaniye-fajla-s-obnovleniyem-ssyilok/tests -p 'test_*.py'` - автономные тесты переименования, разрешения ссылок, fail-closed-границ и отката.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-proverka-git-zavisimostej/tests -p 'test_*.py'` - автономные тесты цепочки форк — `origin` — `upstream` — `.gitmodules` — gitlink.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-proverka-nazvanij-avtomatizacij/tests -p 'test_*.py'` - локальные тесты реестра русских латинских названий автоматизаций.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-zapusk-prototipov/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-zapusk-prototipov`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-obratnyiye-ssyilki-voprosov/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-obratnyiye-ssyilki-voprosov`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-audit-pokryitiya-voprosov-i-otvetov/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-audit-pokryitiya-voprosov-i-otvetov`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-indeks-readme/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-indeks-readme`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-materialyi-zaprosov/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-materialyi-zaprosov`.
- `python3 Инструменты/fum-struktura-papok-zaprosov/scripts/struktura-papok-zaprosov.py validate --repo-root .` - проверка единой структуры папок запросов и отсутствия активного параллельного каталога `Запросы/`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-struktura-papok-zaprosov/tests -p 'test_*.py'` - автономные тесты планирования, миграции, отката, создания и валидации папок запросов.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-moskovskoye-vremya-rabochej-sessii/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-moskovskoye-vremya-rabochej-sessii`.
- `python3 Инструменты/fum-otchyotyi-o-zapuskakh-proverok/scripts/отчёты_о_запусках_проверок.py запустить --корень-репозитория . --запрос Журнал/<YYYY-MM-DD_HH-MM-SS_MSK_краткое-название>/запрос.md --название '<название вызова>' --исполнитель '<метка исполнителя>' --класс-проверки адресная -- <программа> <аргументы...>` - точка входа для запуска одной прямой проверки с обязательным классом и атомарной машинной записью её исхода, длительности и Git-отпечатка; перед закрытием `проверить-план` подтверждает единственный финальный smoke-check.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-otchyotyi-o-zapuskakh-proverok/tests -p 'test_*.py'` - автономные тесты машинного учёта запусков, детерминированного снимка и Markdown-отчёта.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-svyaznostj-rabochej-sessii`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-kompleksnaya-proverka-repozitoriya/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-kompleksnaya-proverka-repozitoriya`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-proverka-trassyi-agentskogo-cikla/tests -p 'test_*.py'` - локальные тесты схемы, фикстур и межсобытийных инвариантов трассы агентского цикла версии `3`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-revjyu-prodelannoj-rabotyi/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-revjyu-prodelannoj-rabotyi`.

## Источники требований

- [исходный запрос 2026-08-14 18:59:37 MSK — Исключить дублирование полной регрессии](../Журнал/2026-08-14_18-59-37_MSK_исключить-дублирование-полной-регрессии/запрос.md)
- [исходный запрос 2026-08-24 15:31:12 MSK — Декомпозировать AGENTS MD](../Журнал/2026-08-24_15-31-12_MSK_декомпозировать-AGENTS-md/запрос.md)

- [исходный запрос 2026-08-23 11:33:38 MSK — Вернуть ручную последовательную схему сессий](../Журнал/2026-08-23_11-33-38_MSK_вернуть-ручную-последовательную-схему-сессий/запрос.md)

- [исходный запрос 2026-08-11 23:30:57 MSK — Заменить автозапуск обязательным продолжением ветки](../Журнал/2026-08-11_23-30-57_MSK_заменить-автозапуск-обязательным-продолжением-ветки/запрос.md)
- [исходный запрос 2026-08-10 14:30:08 MSK — Добавить аналитику по числу завершённых шагов](../Журнал/2026-08-10_14-30-08_MSK_добавить-аналитику-по-числу-завершённых-шагов/запрос.md)
- [исходный запрос 2026-08-10 10:19:59 MSK — Добавить простой сброс FIFO к текущему HEAD](../Журнал/2026-08-10_10-19-59_MSK_добавить-простой-сброс-FIFO-к-текущему-HEAD/запрос.md)
- [исходный запрос 2026-08-07 20:34:22 MSK — Добавить штатный сброс очереди](../Журнал/2026-08-07_20-34-22_MSK_добавить-штатный-сброс-очереди/запрос.md)
- [исходный запрос 2026-08-06 15:14:50 MSK — Сделать README инструкцией использования FUM](../Журнал/2026-08-06_15-14-50_MSK_сделать-README-инструкцией-использования-FUM/запрос.md)
- [исходный запрос 2026-08-05 22:56:33 MSK — Проанализировать опыт починки и создать инструмент починки автозапуска](../Журнал/2026-08-05_22-56-33_MSK_проанализировать-опыт-починки-и-создать-инструмент-починки-автозапуска/запрос.md)
- [исходный запрос 2026-08-05 12:02:53 MSK - Перенести автозапуск шагов в универсальный диспетчер](../Журнал/2026-08-05_12-02-53_MSK_перенести-автозапуск-шагов-в-универсальный-диспетчер/запрос.md)
- [исходный запрос 2026-08-05 09:07:08 MSK - Добавить универсальный выбор и защищённую резервацию запуска](../Журнал/2026-08-05_09-07-08_MSK_добавить-универсальный-выбор-и-защищённую-резервацию-запуска/запрос.md)
- [исходный запрос 2026-08-04 20:45:26 MSK - Формировать отчёты о запусках тестов](../Журнал/2026-08-04_20-45-26_MSK_формировать-отчёты-о-запусках-тестов/запрос.md)
- [исходный запрос 2026-08-03 11:49:04 MSK — Объединить запросы и журнал](../Журнал/2026-08-03_11-49-04_MSK_объединить-запросы-и-журнал/запрос.md)
- [исходный запрос 2026-08-01 09:16:33 MSK — Исправить повторный автозапуск после отката](../Журнал/2026-08-01_09-16-33_MSK_исправить-повторный-автозапуск-после-отката/запрос.md)
- [исходный запрос 2026-07-31 16:31:18 MSK - Отключить автоматическую публикацию master](../Журнал/2026-07-31_16-31-18_MSK_отключить-автоматическую-публикацию-master/запрос.md)
- [исходный запрос 2026-07-31 14:59:59 MSK — Исправить подтверждение свободной очереди автозапуска](../Журнал/2026-07-31_14-59-59_MSK_исправить-подтверждение-свободной-очереди-автозапуска/запрос.md)
- [исходный запрос 2026-07-29 14:32:38 MSK — Закрепить неблокирующее модельное ветвление](../Журнал/2026-07-29_14-32-38_MSK_закрепить-неблокирующее-модельное-ветвление/запрос.md)
- [исходный запрос 2026-07-29 09:04:03 MSK — Расширить динамический выбор следующего шага](../Журнал/2026-07-29_09-04-03_MSK_расширить-динамический-выбор-следующего-шага/запрос.md)
- [исходный запрос 2026-07-27 18:28:42 MSK - Выбирать следующий шаг при запуске с учётом истории коммитов](../Журнал/2026-07-27_18-28-42_MSK_выбирать-следующий-шаг-при-запуске-с-учётом-истории-коммитов/запрос.md)
- [исходный запрос 2026-07-27 16:12:29 MSK - Учитывать все проверочные вызовы в профиле времени](../Журнал/2026-07-27_16-12-29_MSK_учитывать-все-проверочные-вызовы-в-профиле-времени/запрос.md)
- [исходный запрос 2026-07-26 15:15:18 MSK - Публиковать работу в GitHub автоматически](../Журнал/2026-07-26_15-15-18_MSK_публиковать-работу-в-GitHub-автоматически/запрос.md)
- [исходный запрос 2026-07-24 16:26:31 MSK - Создать обобщённый инструмент переименования файла](../Журнал/2026-07-24_16-26-31_MSK_создать-обобщённый-инструмент-переименования-файла/запрос.md)
- [исходный запрос 2026-07-23 15:26:35 MSK - Запретить внешние навыки в репозитории](../Журнал/2026-07-23_15-26-35_MSK_запретить-внешние-навыки-в-репозитории/запрос.md)
- [исходный запрос 2026-07-23 14:47:43 MSK - Включать профиль времени в отчёты журнала](../Журнал/2026-07-23_14-47-43_MSK_включать-профиль-времени-в-отчёты-журнала/запрос.md)
- [исходный запрос 2026-07-23 10:44:00 MSK - Автоматизировать обновление ссылок при смене статуса карточки](../Журнал/2026-07-23_10-44-00_MSK_автоматизировать-обновление-ссылок-при-смене-статуса-карточки/запрос.md)
- [исходный запрос 2026-07-22 10:02:43 MSK - Добавить аудит покрытия вопросов и ответов](../Журнал/2026-07-22_10-02-43_MSK_добавить-аудит-покрытия-вопросов-и-ответов/запрос.md)
- [исходный запрос 2026-07-22 08:44:00 MSK - Мигрировать legacy имена автоматизаций](../Журнал/2026-07-22_08-44-00_MSK_мигрировать-legacy-имена-автоматизаций/запрос.md)
- [исходный запрос 2026-07-21 11:32:46 MSK - Актуализировать входные описания FUM](../Журнал/2026-07-21_11-32-46_MSK_актуализировать-входные-описания-FUM/запрос.md)
- [исходный запрос 2026-07-21 12:18:37 MSK - Закрепить транслитерацию названий автоматизаций](../Журнал/2026-07-21_12-18-37_MSK_закрепить-транслитерацию-названий-автоматизаций/запрос.md)
- [исходный запрос 2026-07-21 13:40:42 MSK — Актуализировать форк и подключить LinguisticKit](../Журнал/2026-07-21_13-40-42_MSK_актуализировать-форк-и-подключить-LinguisticKit/запрос.md)
- [исходный запрос 2026-07-21 18:31:35 MSK — Ввести последовательную очередь сессий без hooks](../Журнал/2026-07-21_18-31-35_MSK_ввести-последовательную-очередь-сессий-без-hooks/запрос.md)
- [исходный запрос 2026-07-22 03:38:35 MSK - Разрешить выполнение доступных карточек шагов](../Журнал/2026-07-22_03-38-35_MSK_разрешить-выполнение-доступных-карточек-шагов/запрос.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-26 14:29:42 MSK -->
<!-- content-sha256: sha256:efc5bfd923c609884cfee6e40641f87a3e06a7c043802d3f714f79da871a1136 -->
<!-- FUM-MD-RECENCY:END -->
