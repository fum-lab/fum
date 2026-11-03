# GitHub Keyboard: исходные матрицы раскладок

Этот закреплённый источник хранит ровно девять upstream-файлов по commit [7495174d91571f98e75db4e615da8a3799868f2e](https://github.com/Roman-Kerimov/Keyboard/commit/7495174d91571f98e75db4e615da8a3799868f2e), наблюдавшемуся в `main` 2026-11-01. Корневое дерево commit — `a2f7c5cf84cfa446b3243aa6952ca28f6f7acf2e`; подпись GitHub отмечена как unsigned.

[Расширенный пакет происхождения](layout-source-data.json) содержит все шесть раскладок в порядке исходного `allLayouts`: QWERTY, Dvorak, Colemak, AZERTY, QWERTZ, QZERTY. Каждая 3×10 матрица сохраняет имена `CharacterComponent`; [общая физическая матрица](layout-source-data.json) связывает позиции и keycode из `Key.layoutBoard`. Для прямого потребления FUMA добавлен компактный [JSON таблиц компонентов](keyboard-layout-components.json): он связывает все 30 позиций каждой раскладки с исходным mac virtual keycode, содержит общие option-позиции, shift-up/shift-right пары, отдельную space-клавишу, upstream Git blob, точные байты и SHA-256 каждого из девяти файлов. Идентификаторы системных раскладок остаются только атрибуцией источника; FUMA не вычисляет выбранную раскладку из нативного input source.

[Манифест источника](source-manifest.json) фиксирует OID каждого исходного файла. [Сохранённые байты upstream](source-files/) проходят Git blob-сверку внутри [детерминированного Swift-генератора](build-layout-source-data.swift), который записывает оба JSON. Генератор сверяет Git blob ID сохранённых байтов перед извлечением. Компактная схема помечает таблицы как полные только в границах закреплённых исходных деклараций; Unicode-рендеринг, комбинации модификаторов, переходы событий и жесты остаются непокрытыми/неизвестными. Ссылка на десятифайловый ROOT receipt `P/keyboard-primary-pins-20261101T130704Z.json` (6244 байта, SHA-256 `e0bb5b505d2958ac6dc93732a1fd9fde1c992aa4b6e26ae2c9ba9c532d5f709c`) сохраняется в компактном JSON; bytes receipt в этом W повторно не читались. [Отчёт извлечения](extraction-report.md) описывает границы этого набора.

Корневой [LICENSE upstream](https://github.com/Roman-Kerimov/Keyboard/blob/7495174d91571f98e75db4e615da8a3799868f2e/LICENSE), blob `0e259d42c996742e9e3cba14c677129b2c1b6311`, побайтно переиспользует уже сохранённый [CC0 текст Klaviatura](../../../../../../../../Приложения/FUMA/Операторы/Klaviatura/Уведомления/CC0-Keyboard.txt); повторной копии нет. Запись фиксирует только upstream LICENSE и не утверждает отдельно проверенную лицензию зависимостей или сторонних данных.

Это адресный набор для шести таблиц, общей модели и физической матрицы; полный репозиторий и CLDR не архивировались. Здесь нет преобразования компонент в Unicode-текст и нет реализации раскладочного движка.

## Все сохранённые файлы

- `source-url.txt`
- `source-manifest.json`
- `layout-source-data.json`
- `keyboard-layout-components.json`
- `build-layout-source-data.swift`
- `extraction-report.md`
- `source-index.md`
- `snapshot-manifest.json`
- `source-files/KeyboardModule/Sources/KeyboardModule/KeyboardLayout.swift`
- `source-files/KeyboardModule/Sources/KeyboardModule/Key.swift`
- `source-files/KeyboardModule/Sources/KeyboardModule/KeyboardLayouts/KeyboardLayout.allLayouts.swift`
- `source-files/KeyboardModule/Sources/KeyboardModule/KeyboardLayouts/KeyboardLayout.qwerty.swift`
- `source-files/KeyboardModule/Sources/KeyboardModule/KeyboardLayouts/KeyboardLayout.dvorak.swift`
- `source-files/KeyboardModule/Sources/KeyboardModule/KeyboardLayouts/KeyboardLayout.colemak.swift`
- `source-files/KeyboardModule/Sources/KeyboardModule/KeyboardLayouts/KeyboardLayout.azerty.swift`
- `source-files/KeyboardModule/Sources/KeyboardModule/KeyboardLayouts/KeyboardLayout.qwertz.swift`
- `source-files/KeyboardModule/Sources/KeyboardModule/KeyboardLayouts/KeyboardLayout.qzerty.swift`

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-11-01 16:25:21 MSK -->
<!-- content-sha256: sha256:a24aadc992735763432ba30730ff962b0a16a2d9f721315a6f696bf6505f1c9b -->
<!-- FUM-MD-RECENCY:END -->
