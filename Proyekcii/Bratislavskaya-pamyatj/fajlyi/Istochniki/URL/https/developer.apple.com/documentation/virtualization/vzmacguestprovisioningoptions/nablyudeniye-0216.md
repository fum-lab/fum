# Provisioning первого запуска macOS

Официальный Markdown прочитан 12 сентября 2026 года. Метаданные доступности API указывают macOS 27.0.0; гостю нужна macOS 27 или новее. Опции действуют только при первом запуске после restore и не переинициализируют уже подготовленного гостя. Документированы username, fullName, password, enablesRemoteLogin и logsInAutomatically; отдельного поля SSH public key в прочитанном перечне нет.

Короткий дословный фрагмент:

> macOS only evaluates these options on the first boot after restore.

Сохранены фрагмент и извлечённые факты, полный текст не переиздаётся. Веб-читатель не принял Content-Type text/markdown; тот же официальный адрес прочитан обычным HTTPS-запросом. Это наблюдение API, не компиляция адаптера и не исполнение provisioning.

## Источники

- [Apple VZMacGuestProvisioningOptions](https://developer.apple.com/documentation/virtualization/vzmacguestprovisioningoptions).
- [Официальный Markdown](https://developer.apple.com/documentation/virtualization/vzmacguestprovisioningoptions.md).
- [Паспорт пилота](../../../../../../../Планирование/macOS-VM-паспорт-пилота.md).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 03:43:42 MSK -->
<!-- content-sha256: sha256:fc7f646119a50af2a8f0d033425090f7dc554cccd82cb78cd1f65445d6518bd8 -->
<!-- FUM-MD-RECENCY:END -->
