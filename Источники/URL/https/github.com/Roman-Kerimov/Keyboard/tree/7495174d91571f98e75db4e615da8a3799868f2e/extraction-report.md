# Отчёт о закреплении GitHub-исходника

- Источник: https://github.com/Roman-Kerimov/Keyboard/tree/7495174d91571f98e75db4e615da8a3799868f2e
- Проверенный ref: `refs/heads/main`, наблюдался на 2026-11-01.
- Commit: `7495174d91571f98e75db4e615da8a3799868f2e`; tree: `a2f7c5cf84cfa446b3243aa6952ca28f6f7acf2e`.
- Подпись commit по GitHub API: unsigned.
- Источники: один упорядоченный список раскладок, шесть файлов таблиц компонентов, общая `KeyboardLayout.swift` и `Key.swift`; пути и Git blob OID находятся в `source-manifest.json`.
- Способ получения: точечные GitHub Git-data API-запросы commit/tree/contents/blob. Каждый сохранённый upstream-файл побайтно совпал с указанным Git blob OID.
- LICENSE: точный OID уже существует в `Приложения/FUMA/Операторы/Klaviatura/Уведомления/CC0-Keyboard.txt`; байты переиспользованы.
- Преобразование: `build-layout-source-data.swift` проверяет Git blob OID источников и лицензии, затем извлекает компоненты 3×10, порядок раскладок, option-строки, два словаря сдвига и физические позиции/keycode в `layout-source-data.json`. Он также пишет `keyboard-layout-components.json`: потребляемые записи keycode→CharacterComponent для шести таблиц и общего option-слоя, с byte count и SHA-256 для каждого исходного файла.
- Полнота: ровно шесть source tables × 30 позиций; shared option — 30 позиций; shift-up — 5 пар; shift-right — 3 пары; space — keycode 49. Полнота означает извлечение объявлений из закреплённых файлов, не полноту поведения клавиатуры. Unicode-преобразование, сочетания модификаторов, переходы ввода и жесты не представлены и остаются неизвестными.
- ROOT receipt: `P/keyboard-primary-pins-20261101T130704Z.json`, 6244 байта, SHA-256 `e0bb5b505d2958ac6dc93732a1fd9fde1c992aa4b6e26ae2c9ba9c532d5f709c`; по сообщению ROOT его десять первичных файлов сверены с Git blob. Сам receipt в этом worktree не перечитывался.
- Объём: только эти девять upstream Swift-файлов и уже имеющийся LICENSE. Полный Git clone, CLDR, upstream-приложение, скрипты и сборки не использовались.
- Граница: пакет сохраняет идентификаторы компонентов, но не таблицу преобразования компонентов в отображаемый Unicode-текст. Это происхождение данных, не FUMA-вычислитель.


<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-11-01 16:25:21 MSK -->
<!-- content-sha256: sha256:de6220a3c3eb4e650ddf2bfaf9629cbc8ce2925c083c32c562a5c0faf1df1264 -->
<!-- FUM-MD-RECENCY:END -->
