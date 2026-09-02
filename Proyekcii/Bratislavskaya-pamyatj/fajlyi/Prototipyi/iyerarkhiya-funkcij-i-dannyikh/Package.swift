// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMFunctionHierarchy",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "FUMFunctionHierarchy", targets: ["FUMFunctionHierarchy"]),
    .executable(name: "FUMFunctionHierarchyProbe", targets: ["FUMFunctionHierarchyProbe"]),
  ],
  targets: [
    .target(
      name: "FUMFunctionHierarchy",
      path: "Sources/FUMFunctionHierarchy"
    ),
    .executableTarget(
      name: "FUMFunctionHierarchyProbe",
      dependencies: ["FUMFunctionHierarchy"],
      path: "Sources/FUMFunctionHierarchyProbe"
    ),
    .testTarget(
      name: "FUMFunctionHierarchyTests",
      dependencies: ["FUMFunctionHierarchy"],
      path: "Tests/FUMFunctionHierarchyTests"
    ),
  ]
)
