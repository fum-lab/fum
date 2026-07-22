# Инструменты репозитория

Этот каталог хранит локальные копии инструментов и рабочих инструкций, которые нужны именно для репозитория FUM.

Локальные инструменты имеют приоритет над внешними одноименными инструментами, если внешний инструмент противоречит правилам `AGENTS.md`.

Локальные автоматизации в этом каталоге должны сопровождаться тестами, которые можно запустить без секретов и сетевых зависимостей по умолчанию.

## Реестры

- [Реестр системных приложений и инструментов](реестр-системных-приложений-и-инструментов.md) - фиксирует повторно используемые приложения, CLI-команды, инструменты среды агента, MCP-инструменты и способы проверки их версий.
- [Реестр названий автоматизаций](реестр-названий-автоматизаций.json) - хранит кириллические источники, точные результаты LinguisticKit, технические slug, отображаемые имена, эталоны и временные legacy-исключения.

## Навыки

- [fum-branch-next-step](fum-branch-next-step/SKILL.md) - проверяет веточный рабочий набор, выдаёт единственного готового кандидата независимо от отложенных карточек и атомарно резервирует его перед созданием фоновой задачи Codex.
- [fum-doc-aggregation](fum-doc-aggregation/SKILL.md) - создаёт и проверяет каркас сводных статей документации из нескольких опорных материалов.
- [fum-estimates](fum-estimates/SKILL.md) - создаёт и проверяет оценочные материалы `Оценки/` со снимком репозитория, методикой, диапазонами, допущениями, ограничениями точности и оформлением результата.
- [fum-glossary](fum-glossary/SKILL.md) - поддерживает глоссарий FUM по локальным правилам именования и ссылок.
- [fum-md-recency](fum-md-recency/SKILL.md) - обновляет служебные метки последнего содержательного редактирования во всех Markdown-файлах и собирает индекс `.md`-файлов от свежих к старым.
- [fum-ocheredj-zadach-git-vetki](fum-ocheredj-zadach-git-vetki/SKILL.md) - последовательно допускает корневые задачи одного worktree в порядке атомарной регистрации и завершает владение атомарным commit+handoff без project hooks и POSIX-блокировок.
- [fum-obsidian-graph-recency](fum-obsidian-graph-recency/SKILL.md) - обновляет группы цвета графа Obsidian как тепловую карту Markdown-узлов по времени последнего содержательного редактирования.
- [fum-planning-registry](fum-planning-registry/SKILL.md) - собирает и проверяет машинно читаемый JSON-реестр канонических карточек требований, производных плановых представлений, MVP-кандидатов, предложений и вопросов.
- [fum-project-files](fum-project-files/SKILL.md) - задаёт общий воспроизводимый инвентарь проектных Markdown-файлов и безопасные границы выходных путей служебных автоматизаций.
- [fum-proverka-git-zavisimostej](fum-proverka-git-zavisimostej/SKILL.md) - добавляет Git submodule из форка рядом с актуальным FUM, инициализирует уже зарегистрированную зависимость после свежего клонирования и автономно проверяет отдельный upstream, достижимость выбранной ревизии из локально полученных refs форка и точный gitlink.
- [fum-proverka-nazvanij-avtomatizacij](fum-proverka-nazvanij-avtomatizacij/SKILL.md) - проверяет точную транслитерацию новых и отображаемых имён, slug, legacy-набор, коллизии и явное состояние зависимости LinguisticKit.
- [fum-prototype-launch](fum-prototype-launch/SKILL.md) - проверяет корневую POSIX-панель `prototipyi.sh` и обязательные `запустить.sh` у всех устойчивых прототипов.
- [fum-question-backlinks](fum-question-backlinks/SKILL.md) - проверяет двунаправленность локальных ссылок между открытыми или частично прояснёнными вопросами и заявленной затронутой документацией.
- [fum-readme-index](fum-readme-index/SKILL.md) - проверяет, что тематический индекс корневого `README.md` напрямую охватывает все номерные документы и папочные точки входа `Документация/`.
- [fum-request-materials](fum-request-materials/SKILL.md) - архивирует устойчивые HTML-URL через общий вход `fum source archive`, сохраняет [прикрепляемые материалы](../Глоссарий/прикрепляемый-материал.md) в `Источники/` и поддерживает специализированное извлечение расшаренных чатов ChatGPT.
- [fum-session-time](fum-session-time/SKILL.md) - формирует согласованные имя и заголовочную метку рабочей сессии в зоне `Europe/Moscow` независимо от зоны хоста.
- [fum-session-coherence](fum-session-coherence/SKILL.md) - проверяет связность [рабочей сессии](../Глоссарий/рабочая-сессия.md): навигацию запросов, журнал, корневой Codex-Thread-ID в запросе и теле коммита, использование канонического MSK-времени, квалифицированную запись инструментов, Markdown-ссылки, регистр путей, формальный конечный `?` материалов `Вопросы и ответы/`, сигналы мета-запросов, нижнее расположение справочных блоков и Git-состояние.
- [fum-smoke-check](fum-smoke-check/SKILL.md) - запускает единый локальный smoke-check: тесты автоматизаций, пересборку проверяемых реестров, полноту корневого README, двунаправленность вопросов, recency-проверку и связность выбранной рабочей сессии.
- [fum-work-review](fum-work-review/SKILL.md) - создаёт и проверяет сохранённые ревью проделанной работы: Git-срез, находки, проверки, остаточные риски и вывод.

