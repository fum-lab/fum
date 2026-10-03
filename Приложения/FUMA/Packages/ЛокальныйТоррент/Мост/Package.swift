// swift-tools-version: 6.0
import PackageDescription
import Foundation
import CryptoKit

// Библиотека поступает только из явной квитанции воспроизводимого сборщика.
func прочитатьСборку() throws -> ([String], [String]) {
    guard let путь = ProcessInfo.processInfo.environment["ФУМ_СБОРКА_ЛИБТОРРЕНТА"],
          путь.hasPrefix("/"), URL(fileURLWithPath: путь).resolvingSymlinksInPath().path == путь else {
        throw NSError(domain: "Мост", code: 1, userInfo: [NSLocalizedDescriptionKey:
            "Нужна ФУМ_СБОРКА_ЛИБТОРРЕНТА: абсолютная квитанция зарегистрированной сборки"])
    }
    let данные = try Data(contentsOf: URL(fileURLWithPath: путь))
    guard let сборка = try JSONSerialization.jsonObject(with: данные) as? [String: Any],
          Set(сборка.keys) == Set(["схема", "коммиты", "регистрация", "аргументы_компиляции",
              "аргументы_линковки", "среда", "длительность_нс", "артефакты", "проба"]),
          сборка["схема"] as? String == "fum.сборка-либторрента.1",
          сборка["проба"] as? String == "успешно",
          let коммиты = сборка["коммиты"] as? [String: String],
          коммиты == ["libtorrent": "56ae8caba38bf154ffc210403cb23f91d0ecaa49",
                      "try_signal": "105cce59972f925a33aa6b1c3109e4cd3caf583d"],
          let регистрация = сборка["регистрация"] as? String,
          регистрация.count == 40, регистрация.allSatisfy({ "0123456789abcdef".contains($0) }),
          let компиляция = сборка["аргументы_компиляции"] as? [String], !компиляция.isEmpty,
          let линковка = сборка["аргументы_линковки"] as? [String], !линковка.isEmpty,
          let артефакты = сборка["артефакты"] as? [String: String], !артефакты.isEmpty else {
        throw NSError(domain: "Мост", code: 2, userInfo: [NSLocalizedDescriptionKey: "Неверная квитанция libtorrent"])
    }
    for (адрес, ожидаемый) in артефакты {
        guard адрес.hasPrefix("/"), ожидаемый.count == 64,
              ожидаемый.allSatisfy({ "0123456789abcdef".contains($0) }) else {
            throw NSError(domain: "Мост", code: 3)
        }
        let байты = try Data(contentsOf: URL(fileURLWithPath: адрес))
        let фактический = SHA256.hash(data: байты).map { String(format: "%02x", $0) }.joined()
        guard фактический == ожидаемый else {
            throw NSError(domain: "Мост", code: 4, userInfo: [NSLocalizedDescriptionKey: "Артефакт сборки изменился: \(адрес)"])
        }
    }
    var корень = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    for _ in 0..<5 { корень.deleteLastPathComponent() }
    func прочитатьГит(_ аргументы: [String]) throws -> String {
        let процесс = Process(); let канал = Pipe()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = ["-C", корень.path] + аргументы
        процесс.environment = ["PATH": "/usr/bin:/bin", "GIT_OPTIONAL_LOCKS": "0",
                              "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null"]
        процесс.standardOutput = канал
        try процесс.run()
        let ответ = канал.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        guard процесс.terminationStatus == 0 else { throw NSError(domain: "Мост", code: 5) }
        return String(decoding: ответ, as: UTF8.self)
    }
    _ = try прочитатьГит(["merge-base", "--is-ancestor", регистрация, "HEAD"])
    for (имя, коммит) in коммиты {
        let адрес = "Приложения/FUMA/Packages/ЛокальныйТоррент/Зависимости/" + имя
        guard try прочитатьГит(["ls-tree", "HEAD", "--", адрес]) == "160000 commit \(коммит)\t\(адрес)\n" else {
            throw NSError(domain: "Мост", code: 6, userInfo: [NSLocalizedDescriptionKey: "Нет зарегистрированного gitlink: \(имя)"])
        }
    }
    return (компиляция, линковка)
}

let сборка: ([String], [String])
do { сборка = try прочитатьСборку() }
catch { fatalError("Сборка Моста закрыта: \(error.localizedDescription)") }

let пакет = Package(
    name: "Мост",
    platforms: [.macOS(.v14)],
    products: [.library(name: "МостЛибторрента", targets: ["МостЛибторрента"]),
               .library(name: "ПробыМоста", targets: ["ПробыМоста"])],
    targets: [
        .target(name: "МостЛибторрента", publicHeadersPath: "include",
                cxxSettings: [.unsafeFlags(сборка.0)], linkerSettings: [.unsafeFlags(сборка.1)]),
        .target(name: "ПробыМоста", dependencies: ["МостЛибторрента"],
                path: "Tests/ПробыМоста", publicHeadersPath: ".",
                cxxSettings: [.unsafeFlags(сборка.0)], linkerSettings: [.unsafeFlags(сборка.1)]),
        .testTarget(name: "Тесты", dependencies: ["МостЛибторрента", "ПробыМоста"])
    ],
    cxxLanguageStandard: .cxx17
)
