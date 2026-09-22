// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FUMA",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "fum", targets: ["FUMApp"]),
        .executable(name: "fum-mcp", targets: ["FUMMCPServer"]),
        .executable(name: "fum-ax-vision-sense", targets: ["FUMAXVisionSense"]),
        .executable(name: "fum-attention-loop", targets: ["FUMAttentionLoop"])
    ],
    dependencies: [
        .package(name: "FUMStructuringOperatorMemory", path: "../../../Прототипы/память-структурирующих-операторов"),
        .package(name: "КонтейнерНаблюдений", path: "../Packages/КонтейнерНаблюдений")
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
        .target(name: "ПутиИсполнения"),
        .target(name: "ИсполнениеОператора", dependencies: [
            "ПутиИсполнения",
            .product(name: "FUMStructuringOperatorMemory", package: "FUMStructuringOperatorMemory"),
            .product(name: "КонтейнерНаблюдений", package: "КонтейнерНаблюдений")
        ]),
        .target(name: "FUMObservationJournal"),
        .testTarget(name: "ИсполнениеОператораTests", dependencies: ["ИсполнениеОператора"]),
        .testTarget(name: "FUMObservationJournalTests", dependencies: ["FUMObservationJournal"]),
        .executableTarget(name: "FUMMCPServer", dependencies: ["ПутиИсполнения", "FUMObservationJournal"]),
        .executableTarget(name: "FUMAXVisionSense", dependencies: ["ПутиИсполнения", "FUMObservationJournal"]),
        .executableTarget(name: "FUMAttentionLoop", dependencies: ["ПутиИсполнения", "FUMObservationJournal"]),
        .testTarget(name: "ПутиИсполненияTests", dependencies: ["ПутиИсполнения"])
    ]
)