## Проверки

- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/<YYYY-MM-DD_HH-MM-SS_MSK>.md --commit-message-file <путь> --codex-thread-id <UUID>` - единый локальный smoke-check репозитория для выбранной рабочей сессии и её подготовленного сообщения коммита.
- `python3 Инструменты/fum-prototype-launch/scripts/check-prototype-launchers.py` - проверка корневой панели `prototipyi.sh` и обязательных точек входа `запустить.sh` всех устойчивых прототипов.
- `python3 Инструменты/fum-question-backlinks/scripts/check-question-backlinks.py` - автономная проверка существования, регистра и обратных ссылок всех локальных целей активных вопросов.
- `python3 Инструменты/fum-readme-index/scripts/check-readme-index.py --repo-root .` - автономная проверка полноты тематического индекса номерной документации в корневом `README.md`.
- `python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py init --repo-root . --path Зависимости/LinguisticKit` - сетевая инициализация уже зарегистрированного submodule из отслеживаемой `.gitmodules` и gitlink после свежего клонирования FUM.
- `python3 Инструменты/fum-proverka-git-zavisimostej/scripts/proveritj-git-zavisimostj.py check --repo-root . --fork-url https://github.com/fum-lab/LinguisticKit.git --upstream-url https://github.com/Roman-Kerimov/LinguisticKit.git --path Зависимости/LinguisticKit --revision 837e2ce107b97ee7b9d3344c9fe99142281fe393` - автономная проверка подключённого submodule LinguisticKit без получения remote.
- `python3 Инструменты/fum-proverka-nazvanij-avtomatizacij/scripts/proveritj-nazvaniya-avtomatizacij.py --repo-root . --registry Инструменты/реестр-названий-автоматизаций.json` - автономная структурная либо живая проверка реестра названий автоматизаций.
- `python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" . status --json` - через изолированный закоммиченный HEAD-bootstrap показывает владельца и FIFO-список ожидающих корневых задач текущего worktree.
- `python3 Инструменты/fum-branch-next-step/scripts/branch-next-step.py validate --repo-root . --json` - проверяет рабочие наборы следующих шагов и наличие ровно одного совпадения для активной именованной ветки.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-branch-next-step/tests -p 'test_*.py'` - локальные тесты выбора, повторной проверки, атомарного claim и fenced-восстановления следующего шага ветки.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-ocheredj-zadach-git-vetki/tests -p 'test_*.py'` - локальные тесты переносимой FIFO-очереди и атомарного commit+handoff.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-doc-aggregation/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-doc-aggregation`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-estimates/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-estimates`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-md-recency/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-md-recency`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-obsidian-graph-recency/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-obsidian-graph-recency`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-planning-registry/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-planning-registry`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-project-files/tests -p 'test_*.py'` - локальные тесты общей политики проектных файлов.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-proverka-git-zavisimostej/tests -p 'test_*.py'` - автономные тесты цепочки форк — `origin` — `upstream` — `.gitmodules` — gitlink.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-proverka-nazvanij-avtomatizacij/tests -p 'test_*.py'` - локальные тесты реестра русских латинских названий автоматизаций.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-prototype-launch/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-prototype-launch`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-question-backlinks/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-question-backlinks`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-readme-index/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-readme-index`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-request-materials/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-request-materials`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-time/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-session-time`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-session-coherence`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-smoke-check/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-smoke-check`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-work-review/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-work-review`.

## Источники требований

- [исходный запрос 2026-07-21 11:32:46 MSK - Актуализировать входные описания FUM](../Запросы/2026-07-21_11-32-46_MSK_актуализировать-входные-описания-FUM.md)
- [исходный запрос 2026-07-21 12:18:37 MSK - Закрепить транслитерацию названий автоматизаций](../Запросы/2026-07-21_12-18-37_MSK_закрепить-транслитерацию-названий-автоматизаций.md)
- [исходный запрос 2026-07-21 13:40:42 MSK — Актуализировать форк и подключить LinguisticKit](../Запросы/2026-07-21_13-40-42_MSK_актуализировать-форк-и-подключить-LinguisticKit.md)
- [исходный запрос 2026-07-21 18:31:35 MSK — Ввести последовательную очередь сессий без hooks](../Запросы/2026-07-21_18-31-35_MSK_ввести-последовательную-очередь-сессий-без-hooks.md)
- [исходный запрос 2026-07-22 03:38:35 MSK - Разрешить выполнение доступных карточек шагов](../Запросы/2026-07-22_03-38-35_MSK_разрешить-выполнение-доступных-карточек-шагов.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-22 04:48:08 MSK -->
<!-- content-sha256: sha256:b63be87bd5a514a90adb1f46a2758d2818379fa34666f7025847c09b4a7788d7 -->
<!-- FUM-MD-RECENCY:END -->
