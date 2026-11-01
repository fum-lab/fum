// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "МодельГлифа",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "МодельГлифа", targets: ["МодельГлифа"]),
  ],
  targets: [
    .target(
      name: "МодельГлифа",
      path: "Sources/FUMGlyphModel",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .unsafeFlags(["-strict-concurrency=complete", "-enable-actor-data-race-checks", "-warnings-as-errors"]),
      ]
    ),
    .testTarget(
      name: "ПроверкиМоделиГлифа",
      dependencies: ["МодельГлифа"],
      path: ".",
      sources: ["Tests/FUMGlyphModelTests"],
      resources: [.copy("Фикстуры")],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .unsafeFlags(["-strict-concurrency=complete", "-enable-actor-data-race-checks", "-warnings-as-errors"]),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
