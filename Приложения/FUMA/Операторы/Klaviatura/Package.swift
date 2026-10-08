// swift-tools-version: 6.0
import PackageDescription
let package = Package(
  name: "Klaviatura", platforms: [.macOS(.v14)],
  products: [.executable(name: "Klaviatura", targets: ["ИсполнительКлавиатуры"])],
  dependencies: [.package(path: "../../../../Прототипы/память-структурирующих-операторов")],
  targets: [
    .target(name: "ЭталонКлавиатуры", dependencies: [.product(name: "FUMStructuringOperatorMemory", package: "память-структурирующих-операторов")]),
    .executableTarget(name: "ИсполнительКлавиатуры", dependencies: ["ЭталонКлавиатуры"]),
    .testTarget(name: "ПроверкиКлавиатуры", dependencies: ["ЭталонКлавиатуры"])
  ])
