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
  dependencies: [.package(path: "../../Зависимости/swift-crypto")],
  targets: [
    .target(
      name: "FUMStructuringOperatorMemory",
      dependencies: [.product(name: "Crypto", package: "swift-crypto")],
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
      dependencies: ["FUMStructuringOperatorMemory"],
      path: "Tests/FUMStructuringOperatorMemoryTests"
    ),
  ]
)
