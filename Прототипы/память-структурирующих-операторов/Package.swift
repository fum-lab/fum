// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMStructuringOperatorMemory",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "FUMStructuringOperatorMemory",
      targets: ["FUMStructuringOperatorMemory"]
    ),
    .executable(
      name: "FUMStructuringOperatorMemoryProbe",
      targets: ["FUMStructuringOperatorMemoryProbe"]
    ),
  ],
  targets: [
    .target(
      name: "FUMStructuringOperatorMemory",
      path: "Sources/FUMStructuringOperatorMemory",
      resources: [
        .copy("Фикстуры"),
        .copy("Определения"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .unsafeFlags([
          "-strict-concurrency=complete",
          "-enable-actor-data-race-checks",
          "-warnings-as-errors",
        ])
      ]
    ),
    .executableTarget(
      name: "FUMStructuringOperatorMemoryProbe",
      dependencies: ["FUMStructuringOperatorMemory"],
      path: "Sources/FUMStructuringOperatorMemoryProbe"
    ),
    .testTarget(
      name: "FUMStructuringOperatorMemoryTests",
      dependencies: ["FUMStructuringOperatorMemory"],
      path: "Tests/FUMStructuringOperatorMemoryTests"
    ),
    .testTarget(
      name: "FUMJSONLProjectionTests",
      dependencies: ["FUMStructuringOperatorMemory"],
      path: "proverki",
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .unsafeFlags([
          "-strict-concurrency=complete",
          "-enable-actor-data-race-checks",
          "-warnings-as-errors",
        ])
      ]
    ),
  ]
)
