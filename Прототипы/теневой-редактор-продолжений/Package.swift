// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMShadowEditor",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "FUMShadowCore", targets: ["FUMShadowCore"]),
    .executable(name: "FUMShadowEditor", targets: ["FUMShadowEditor"]),
    .executable(name: "FUMShadowProbe", targets: ["FUMShadowProbe"]),
  ],
  targets: [
    .target(
      name: "FUMShadowCore",
      path: "Sources/FUMShadowCore"
    ),
    .executableTarget(
      name: "FUMShadowEditor",
      dependencies: ["FUMShadowCore"],
      path: "Sources/FUMShadowEditor"
    ),
    .executableTarget(
      name: "FUMShadowProbe",
      dependencies: ["FUMShadowCore"],
      path: "Sources/FUMShadowProbe"
    ),
    .testTarget(
      name: "FUMShadowCoreTests",
      dependencies: ["FUMShadowCore"],
      path: "Tests/FUMShadowCoreTests"
    ),
  ]
)
