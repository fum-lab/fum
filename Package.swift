// swift-tools-version: 6.0
import PackageDescription

let настройки: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
]

let package = Package(
    name: "FUMA",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "fuma", targets: ["КомандаЗапуска"])],
    dependencies: [
        .package(path: "Зависимости/LinguisticKit")
    ],
    targets: [
        .target(name: "АктуализацияПутей",
            dependencies: [.product(name: "LinguisticKit.static", package: "LinguisticKit")],
            path: "iskhodniki/aktualizaciya-putej", exclude: ["rukovodstvo.md"],
            swiftSettings: настройки),
        .testTarget(name: "proverki-aktualizaciya-putej", dependencies: ["АктуализацияПутей"],
            path: "proverki/aktualizaciya-putej", swiftSettings: настройки),
        .target(name: "КонтейнерНаблюдений",
            path: "Приложения/FUMA/Packages/КонтейнерНаблюдений/Sources/КонтейнерНаблюдений",
            swiftSettings: настройки),
        .target(name: "ОсноваЗапуска", dependencies: ["КонтейнерНаблюдений"],
            path: "iskhodniki/zapusk", exclude: ["Команда.swift", "README.md"],
            swiftSettings: настройки),
        .executableTarget(name: "КомандаЗапуска", dependencies: ["ОсноваЗапуска"],
            path: "iskhodniki/zapusk",
            exclude: ["ПоляЗапуска.swift", "АргументыЗапуска.swift", "ЦиклЗапуска.swift", "ПутьХранилища.swift", "README.md"],
            sources: ["Команда.swift"], swiftSettings: настройки),
        .testTarget(name: "ПроверкиЗапуска", dependencies: ["ОсноваЗапуска", "КонтейнерНаблюдений"],
            path: "proverki/zapusk", swiftSettings: настройки)
    ],
    swiftLanguageModes: [.v6]
)
