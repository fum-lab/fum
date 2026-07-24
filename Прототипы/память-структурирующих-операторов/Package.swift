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
        .copy("Фикстуры")
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
  ]
)
