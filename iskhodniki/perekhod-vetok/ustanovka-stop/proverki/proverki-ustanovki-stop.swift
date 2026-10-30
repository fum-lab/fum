import Foundation
import Darwin
import Testing
@testable import УстановкаStop

@Suite("Атомарные байты Stop: собственные filesystem fixtures", .serialized)
struct ПроверкиАтомарныхБайтовStop {
    private enum Инъекция: Error { case отказ }
    private struct Фикстура {
        let корень: URL
        let цель: URL
        let чужой: URL
        let старые = Data("{\"FUMStop\":\"old\",\"GitKrakenStop\":{\"keep\":true}}\n".utf8)
        let новые = Data("{\"FUMStop\":\"new\",\"GitKrakenStop\":{\"keep\":true}}\n".utf8)
        let чужие = Data("{\"foreign\":\"оставить побайтно\"}\n".utf8)
        init() throws {
            корень = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
                .appendingPathComponent("fum-atomic-stop-\(UUID().uuidString.lowercased())")
            цель = корень.appendingPathComponent("hooks.json")
            чужой = корень.appendingPathComponent("foreign.json")
            try FileManager.default.createDirectory(at: корень, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
            try Self.записать(старые, цель)
            try Self.записать(чужие, чужой)
        }
        static func записать(_ d: Data, _ p: URL, режим: Int = 0o600) throws {
            if FileManager.default.fileExists(atPath: p.path) {
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: p.path)
            }
            try d.write(to: p)
            try FileManager.default.setAttributes([.posixPermissions: режим], ofItemAtPath: p.path)
        }
        func очистить() {
            do { try FileManager.default.removeItem(at: корень) }
            catch { Issue.record("Собственная fixture не удалена: \(error)") }
        }
        var старыйSHA: String { АтомарныеБайтыStop.sha256(старые) }
        func заменить(_ точки: ТочкиАтомарнойЗаменыStop = ТочкиАтомарнойЗаменыStop())
            throws -> СнимокБайтовStop {
            try АтомарныеБайтыStop.заменить(цель.path, ожидаемыйSHA256: старыйSHA,
                новыми: новые, точки: точки)
        }
        func безВременных() throws -> Bool {
            try FileManager.default.contentsOfDirectory(atPath: корень.path)
                .allSatisfy { !$0.hasPrefix(".fum-stop-") }
        }
    }

    private func отказ(_ граница: ГраницаОтказаStop,
                       _ действие: () throws -> Void) -> ОтказАтомарнойЗаменыStop? {
        do { try действие(); Issue.record("Ожидался типизированный отказ"); return nil }
        catch let e as ОтказАтомарнойЗаменыStop {
            #expect(e.граница == граница)
            #expect(!e.фаза.isEmpty)
            return e
        } catch { Issue.record("Неверный тип ошибки: \(error)"); return nil }
    }

