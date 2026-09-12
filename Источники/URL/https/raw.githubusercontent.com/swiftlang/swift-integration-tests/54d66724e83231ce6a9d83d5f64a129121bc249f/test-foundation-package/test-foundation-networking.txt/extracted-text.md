# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-integration-tests/54d66724e83231ce6a9d83d5f64a129121bc249f/test-foundation-package/test-foundation-networking.txt>

## Содержимое

```text
REQUIRES: platform=Linux
REQUIRES: rdar73904335
RUN: rm -rf %t
RUN: mkdir -p %t
RUN: %{swiftc}  -o %t/test-foundation-networking %S/test-foundation-networking.swift
RUN: %t/test-foundation-networking | %{FileCheck} %s
CHECK: http://example.com
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:0fa7fd010aef64f982d26340c8ec89ce7c3ef5500c9a28718691ef54bd9bd6e4 -->
<!-- FUM-MD-RECENCY:END -->
