// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMLiveSingleAgentEpisode",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "FUMLiveEpisodeCore", targets: ["FUMLiveEpisodeCore"]),
    .library(name: "FUMLiveEpisodeRuntime", targets: ["FUMLiveEpisodeRuntime"]),
    .executable(name: "FUMLiveEpisodeProbe", targets: ["FUMLiveEpisodeProbe"]),
  ],
  dependencies: [
    .package(path: "../воспроизводимое-пополнение-памяти"),
    .package(path: "../чистый-модельный-шаг"),
  ],
  targets: [
    .target(
      name: "FUMLiveEpisodeCore",
      path: "Sources/FUMLiveEpisodeCore"
    ),
    .target(
      name: "FUMLiveEpisodeRuntime",
      dependencies: [
        "FUMLiveEpisodeCore",
        .product(
          name: "FUMReproducibleMemoryPopulation",
          package: "воспроизводимое-пополнение-памяти"
        ),
        .product(name: "FUMPureModelStep", package: "чистый-модельный-шаг"),
      ],
      path: "Sources/FUMLiveEpisodeRuntime"
    ),
    .executableTarget(
      name: "FUMLiveEpisodeProbe",
      dependencies: ["FUMLiveEpisodeCore", "FUMLiveEpisodeRuntime"],
      path: "Sources/FUMLiveEpisodeProbe"
    ),
    .testTarget(
      name: "FUMLiveEpisodeCoreTests",
      dependencies: ["FUMLiveEpisodeCore"],
      path: "Tests/FUMLiveEpisodeCoreTests"
    ),
    .testTarget(
      name: "FUMLiveEpisodeRuntimeTests",
      dependencies: ["FUMLiveEpisodeCore", "FUMLiveEpisodeRuntime"],
      path: "Tests/FUMLiveEpisodeRuntimeTests"
    ),
  ]
)
