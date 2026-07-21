# Инструменты репозитория

Этот каталог хранит локальные копии инструментов и рабочих инструкций, которые нужны именно для репозитория FUM.

Локальные инструменты имеют приоритет над внешними одноименными инструментами, если внешний инструмент противоречит правилам `AGENTS.md`.

Локальные автоматизации в этом каталоге должны сопровождаться тестами, которые можно запустить без секретов и сетевых зависимостей по умолчанию.

## Реестры

- [Реестр системных приложений и инструментов](реестр-системных-приложений-и-инструментов.md) - фиксирует повторно используемые приложения, CLI-команды, инструменты среды агента, MCP-инструменты и способы проверки их версий.

## Навыки

- [fum-branch-next-step](fum-branch-next-step/SKILL.md) - проверяет, выдаёт и атомарно резервирует единственный следующий шаг активной именованной Git-ветки перед созданием фоновой задачи Codex.
- [fum-branch-task-gate](fum-branch-task-gate/SKILL.md) - сериализует ходы и незакоммиченную работу одной именованной Git-ветки через проектные `UserPromptSubmit`/`PreToolUse`/`Stop` hooks Codex, fenced-владение worktree и проверку Git-состояния вне корневой `.obsidian/`.
- [fum-doc-aggregation](fum-doc-aggregation/SKILL.md) - создаёт и проверяет каркас сводных статей документации из нескольких опорных материалов.
- [fum-estimates](fum-estimates/SKILL.md) - создаёт и проверяет оценочные материалы `Оценки/` со снимком репозитория, методикой, диапазонами, допущениями, ограничениями точности и оформлением результата.
- [fum-glossary](fum-glossary/SKILL.md) - поддерживает глоссарий FUM по локальным правилам именования и ссылок.
- [fum-md-recency](fum-md-recency/SKILL.md) - обновляет служебные метки последнего содержательного редактирования во всех Markdown-файлах и собирает индекс `.md`-файлов от свежих к старым.
- [fum-obsidian-graph-recency](fum-obsidian-graph-recency/SKILL.md) - обновляет группы цвета графа Obsidian как тепловую карту Markdown-узлов по времени последнего содержательного редактирования.
- [fum-planning-registry](fum-planning-registry/SKILL.md) - собирает и проверяет машинно читаемый JSON-реестр канонических карточек требований, производных плановых представлений, MVP-кандидатов, предложений и вопросов.
- [fum-project-files](fum-project-files/SKILL.md) - задаёт общий воспроизводимый инвентарь проектных Markdown-файлов и безопасные границы выходных путей служебных автоматизаций.
- [fum-prototype-launch](fum-prototype-launch/SKILL.md) - проверяет корневую POSIX-панель `prototipyi.sh` и обязательные `запустить.sh` у всех устойчивых прототипов.
- [fum-question-backlinks](fum-question-backlinks/SKILL.md) - проверяет двунаправленность локальных ссылок между открытыми или частично прояснёнными вопросами и заявленной затронутой документацией.
- [fum-request-materials](fum-request-materials/SKILL.md) - сохраняет [прикрепляемые материалы](../Глоссарий/прикрепляемый-материал.md) исходных запросов в `Источники/` и автоматизирует извлечение расшаренных чатов ChatGPT.
- [fum-session-time](fum-session-time/SKILL.md) - формирует согласованные имя и заголовочную метку рабочей сессии в зоне `Europe/Moscow` независимо от зоны хоста.
- [fum-session-coherence](fum-session-coherence/SKILL.md) - проверяет связность [рабочей сессии](../Глоссарий/рабочая-сессия.md): навигацию запросов, журнал, корневой Codex-Thread-ID в запросе и теле коммита, использование канонического MSK-времени, квалифицированную запись инструментов, Markdown-ссылки, регистр путей, формальный конечный `?` материалов `Вопросы и ответы/`, сигналы мета-запросов, нижнее расположение справочных блоков и Git-состояние.
- [fum-smoke-check](fum-smoke-check/SKILL.md) - запускает единый локальный smoke-check: тесты автоматизаций, пересборку проверяемых реестров, двунаправленность вопросов, recency-проверку и связность выбранной рабочей сессии.
- [fum-work-review](fum-work-review/SKILL.md) - создаёт и проверяет сохранённые ревью проделанной работы: Git-срез, находки, проверки, остаточные риски и вывод.

## Проверки

- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/<YYYY-MM-DD_HH-MM-SS_MSK>.md --commit-message-file <путь> --codex-thread-id <UUID>` - единый локальный smoke-check репозитория для выбранной рабочей сессии и её подготовленного сообщения коммита.
- `python3 Инструменты/fum-prototype-launch/scripts/check-prototype-launchers.py` - проверка корневой панели `prototipyi.sh` и обязательных точек входа `запустить.sh` всех устойчивых прототипов.
- `python3 Инструменты/fum-question-backlinks/scripts/check-question-backlinks.py` - автономная проверка существования, регистра и обратных ссылок всех локальных целей активных вопросов.
- `python3 Инструменты/fum-branch-task-gate/scripts/branch-task-gate.py status --repo-root . --json` - показывает владельца и блокирующие пути текущей Git-ветки; код `0` означает готовность, код `1` - занятое состояние.
- `python3 Инструменты/fum-branch-next-step/scripts/branch-next-step.py validate --repo-root . --json` - проверяет записи следующих шагов и наличие ровно одного совпадения для активной именованной ветки.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-branch-next-step/tests -p 'test_*.py'` - локальные тесты выбора, повторной проверки, атомарного claim и fenced-восстановления следующего шага ветки.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-branch-task-gate/tests -p 'test_*.py'` - локальные тесты сериализации задач одной Git-ветки.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-doc-aggregation/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-doc-aggregation`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-estimates/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-estimates`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-md-recency/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-md-recency`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-obsidian-graph-recency/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-obsidian-graph-recency`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-planning-registry/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-planning-registry`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-project-files/tests -p 'test_*.py'` - локальные тесты общей политики проектных файлов.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-prototype-launch/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-prototype-launch`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-question-backlinks/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-question-backlinks`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-request-materials/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-request-materials`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-time/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-session-time`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-session-coherence`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-smoke-check/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-smoke-check`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-work-review/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-work-review`.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-21 08:46:15 MSK -->
<!-- content-sha256: sha256:6f142d08b4e40d04487cd055600d55ea82d37869070ad12c821dde19dde5cb1d -->
<!-- FUM-MD-RECENCY:END -->
