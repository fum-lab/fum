# Инструменты репозитория

Этот каталог хранит локальные копии инструментов и рабочих инструкций, которые нужны именно для репозитория FUM.

Локальные инструменты имеют приоритет над внешними одноименными инструментами, если внешний инструмент противоречит правилам `AGENTS.md`.

Локальные автоматизации в этом каталоге должны сопровождаться тестами, которые можно запустить без секретов и сетевых зависимостей по умолчанию.

## Реестры

- [Реестр системных приложений и инструментов](реестр-системных-приложений-и-инструментов.md) - фиксирует повторно используемые приложения, CLI-команды, инструменты среды агента, MCP-инструменты и способы проверки их версий.

## Навыки

- [fum-doc-aggregation](fum-doc-aggregation/SKILL.md) - создаёт и проверяет каркас сводных статей документации из нескольких опорных материалов.
- [fum-estimates](fum-estimates/SKILL.md) - создаёт и проверяет оценочные материалы `Оценки/` со снимком репозитория, методикой, диапазонами, допущениями, ограничениями точности и оформлением результата.
- [fum-glossary](fum-glossary/SKILL.md) - поддерживает глоссарий FUM по локальным правилам именования и ссылок.
- [fum-md-recency](fum-md-recency/SKILL.md) - обновляет служебные метки последнего содержательного редактирования во всех Markdown-файлах и собирает индекс `.md`-файлов от свежих к старым.
- [fum-obsidian-graph-recency](fum-obsidian-graph-recency/SKILL.md) - обновляет группы цвета графа Obsidian как тепловую карту Markdown-узлов по времени последнего содержательного редактирования.
- [fum-planning-registry](fum-planning-registry/SKILL.md) - собирает и проверяет машинно читаемый JSON-реестр требований, вариантов реализации, MVP-кандидатов, предложений и вопросов.
- [fum-request-materials](fum-request-materials/SKILL.md) - сохраняет [прикрепляемые материалы](../Глоссарий/прикрепляемый-материал.md) исходных запросов в `Источники/` и автоматизирует извлечение расшаренных чатов ChatGPT.
- [fum-session-coherence](fum-session-coherence/SKILL.md) - проверяет связность [рабочей сессии](../Глоссарий/рабочая-сессия.md): навигацию запросов, журнал, инструменты, Markdown-ссылки, сигналы мета-запросов и Git-состояние.
- [fum-smoke-check](fum-smoke-check/SKILL.md) - запускает единый локальный smoke-check: тесты автоматизаций, пересборку проверяемых реестров, recency-проверку и связность выбранной рабочей сессии.
- [fum-work-review](fum-work-review/SKILL.md) - создаёт и проверяет сохранённые ревью проделанной работы: Git-срез, находки, проверки, остаточные риски и вывод.

## Проверки

- `python3 Инструменты/fum-smoke-check/scripts/run-smoke-check.py --request Запросы/<YYYY-MM-DD_HH-MM-SS_MSK>.md` - единый локальный smoke-check репозитория для выбранной рабочей сессии.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-doc-aggregation/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-doc-aggregation`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-estimates/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-estimates`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-md-recency/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-md-recency`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-obsidian-graph-recency/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-obsidian-graph-recency`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-planning-registry/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-planning-registry`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-request-materials/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-request-materials`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-session-coherence`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-smoke-check/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-smoke-check`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-work-review/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-work-review`.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-01 17:10:34 MSK -->
<!-- content-sha256: sha256:daa15f0d13c21c621eca38d5fb95786dcf106f8c9a934a607b333ccc7eb4bad7 -->
<!-- FUM-MD-RECENCY:END -->
