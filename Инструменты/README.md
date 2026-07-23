# Инструменты репозитория

Этот каталог хранит локальные копии инструментов и рабочих инструкций, которые нужны именно для репозитория FUM.

Локальные инструменты имеют приоритет над внешними одноименными инструментами, если внешний инструмент противоречит правилам `AGENTS.md`.

Локальные автоматизации в этом каталоге должны сопровождаться тестами, которые можно запустить без секретов и сетевых зависимостей по умолчанию.

## Реестры

- [Реестр системных приложений и инструментов](реестр-системных-приложений-и-инструментов.md) - фиксирует повторно используемые приложения, CLI-команды, инструменты среды агента, MCP-инструменты и способы проверки их версий.
- [Реестр названий автоматизаций](реестр-названий-автоматизаций.json) - хранит кириллические источники, точные результаты LinguisticKit, технические slug, отображаемые имена и эталоны; канонические поля совместимости `legacy` и `legacy_display` пусты после миграции.

## Навыки

- [fum-sleduyusjhij-shag-vetki](fum-sleduyusjhij-shag-vetki/SKILL.md) - проверяет веточный рабочий набор, выдаёт единственного готового кандидата независимо от отложенных карточек и атомарно резервирует его перед созданием фоновой задачи Codex.
- [fum-sborka-svodnoj-dokumentacii](fum-sborka-svodnoj-dokumentacii/SKILL.md) - создаёт и проверяет каркас сводных статей документации из нескольких опорных материалов.
- [fum-ocenki](fum-ocenki/SKILL.md) - создаёт и проверяет оценочные материалы `Оценки/` со снимком репозитория, методикой, диапазонами, допущениями, ограничениями точности и оформлением результата.
- [fum-glossarij](fum-glossarij/SKILL.md) - поддерживает глоссарий FUM по локальным правилам именования и ссылок.
- [fum-svezhestj-markdown](fum-svezhestj-markdown/SKILL.md) - обновляет служебные метки последнего содержательного редактирования во всех Markdown-файлах и собирает индекс `.md`-файлов от свежих к старым.
- [fum-ocheredj-zadach-git-vetki](fum-ocheredj-zadach-git-vetki/SKILL.md) - последовательно допускает корневые задачи одного worktree в порядке атомарной регистрации и завершает владение атомарным commit+handoff без project hooks и POSIX-блокировок.
- [fum-svezhestj-grafa-obsidian](fum-svezhestj-grafa-obsidian/SKILL.md) - обновляет группы цвета графа Obsidian как тепловую карту Markdown-узлов по времени последнего содержательного редактирования.
- [fum-reyestr-planirovaniya](fum-reyestr-planirovaniya/SKILL.md) - собирает и проверяет машинно читаемый JSON-реестр и безопасно переименовывает карточки шагов с обновлением живых текстовых путей.
- [fum-proyektnyiye-fajlyi](fum-proyektnyiye-fajlyi/SKILL.md) - задаёт общий воспроизводимый инвентарь проектных Markdown-файлов и безопасные границы выходных путей служебных автоматизаций.
- [fum-proverka-git-zavisimostej](fum-proverka-git-zavisimostej/SKILL.md) - добавляет Git submodule из форка рядом с актуальным FUM, инициализирует уже зарегистрированную зависимость после свежего клонирования и автономно проверяет отдельный upstream, достижимость выбранной ревизии из локально полученных refs форка и точный gitlink.
- [fum-proverka-nazvanij-avtomatizacij](fum-proverka-nazvanij-avtomatizacij/SKILL.md) - проверяет точную транслитерацию репозиторных и отображаемых имён, slug, отсутствие канонических legacy-исключений, коллизии и явное состояние зависимости LinguisticKit.
- [fum-zapusk-prototipov](fum-zapusk-prototipov/SKILL.md) - проверяет корневую POSIX-панель `prototipyi.sh` и обязательные `запустить.sh` у всех устойчивых прототипов.
- [fum-obratnyiye-ssyilki-voprosov](fum-obratnyiye-ssyilki-voprosov/SKILL.md) - проверяет двунаправленность локальных ссылок между открытыми или частично прояснёнными вопросами и заявленной затронутой документацией.
- [fum-audit-pokryitiya-voprosov-i-otvetov](fum-audit-pokryitiya-voprosov-i-otvetov/SKILL.md) - извлекает вопросительные предложения из дословных блоков запросов, сопоставляет их с source-ссылками карточек и оставляет смысловой отбор ручным.
- [fum-indeks-readme](fum-indeks-readme/SKILL.md) - проверяет, что тематический индекс корневого `README.md` напрямую охватывает все номерные документы и папочные точки входа `Документация/`.
- [fum-materialyi-zaprosov](fum-materialyi-zaprosov/SKILL.md) - архивирует устойчивые HTML-URL через общий вход `fum source archive`, сохраняет [прикрепляемые материалы](../Глоссарий/прикрепляемый-материал.md) в `Источники/` и поддерживает специализированное извлечение расшаренных чатов ChatGPT.
- [fum-moskovskoye-vremya-rabochej-sessii](fum-moskovskoye-vremya-rabochej-sessii/SKILL.md) - формирует согласованные имя и заголовочную метку рабочей сессии в зоне `Europe/Moscow` независимо от зоны хоста.
- [fum-svyaznostj-rabochej-sessii](fum-svyaznostj-rabochej-sessii/SKILL.md) - проверяет связность [рабочей сессии](../Глоссарий/рабочая-сессия.md): навигацию запросов, журнал и его обязательный профиль времени, корневой Codex-Thread-ID в запросе и теле коммита, использование канонического MSK-времени, квалифицированную запись инструментов, Markdown-ссылки, регистр путей, формальный конечный `?` материалов `Вопросы и ответы/`, сигналы мета-запросов, нижнее расположение справочных блоков и Git-состояние.
- [fum-kompleksnaya-proverka-repozitoriya](fum-kompleksnaya-proverka-repozitoriya/SKILL.md) - запускает единый локальный smoke-check: тесты автоматизаций, пересборку проверяемых реестров, полноту корневого README, двунаправленность вопросов, recency-проверку и связность выбранной рабочей сессии.
- [fum-revjyu-prodelannoj-rabotyi](fum-revjyu-prodelannoj-rabotyi/SKILL.md) - создаёт и проверяет сохранённые ревью проделанной работы: Git-срез, находки, проверки, остаточные риски и вывод.