    @Test func точныеБайтыРежимИЧужойJSONНеМеняется() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let r = try ф.заменить()
        #expect(r.данные == ф.новые)
        #expect(r.sha256 == АтомарныеБайтыStop.sha256(ф.новые))
        #expect(r.отпечаток.режим & 0o7777 == 0o600)
        #expect(r.отпечаток.ссылки == 1)
        #expect(try Data(contentsOf: ф.цель) == ф.новые)
        #expect(try Data(contentsOf: ф.чужой) == ф.чужие)
        #expect(try ф.безВременных())
    }

    @Test func неверныйОжидаемыйSHAНеПишет() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let e = отказ(.доRename) {
            _ = try АтомарныеБайтыStop.заменить(ф.цель.path,
                ожидаемыйSHA256: String(repeating: "0", count: 64), новыми: ф.новые)
        }
        #expect(e?.фаза == "ожидаемый-SHA")
        #expect(e?.наблюдаемыйSHA256 == ф.старыйSHA)
        #expect(try Data(contentsOf: ф.цель) == ф.старые)
        #expect(try ф.безВременных())
    }

    @Test func ссылкиНаЦельИРодителяОтклоняются() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let ссылка = ф.корень.appendingPathComponent("link.json")
        try FileManager.default.createSymbolicLink(at: ссылка, withDestinationURL: ф.цель)
        let настоящий = ф.корень.appendingPathComponent("real")
        try FileManager.default.createDirectory(at: настоящий, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        let вложенный = настоящий.appendingPathComponent("hooks.json")
        try Фикстура.записать(ф.старые, вложенный)
        let alias = ф.корень.appendingPathComponent("alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: настоящий)
        for p in [ссылка, alias.appendingPathComponent("hooks.json")] {
            _ = отказ(.доRename) {
                _ = try АтомарныеБайтыStop.заменить(p.path,
                    ожидаемыйSHA256: ф.старыйSHA, новыми: ф.новые)
            }
        }
        #expect(try Data(contentsOf: ф.цель) == ф.старые)
        #expect(try Data(contentsOf: вложенный) == ф.старые)
    }

    @Test func hardlinkПраваИРазмерОтклоняются() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let link = ф.корень.appendingPathComponent("hard.json")
        try FileManager.default.linkItem(at: ф.цель, to: link)
        _ = отказ(.доRename) { _ = try ф.заменить() }
        try FileManager.default.removeItem(at: link)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: ф.цель.path)
        _ = отказ(.доRename) { _ = try ф.заменить() }
        let большие = Data(repeating: 0x61, count: 1_048_577)
        try Фикстура.записать(большие, ф.цель)
        _ = отказ(.доRename) { _ = try ф.заменить() }
        #expect(try Data(contentsOf: ф.цель) == большие)
        #expect(try ф.безВременных())
    }

    @Test func driftПередRenameСохраняетВнешнееИзменение() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        let изменённые = Data("{\"external\":\"новое значение\"}\n".utf8)
        var т = ТочкиАтомарнойЗаменыStop()
        т.передRename = { try Фикстура.записать(изменённые, ф.цель) }
        let e = отказ(.доRename) { _ = try ф.заменить(т) }
        #expect(e?.фаза == "сверка-старого")
        #expect(e?.наблюдаемыйSHA256 == АтомарныеБайтыStop.sha256(изменённые))
        #expect(try Data(contentsOf: ф.цель) == изменённые)
        #expect(try ф.безВременных())
    }

    @Test func отказКонтроляНепосредственноПередRenameСохраняетСтарое() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var точки = ТочкиАтомарнойЗаменыStop()
        точки.передRename = { throw Инъекция.отказ }
        let e = отказ(.доRename) { _ = try ф.заменить(точки) }
        #expect(e?.фаза == "перед-rename")
        #expect(e?.наблюдаемыйSHA256 == ф.старыйSHA)
        #expect(try Data(contentsOf: ф.цель) == ф.старые)
        #expect(try ф.безВременных())
    }

    @Test func отказFsyncФайлаДоRenameСохраняетСтарое() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var число = 0
        var т = ТочкиАтомарнойЗаменыStop()
        т.синхронизацияФайла = { _ in число += 1; throw Инъекция.отказ }
        let e = отказ(.доRename) { _ = try ф.заменить(т) }
        #expect(e?.фаза == "fsync-файла")
        #expect(число == 1)
        #expect(try Data(contentsOf: ф.цель) == ф.старые)
        #expect(try ф.безВременных())
    }

    @Test func отказFsyncКаталогаПослеRenameЭтоUNKNOWNБезПовтора() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var число = 0
        var т = ТочкиАтомарнойЗаменыStop()
        т.синхронизацияКаталога = { _ in число += 1; throw Инъекция.отказ }
        let e = отказ(.послеRename) { _ = try ф.заменить(т) }
        #expect(e?.фаза == "fsync-каталога")
        #expect(e?.наблюдаемыйSHA256 == АтомарныеБайтыStop.sha256(ф.новые))
        #expect(число == 1)
        #expect(try Data(contentsOf: ф.цель) == ф.новые)
        #expect(try Data(contentsOf: ф.чужой) == ф.чужие)
        #expect(try ф.безВременных())
    }

    @Test func отказЧтенияПослеRenameНеВозвращаетПрежнийSHA() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        var точки = ТочкиАтомарнойЗаменыStop()
        точки.синхронизацияКаталога = { _ in
            try FileManager.default.setAttributes([.posixPermissions: 0o400],
                ofItemAtPath: ф.цель.path)
            throw Инъекция.отказ
        }
        let e = отказ(.послеRename) { _ = try ф.заменить(точки) }
        #expect(e?.фаза == "fsync-каталога")
        #expect(e?.наблюдаемыйSHA256 == nil)
        #expect(try Data(contentsOf: ф.цель) == ф.новые)
        #expect(try ф.безВременных())
    }

    @Test func общийReaderТочныеРежимыMetadataPolicyИПредел() throws {
        let ф = try Фикстура(); defer { ф.очистить() }
        for режим in [mode_t(0o400), mode_t(0o500)] {
            try FileManager.default.setAttributes(
                [.posixPermissions: Int(режим)], ofItemAtPath: ф.цель.path)
            let r = try АтомарныеБайтыStop.прочитать(ф.цель.path, ожидаемыйРежим: режим)
            #expect(r.данные == ф.старые)
            #expect(r.sha256 == ф.старыйSHA)
            #expect(r.отпечаток.режим & 0o7777 == режим)
            _ = отказ(.доRename) { _ = try АтомарныеБайтыStop.прочитать(ф.цель.path) }
        }
        try Фикстура.записать(ф.старые, ф.цель, режим: 0o644)
        #expect(try АтомарныеБайтыStop.прочитать(
            ф.цель.path, ожидаемыйРежим: nil).данные == ф.старые)
        _ = отказ(.доRename) {
            _ = try АтомарныеБайтыStop.прочитать(
                ф.цель.path, ожидаемыйРежим: nil, предел: ф.старые.count - 1)
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o664], ofItemAtPath: ф.цель.path)
        _ = отказ(.доRename) {
            _ = try АтомарныеБайтыStop.прочитать(ф.цель.path, ожидаемыйРежим: nil)
        }
    }
}

