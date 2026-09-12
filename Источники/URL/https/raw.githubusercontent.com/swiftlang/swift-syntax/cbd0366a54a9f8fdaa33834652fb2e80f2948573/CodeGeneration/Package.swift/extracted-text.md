# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-syntax/cbd0366a54a9f8fdaa33834652fb2e80f2948573/CodeGeneration/Package.swift>

## Содержимое

```text
// swift-tools-version:5.7

import Foundation
import PackageDescription

let package = Package(
  name: "CodeGeneration",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .executable(name: "generate-swift-syntax", targets: ["generate-swift-syntax"])
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", from: "510.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
  ],
  targets: [
    .executableTarget(
      name: "generate-swift-syntax",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftBasicFormat", package: "swift-syntax"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "SyntaxSupport",
        "Utils",
      ],
      exclude: [
        "templates/swiftsyntax/SwiftSyntaxDoccIndexTemplate.md"
      ]
    ),
    .target(
      name: "SyntaxSupport",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "Utils",
      dependencies: [
        .product(name: "SwiftBasicFormat", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        "SyntaxSupport",
      ]
    ),
    .testTarget(
      name: "ValidateSyntaxNodes",
      dependencies: [
        "SyntaxSupport"
      ]
    ),
  ]
)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:c8e750404076c9b5598d80dc93bbbc6181611edf0e23fb8eb2abcec310756788 -->
<!-- FUM-MD-RECENCY:END -->
