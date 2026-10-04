// swift-tools-version: 6.0
import PackageDescription
import Foundation

// Манифест использует только уже зарегистрированный checkout зависимости.
// Отсутствие oracle не превращается в положительное сравнение.
let корень = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent().deletingLastPathComponent()
  .deletingLastPathComponent().deletingLastPathComponent()
  .deletingLastPathComponent().deletingLastPathComponent()
let зависимость = корень.appendingPathComponent("Зависимости/LinguisticKit")
let естьЭталон = FileManager.default.fileExists(
  atPath: зависимость.appendingPathComponent("Package.swift").path)
var пакеты: [Package.Dependency] = [
  .package(path: корень.appendingPathComponent("Прототипы/память-структурирующих-операторов").path)
]
var продукты: [Target.Dependency] = [
  .product(name: "FUMStructuringOperatorMemory", package: "память-структурирующих-операторов")
]
if естьЭталон {
  пакеты.append(.package(path: зависимость.path))
  продукты.append(.product(name: "LinguisticKit.static", package: "LinguisticKit"))
}
let package = Package(
  name: "ПроверкаТранслитерации",
  platforms: [.macOS(.v14)],
  products: [.executable(name: "ПроверкаТранслитерации", targets: ["ПроверкаТранслитерации"])],
  dependencies: пакеты,
  targets: [.executableTarget(
    name: "ПроверкаТранслитерации", dependencies: продукты,
    swiftSettings: естьЭталон ? [.define("LINGUISTICKIT_ORACLE")] : [])],
  swiftLanguageModes: [.v5]
)
