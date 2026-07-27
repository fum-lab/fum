// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMVerifiableMultiAgentContour",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "FUMVerifiableMultiAgentContour",
      targets: ["FUMVerifiableMultiAgentContour"]
    ),
    .executable(name: "FUMWorkPackageProbe", targets: ["FUMWorkPackageProbe"]),
  ],
  targets: [
    .target(
      name: "FUMVerifiableMultiAgentContour",
      path: "Sources/FUMVerifiableMultiAgentContour",
      resources: [
        .copy("Фикстуры"),
        .copy("РабочаяОбласть"),
      ]
    ),
    .executableTarget(
      name: "FUMWorkPackageProbe",
      dependencies: ["FUMVerifiableMultiAgentContour"],
      path: "Sources/FUMWorkPackageProbe"
    ),
    .testTarget(
      name: "FUMVerifiableMultiAgentContourTests",
      dependencies: ["FUMVerifiableMultiAgentContour"],
      path: "Tests/FUMVerifiableMultiAgentContourTests"
    ),
  ]
)
