# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-integration-tests/54d66724e83231ce6a9d83d5f64a129121bc249f/test-foundation-package/test-foundation-networking-fetch.swift>

## Содержимое

```text
import Foundation
import FoundationNetworking

let url = URL(string: "http://swift.org")!
let data = try! Data(contentsOf: url)
print(data.underestimatedCount)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:7fc89a51e2c30b534a92c200e69176f347855d9f43953941b4768c181e2956d3 -->
<!-- FUM-MD-RECENCY:END -->
