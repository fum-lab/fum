// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMPureModelStep",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "FUMPureModelStep", targets: ["FUMPureModelStep"]),
    .executable(name: "FUMModelStepProbe", targets: ["FUMModelStepProbe"]),
  ],
  targets: [
    .target(
      name: "FUMPureModelStep",
      path: "Sources/FUMPureModelStep"
    ),
    .executableTarget(
      name: "FUMModelStepProbe",
      dependencies: ["FUMPureModelStep"],
      path: "Sources/FUMModelStepProbe"
    ),
    .testTarget(
      name: "FUMPureModelStepTests",
      dependencies: ["FUMPureModelStep"],
      path: "Tests/FUMPureModelStepTests"
    ),
  ]
)
