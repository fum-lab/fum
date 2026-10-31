import Foundation
import CryptoKit
import Darwin
import Testing
@testable import УстановкаStop

@Suite("Кооперативный publisher и устойчивая попытка", .serialized)
struct ПроверкиПротоколаПубликацииStop {
    private enum Инъекция: Error { case отказ }
    private struct Фикстура {
        let root: URL
        var lock: URL { root.appendingPathComponent("current.json.lock") }
        var config: URL { root.appendingPathComponent("hooks.json") }
        init() throws {
            root = URL(fileURLWithPath: "/private/tmp/fum-stop-protocol-" + UUID().uuidString.lowercased())
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
            try Self.write(Data(), lock)
        }
        static func write(_ data: Data, _ path: URL, mode: Int = 0o600) throws {
            if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path.path)
            }
            try data.write(to: path)
            try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: path.path)
        }
        static func json(_ o: [String: Any]) throws -> Data {
            try JSONSerialization.data(withJSONObject: o, options: [.sortedKeys, .withoutEscapingSlashes])
        }
        func pin() throws -> СсылкаЗамкаStop {
            var s = Darwin.stat()
            guard lstat(lock.path, &s) == 0 else { throw Инъекция.отказ }
            return СсылкаЗамкаStop(path: lock.path, device: Int64(s.st_dev), inode: UInt64(s.st_ino))
        }
        func cleanup() {
            do { try FileManager.default.removeItem(at: root) }
            catch { Issue.record("Собственная fixture не удалена: \(error)") }
        }
    }
    private func refused(_ body: () throws -> Void) {
        do { try body(); Issue.record("Ожидался отказ до эффекта") } catch { }
    }

    @Test func busyНеДаётЭффектаИОсвобождаетсяПослеУспехаИОшибки() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let pin = try f.pin()
        var effects = 0
        try ЗамокТекущегоStop.выполнить(pin) { check in
            try check()
            refused { try ЗамокТекущегоStop.выполнить(pin) { _ in effects += 1 } }
        }
        #expect(effects == 0)
        refused { try ЗамокТекущегоStop.выполнить(pin) { _ in throw Инъекция.отказ } }
        try ЗамокТекущегоStop.выполнить(pin) { check in try check(); effects += 1 }
        #expect(effects == 1)
    }

    @Test func preflightВидитПубликациюПередЗамкомИЧитаетТолькоПодЗамком() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let pin = try f.pin(), path = f.root.appendingPathComponent("current.json")
        let old = Data("old-HEAD/continue".utf8), new = Data("new-HEAD/pause".utf8)
        try Фикстура.write(old, path)
        var unlockedReads = 0
        let seen = try УстановщикStop.предварительнаяПроверка(pin, передЗамком: {
            try ЗамокТекущегоStop.выполнить(pin) { _ in
                _ = try АтомарныеБайтыStop.заменить(path.path,
                    ожидаемыйSHA256: АтомарныеБайтыStop.sha256(old), новыми: new)
            }
        }, наблюдать: {
            // Независимый open FD того же inode не должен получить flock.
            do { try ЗамокТекущегоStop.выполнить(pin) { _ in unlockedReads += 1 } }
            catch { }
            return try АтомарныеБайтыStop.прочитать(path.path).данные
        })
        #expect(seen == new)
        #expect(unlockedReads == 0)
        #expect(try Data(contentsOf: path) == new)
        try ЗамокТекущегоStop.выполнить(pin) { check in try check() }
    }

    @Test func ссылкиПраваРазмерИПодменаInodeОтклоняются() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let original = try f.pin()
        let link = f.root.appendingPathComponent("hard")
        try FileManager.default.linkItem(at: f.lock, to: link)
        refused { _ = try ЗамокТекущегоStop.выполнить(original) { _ in Issue.record("hardlink принят") } }
        try FileManager.default.removeItem(at: link)
        for mode in [0o644, 0o400] {
            try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: f.lock.path)
            refused { _ = try ЗамокТекущегоStop.выполнить(original) { _ in Issue.record("mode принят") } }
        }
        try Фикстура.write(Data([1]), f.lock)
        refused { _ = try ЗамокТекущегоStop.выполнить(original) { _ in Issue.record("size принят") } }
        try Фикстура.write(Data(), f.lock)
        let pin = try f.pin()
        try ЗамокТекущегоStop.выполнить(pin) { check in
            let replacement = f.root.appendingPathComponent("new-lock")
            try Фикстура.write(Data(), replacement)
            #expect(Darwin.rename(replacement.path, f.lock.path) == 0)
            refused { try check() }
        }
        refused { _ = try ЗамокТекущегоStop.выполнить(pin) { _ in Issue.record("old inode принят") } }
        try FileManager.default.removeItem(at: f.lock)
        try FileManager.default.createSymbolicLink(at: f.lock, withDestinationURL: link)
        refused { _ = try ЗамокТекущегоStop.выполнить(original) { _ in Issue.record("symlink принят") } }
    }

    @Test func другойPlanPathHEADИВремяНеОбходятIntentБезOutcome() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let sha = String(repeating: "a", count: 64), candidate = String(repeating: "b", count: 64)
        let first = try УстановщикStop.receiptPaths(config: f.config.path, oldSHA: sha, candidateSHA: candidate)
        #expect(first.intent.hasPrefix(f.root.path + "/.fum-stop-install-"))
        try УстановщикStop.receipt(first.intent,
            ["planPath": f.root.path + "/one/plan.json", "HEAD": "old", "time": 1])
        let second = try УстановщикStop.receiptPaths(config: f.config.path, oldSHA: sha, candidateSHA: candidate)
        #expect(first.intent == second.intent && first.key == second.key)
        refused { try УстановщикStop.receipt(second.intent,
            ["planPath": f.root.path + "/two/plan.json", "HEAD": "new", "time": 2]) }
        #expect(!FileManager.default.fileExists(atPath: first.outcome))
        let saved = try Data(contentsOf: URL(fileURLWithPath: first.intent))
        #expect(saved.range(of: Data("old".utf8)) != nil)
    }

    @Test func частичныйIntentИUNKNOWNНеУдаляютсяИНеПовторяются() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        for (index, partial) in [true, false].enumerated() {
            let p = try УстановщикStop.receiptPaths(config: f.config.path,
                oldSHA: String(repeating: "a", count: 64), candidateSHA: String(repeating: String(index), count: 64))
            if partial { try Фикстура.write(Data("{".utf8), URL(fileURLWithPath: p.intent)) }
            else {
                try УстановщикStop.receipt(p.intent, ["status": "INTENT"])
                try УстановщикStop.receipt(p.outcome, ["status": "UNKNOWN"])
            }
            let before = try Data(contentsOf: URL(fileURLWithPath: p.intent))
            var effects = 0
            do { try УстановщикStop.receipt(p.intent, ["status": "INTENT"]); effects += 1 } catch { }
            #expect(effects == 0)
            #expect(try Data(contentsOf: URL(fileURLWithPath: p.intent)) == before)
        }
    }

    @Test func первоеСозданиеАтомарноИСохраняетПоявившуюсяЦель() throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let target = f.root.appendingPathComponent("current.json")
        let data = Data("first".utf8), foreign = Data("foreign".utf8)
        let r = try АтомарныеБайтыStop.создатьЕслиОтсутствует(target.path, новыми: data)
        #expect(r.данные == data)
        refused { _ = try АтомарныеБайтыStop.создатьЕслиОтсутствует(target.path, новыми: foreign) }
        #expect(try Data(contentsOf: target) == data)
        try FileManager.default.removeItem(at: target)
        var points = ТочкиАтомарнойЗаменыStop()
        points.передRename = { try Фикстура.write(foreign, target) }
        refused { _ = try АтомарныеБайтыStop.записать(target.path,
            ожидаемыйSHA256: nil, новыми: data, точки: points) }
        #expect(try Data(contentsOf: target) == foreign)
    }

    @Test(arguments: [2, 3]) func publisherCLIПроверяетСоздаётИЗаменяетПодТемЖеЗамком(_ версия: Int) throws {
        let f = try Фикстура(); defer { f.cleanup() }
        let root = f.root.path, common = root + "/git", gitDir = common + "/worktrees/synthetic"
        let w = root + "/W", ref = "refs/heads/fum/synthetic/master"
        for p in [gitDir, common + "/refs/heads/fum/synthetic", w] {
            try FileManager.default.createDirectory(atPath: p, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700])
        }
        for (path, text) in [(w + "/.git", "gitdir: \(gitDir)\n"),
            (gitDir + "/gitdir", "\(w)/.git\n"), (gitDir + "/commondir", "../..\n"),
            (gitDir + "/HEAD", "ref: \(ref)\n"), (common + "/" + ref, String(repeating: "b", count: 40) + "\n")] {
            try Фикстура.write(Data(text.utf8), URL(fileURLWithPath: path))
        }
        let current = root + "/current.json", source = String(repeating: "a", count: 40)
        let headerURL = f.root.appendingPathComponent("header.json")
        let старыйV2 = f.root.appendingPathComponent("retained-v2-current.json")
        let старыеБайты = Data("V2 retained fixture; не является новым V3 current\n".utf8)
        try Фикстура.write(старыеБайты, старыйV2)
        var header: [String: Any] = ["схема": "fum.stop-заголовок.\(версия)",
            "задача": "00000000-0000-4000-8000-000000000001", "узел": "synthetic",
            "область": "test", "поколение": "generation1", "cwd": w, "дерево": w,
            "ref": ref, "gitDir": gitDir, "commonGitDir": common, "backend": "files",
            "objectFormat": "sha1", "исходники": source, "состояние": current,
            "каталогКвитанций": root, "максимальныйВозрастСекунд": 900]
        if версия == 3 { header["состояниеV2"] = старыйV2.path }
        var headerData = try Фикстура.json(header)
        try Фикстура.write(headerData, headerURL, mode: 0o400)
        var headerSHA = АтомарныеБайтыStop.sha256(headerData)
        var snapshot: [String: Any] = ["схема": "fum.текущие-обязательства-stop.\(версия)",
            "заголовокSHA256": headerSHA, "задача": header["задача"]!, "узел": "synthetic",
            "область": "test", "поколение": "generation1",
            "управление": ["действие": "стоп", "основание": "Синтетическая проверка"]]
        let pin = try f.pin()
        let candidateURL = f.root.appendingPathComponent("candidate.json")
        let planURL = f.root.appendingPathComponent("plan.json")
        func run(_ initiallyAbsent: Bool, expected: String?, check: Bool) throws -> Int32 {
            let bytes = try Фикстура.json(snapshot)
            try Фикстура.write(bytes, candidateURL)
            var plan: [String: Any] = ["schema": "fum.stop-current-publication.1", "source": source,
                "header": ["path": headerURL.path, "bytes": headerData.count, "sha256": headerSHA, "mode": 0o400],
                "candidate": ["path": candidateURL.path, "bytes": bytes.count, "sha256": АтомарныеБайтыStop.sha256(bytes), "mode": 0o600],
                "current": ["path": current, "mode": 0o600, "maxBytes": 32768,
                    "lock": ["path": pin.path, "device": pin.device, "inode": pin.inode]],
                "initiallyAbsent": initiallyAbsent]
            if let expected { plan["expectedSHA256"] = expected }
            let data = try Фикстура.json(plan); try Фикстура.write(data, planURL)
            var argv = ["--опубликовать-текущий", "--план", planURL.path,
                "--хэш-плана", АтомарныеБайтыStop.sha256(data)]
            argv += check ? ["--проверить"] : ["--применить", АтомарныеБайтыStop.sha256(bytes)]
            return УстановщикStop.команда(argv)
        }
        #expect(try run(true, expected: nil, check: true) == 0)
        #expect(!FileManager.default.fileExists(atPath: current))
        #expect(try run(true, expected: nil, check: false) == 0)
        let first = try АтомарныеБайтыStop.прочитать(current)
        #expect(first.данные == (try Фикстура.json(snapshot)))
        #expect(try run(true, expected: nil, check: false) != 0)
        snapshot["управление"] = ["действие": "пауза", "основание": "Следующий синтетический снимок"]
        #expect(try run(false, expected: first.sha256, check: false) == 0)
        #expect(try АтомарныеБайтыStop.прочитать(current).данные == Фикстура.json(snapshot))
        #expect(try run(false, expected: first.sha256, check: false) != 0)
        let finalSHA = try АтомарныеБайтыStop.sha256(Фикстура.json(snapshot))
        try ЗамокТекущегоStop.выполнить(pin) { _ in
            let busyCode = try run(false, expected: finalSHA, check: true)
            #expect(busyCode != 0)
        }
        snapshot["схема"] = "fum.текущие-обязательства-stop.\(версия == 2 ? 3 : 2)"
        #expect(try run(false, expected: finalSHA, check: true) != 0)
        snapshot["схема"] = "fum.текущие-обязательства-stop.\(версия)"
        if версия == 3 {
            let сохранённыйCurrent = try Data(contentsOf: URL(fileURLWithPath: current))
            for вид in ["жёсткая-ссылка", "символическая-ссылка", "родитель-ссылка"] {
                let ссылка = f.root.appendingPathComponent("v2-alias-" + вид)
                if вид == "жёсткая-ссылка" {
                    try FileManager.default.linkItem(at: URL(fileURLWithPath: current), to: ссылка)
                    header["состояниеV2"] = ссылка.path
                } else if вид == "символическая-ссылка" {
                    try FileManager.default.createSymbolicLink(at: ссылка,
                        withDestinationURL: URL(fileURLWithPath: current))
                    header["состояниеV2"] = ссылка.path
                } else {
                    try FileManager.default.createSymbolicLink(at: ссылка, withDestinationURL: f.root)
                    header["состояниеV2"] = ссылка.appendingPathComponent("current.json").path
                }
                headerData = try Фикстура.json(header); headerSHA = АтомарныеБайтыStop.sha256(headerData)
                try Фикстура.write(headerData, headerURL, mode: 0o400)
                snapshot["заголовокSHA256"] = headerSHA
                let именаДо = try FileManager.default.contentsOfDirectory(atPath: root).sorted()
                #expect(try run(false, expected: finalSHA, check: true) != 0)
                #expect(try run(false, expected: finalSHA, check: false) != 0)
                #expect(try FileManager.default.contentsOfDirectory(atPath: root).sorted() == именаДо)
                #expect(try Data(contentsOf: URL(fileURLWithPath: current)) == сохранённыйCurrent)
                #expect(try Data(contentsOf: старыйV2) == старыеБайты)
                try FileManager.default.removeItem(at: ссылка)
            }
            header["состояниеV2"] = current
            headerData = try Фикстура.json(header); headerSHA = АтомарныеБайтыStop.sha256(headerData)
            try Фикстура.write(headerData, headerURL, mode: 0o400)
            snapshot["заголовокSHA256"] = headerSHA
            #expect(try run(false, expected: finalSHA, check: true) != 0)
        }
        #expect(try Data(contentsOf: старыйV2) == старыеБайты)
    }
}

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


