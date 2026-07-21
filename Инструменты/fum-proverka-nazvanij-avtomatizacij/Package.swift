// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "fum-proverka-nazvanij-avtomatizacij",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    .package(path: "../../Зависимости/LinguisticKit")
  ],
  targets: [
    .executableTarget(
      name: "preobrazovatj-nazvaniya",
      dependencies: [
        .product(name: "LinguisticKit", package: "LinguisticKit")
      ]
    )
  ]
)
