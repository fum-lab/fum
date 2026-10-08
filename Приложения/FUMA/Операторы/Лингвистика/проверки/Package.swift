// swift-tools-version: 6.0
import PackageDescription
import Foundation

// Манифест использует только уже зарегистрированный checkout зависимости.
// Отсутствие oracle не превращается в положительное сравнение.
let каталогПакета = URL(fileURLWithPath: Context.packageDirectory, isDirectory: true)
let корень = каталогПакета
  .deletingLastPathComponent().deletingLastPathComponent()
  .deletingLastPathComponent().deletingLastPathComponent()
  .deletingLastPathComponent()
let память = корень.appendingPathComponent("Прототипы/память-структурирующих-операторов")
func обычныйФайл(_ адрес: URL) -> Bool {
  let атрибуты = try? FileManager.default.attributesOfItem(atPath: адрес.path)
  return атрибуты?[.type] as? FileAttributeType == .typeRegular
}
guard каталогПакета.path == корень.appendingPathComponent(
  "Приложения/FUMA/Операторы/Лингвистика/проверки").path,
  обычныйФайл(корень.appendingPathComponent("AGENTS.md")),
  обычныйФайл(корень.appendingPathComponent(".gitmodules")),
  обычныйФайл(память.appendingPathComponent("Package.swift")) else {
  fatalError("FUM: неверный корень пакета", file: "Package.swift", line: 0)
}
let зависимость = корень.appendingPathComponent("Зависимости/LinguisticKit")
let естьЭталон = FileManager.default.fileExists(
  atPath: зависимость.appendingPathComponent("Package.swift").path)
var пакеты: [Package.Dependency] = [
  .package(path: память.path)
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
