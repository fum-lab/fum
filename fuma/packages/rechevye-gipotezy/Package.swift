// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "РечевыеПути",
  platforms: [.macOS(.v14)],
  products: [.library(name: "РечевыеПути", targets: ["РечевыеПути"])],
  dependencies: [.package(path: "../../../Прототипы/память-структурирующих-операторов")],
  targets: [
    .target(name: "РечевыеПути"),
    .testTarget(
      name: "ПроверкиРечевыхПутей",
      dependencies: [
        "РечевыеПути",
        .product(name: "FUMStructuringOperatorMemory", package: "память-структурирующих-операторов")
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
