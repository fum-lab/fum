# Извлечённый текст

Источник: <https://raw.githubusercontent.com/swiftlang/swift-llvm-bindings/ff46438cbcea2e04f8b751c4f629c962e58a3e52/Package.swift>

## Содержимое

```text
// swift-tools-version:5.9
// WARNING: Swift Package Manager support is experimental, please consider using CMake to build this project.

import PackageDescription
import class Foundation.ProcessInfo

let env = ProcessInfo.processInfo.environment

func getLLVMSwiftSettings() -> [SwiftSetting]? {
    let env = ProcessInfo.processInfo.environment
    guard let llvmHeaderPath = env["SWIFT_LLVM_BINDINGS_PATH_TO_LLVM_HEADERS"] else {
        print("please pass an environment variable to swift-package: " +
              "SWIFT_LLVM_BINDINGS_PATH_TO_LLVM_HEADERS " +
              "(e.g. swift/llvm-project/llvm/include)")
        return nil
    }
    let llvmModuleMapPath = "\(llvmHeaderPath)/module.modulemap"
    guard let llvmGeneratedHeaderPath = env["SWIFT_LLVM_BINDINGS_PATH_TO_LLVM_GENERATED_HEADERS"] else {
        print("please pass an environment variable to swift-package: " +
              "SWIFT_LLVM_BINDINGS_PATH_TO_LLVM_GENERATED_HEADERS " +
              "(e.g. swift/build/Ninja-DebugAssert/llvm-macosx-arm64/include)")
        return nil
    }

    return [
        .interoperabilityMode(.Cxx),
        .unsafeFlags([
             "-I\(llvmHeaderPath)",
             "-Xcc", "-I\(llvmHeaderPath)",
             "-I\(llvmGeneratedHeaderPath)",
             "-Xcc", "-I\(llvmGeneratedHeaderPath)",
             "-Xcc", "-fmodule-map-file=\(llvmModuleMapPath)",
        ]),
    ]
}

let package = Package(
  name: "SwiftLLVMBindings",
  products: [
    .library(name: "SwiftLLVM_Utils", targets: ["SwiftLLVM_Utils"]),
  ],
  targets: [
    .target(
      name: "SwiftLLVM_Utils",
      path: "Sources/LLVM",
      exclude: ["CMakeLists.txt"],
      sources: ["LLVM_Utils.swift"],
      swiftSettings: getLLVMSwiftSettings()
    ),
  ],
  cxxLanguageStandard: .cxx17
)
```

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 04:23:00 MSK -->
<!-- content-sha256: sha256:4a131a0434345debe89fe18b0717b82b43d4ceb6ad0a225ca9b84f1f70678e9d -->
<!-- FUM-MD-RECENCY:END -->
