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
            dependencies: ["CMpvShim", "ПутиИсполнения", "ИсполнениеОператора"],
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
        .testTarget(name: "ИсполнениеОператораTests", dependencies: ["ИсполнениеОператора"]),
        .executableTarget(name: "FUMMCPServer", dependencies: ["ПутиИсполнения"]),
        .executableTarget(name: "FUMAXVisionSense", dependencies: ["ПутиИсполнения"]),
        .executableTarget(name: "FUMAttentionLoop", dependencies: ["ПутиИсполнения"]),
        .testTarget(name: "ПутиИсполненияTests", dependencies: ["ПутиИсполнения"])
    ]
)
