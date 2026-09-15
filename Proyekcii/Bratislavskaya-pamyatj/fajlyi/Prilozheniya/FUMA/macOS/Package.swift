// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FUMMacOSOrgans",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "fum", targets: ["FUMApp"]),
        .executable(name: "fum-mcp", targets: ["FUMMCPServer"]),
        .executable(name: "fum-ax-vision-sense", targets: ["FUMAXVisionSense"]),
        .executable(name: "fum-attention-loop", targets: ["FUMAttentionLoop"])
    ],
    targets: [
        .executableTarget(
            name: "FUMApp",
            dependencies: ["CMpvShim", "ПутиИсполнения"],
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
        .executableTarget(name: "FUMMCPServer", dependencies: ["ПутиИсполнения"]),
        .executableTarget(name: "FUMAXVisionSense", dependencies: ["ПутиИсполнения"]),
        .executableTarget(name: "FUMAttentionLoop", dependencies: ["ПутиИсполнения"]),
        .testTarget(name: "ПутиИсполненияTests", dependencies: ["ПутиИсполнения"])
    ]
)