@Suite("Файловые ссылки: общий конечный корпус", .serialized)
struct ПроверкиФайловыхСсылок {
    private struct Случай: Decodable {
        let имя: String
        let обычный: String?
        let упакованные: String?
        let типОбычного: String?
        let типУпакованного: String?
        let праваОбычного: Int?
        let праваКаталогаОбычного: Int?
        let праваУпакованного: Int?
        let увеличитьУпакованный: Int?
        let залитьУпакованныйПереносами: Int?
        let числоУпакованныхЗаписей: Int?
        let таблицыСсылок: Bool?
        let родительОбычногоСсылка: Bool?
        let результат: String?
        let источник: String?
        let изменение: String?
        let ошибка: String?
    }
    private struct Корпус: Decodable {
        let схема: String
        let ссылка: String
        let объект: String
        let другойОбъект: String
        let случаи: [Случай]
    }
    private static func сохранить(_ данные: Data, _ путь: URL, права: Int = 0o644) throws {
        try FileManager.default.createDirectory(at: путь.deletingLastPathComponent(),
            withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try данные.write(to: путь)
        try FileManager.default.setAttributes([.posixPermissions: права], ofItemAtPath: путь.path)
    }
    private static func узел(_ тип: String, данные: Data, путь: URL, права: Int) throws {
        guard тип != "нет" else { return }
        let родитель = путь.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: родитель,
            withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        switch тип {
        case "обычный": try сохранить(данные, путь, права: права)
        case "ссылка":
            let цель = родитель.appendingPathComponent("цель-" + UUID().uuidString)
            try сохранить(данные, цель)
            try FileManager.default.createSymbolicLink(at: путь, withDestinationURL: цель)
        case "оборванная-ссылка":
            try FileManager.default.createSymbolicLink(at: путь,
                withDestinationURL: родитель.appendingPathComponent("нет-цели"))
        case "каталог":
            try FileManager.default.createDirectory(at: путь, withIntermediateDirectories: false,
                attributes: [.posixPermissions: 0o700])
        case "канал":
            guard Darwin.mkfifo(путь.path, 0o600) == 0 else { throw ОтказФайловойСсылки.метаданные }
        case "жёсткая-ссылка":
            try сохранить(данные, путь)
            try FileManager.default.linkItem(at: путь,
                to: родитель.appendingPathComponent("другая-связь-" + UUID().uuidString))
        default: throw ОтказФайловойСсылки.формат
        }
    }
    private static func заменить(_ данные: Data, _ путь: URL) throws {
        let новый = путь.deletingLastPathComponent().appendingPathComponent("замена-" + UUID().uuidString)
        try сохранить(данные, новый)
        guard Darwin.rename(новый.path, путь.path) == 0 else { throw ОтказФайловойСсылки.метаданные }
    }
    @Test func общийКорпусИКонечныеПодтверждения() throws {
        let среда = ProcessInfo.processInfo.environment
        let путьКорпуса = try #require(среда["ФУМ_ВЕКТОРЫ_ССЫЛОК"])
        let ожидаемыйХэш = try #require(среда["ФУМ_ХЭШ_ВЕКТОРОВ_ССЫЛОК"])
        let родитель = URL(fileURLWithPath: try #require(среда["ФУМ_ФИКСТУРЫ_ССЫЛОК"]))
        let данные = try Data(contentsOf: URL(fileURLWithPath: путьКорпуса))
        let хэш = SHA256.hash(data: данные).map { String(format: "%02x", $0) }.joined()
        try #require(хэш == ожидаемыйХэш)
        let корпус = try JSONDecoder().decode(Корпус.self, from: данные)
        try #require(корпус.схема == "фум.векторы-файловых-ссылок.1")
        try #require(корпус.случаи.count == 54)
        var проверено = 0
        for случай in корпус.случаи {
            let корень = родитель.appendingPathComponent(UUID().uuidString.lowercased())
            let общий = корень.appendingPathComponent("общее")
            try FileManager.default.createDirectory(at: общий, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700])
            let обычный = общий.appendingPathComponent(корпус.ссылка)
            let упакованный = общий.appendingPathComponent("packed-refs")
            let привязка = корень.appendingPathComponent("HEAD")
            let исходнаяПривязка = Data(("ref: " + корпус.ссылка + "\n").utf8)
            try Self.сохранить(исходнаяПривязка, привязка)
            let указательДерева = корень.appendingPathComponent(".git")
            let обратнаяСсылка = корень.appendingPathComponent("gitdir")
            let общийУказатель = корень.appendingPathComponent("commondir")
            for путь in [указательДерева, обратнаяСсылка, общийУказатель] {
                try Self.сохранить(Data("Синтетическая привязка\n".utf8), путь)
            }
            if случай.родительОбычногоСсылка == true {
                try FileManager.default.createSymbolicLink(at: общий.appendingPathComponent("refs"),
                    withDestinationURL: корень.appendingPathComponent("нет-каталога"))
            }
            try Self.узел(случай.типОбычного ?? (случай.обычный == nil ? "нет" : "обычный"),
                данные: Data((случай.обычный ?? "").utf8), путь: обычный, права: случай.праваОбычного ?? 0o644)
            var данныеУпакованного = Data((случай.упакованные ?? "").utf8)
            if let размер = случай.увеличитьУпакованный {
                try #require(размер == ЧитательФайловойСсылки.пределУпакованных + 1)
                данныеУпакованного = Data(repeating: 48, count: размер)
            }
            if let размер = случай.залитьУпакованныйПереносами {
                try #require(размер == ЧитательФайловойСсылки.пределУпакованных)
                данныеУпакованного = Data(repeating: 10, count: размер)
            }
            if let записей = случай.числоУпакованныхЗаписей {
                try #require(записей == 16_385)
                for номер in 1..<записей {
                    данныеУпакованного.append(Data((корпус.объект + " refs/x" + String(номер) + "\n").utf8))
                }
                try #require(данныеУпакованного.count <= ЧитательФайловойСсылки.пределУпакованных)
            }
            try Self.узел(случай.типУпакованного ?? (случай.упакованные == nil ? "нет" : "обычный"),
                данные: данныеУпакованного, путь: упакованный, права: случай.праваУпакованного ?? 0o644)
            if случай.таблицыСсылок == true {
                try FileManager.default.createDirectory(at: общий.appendingPathComponent("reftable"),
                    withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            }
            if let праваКаталога = случай.праваКаталогаОбычного {
                let каталог = обычный.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: каталог, withIntermediateDirectories: true,
                    attributes: [.posixPermissions: 0o700])
                try FileManager.default.setAttributes([.posixPermissions: праваКаталога], ofItemAtPath: каталог.path)
            }
            var наблюдаемаяОшибка: String?
            do {
                let снимок = try ЧитательФайловойСсылки.прочитать(общийКаталог: общий.path,
                    ссылка: корпус.ссылка, связанныеФайлы: [привязка.path, указательДерева.path, обратнаяСсылка.path, общийУказатель.path])
                #expect(снимок.идентификаторОбъекта == случай.результат)
                #expect(снимок.источник.rawValue == случай.источник)
                if let изменение = случай.изменение {
                    switch изменение {
                    case "создать-обычный": try Self.сохранить(Data((корпус.объект + "\n").utf8), обычный)
                    case "создать-другой-обычный": try Self.сохранить(Data((корпус.другойОбъект + "\n").utf8), обычный)
                    case "изменить-обычный": try Self.сохранить(Data((корпус.другойОбъект + "\n").utf8), обычный)
                    case "изменить-упакованный":
                        try Self.сохранить(данныеУпакованного + Data((корпус.другойОбъект + " refs/tags/новая\n").utf8), упакованный)
                    case "заменить-упакованный": try Self.заменить(данныеУпакованного, упакованный)
                    case "изменить-привязку": try Self.сохранить(Data("ref: refs/heads/другая\n".utf8), привязка)
                    case "заменить-привязку": try Self.заменить(исходнаяПривязка, привязка)
                    case "изменить-указатель-дерева": try Self.сохранить(Data("Другая привязка\n".utf8), указательДерева)
                    case "изменить-обратную-ссылку": try Self.сохранить(Data("Другая привязка\n".utf8), обратнаяСсылка)
                    case "изменить-общий-указатель": try Self.сохранить(Data("Другая привязка\n".utf8), общийУказатель)
                    case "создать-каталог-ссылок":
                        try FileManager.default.createDirectory(at: общий.appendingPathComponent("refs"),
                            withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
                    default: throw ОтказФайловойСсылки.формат
                    }
                }
                try снимок.подтвердить()
            } catch let отказ as ОтказФайловойСсылки {
                наблюдаемаяОшибка = отказ.rawValue
            } catch {
                Issue.record("Непредусмотренная ошибка случая \(случай.имя): \(error)")
            }
            if наблюдаемаяОшибка != случай.ошибка {
                Issue.record("Случай \(случай.имя): получено \(наблюдаемаяОшибка ?? "успех"), ожидалось \(случай.ошибка ?? "успех")")
            }
            #expect(наблюдаемаяОшибка == случай.ошибка)
            проверено += 1
        }
        #expect(проверено == 54)
    }
}


import Foundation
import Darwin
import Testing
import УстановкаStop

private enum СбойПослеRenameV4: Error { case намеренный }
struct ПроверкиАтомарнойГраницыV4 {
    @Test func послеRenameНеСохраняетсяСтароеНаблюдение() throws {
        let родитель = try #require(ProcessInfo.processInfo.environment["ФУМ_СВИДЕТЕЛЬСТВА_ЯКОРЯ"])
        var сведения = stat()
        #expect(lstat(родитель, &сведения) == 0)
        #expect(сведения.st_mode & S_IFMT == S_IFDIR)
        #expect(сведения.st_mode & 0o7777 == 0o700 && сведения.st_uid == geteuid())
        let корень = родитель + "/atomic-" + UUID().uuidString.lowercased()
        try #require(mkdir(корень, 0o700) == 0)
        let путь = корень + "/pointer.json"
        let старые = Data("retained-before-rename\n".utf8)
        let новые = Data("retained-after-rename\n".utf8)
        _ = try АтомарныеБайтыStop.создатьЕслиОтсутствует(путь, новыми: старые)
        var удержанный: Int32 = -1
        defer { if удержанный >= 0 { _ = Darwin.close(удержанный) } }
        var отказ: ОтказАтомарнойЗаменыStop?
        do {
            _ = try АтомарныеБайтыStop.заменитьУказательV4(путь,
                ожидаемыйSHA256: АтомарныеБайтыStop.sha256(старые), новыми: новые,
                проверить: {}, отметить: { фаза in
                    if фаза == "после-rename" {
                        удержанный = open(путь, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
                        try #require(удержанный >= 0)
                        try #require(fchmod(удержанный, 0) == 0)
                        throw СбойПослеRenameV4.намеренный
                    }
                })
            Issue.record("После намеренного отказа не должен возвращаться успех")
        } catch let ошибка as ОтказАтомарнойЗаменыStop { отказ = ошибка }
        let известный = try #require(отказ)
        #expect(известный.граница == .послеRename)
        #expect(известный.наблюдаемыйSHA256 == nil)
        #expect(известный.оставленныйВременныйФайл == nil)
        try #require(удержанный >= 0)
        var буфер = [UInt8](repeating: 0, count: новые.count + 1)
        let число = буфер.withUnsafeMutableBytes { Darwin.read(удержанный, $0.baseAddress, $0.count) }
        #expect(число == новые.count)
        #expect(Data(буфер.prefix(число >= 0 ? число : 0)) == новые)
        var поИмени = stat(), поFD = stat()
        try #require(lstat(путь, &поИмени) == 0 && fstat(удержанный, &поFD) == 0)
        #expect(поИмени.st_ino == поFD.st_ino && поИмени.st_dev == поFD.st_dev)
        #expect(поИмени.st_mode & 0o7777 == 0)
        #expect(try FileManager.default.contentsOfDirectory(atPath: корень) == ["pointer.json"])
        // Режим 000 и новые байты сохраняются как свидетельство, без восстановления или удаления.
    }
}
