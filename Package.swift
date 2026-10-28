// swift-tools-version: 6.0
import Foundation
import PackageDescription

let настройки: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
]

let кореньПакета = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let manifestLinguisticKit = кореньПакета
    .appendingPathComponent("Зависимости/LinguisticKit/Package.swift")
let linguisticKitМатериализован = FileManager.default.fileExists(atPath: manifestLinguisticKit.path)

let продуктыBootstrap: [Product] = [
    .executable(name: "bootstrap-zavisimosti", targets: ["КомандаBootstrapЗависимости"]),
]

let целиBootstrap: [Target] = [
    .target(name: "BootstrapЗависимости",
        path: "Инструменты/fum-proverka-git-zavisimostej/swift",
        exclude: ["komanda-bootstrap-zavisimosti.swift", "proverki-bootstrap-zavisimosti.swift"],
        sources: ["bootstrap-zavisimosti.swift", "bezopasnaya-granica-bootstrap.swift"],
        swiftSettings: настройки),
    .executableTarget(name: "КомандаBootstrapЗависимости",
        dependencies: ["BootstrapЗависимости"],
        path: "Инструменты/fum-proverka-git-zavisimostej/swift",
        exclude: ["bootstrap-zavisimosti.swift", "bezopasnaya-granica-bootstrap.swift", "proverki-bootstrap-zavisimosti.swift"],
        sources: ["komanda-bootstrap-zavisimosti.swift"],
        swiftSettings: настройки),
    .testTarget(name: "proverki-bootstrap-zavisimosti",
        dependencies: ["BootstrapЗависимости"],
        path: "Инструменты/fum-proverka-git-zavisimostej/swift",
        exclude: ["bootstrap-zavisimosti.swift", "bezopasnaya-granica-bootstrap.swift", "komanda-bootstrap-zavisimosti.swift"],
        sources: ["proverki-bootstrap-zavisimosti.swift"],
        swiftSettings: настройки),
]

let продуктыПолногоПакета: [Product] = [
    .executable(name: "fuma", targets: ["КомандаЗапуска"]),
    .executable(name: "proverka-marshruta-pravil", targets: ["КомандаМаршрутаПравил"]),
]

let целиПолногоПакета: [Target] = [
    .target(name: "МатериализацияУзлов",
        path: "iskhodniki/perekhod-vetok/uzlyi/sinkhronizaciya",
        sources: ["kontrakt-istochnika-kodeks.swift", "adapter-git-avtor-commita.swift"],
        swiftSettings: настройки),
    .target(name: "FUMStructuringOperatorMemory",
        path: "Прототипы/память-структурирующих-операторов/Sources/FUMStructuringOperatorMemory",
        resources: [.copy("Фикстуры"), .copy("Определения")], swiftSettings: настройки),
    .target(name: "ЖурналУзла", dependencies: ["FUMStructuringOperatorMemory", "ОсноваЗапуска"],
        path: "iskhodniki/zhurnal", exclude: ["381.json", "publikacionnaya-politika.json", "karta-imyon.json", "primer.json", "profilj.json", "rukovodstvo.md", "zhurnal", "proverki", "uchyot-proverok.swift"],
        resources: [.copy("opredeleniya")], swiftSettings: настройки),
    .testTarget(name: "proverki-zhurnala", dependencies: ["ЖурналУзла", "ОсноваЗапуска"],
        path: "iskhodniki/zhurnal/proverki", swiftSettings: настройки),
    .target(name: "АктуализацияПутей",
        dependencies: [.product(name: "LinguisticKit.static", package: "LinguisticKit")],
        path: "iskhodniki/aktualizaciya-putej", exclude: ["rukovodstvo.md"],
        swiftSettings: настройки),
    .testTarget(name: "proverki-aktualizaciya-putej", dependencies: ["АктуализацияПутей"],
        path: "proverki/aktualizaciya-putej", swiftSettings: настройки),
    .target(name: "ПроверкаМаршрутаПравил", dependencies: ["FUMStructuringOperatorMemory"],
        path: "iskhodniki/proverka-marshruta-pravil", exclude: ["komanda"],
        resources: [.copy("opredeleniya")], swiftSettings: настройки),
    .executableTarget(name: "КомандаМаршрутаПравил", dependencies: ["ПроверкаМаршрутаПравил"],
        path: "iskhodniki/proverka-marshruta-pravil/komanda", swiftSettings: настройки),
    .testTarget(name: "proverki-marshruta-pravil", dependencies: ["ПроверкаМаршрутаПравил"],
        path: "proverki/proverka-marshruta-pravil", swiftSettings: настройки),
    .target(name: "КонтейнерНаблюдений",
        path: "Приложения/FUMA/Packages/КонтейнерНаблюдений/Sources/КонтейнерНаблюдений",
        swiftSettings: настройки),
    .target(name: "СнимокАгентскойЗадачи", dependencies: ["КонтейнерНаблюдений"],
        path: "Приложения/FUMA/Packages/СнимокАгентскойЗадачи/Sources/СнимокАгентскойЗадачи",
        swiftSettings: настройки),
    .target(name: "АрхивныйСнимокЗадачи", dependencies: ["КонтейнерНаблюдений", "СнимокАгентскойЗадачи"],
        path: "Приложения/FUMA/Packages/АрхивныйСнимокЗадачи/Sources/АрхивныйСнимокЗадачи",
        swiftSettings: настройки),
    .target(name: "ОсноваЗапуска", dependencies: ["КонтейнерНаблюдений", "АрхивныйСнимокЗадачи", "FUMStructuringOperatorMemory"],
        path: "iskhodniki/zapusk", exclude: ["Команда.swift", "README.md", "zhurnal", "proverki"],
        swiftSettings: настройки),
    .executableTarget(name: "КомандаЗапуска", dependencies: ["ОсноваЗапуска", "ЖурналУзла", "МатериализацияУзлов"],
        path: "iskhodniki/zapusk",
        exclude: ["ПоляЗапуска.swift", "АргументыЗапуска.swift", "ЦиклЗапуска.swift", "ПутьХранилища.swift", "vkhod-paketa-putej.swift", "obrabotchik-paketa-putej.swift", "priyomnik-fuma-jsonl.swift", "proverka-versionnoj-svyazi-priyomki.swift", "svyazj-kvitancii-modeli.swift", "README.md", "zhurnal", "proverki"],
        sources: ["Команда.swift"], swiftSettings: настройки),
    .testTarget(name: "proverki-paketa-putej", dependencies: ["ОсноваЗапуска", "АрхивныйСнимокЗадачи", "FUMStructuringOperatorMemory", "КонтейнерНаблюдений"],
        path: "iskhodniki/zapusk/proverki", swiftSettings: настройки),
    .testTarget(name: "ПроверкиЗапуска", dependencies: ["ОсноваЗапуска", "КонтейнерНаблюдений"],
        path: "proverki/zapusk", swiftSettings: настройки),
]

let package = Package(
    name: "FUMA",
    platforms: [.macOS(.v14)],
    products: продуктыBootstrap + (linguisticKitМатериализован ? продуктыПолногоПакета : []),
    dependencies: linguisticKitМатериализован ? [
        .package(path: "Зависимости/LinguisticKit"),
    ] : [],
    targets: целиBootstrap + (linguisticKitМатериализован ? целиПолногоПакета : []),
    swiftLanguageModes: [.v6]
)