@Suite("Точная граница команды Stop", .serialized)
struct ПроверкиДельтыКомандыStop {
    private struct Фикстура {
        let old: Data
        let candidate: Data
        let offset: Int
        let length: Int
        let oldSHA: String
        let command: String

        static func json(_ object: Any) throws -> Data {
            try JSONSerialization.data(withJSONObject: object,
                options: [.sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed])
        }

        init() throws {
            let oldCommand = "exec '/synthetic-old/fuma' 'stop'"
            let newCommand = "exec /usr/bin/env -i 'PATH=' '/synthetic-new/fuma' 'stop'"
            let foreign: [String: Any] = ["type": "command", "command": "keep-foreign", "timeout": 90]
            let target: [String: Any] = ["type": "command", "command": oldCommand, "timeout": 90]
            let stops: [[String: Any]] = [["hooks": [foreign]], ["hooks": [target]]]
            let object: [String: Any] = ["hooks": ["Stop": stops], "keep": "Ёж"]
            let bytes = try Self.json(object)
            let token = try Self.json(oldCommand)
            let range = try #require(bytes.range(of: token))
            let replacement = try Self.json(newCommand)
            var changed = bytes
            changed.replaceSubrange(range, with: replacement)
            old = bytes; candidate = changed
            offset = range.lowerBound; length = token.count
            oldSHA = АтомарныеБайтыStop.sha256(Data(oldCommand.utf8))
            command = newCommand
        }

        func проверить(_ bytes: Data? = nil, offset: Int? = nil, length: Int? = nil,
                       sha: String? = nil, command: String? = nil) throws {
            try УстановщикStop.проверитьДельту(old: old, candidate: bytes ?? candidate,
                offset: offset ?? self.offset, length: length ?? self.length,
                oldCommandSHA256: sha ?? oldSHA, newCommand: command ?? self.command)
        }
    }

    @Test func разрешенаТолькоОднаКомандаСПобайтнымСохранениемОстального() throws {
        let ф = try Фикстура()
        try ф.проверить()
        #expect(ф.candidate.prefix(ф.offset) == ф.old.prefix(ф.offset))
        let tail = ф.old.count - ф.offset - ф.length
        #expect(ф.candidate.suffix(tail) == ф.old.suffix(tail))
        let object = try #require(try JSONSerialization.jsonObject(with: ф.candidate) as? [String: Any])
        #expect(object["keep"] as? String == "Ёж")
    }

    @Test func чужаяДельтаНеверныеГраницыХэшИКомандаОтвергаются() throws {
        let ф = try Фикстура()
        var before = ф.candidate; before[0] = 0x5b
        var after = ф.candidate; after.append(10)
        let cases: [() throws -> Void] = [
            { try ф.проверить(before) },
            { try ф.проверить(after) },
            { try ф.проверить(offset: ф.offset + 1) },
            { try ф.проверить(length: 0) },
            { try ф.проверить(sha: String(repeating: "0", count: 64)) },
            { try ф.проверить(command: "unexpected-command") }
        ]
        for действие in cases {
            do { try действие(); Issue.record("Недопустимая дельта принята") }
            catch { }
        }
    }

    @Test func чистоеОкружениеИАпострофФормируютсяКакТочныеАргументы() {
        let value = УстановщикStop.command(["/private/tmp/a'b/fuma", "stop"])
        #expect(value == "exec /usr/bin/env -i 'PATH=' '/private/tmp/a'\"'\"'b/fuma' 'stop'")
    }
}
