# Отчёт о закреплении GitHub-исходника

- Источник: https://github.com/Roman-Kerimov/Keyboard/tree/7495174d91571f98e75db4e615da8a3799868f2e
- Проверенный ref: `refs/heads/main`, наблюдался на 2026-11-01.
- Commit: `7495174d91571f98e75db4e615da8a3799868f2e`; tree: `a2f7c5cf84cfa446b3243aa6952ca28f6f7acf2e`.
- Подпись commit по GitHub API: unsigned.
- Источники: один упорядоченный список раскладок, шесть файлов таблиц компонентов, общая `KeyboardLayout.swift` и `Key.swift`; пути и Git blob OID находятся в `source-manifest.json`.
- Способ получения: точечные GitHub Git-data API-запросы commit/tree/contents/blob. Каждый сохранённый upstream-файл побайтно совпал с указанным Git blob OID.
- LICENSE: точный OID уже существует в `Приложения/FUMA/Операторы/Klaviatura/Уведомления/CC0-Keyboard.txt`; байты переиспользованы.
- Преобразование: `build-layout-source-data.swift` проверяет Git blob OID источников и лицензии, затем извлекает компоненты 3×10, порядок раскладок, option-строки, два словаря сдвига и физические позиции/keycode в `layout-source-data.json`.
- Объём: только эти девять upstream Swift-файлов и уже имеющийся LICENSE. Полный Git clone, CLDR, upstream-приложение, скрипты и сборки не использовались.
- Граница: пакет сохраняет идентификаторы компонентов, но не таблицу преобразования компонентов в отображаемый Unicode-текст. Это происхождение данных, не FUMA-вычислитель.


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-11-01 16:08:22 MSK -->
<!-- content-sha256: sha256:80bfa6868c210b98fb3e1c24200e836f6dad73bceb8357f9f2b623b6422622fd -->
<!-- FUM-MD-RECENCY:END -->
