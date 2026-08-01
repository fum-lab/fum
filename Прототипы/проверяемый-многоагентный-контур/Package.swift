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
    .library(
      name: "FUMDistributedEpisodeMemory",
      targets: ["FUMDistributedEpisodeMemory"]
    ),
    .executable(name: "FUMWorkPackageProbe", targets: ["FUMWorkPackageProbe"]),
  ],
  dependencies: [
    .package(path: "../воспроизводимое-пополнение-памяти")
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
    .target(
      name: "FUMDistributedEpisodeMemory",
      dependencies: [
        "FUMVerifiableMultiAgentContour",
        .product(
          name: "FUMReproducibleMemoryPopulation",
          package: "воспроизводимое-пополнение-памяти"
        ),
      ],
      path: "Sources/FUMDistributedEpisodeMemory"
    ),
    .executableTarget(
      name: "FUMWorkPackageProbe",
      dependencies: ["FUMDistributedEpisodeMemory", "FUMVerifiableMultiAgentContour"],
      path: "Sources/FUMWorkPackageProbe"
    ),
    .testTarget(
      name: "FUMVerifiableMultiAgentContourTests",
      dependencies: ["FUMVerifiableMultiAgentContour"],
      path: "Tests/FUMVerifiableMultiAgentContourTests"
    ),
    .testTarget(
      name: "FUMDistributedEpisodeMemoryTests",
      dependencies: ["FUMDistributedEpisodeMemory"],
      path: "Tests/FUMDistributedEpisodeMemoryTests"
    ),
  ]
)
