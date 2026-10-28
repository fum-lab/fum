// swift-tools-version: 6.0
import PackageDescription

let настройки: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors", "-enable-actor-data-race-checks"])
]

let package = Package(
    name: "FUMA",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "fuma", targets: ["КомандаЗапуска"]),
        .library(name: "МетаданныеКоммита", targets: ["МетаданныеКоммита"]),
    ],
    dependencies: [
        .package(path: "Зависимости/LinguisticKit")
    ],
    targets: [
        .target(
            name: "МетаданныеКоммита",
            dependencies: ["FUMStructuringOperatorMemory"],
            path: "koordinaciya",
            exclude: [
                "журнал.jsonl",
                "квитанция-root-native-client.json",
                "координатор.swift",
                "проверки.swift",
                "состояние.json",
            ],
            sources: [
                "генератор-метаданных-коммита.swift",
                "потребитель-метаданных-коммита.swift",
            ],
            resources: [.copy("fuma")],
            swiftSettings: настройки
        ),
        .testTarget(
            name: "ПроверкиМетаданныхКоммита",
            dependencies: ["МетаданныеКоммита"],
            path: "proverki/metadannye-kommita",
            swiftSettings: настройки
        ),
        .target(
            name: "МатериализацияУзлов",
            dependencies: ["FUMStructuringOperatorMemory"],
            path: "iskhodniki/perekhod-vetok/uzlyi",
            sources: [
                "sinkhronizaciya/kontrakt-istochnika-kodeks.swift",
                "sinkhronizaciya/adapter-git-avtor-commita.swift",
                "polnomochiya.swift",
                "stop.swift",
            ],
            resources: [.copy("opredeleniya")],
            swiftSettings: настройки
        ),
        .testTarget(
            name: "ПроверкиМатериализацииУзлов",
            dependencies: ["МатериализацияУзлов", "FUMStructuringOperatorMemory"],
            path: "iskhodniki/perekhod-vetok/proverki",
            swiftSettings: настройки
        ),
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
        .testTarget(name: "ПроверкиЗапуска", dependencies: ["ОсноваЗапуска", "КонтейнерНаблюдений", "МатериализацияУзлов"],
            path: "proverki/zapusk", swiftSettings: настройки)
    ],
    swiftLanguageModes: [.v6]
)
