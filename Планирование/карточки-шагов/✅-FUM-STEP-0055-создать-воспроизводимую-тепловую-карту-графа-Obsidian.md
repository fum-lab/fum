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

Создана локальная автоматизация [fum-svezhestj-grafa-obsidian](../../Инструменты/fum-svezhestj-grafa-obsidian/SKILL.md), которая строит `colorGroups` в `.obsidian/graph.json` из `FUM-MD-RECENCY`; общий [fum-kompleksnaya-proverka-repozitoriya](../../Инструменты/fum-kompleksnaya-proverka-repozitoriya/SKILL.md) расширен проверкой актуальности этой карты.

## Источники

- [исходный запрос 2026-07-01 15:35:24 MSK](../../Журнал/2026-07-01_15-35-24_MSK/запрос.md), [Воспроизводимые автоматизации FUM](../../Документация/17-воспроизводимые-автоматизации.md), [fum-svezhestj-grafa-obsidian](../../Инструменты/fum-svezhestj-grafa-obsidian/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-08-03 14:54:04 MSK -->
<!-- content-sha256: sha256:4f5a6784fe5d4b559549273de42dc497d06a2a7b0266a37699704e1469c9a0e4 -->
<!-- FUM-MD-RECENCY:END -->
