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

- [исходный запрос 2026-07-01 15:35:24 MSK](../../Запросы/2026-07-01_15-35-24_MSK.md), [Воспроизводимые автоматизации FUM](../../Документация/17-воспроизводимые-автоматизации.md), [fum-svezhestj-grafa-obsidian](../../Инструменты/fum-svezhestj-grafa-obsidian/SKILL.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-22 09:17:49 MSK -->
<!-- content-sha256: sha256:4643cd2e0d8ca033aadda8cbaad863311981cc9263b58183fb74c5be69c9ef92 -->
<!-- FUM-MD-RECENCY:END -->
