// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMStructuringOperatorMemory",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "СравнениеДекодирования", targets: ["СравнениеДекодирования"]),
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
    .target(name: "СтендДекодирования", dependencies: ["FUMStructuringOperatorMemory"]),
    .executableTarget(name: "СравнениеДекодирования", dependencies: ["СтендДекодирования"]),
    .target(
      name: "FUMStructuringOperatorMemory",
      path: "Sources/FUMStructuringOperatorMemory",
      resources: [
        .copy("Фикстуры"),
        .copy("Определения"),
      ]
    ),
    .executableTarget(
      name: "FUMStructuringOperatorMemoryProbe",
      dependencies: ["FUMStructuringOperatorMemory"],
      path: "Sources/FUMStructuringOperatorMemoryProbe"
    ),
    .testTarget(
      name: "FUMStructuringOperatorMemoryTests",
      dependencies: ["FUMStructuringOperatorMemory", "СтендДекодирования"],
      path: "Tests/FUMStructuringOperatorMemoryTests"
    ),
  ]
)
