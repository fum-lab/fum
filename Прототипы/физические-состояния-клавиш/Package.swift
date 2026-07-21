// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FUMPhysicalKeyboard",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "FUMInputCore", targets: ["FUMInputCore"]),
    .library(name: "FUMInputMac", targets: ["FUMInputMac"]),
    .executable(name: "FUMInputGuide", targets: ["FUMInputGuide"]),
    .executable(name: "FUMInputProbe", targets: ["FUMInputProbe"]),
  ],
  targets: [
    .target(
      name: "FUMInputCore",
      path: "Sources/FUMInputCore"
    ),
    .target(
      name: "FUMInputMac",
      dependencies: ["FUMInputCore"],
      path: "Sources/FUMInputMac",
      linkerSettings: [
        .linkedFramework("AppKit"),
        .linkedFramework("CoreGraphics"),
        .linkedFramework("GameController"),
        .linkedFramework("IOKit"),
      ]
    ),
    .executableTarget(
      name: "FUMInputGuide",
      dependencies: ["FUMInputCore", "FUMInputMac"],
      path: "Sources/FUMInputGuide",
      linkerSettings: [
        .linkedFramework("AppKit"),
        .linkedFramework("SwiftUI"),
      ]
    ),
    .executableTarget(
      name: "FUMInputProbe",
      dependencies: ["FUMInputCore", "FUMInputMac"],
      path: "Sources/FUMInputProbe"
    ),
    .testTarget(
      name: "FUMInputCoreTests",
      dependencies: ["FUMInputCore"],
      path: "Tests/FUMInputCoreTests"
    ),
    .testTarget(
      name: "FUMInputMacTests",
      dependencies: ["FUMInputCore", "FUMInputMac"],
      path: "Tests/FUMInputMacTests"
    ),
  ]
)
