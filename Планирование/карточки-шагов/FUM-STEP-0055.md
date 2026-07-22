+++
schema_version = 1
card_id = "FUM-STEP-0055"
status = "completed"
+++
# Создать воспроизводимую тепловую карту графа Obsidian

[Карточка шага](../../Глоссарий/карточка-шага.md) сохраняет один атомарный плановый шаг и его происхождение отдельно от веточного выбора.

## Задача

Создать воспроизводимую тепловую карту узлов графа Obsidian по времени последнего содержательного редактирования и сохранить необходимые настройки графа в Git.

## Результат

Создана локальная автоматизация [fum-obsidian-graph-recency](../../Инструменты/fum-obsidian-graph-recency/SKILL.md), которая строит `colorGroups` в `.obsidian/graph.json` из `FUM-MD-RECENCY`; общий [fum-smoke-check](../../Инструменты/fum-smoke-check/SKILL.md) расширен проверкой актуальности этой карты.

## Источники

- [исходный запрос 2026-07-01 15:35:24 MSK](../../Запросы/2026-07-01_15-35-24_MSK.md), [Воспроизводимые автоматизации FUM](../../Документация/17-воспроизводимые-автоматизации.md), [fum-obsidian-graph-recency](../../Инструменты/fum-obsidian-graph-recency/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-22 03:17:01 MSK -->
<!-- content-sha256: sha256:300a5bb9bd078b0e508e8592b5473c3966e7bde6e4de4a7c6b9b29134b9b6f6d -->
<!-- FUM-MD-RECENCY:END -->
