// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMNetworkEnvironment",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "FUMNetworkEnvironment", targets: ["FUMNetworkEnvironment"]),
    .executable(
      name: "FUMNetworkEnvironmentProbe",
      targets: ["FUMNetworkEnvironmentProbe"]
    ),
  ],
  targets: [
    .target(
      name: "FUMNetworkEnvironment",
      path: "Sources/FUMNetworkEnvironment"
    ),
    .executableTarget(
      name: "FUMNetworkEnvironmentProbe",
      dependencies: ["FUMNetworkEnvironment"],
      path: "Sources/FUMNetworkEnvironmentProbe"
    ),
    .testTarget(
      name: "FUMNetworkEnvironmentTests",
      dependencies: ["FUMNetworkEnvironment"],
      path: "Tests/FUMNetworkEnvironmentTests"
    ),
  ]
)
