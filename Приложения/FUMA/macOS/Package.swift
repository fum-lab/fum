// swift-tools-version: 6.0

import PackageDescription
import Foundation

let package = Package(
    name: "FUMA",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "fum", targets: ["FUMApp"]),
        .executable(name: "fum-оператор", targets: ["КомандаОператора"]),
        .executable(name: "fum-mcp", targets: ["FUMMCPServer"]),
        .executable(name: "fum-ax-vision-sense", targets: ["FUMAXVisionSense"]),
        .executable(name: "fum-attention-loop", targets: ["FUMAttentionLoop"])
    ],
    dependencies: [
        .package(name: "FUMStructuringOperatorMemory", path: "../../../Прототипы/память-структурирующих-операторов"),
        .package(name: "КонтейнерНаблюдений", path: "../Packages/КонтейнерНаблюдений"),
        .package(name: "АрхивныйСнимокЗадачи", path: "../Packages/АрхивныйСнимокЗадачи"),
        .package(name: "КомпозицияНаблюдений", path: "../Packages/КомпозицияНаблюдений")
    ],
    targets: [
        .executableTarget(
            name: "FUMApp",
            dependencies: ["CMpvShim", "ПутиИсполнения", "ИсполнениеОператора", "FUMObservationJournal"],
            linkerSettings: [
                .linkedFramework("OpenGL"),
                .linkedLibrary("mpv")
            ]
        ),
        .target(
            name: "CMpvShim",
            dependencies: ["CMpvSystem"],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("OpenGL"),
                .linkedLibrary("mpv")
            ]
        ),
        .systemLibrary(name: "CMpvSystem", pkgConfig: "mpv", providers: [.brew(["mpv"])]),
        .executableTarget(name: "КомандаОператора", dependencies: ["ИсполнениеОператора",
            .product(name: "КомпозицияНаблюдений", package: "КомпозицияНаблюдений")],
            path: "Sources/komanda-operatora",
            swiftSettings: [.swiftLanguageMode(.v6),
                .unsafeFlags(["-strict-concurrency=complete", "-warnings-as-errors"])]),
        .target(name: "ПутиИсполнения"),
        .target(name: "ИсполнениеОператора", dependencies: [
            "ПутиИсполнения",
            .product(name: "FUMStructuringOperatorMemory", package: "FUMStructuringOperatorMemory"),
            .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений"),
            .product(name: "АрхивныйСнимокЗадачи", package: "АрхивныйСнимокЗадачи")
        ]),
        .target(name: "FUMObservationJournal"),
        .testTarget(name: "FUMAOperatorExecutionTests", dependencies: ["ИсполнениеОператора"],
            path: "Tests/ИсполнениеОператораTests"),
        .testTarget(name: "FUMObservationJournalTests", dependencies: ["FUMObservationJournal"]),
        .executableTarget(name: "FUMMCPServer", dependencies: ["ПутиИсполнения", "FUMObservationJournal"]),
        .executableTarget(name: "FUMAXVisionSense", dependencies: ["ПутиИсполнения", "FUMObservationJournal"]),
        .executableTarget(name: "FUMAttentionLoop", dependencies: ["ПутиИсполнения", "FUMObservationJournal"]),
        .testTarget(name: "ПутиИсполненияTests", dependencies: ["ПутиИсполнения"])
    ]
)

// Адресный тестовый граф не собирает GUI и соседние executable targets.
if ProcessInfo.processInfo.environment["ФУМА_ПРОВЕРКА_ОПЕРАТОРА"] == "1" {
    package.products = package.products.filter { $0.name == "fum-оператор" }
    let имена: Set<String> = ["ПутиИсполнения", "ИсполнениеОператора", "КомандаОператора", "FUMAOperatorExecutionTests"]
    package.targets = package.targets.filter { имена.contains($0.name) }
}
