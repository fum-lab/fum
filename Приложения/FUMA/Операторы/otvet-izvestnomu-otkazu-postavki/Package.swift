// swift-tools-version: 6.0
import PackageDescription

let строгиеНастройки: [SwiftSetting] = [
  .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
]

let package = Package(
  name: "ОтветНаОтказПоставки",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "ОтветНаОтказПоставки", targets: ["ОтветНаОтказПоставки"])
  ],
  dependencies: [
    .package(path: "../../../../Прототипы/память-структурирующих-операторов")
  ],
  targets: [
    .target(
      name: "ОтветНаОтказПоставки",
      dependencies: [
        .product(name: "FUMStructuringOperatorMemory", package: "память-структурирующих-операторов")
      ], resources: [.process("Resources")], swiftSettings: строгиеНастройки
    ),
    .testTarget(name: "ПроверкиОтветаНаОтказ", dependencies: ["ОтветНаОтказПоставки"], swiftSettings: строгиеНастройки)
  ], swiftLanguageModes: [.v6]
)
