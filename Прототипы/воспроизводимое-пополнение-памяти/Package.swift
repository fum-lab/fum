// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMReproducibleMemoryPopulation",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "FUMReproducibleMemoryPopulation",
      targets: ["FUMReproducibleMemoryPopulation"]
    ),
    .executable(
      name: "FUMMemoryPopulationProbe",
      targets: ["FUMMemoryPopulationProbe"]
    ),
  ],
  targets: [
    .target(
      name: "FUMReproducibleMemoryPopulation",
      path: "Sources/FUMReproducibleMemoryPopulation",
      resources: [
        .copy("Фикстуры")
      ]
    ),
    .executableTarget(
      name: "FUMMemoryPopulationProbe",
      dependencies: ["FUMReproducibleMemoryPopulation"],
      path: "Sources/FUMMemoryPopulationProbe"
    ),
    .testTarget(
      name: "FUMReproducibleMemoryPopulationTests",
      dependencies: ["FUMReproducibleMemoryPopulation"],
      path: "Tests/FUMReproducibleMemoryPopulationTests"
    ),
  ]
)
