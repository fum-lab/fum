import Foundation
import CryptoKit
import Testing
@testable import ОсноваЗапуска

@Suite("Языковой consumer настоящего индекса", .serialized)
struct ПроверкиЯзыковогоИндекса {
    @Test("Stage0 с латиницей отклоняется при русском рабочем файле")
    func латиницаВИндексе() throws {
        let репозиторий = try РепозиторийЯзыковогоТеста()
        defer { репозиторий.убрать() }
        try репозиторий.записать("пример.swift", "func oldName() {}\n")
        _ = try репозиторий.гит(["add", "--", "пример.swift"])
        try репозиторий.записать("пример.swift", "func отчёт() {}\n")
        let результат = try ПроверкаЯзыковогоИндекса.проверить(корень: репозиторий.корень.path,
            политика: репозиторий.политика)
        #expect(результат.нарушения.map(\.имя) == ["oldName"])
    }

    @Test("Русский stage0 принимается при латинском рабочем файле")
    func русскийИндекс() throws {
        let репозиторий = try РепозиторийЯзыковогоТеста()
        defer { репозиторий.убрать() }
        try репозиторий.записать("с пробелом\tещё.swift", "func отчёт() {}\n")
        _ = try репозиторий.гит(["add", "--", "с пробелом\tещё.swift"])
        try репозиторий.записать("с пробелом\tещё.swift", "func badDiskName() {}\n")
        let результат = try ПроверкаЯзыковогоИндекса.проверить(корень: репозиторий.корень.path,
            политика: репозиторий.политика)
        #expect(результат.нарушения.isEmpty)
        #expect(результат.провереноФайлов == 1)
        #expect(!результат.хэшИндекса.isEmpty)
    }

    @Test("Изменённый snapshot не скрывается восстановленным рабочим файлом")
    func снимокНеРасширяется() throws {
        let репозиторий = try РепозиторийЯзыковогоТеста()
        defer { репозиторий.убрать() }
        try репозиторий.записать("граница.json", "{\"новыйОстаток\":1}\n")
        _ = try репозиторий.гит(["add", "--", "граница.json"])
        try репозиторий.записать("граница.json", "{}\n")
        #expect(throws: ОтказЧитателяЯзыка.политика) {
            try ПроверкаЯзыковогоИндекса.проверить(корень: репозиторий.корень.path,
                политика: репозиторий.политика)
        }
    }

    @Test("Изменённая строка старого имени не получает разрешение по равному счётчику")
    func староеИмяНаНовойСтроке() throws {
        let репозиторий = try РепозиторийЯзыковогоТеста(начальныйКод: "func oldName() {}\nfunc русское() {}\n")
        defer { репозиторий.убрать() }
        try репозиторий.записать("пример.swift", "func oldName() { let число = 1 }\nfunc русское() {}\n")
        _ = try репозиторий.гит(["add", "--", "пример.swift"])
        let результат = try ПроверкаЯзыковогоИндекса.проверить(корень: репозиторий.корень.path,
            политика: репозиторий.политика)
        #expect(результат.нарушения.map(\.имя) == ["oldName"])
    }

    @Test("Неизменённая строка старого имени остаётся историческим остатком")
    func прежнийОстаток() throws {
        let репозиторий = try РепозиторийЯзыковогоТеста(начальныйКод: "func oldName() {}\n")
        defer { репозиторий.убрать() }
        try репозиторий.записать("пример.swift", "func oldName() {}\nfunc отчёт() {}\n")
        _ = try репозиторий.гит(["add", "--", "пример.swift"])
        #expect(try ПроверкаЯзыковогоИндекса.проверить(корень: репозиторий.корень.path,
            политика: репозиторий.политика).нарушения.isEmpty)
    }

    @Test("Git reader запрещает lazy fetch, сохраняя effective index")
    func окружениеБезСети() {
        let среда = ЧитательГитЯзыка.окружение(["GIT_INDEX_FILE": "/явный-индекс", "GIT_NO_LAZY_FETCH": "0"])
        #expect(среда["GIT_NO_LAZY_FETCH"] == "1")
        #expect(среда["GIT_INDEX_FILE"] == "/явный-индекс")
    }

    @Test("Новый CR-only stage0 не скрывает латиницу")
    func индексВозвратаКаретки() throws {
        let репозиторий = try РепозиторийЯзыковогоТеста()
        defer { репозиторий.убрать() }
        try репозиторий.записать("новый.swift", "// комментарий\rfunc oldName() {}\r")
        _ = try репозиторий.гит(["add", "--", "новый.swift"])
        let результат = try ПроверкаЯзыковогоИндекса.проверить(корень: репозиторий.корень.path,
            политика: репозиторий.политика)
        #expect(результат.нарушения.map(\.имя) == ["oldName"])
    }

    @Test("Настоящий pre-commit запрещает латинский stage0 и принимает русский при противоположном диске")
    func настоящийХук() throws {
        let репозиторий = try РепозиторийЯзыковогоТеста()
        defer { репозиторий.убрать() }
        let исходники = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        for путь in ЗакреплённаяПолитикаЯзыка.принятая.снимки.keys {
            try репозиторий.записать(путь, String(contentsOf: исходники.appendingPathComponent(путь), encoding: .utf8))
            _ = try репозиторий.гит(["add", "--", путь])
        }
        let исходныйГит = ЧитательГитЯзыка(корень: исходники.path, среда: ProcessInfo.processInfo.environment)
        let общий = try исходныйГит.строка(["rev-parse", "--path-format=absolute", "--git-common-dir"])
        try репозиторий.записать(".git/objects/info/alternates", общий + "/objects\n")
        _ = try репозиторий.гит(["-c", "user.name=Проверка", "-c", "user.email=test@example.invalid",
            "-c", "core.hooksPath=/dev/null", "commit", "-qm", "Закрепить принятую политику"])
        let путьПолитики = "iskhodniki/zapusk/ВнешниеИмена.json"
        let политика = try String(contentsOf: исходники.appendingPathComponent(путьПолитики), encoding: .utf8)
        try репозиторий.записать(путьПолитики, политика + " ")
        _ = try репозиторий.гит(["add", "--", путьПолитики])
        try репозиторий.записать(путьПолитики, политика)
        #expect(throws: ОтказЧитателяЯзыка.политика) {
            try ПроверкаЯзыковогоИндекса.проверить(корень: репозиторий.корень.path)
        }
        _ = try репозиторий.гит(["add", "--", путьПолитики])
        let путьКонтракта = "iskhodniki/zapusk/ВнешнийКонтракт.swift"
        let контракт = try Data(contentsOf: исходники.appendingPathComponent(путьКонтракта))
        #expect(ЧитательГитЯзыка.вычислитьХэш(контракт) == "88c970f9184dfe8ef34826dca02a891d81b8270fa47a675b62317c9a803102eb")
        try репозиторий.записать(путьКонтракта, String(decoding: контракт, as: UTF8.self))
        _ = try репозиторий.гит(["add", "--", путьКонтракта])
        let основа = try репозиторий.гит(["rev-parse", "HEAD"])
        let бинарник = try #require(ProcessInfo.processInfo.environment["FUM_SWIFT_LANGUAGE_GATE_BINARY"])
        #expect(FileManager.default.isExecutableFile(atPath: бинарник))
        let хук = исходники.appendingPathComponent("iskhodniki/zapusk/hooks").path
        let аргументы = ["-c", "user.name=Проверка", "-c", "user.email=test@example.invalid",
            "-c", "core.hooksPath=" + хук, "commit", "-qm", "Проверить настоящий hook"]
        try репозиторий.записать("пример.swift", "func oldName() {}\n")
        _ = try репозиторий.гит(["add", "--", "пример.swift"])
        try репозиторий.записать("пример.swift", "func отчёт() {}\n")
        let отказ = try репозиторий.вызватьГит(аргументы, дополнение: ["FUM_SWIFT_LANGUAGE_GATE_BINARY": бинарник])
        #expect(отказ.0 == 1)
        #expect(try репозиторий.гит(["rev-parse", "HEAD"]) == основа)
        try репозиторий.записать("пример.swift", "func отчёт() {}\n")
        _ = try репозиторий.гит(["add", "--", "пример.swift"])
        try репозиторий.записать("пример.swift", "func badDiskName() {}\n")
        let успех = try репозиторий.вызватьГит(аргументы, дополнение: ["FUM_SWIFT_LANGUAGE_GATE_BINARY": бинарник])
        #expect(успех.0 == 0)
        #expect(try репозиторий.гит(["show", "HEAD:пример.swift"]) == Data("func отчёт() {}\n".utf8))
        #expect(try репозиторий.гит(["show", "HEAD:" + путьКонтракта]) == контракт)
    }
}

