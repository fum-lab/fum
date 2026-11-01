# GitHub Keyboard: исходные матрицы раскладок

Этот закреплённый источник хранит ровно девять upstream-файлов по commit [7495174d91571f98e75db4e615da8a3799868f2e](https://github.com/Roman-Kerimov/Keyboard/commit/7495174d91571f98e75db4e615da8a3799868f2e), наблюдавшемуся в `main` 2026-11-01. Корневое дерево commit — `a2f7c5cf84cfa446b3243aa6952ca28f6f7acf2e`; подпись GitHub отмечена как unsigned.

[Машинный пакет](layout-source-data.json) содержит все шесть раскладок в порядке исходного `allLayouts`: QWERTY, Dvorak, Colemak, AZERTY, QWERTZ, QZERTY. Каждая 3×10 матрица сохраняет имена `CharacterComponent`; [общая физическая матрица](layout-source-data.json) связывает позиции и keycode из `Key.layoutBoard`. Общие option-строки, shift-up и shift-right словари сохранены отдельно. Идентификаторы системных раскладок остаются только атрибуцией источника; FUMA не вычисляет выбранную раскладку из нативного input source.

[Манифест источника](source-manifest.json) фиксирует OID каждого исходного файла. [Сохранённые байты upstream](source-files/) проходят Git blob-сверку внутри [детерминированного Swift-генератора](build-layout-source-data.swift), который записывает `layout-source-data.json`. [Отчёт извлечения](extraction-report.md) описывает границы этого набора.

Корневой [LICENSE upstream](https://github.com/Roman-Kerimov/Keyboard/blob/7495174d91571f98e75db4e615da8a3799868f2e/LICENSE), blob `0e259d42c996742e9e3cba14c677129b2c1b6311`, побайтно переиспользует уже сохранённый [CC0 текст Klaviatura](../../../../../../../../Приложения/FUMA/Операторы/Klaviatura/Уведомления/CC0-Keyboard.txt); повторной копии нет. Запись фиксирует только upstream LICENSE и не утверждает отдельно проверенную лицензию зависимостей или сторонних данных.

Это адресный набор для шести таблиц, общей модели и физической матрицы; полный репозиторий и CLDR не архивировались. Здесь нет преобразования компонент в Unicode-текст и нет реализации раскладочного движка.

## Все сохранённые файлы

- `source-url.txt`
- `source-manifest.json`
- `layout-source-data.json`
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
<!-- last-content-edit: 2026-11-01 16:08:22 MSK -->
<!-- content-sha256: sha256:92cc2dbb93e84a7b5bd07efa169a3690728923eeb08f7f69ee4dbedf5c1a5eb2 -->
<!-- FUM-MD-RECENCY:END -->
