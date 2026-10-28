import Foundation
import Testing
@testable import ЖурналУзла

private enum ОтказПредпроверкиПубликации: Error, Equatable {
    case командаGit
    case состав
    case новаяROOTПараЖурнала
    case json
    case меткаПроекции
}

private enum ПредпроверкаСоставаПубликации {
    static let основа = "c55b341085688e034206c2b6ebb31cb9070de705"
    static let путьЗаписи = "Прототипы/память-структурирующих-операторов/zhurnal/371c41f5f2ccafa252e89780ecdcb03dbb5812984c70e38c2c6d9f7a57771d15.json"
    static let путьТеста = "iskhodniki/zhurnal/proverki/предпроверка-состава-публикации.swift"
    static let разрешённыеПути: Set<String> = [путьЗаписи, путьТеста]

    static func проверитьСостав(_ пути: [String]) throws {
        guard !пути.contains(where: { $0.hasPrefix("Журнал/") && $0.hasSuffix(".md") })
        else { throw ОтказПредпроверкиПубликации.новаяROOTПараЖурнала }
        guard пути.count == Set(пути).count, Set(пути) == разрешённыеПути
        else { throw ОтказПредпроверкиПубликации.состав }
    }

    static func проверитьJSON(_ данные: Data) throws {
        try ПубличноеПредставление.проверить(данные)
        guard let объект = try JSONSerialization.jsonObject(with: данные) as? [String: Any],
              let содержание = объект["данные"] as? [String: Any],
              let проверки = содержание["проверки"] as? [[String: Any]]
        else { throw ОтказПредпроверкиПубликации.json }
        let совпадения = проверки.filter {
            $0["название"] as? String == "read-only сверка worktree, ветки и remote"
        }
        guard совпадения.count == 1,
              let свидетельство = совпадения[0]["свидетельство"] as? String,
              свидетельство.hasPrefix("ПУБЛИЧНАЯ ПРОЕКЦИЯ (не дословный исходный текст):")
        else { throw ОтказПредпроверкиПубликации.меткаПроекции }
    }

    static func выполнитьGit(_ аргументы: [String], корень: URL) throws -> Data {
        let процесс = Process()
        let каталогиПоиска = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)
        guard let путьКоманды = каталогиПоиска
            .map({ URL(fileURLWithPath: $0).appendingPathComponent("git").path })
            .first(where: FileManager.default.isExecutableFile(atPath:))
        else { throw ОтказПредпроверкиПубликации.командаGit }
        процесс.executableURL = URL(fileURLWithPath: путьКоманды)
        процесс.arguments = ["-C", корень.path] + аргументы
        let канал = Pipe()
        процесс.standardOutput = канал
        процесс.standardError = FileHandle.nullDevice
        do {
            try процесс.run()
        } catch {
            throw ОтказПредпроверкиПубликации.командаGit
        }
        let данные = канал.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        guard процесс.terminationStatus == 0 else { throw ОтказПредпроверкиПубликации.командаGit }
        return данные
    }
}

@Suite("Предпроверка состава публикации", .serialized)
struct ТестыПредпроверкиСоставаПубликации {
@Test func новаяROOTMarkdownПараЗапросаИОтчётаОтклоняется() throws {
    let наблюдаемые = Array(ПредпроверкаСоставаПубликации.разрешённыеПути) + [
        "Журнал/2026-10-28_пример/запрос.md",
        "Журнал/2026-10-28_пример/отчёт.md",
    ]
    #expect(throws: ОтказПредпроверкиПубликации.новаяROOTПараЖурнала) {
        try ПредпроверкаСоставаПубликации.проверитьСостав(наблюдаемые)
    }
}

@Test func абсолютныйПутьВJSONОтклоняется() throws {
    let адрес = String(UnicodeScalar(47)!) + ["Users", "fixture", "repo"].joined(separator: "/")
    let данные = try JSONSerialization.data(withJSONObject: [
        "данные": [
            "проверки": [[
                "название": "read-only сверка worktree, ветки и remote",
                "свидетельство": "ПУБЛИЧНАЯ ПРОЕКЦИЯ (не дословный исходный текст): " + адрес,
            ]],
        ],
    ])
    #expect(throws: ОтказЖурнала.публикация) {
        try ПредпроверкаСоставаПубликации.проверитьJSON(данные)
    }
}

@Test func непомеченнаяПроекцияJSONОтклоняется() throws {
    let данные = try JSONSerialization.data(withJSONObject: [
        "данные": [
            "проверки": [[
                "название": "read-only сверка worktree, ветки и remote",
                "свидетельство": "Собственный managed worktree с repo-relative ref.",
            ]],
        ],
    ])
    #expect(throws: ОтказПредпроверкиПубликации.меткаПроекции) {
        try ПредпроверкаСоставаПубликации.проверитьJSON(данные)
    }
}

@Test(.enabled(if: ProcessInfo.processInfo.environment["FUM_STAGE_PREFLIGHT_ROOT"] != nil))
func предпроверкаТекущейВходящейДельты() throws {
    guard let адресКорня = ProcessInfo.processInfo.environment["FUM_STAGE_PREFLIGHT_ROOT"] else {
        throw ОтказПредпроверкиПубликации.командаGit
    }
    let корень = URL(fileURLWithPath: адресКорня, isDirectory: true)
    let голова = String(decoding: try ПредпроверкаСоставаПубликации.выполнитьGit(
        ["rev-parse", "HEAD"], корень: корень), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    #expect(голова == ПредпроверкаСоставаПубликации.основа)

    let сырыеПути = try ПредпроверкаСоставаПубликации.выполнитьGit(
        ["diff", "--cached", "--name-only", "-z", "--no-renames", ПредпроверкаСоставаПубликации.основа],
        корень: корень)
    let пути = сырыеПути.split(separator: 0).map { String(decoding: $0, as: UTF8.self) }
    try ПредпроверкаСоставаПубликации.проверитьСостав(пути)

    let json = try ПредпроверкаСоставаПубликации.выполнитьGit(
        ["show", ":" + ПредпроверкаСоставаПубликации.путьЗаписи], корень: корень)
    try ПредпроверкаСоставаПубликации.проверитьJSON(json)
}
}
