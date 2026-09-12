# Извлечённый текст

Источник: <https://raw.githubusercontent.com/jpsim/Yams/0d9ee7ea8c4ebd4a489ad7a73d5c6cad55d6fed3/Package.swift>

## Содержимое

```text
// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "Yams",
    products: [
        .library(name: "Yams", targets: ["Yams"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CYaml",
            exclude: ["CMakeLists.txt"],
            cSettings: [.define("YAML_DECLARE_STATIC")]
        ),
        .target(
            name: "Yams",
            dependencies: ["CYaml"],
            exclude: ["CMakeLists.txt"]
        ),
        .testTarget(
            name: "YamsTests",
            dependencies: ["Yams"],
            exclude: ["CMakeLists.txt"],
            resources: [
                .copy("Fixtures/SourceKitten#289/debug.yaml"),
            ]
        )
    ]
)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:8b1f592bcf96e0a9aed31d3d50f1f2f4a5482924fa53bd2ee0788a6d2b7139de -->
<!-- FUM-MD-RECENCY:END -->
