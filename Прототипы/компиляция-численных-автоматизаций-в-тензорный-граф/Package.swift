// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMTensorGraphCompiler",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "FUMTensorGraphCompiler", targets: ["FUMTensorGraphCompiler"]),
    .executable(name: "FUMTensorGraphProbe", targets: ["FUMTensorGraphProbe"]),
  ],
  targets: [
    .target(
      name: "FUMTensorGraphCompiler",
      path: "Sources/FUMTensorGraphCompiler",
      resources: [
        .copy("Фикстуры")
      ]
    ),
    .executableTarget(
      name: "FUMTensorGraphProbe",
      dependencies: ["FUMTensorGraphCompiler"],
      path: "Sources/FUMTensorGraphProbe"
    ),
    .testTarget(
      name: "FUMTensorGraphCompilerTests",
      dependencies: ["FUMTensorGraphCompiler"],
      path: "Tests/FUMTensorGraphCompilerTests"
    ),
  ]
)
