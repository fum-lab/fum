// swift-tools-version: 6.0
import PackageDescription
let строгиеНастройки: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors", "-strict-concurrency=complete"])
]
let пакет = Package(
    name: "ПереходВеток",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ПереходВеток", targets: ["ПереходВеток"]),
               .executable(name: "переход-веток", targets: ["КомандаПерехода"]),
               .executable(name: "исполнитель-фикстуры", targets: ["ИсполнительФикстуры"])],
    targets: [
        .target(name: "ПереходВеток", path: "Sources/perekhod-vetok", exclude: ["Команда.swift"],
                swiftSettings: строгиеНастройки),
        .executableTarget(name: "КомандаПерехода", dependencies: ["ПереходВеток"],
                          path: "Sources/perekhod-vetok",
                          exclude: ["Документы.swift", "Файлы.swift", "Переход.swift", "Планирование.swift", "Интерфейс.swift"],
                          sources: ["Команда.swift"], swiftSettings: строгиеНастройки),
        .executableTarget(name: "ИсполнительФикстуры", dependencies: ["ПереходВеток"], path: "Sources/fixture-driver",
                          swiftSettings: строгиеНастройки),
        .testTarget(name: "ПроверкиПерехода", dependencies: ["ПереходВеток"], path: "Tests",
                    swiftSettings: строгиеНастройки)
    ],
    swiftLanguageModes: [.v6]
)
