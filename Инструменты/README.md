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
- [fum-planning-registry](fum-planning-registry/SKILL.md) - собирает и проверяет машинно читаемый JSON-реестр требований, вариантов реализации, MVP-кандидатов, предложений и вопросов.
- [fum-request-materials](fum-request-materials/SKILL.md) - сохраняет [прикрепляемые материалы](../Глоссарий/прикрепляемый-материал.md) исходных запросов в `Источники/` и автоматизирует извлечение расшаренных чатов ChatGPT.
- [fum-session-coherence](fum-session-coherence/SKILL.md) - проверяет связность [рабочей сессии](../Глоссарий/рабочая-сессия.md): навигацию запросов, журнал, инструменты, Markdown-ссылки, сигналы мета-запросов и Git-состояние.

## Проверки

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-doc-aggregation/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-doc-aggregation`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-estimates/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-estimates`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-md-recency/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-md-recency`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-planning-registry/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-planning-registry`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-request-materials/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-request-materials`.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s Инструменты/fum-session-coherence/tests -p 'test_*.py'` - локальные тесты автоматизации `fum-session-coherence`.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-01 13:49:10 MSK -->
<!-- content-sha256: sha256:d34086068471dc0f3bef59e2c5da1ea7800bf00f306450c18abedf5ce695aa0c -->
<!-- FUM-MD-RECENCY:END -->
