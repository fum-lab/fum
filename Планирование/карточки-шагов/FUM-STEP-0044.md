+++
schema_version = 1
card_id = "FUM-STEP-0044"
status = "completed"
+++
# Расширить общий fum-kompleksnaya-proverka-repozitoriya обнаружением SwiftPM-пакетов, тестами, сборкой исполняемых продуктов и явным lint-контрактом

[Карточка шага](../../Глоссарий/карточка-шага.md) сохраняет один атомарный плановый шаг и его происхождение отдельно от веточного выбора.

## Задача

Расширить общий `fum-kompleksnaya-proverka-repozitoriya` обнаружением SwiftPM-пакетов, тестами, сборкой исполняемых продуктов и явным lint-контрактом.

## Результат

Общий прогон автоматически находит два пакета, запускает 51 Swift-тест, отдельно собирает `FUMShadowEditor`, `FUMShadowProbe` и `FUMInputProbe`, применяет строгий lint по умолчанию и проверяет хэш-привязанное исключение теневого редактора.

## Источники

- [исходный запрос 2026-07-20 15:34:46 MSK](../../Запросы/2026-07-20_15-34-46_MSK_включить-SwiftPM-в-общий-smoke-check.md), [журнал](../../Журнал/2026-07-20_15-34-46_MSK_включить-SwiftPM-в-общий-smoke-check.md), [fum-kompleksnaya-proverka-repozitoriya](../../Инструменты/fum-kompleksnaya-proverka-repozitoriya/SKILL.md), [ревью проекта](../../Ревью/2026-07-18_07-44-15_MSK_ревью-проекта.md)

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-22 09:17:49 MSK -->
<!-- content-sha256: sha256:567d1cfced67fb72787adf37016bbbb873c26be674ffed664f5aabf1274fd05d -->
<!-- FUM-MD-RECENCY:END -->
