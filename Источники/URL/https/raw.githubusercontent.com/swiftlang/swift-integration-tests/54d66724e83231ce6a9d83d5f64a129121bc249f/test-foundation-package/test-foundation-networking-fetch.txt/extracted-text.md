# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-integration-tests/54d66724e83231ce6a9d83d5f64a129121bc249f/test-foundation-package/test-foundation-networking-fetch.txt>

## Содержимое

```text
REQUIRES: platform=Linux
REQUIRES: rdar73904335

RUN: rm -rf %t
RUN: mkdir -p %t
RUN: %{swiftc}  -o %t/test-foundation-networking-fetch %S/test-foundation-networking-fetch.swift
RUN: %t/test-foundation-networking-fetch | %{FileCheck} %s

CHECK: {{[0-9]+}}
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:5cb6ed1737bb1626d1fb6a0de1957d9ee28a79211976bd869d0399a8798a006d -->
<!-- FUM-MD-RECENCY:END -->