private struct РепозиторийЯзыковогоТеста {
    let корень: URL
    var политика: ЗакреплённаяПолитикаЯзыка {
        .init(снимки: ["граница.json": SHA256.hash(data: Data("{}\n".utf8)).map {
            String(format: "%02x", $0)
        }.joined()], путьИсключений: nil)
    }

    init(начальныйКод: String = "// основа\n") throws {
        let первичный = FileManager.default.temporaryDirectory.appendingPathComponent("fum-yazyk-test-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: первичный, withIntermediateDirectories: false)
        корень = URL(fileURLWithPath: try ЧитательГитЯзыка.физическийПуть(первичный.path))
        _ = try гит(["init", "-q"])
        try записать("граница.json", "{}\n")
        try записать("пример.swift", начальныйКод)
        _ = try гит(["add", "--", "граница.json", "пример.swift"])
        _ = try гит(["-c", "user.name=Проверка", "-c", "user.email=test@example.invalid",
                      "-c", "core.hooksPath=/dev/null", "commit", "-qm", "Начальная основа"])
    }

    func записать(_ имя: String, _ текст: String) throws {
        let путь = корень.appendingPathComponent(имя)
        try FileManager.default.createDirectory(at: путь.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(текст.utf8).write(to: путь)
    }

    func гит(_ аргументы: [String]) throws -> Data {
        let результат = try вызватьГит(аргументы)
        guard результат.0 == 0 else { throw ОтказЯзыковогоДопуска.неподдержанныйСинтаксис("Git fixture") }
        return результат.1
    }

    func вызватьГит(_ аргументы: [String], дополнение: [String: String] = [:]) throws -> (Int32, Data) {
        let процесс = Process()
        процесс.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        процесс.arguments = ["-C", корень.path] + аргументы
        var среда = ProcessInfo.processInfo.environment
        for ключ in ["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_AUTHOR_NAME", "GIT_AUTHOR_EMAIL",
                     "GIT_COMMITTER_NAME", "GIT_COMMITTER_EMAIL"] { среда.removeValue(forKey: ключ) }
        среда.merge(дополнение) { _, новое in новое }
        процесс.environment = среда
        let канал = Pipe()
        процесс.standardOutput = канал
        процесс.standardError = FileHandle.nullDevice
        try процесс.run()
        let данные = канал.fileHandleForReading.readDataToEndOfFile()
        процесс.waitUntilExit()
        return (процесс.terminationStatus, данные)
    }

    func убрать() { try? FileManager.default.removeItem(at: корень) }
}
