// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMLiveSingleAgentEpisode",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "FUMLiveEpisodeCore", targets: ["FUMLiveEpisodeCore"]),
    .executable(name: "FUMLiveEpisodeProbe", targets: ["FUMLiveEpisodeProbe"]),
  ],
  targets: [
    .target(
      name: "FUMLiveEpisodeCore",
      path: "Sources/FUMLiveEpisodeCore"
    ),
    .executableTarget(
      name: "FUMLiveEpisodeProbe",
      dependencies: ["FUMLiveEpisodeCore"],
      path: "Sources/FUMLiveEpisodeProbe"
    ),
    .testTarget(
      name: "FUMLiveEpisodeCoreTests",
      dependencies: ["FUMLiveEpisodeCore"],
      path: "Tests/FUMLiveEpisodeCoreTests"
    ),
  ]
)
