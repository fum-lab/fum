# Зеркало и офлайн-сборка Codex CLI

По [уточнению 243](../запрос.md) создано публичное зеркало [fum-lab/codex](https://github.com/fum-lab/codex). GitHub подтвердил fork и parent/source openai/codex. Независимые Git-чтения main обоих репозиториев дали `33bdf976ccd1130823d4fe041e4d5075ab511d67`. Это проверенный снимок main, а не утверждение о стабильном релизе. Локальные clone, gitlink, установка и сборка здесь не выполнялись.

## Состав воспроизводимого комплекта

Проверено по официальному исходному снимку 11 сентября 2026 года.

- Rust 1.95.0, выбранный target и компоненты toolchain; исходники, Cargo.toml, Cargo.lock и конфигурация Cargo; доступные без сети архивы crates с контрольными суммами; C/C++ компилятор, linker и применимый SDK. Lockfile включает шесть Git-источников: microsoft/mxc, helix-editor/nucleo, dzbarsky/rules_rust, openai-oss-forks/crossterm, tokio-tungstenite и tungstenite-rs. Зеркалируются точные полные ревизии lockfile и необходимые вложенные зависимости. [Rust toolchain](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/codex-rs/rust-toolchain.toml), [Cargo.lock](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/codex-rs/Cargo.lock), [Cargo.toml](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/codex-rs/Cargo.toml).
- Одиночный бинарник codex и полный релиз имеют разные границы. Полная поставка дополнительно содержит codex-code-mode-host, proxy и платформенные helpers. Для workspace/release-профиля существенен V8 150.4.0: Cargo обычно получает native-архивы, поэтому нужны закреплённые архивы, bindings и checksum manifest. Исходная сборка использует отдельный Bazel-граф, V8 15.0.245.2, закреплённые libc++, libc++abi и llvm-libc и остальные входы MODULE.bazel/lock. Сохранённый готовый бинарник не является свидетельством сборки V8 из исходников. [Состав релиза](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/.github/workflows/rust-release.yml), [контракт V8](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/third_party/v8/README.md).
- npm launcher запускает подготовленный Rust-бинарник. Для обычной документированной Cargo-сборки JS-пакеты не обязательны; npm-упаковка отдельно требует закреплённых Node/npm, pnpm 10.34.5, pnpm-lock.yaml и платформенных payload. Корневым JS-инструментам нужен Node не ниже 22, launcher — не ниже 16. Матрица упаковки: macOS, Linux musl и Windows MSVC для arm64/x64. [Инструкция сборки](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/docs/install.md), [package.json](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/package.json), [упаковщик](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/codex-cli/scripts/build_npm_package.py).

## Лицензии и границы автономности

Codex сохраняет Apache-2.0. В поставке сохраняются LICENSE, NOTICE, применимые уведомления и сведения об изменениях. NOTICE отдельно указывает происхождение из Ratatui под MIT. CC0 собственного кода FUM не изменяет лицензии внешних компонентов. Полный лицензионный состав проверяется для выбранного профиля. [LICENSE](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/LICENSE), [NOTICE](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/NOTICE).

Приёмка автоматизации: закреплённый комплект, сборка с замороженным lockfile и фактически запрещённой сетью, проверка выбранных возможностей, хэши результатов и профиль времени, памяти и диска. Побитовая воспроизводимость проверяется отдельно и пока не доказана.

Доступность модели также проверяется отдельно. Облачному backend нужен сервис; локальные Ollama или LM Studio требуют собственного runtime и заранее доступной модели. Зеркало CLI не предоставляет эти данные автоматически. [Обработка локальных провайдеров](https://github.com/openai/codex/blob/33bdf976ccd1130823d4fe041e4d5075ab511d67/codex-rs/utils/oss/src/lib.rs).

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 22:03:48 MSK -->
<!-- content-sha256: sha256:26c8982f767616fc981397cef542e2336069ad34d0ea72c631a0c9a788d3acad -->
<!-- FUM-MD-RECENCY:END -->