## Проверки

- `python3 Инструменты/fum-kompleksnaya-proverka-repozitoriya/scripts/run-smoke-check.py --request Запросы/<YYYY-MM-DD_HH-MM-SS_MSK>.md --commit-message-file <путь> --codex-thread-id <UUID>` - единый локальный smoke-check репозитория для выбранной рабочей сессии и её подготовленного сообщения коммита.
- `python3 Инструменты/fum-zapusk-prototipov/scripts/check-prototype-launchers.py` - проверка корневой панели `prototipyi.sh` и обязательных точек входа `запустить.sh` всех устойчивых прототипов.
- `python3 Инструменты/fum-obratnyiye-ssyilki-voprosov/scripts/check-question-backlinks.py` - автономная проверка существования, регистра и обратных ссылок всех локальных целей активных вопросов.
- `python3 Инструменты/fum-audit-pokryitiya-voprosov-i-otvetov/scripts/audit-question-answer-coverage.py --repo-root .` - детерминированный список вопросительных кандидатов, их ссылочного покрытия и обязательных ручных смысловых проверок.
- `python3 Инструменты/fum-indeks-readme/scripts/check-readme-index.py --repo-root .` - автономная проверка полноты тематического индекса номерной документации в корневом `README.md`.
- `python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init --repo-root . --path Зависимости/LinguisticKit` - сетевая инициализация уже зарегистрированного submodule из отслеживаемой `.gitmodules` и gitlink после свежего клонирования FUM.
- `python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py check --repo-root . --fork-url https://github.com/fum-lab/LinguisticKit.git --upstream-url https://github.com/Roman-Kerimov/LinguisticKit.git --path Зависимости/LinguisticKit --revision 837e2ce107b97ee7b9d3344c9fe99142281fe393` - автономная проверка подключённого submodule LinguisticKit без получения remote.
- `python3 Инструменты/fum-proverka-nazvanij-avtomatizacij/scripts/proveritj-nazvaniya-avtomatizacij.py --repo-root . --registry Инструменты/реестр-названий-автоматизаций.json` - автономная структурная либо живая проверка реестра названий автоматизаций.
- `python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . status --json` - через изолированный закоммиченный HEAD-bootstrap показывает владельца и FIFO-список ожидающих корневых задач текущего worktree.
- `python3 Инструменты/fum-sleduyusjhij-shag-vetki/scripts/branch-next-step.py validate --repo-root . --json` - проверяет рабочие наборы следующих шагов и наличие ровно одного совпадения для активной именованной ветки.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-sleduyusjhij-shag-vetki/tests -p 'test_*.py'` - локальные тесты выбора, атомарного claim, идемпотентного восстановления потерянного ответа и fenced-восстановления следующего шага ветки.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-ocheredj-zadach-git-vetki/tests -p 'test_*.py'` - локальные тесты переносимой FIFO-очереди и атомарного commit+handoff.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-sborka-svodnoj-dokumentacii/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-sborka-svodnoj-dokumentacii`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-ocenki/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-ocenki`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-svezhestj-markdown/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-svezhestj-markdown`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-svezhestj-grafa-obsidian/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-svezhestj-grafa-obsidian`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-reyestr-planirovaniya/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-reyestr-planirovaniya`.
- `python3 Инструменты/fum-reyestr-planirovaniya/scripts/rename-step-card.py --card-id FUM-STEP-NNNN --status <active|completed|absorbed|withdrawn> [--description <краткое-название>]` - Git-переименование карточки шага с синхронизацией статуса, индекса и живых текстовых путей.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-proyektnyiye-fajlyi/tests -p 'test_*.py'` - локальные тесты общей политики проектных файлов.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-proverka-git-zavisimostej/tests -p 'test_*.py'` - автономные тесты цепочки форк — `origin` — `upstream` — `.gitmodules` — gitlink.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-proverka-nazvanij-avtomatizacij/tests -p 'test_*.py'` - локальные тесты реестра русских латинских названий автоматизаций.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-zapusk-prototipov/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-zapusk-prototipov`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-obratnyiye-ssyilki-voprosov/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-obratnyiye-ssyilki-voprosov`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-audit-pokryitiya-voprosov-i-otvetov/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-audit-pokryitiya-voprosov-i-otvetov`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-indeks-readme/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-indeks-readme`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-materialyi-zaprosov/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-materialyi-zaprosov`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-moskovskoye-vremya-rabochej-sessii/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-moskovskoye-vremya-rabochej-sessii`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-svyaznostj-rabochej-sessii/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-svyaznostj-rabochej-sessii`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-kompleksnaya-proverka-repozitoriya/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-kompleksnaya-proverka-repozitoriya`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-revjyu-prodelannoj-rabotyi/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-revjyu-prodelannoj-rabotyi`.

## Источники требований

- [исходный запрос 2026-07-23 14:47:43 MSK - Включать профиль времени в отчёты журнала](../Запросы/2026-07-23_14-47-43_MSK_включать-профиль-времени-в-отчёты-журнала.md)
- [исходный запрос 2026-07-23 10:44:00 MSK - Автоматизировать обновление ссылок при смене статуса карточки](../Запросы/2026-07-23_10-44-00_MSK_автоматизировать-обновление-ссылок-при-смене-статуса-карточки.md)
- [исходный запрос 2026-07-22 10:02:43 MSK - Добавить аудит покрытия вопросов и ответов](../Запросы/2026-07-22_10-02-43_MSK_добавить-аудит-покрытия-вопросов-и-ответов.md)
- [исходный запрос 2026-07-22 08:44:00 MSK - Мигрировать legacy имена автоматизаций](../Запросы/2026-07-22_08-44-00_MSK_мигрировать-legacy-имена-автоматизаций.md)
- [исходный запрос 2026-07-21 11:32:46 MSK - Актуализировать входные описания FUM](../Запросы/2026-07-21_11-32-46_MSK_актуализировать-входные-описания-FUM.md)
- [исходный запрос 2026-07-21 12:18:37 MSK - Закрепить транслитерацию названий автоматизаций](../Запросы/2026-07-21_12-18-37_MSK_закрепить-транслитерацию-названий-автоматизаций.md)
- [исходный запрос 2026-07-21 13:40:42 MSK — Актуализировать форк и подключить LinguisticKit](../Запросы/2026-07-21_13-40-42_MSK_актуализировать-форк-и-подключить-LinguisticKit.md)
- [исходный запрос 2026-07-21 18:31:35 MSK — Ввести последовательную очередь сессий без hooks](../Запросы/2026-07-21_18-31-35_MSK_ввести-последовательную-очередь-сессий-без-hooks.md)
- [исходный запрос 2026-07-22 03:38:35 MSK - Разрешить выполнение доступных карточек шагов](../Запросы/2026-07-22_03-38-35_MSK_разрешить-выполнение-доступных-карточек-шагов.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-23 14:58:42 MSK -->
<!-- content-sha256: sha256:ac3754980687a1790dd6b598d870bd2c705b175a1711ac9dfdf244de2e758a98 -->
<!-- FUM-MD-RECENCY:END -->
