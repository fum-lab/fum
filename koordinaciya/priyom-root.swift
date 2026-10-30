import CryptoKit
import Foundation
import Darwin
import КонтейнерНаблюдений

// Программа определяет порядок; этот мост исполняет только конечный набор эффектов.
// Доверенный host выбирает поручение/контекст отдельно от stdin и checkpoint.
enum ОшибкаПриёмаROOT: Error { case отказ(String), неизвестно(String) }
func хэшПриёмаROOT(_ bytes: Data) -> String { SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined() }
func байтыПриёмаROOT<T: Encodable>(_ value: T) throws -> Data {
    let e = JSONEncoder(); e.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]; return try e.encode(value)
}
private func требоватьПриём(_ condition: Bool, _ reason: String) throws {
    if !condition { throw ОшибкаПриёмаROOT.отказ(reason) }
}
private func физическийПутьПриёмаROOT(_ path: String) throws -> String {
    guard let p = realpath(path, nil) else { throw ОшибкаПриёмаROOT.отказ("realpath") }
    defer { free(p) }
    return String(cString: p)
}
struct PinПриёмаROOT: Codable, Sendable { let путь: String; let sha256: String }
struct ПоручениеПриёмаROOT: Codable, Sendable {
    let схема: String
    let идентификатор: String
    let ROOT: String
    let писатель: String
    let W: String
    let ref: String
    let origin: String
    let L: String
    let M: String
    let дерево: String
    let пути: [String]
    let pins: [PinПриёмаROOT]
}
struct СредаПриёмаROOT {
    let metadataCLI: String
    let metadataState: String
    let программа: String
    let переменные: [String: String]
    let segment: URL
    let logs: URL
}
// Не Decodable: предложенный JSON не может восстановить полномочие host.
struct ПодготовленныйКонтекстПриёмаROOT {
    let поручение: ПоручениеПриёмаROOT
    let хэш: String
    let среда: СредаПриёмаROOT
    let окружение: [String: String]
    let кандидатЗапуска: КандидатПодготовкиЗапускаКодекс
    let native: () -> String
    let stop: () -> Bool
    let revoked: () -> Bool

    static func подготовить(поручение: URL, ожидаемыйSHA256: String, среда: СредаПриёмаROOT,
        native: @escaping () -> String, stop: @escaping () -> Bool = { false },
        revoked: @escaping () -> Bool = { false }) throws -> Self {
        try создать(поручение, ожидаемыйSHA256, среда, native, stop, revoked, fixture: false)
    }
    #if TESTING
    static func дляЛокальнойФикстуры(поручение: URL, ожидаемыйSHA256: String, среда: СредаПриёмаROOT,
        native: @escaping () -> String, stop: @escaping () -> Bool = { false },
        revoked: @escaping () -> Bool = { false }) throws -> Self {
        try создать(поручение, ожидаемыйSHA256, среда, native, stop, revoked, fixture: true)
    }
    #endif
    private static func создать(_ file: URL, _ expected: String, _ env: СредаПриёмаROOT,
        _ native: @escaping () -> String, _ stop: @escaping () -> Bool,
        _ revoked: @escaping () -> Bool, fixture: Bool) throws -> Self {
        let bytes = try Data(contentsOf: file)
        try требоватьПриём(хэшПриёмаROOT(bytes) == expected, "поручение-SHA")
        let p = try JSONDecoder().decode(ПоручениеПриёмаROOT.self, from: bytes)
        try требоватьПриём(p.схема == "fum.root-acceptance-program.1" && UUID(uuidString: p.ROOT) != nil &&
            p.писатель == native() && (fixture || p.писатель == p.ROOT), "ROOT-custody")
        try требоватьПриём(ПутьФизическогоРабочегоДереваGit(путь: p.W) != nil && ПолныйРефGit(реф: p.ref) != nil &&
            [p.L, p.M, p.дерево].allSatisfy { OIDКоммитаGit(oid: $0) != nil } && p.L != p.M &&
            !p.идентификатор.isEmpty && p.идентификатор.utf8.allSatisfy { (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) || $0 == 45 }, "контекст")
        try требоватьПриём(fixture ? p.origin.hasPrefix("file://") : АдресУдалённогоGit(адрес: p.origin) != nil, "origin")
        try требоватьПриём(!p.пути.isEmpty && Set(p.пути).count == p.пути.count && p.пути.allSatisfy {
            !$0.hasPrefix("/") && !$0.utf8.contains(0) && !$0.split(separator: "/", omittingEmptySubsequences: false).contains(where: { $0.isEmpty || $0 == "." || $0 == ".." })
        }, "paths")
        let keys = ["KOORDINACIYA_FUMA_DEFINITION", "KOORDINACIYA_FUMA_OPERATOR", "KOORDINACIYA_FUMA_RUN_ROOT"]
        for k in keys + ["FUM_RUNTIME_ROOT", "FUM_MEMORY_ROOT"] { try требоватьПриём(!(env.переменные[k] ?? "").isEmpty, "missing-" + k) }
        let files = [env.metadataCLI, env.metadataState, env.программа, env.переменные[keys[0]]!, env.переменные[keys[1]]!]
        try требоватьПриём(Set(p.pins.map(\.путь)).count == p.pins.count, "duplicate-pin")
        for f in files { try требоватьПриём(p.pins.contains { $0.путь == f }, "missing-pin") }
        for pin in p.pins {
            let physical = try физическийПутьПриёмаROOT(pin.путь)
            let actual = хэшПриёмаROOT(try Data(contentsOf: URL(fileURLWithPath: pin.путь)))
            try требоватьПриём(physical == pin.путь && actual == pin.sha256, "pin path=" + pin.путь + " physical=" + physical + " hashMatches=" + String(actual == pin.sha256))
        }
        for dir in [env.segment, env.logs] + [keys[2], "FUM_RUNTIME_ROOT", "FUM_MEMORY_ROOT"].map({ URL(fileURLWithPath: env.переменные[$0]!) }) {
            let perms = try FileManager.default.attributesOfItem(atPath: dir.path)[.posixPermissions] as? NSNumber
            try требоватьПриём(try физическийПутьПриёмаROOT(dir.path) == dir.path && dir.path != p.W && !dir.path.hasPrefix(p.W + "/") &&
                perms != nil && perms!.intValue & 0o077 == 0, "private-directory")
        }
        let разрешённыеВходы = Set(keys + ["FUM_RUNTIME_ROOT", "FUM_MEMORY_ROOT",
            "FUM_COMMIT_PREPARATION", "FUM_COMMIT_PREPARATION_SHA256"])
        try требоватьПриём(Set(env.переменные.keys).isSubset(of: разрешённыеВходы), "unknown-runtime-input")
        guard let selector = env.переменные["FUM_COMMIT_PREPARATION"],
              let selectorSHA = env.переменные["FUM_COMMIT_PREPARATION_SHA256"] else {
            throw ОшибкаПриёмаROOT.отказ("missing-commit-preparation")
        }
        let кандидат: КандидатПодготовкиЗапускаКодекс
        do { кандидат = try ЧитательПодготовкиЗапускаКодекс.загрузить(селектор: selector, sha256: selectorSHA) }
        catch { throw ОшибкаПриёмаROOT.отказ("invalid-commit-preparation") }
        let k = кандидат.ожидаемыйКонтекст, r = кандидат.средаГенератора
        try требоватьПриём(k.идентификаторКорневойЗадачи == p.ROOT &&
            k.идентификаторЭтапа.utf8.elementsEqual(p.писатель.utf8) &&
            k.физическийКорень.utf8.elementsEqual(p.W.utf8) && k.полныйRef == p.ref &&
            k.исходныйOID == p.L && k.деревоКоммита == p.дерево && k.родители == [p.L, p.M], "preparation-host-context")
        try требоватьПриём(r.исполняемыйФайлМетаданных.путь == env.metadataCLI &&
            r.состояниеМетаданных.путь == env.metadataState, "preparation-metadata-input")
        for key in keys + ["FUM_RUNTIME_ROOT", "FUM_MEMORY_ROOT"] {
            try требоватьПриём(env.переменные[key] == кандидат.окружениеМетаданных[key], "preparation-runtime-input")
        }
        for pin in кандидат.закреплённыеФайлы {
            try требоватьПриём(p.pins.contains { $0.путь.utf8.elementsEqual(pin.путь.utf8) && $0.sha256 == pin.хэш }, "preparation-unadmitted-pin")
        }
        return Self(поручение: p, хэш: expected, среда: env,
            окружение: кандидат.окружениеМетаданных, кандидатЗапуска: кандидат,
            native: native, stop: stop, revoked: revoked)
    }
}
struct ПроцессПриёмаROOT: Codable {
    let executable: String; let argv: [String]; let cwd: String
    let exit: Int32?; let signal: Bool; let stdoutSHA256: String; let stderrSHA256: String
}
struct ИсходПриёмаROOT { let стадия: String; let commit: String?; let повтор: Bool }
private struct ЗаписьПриёмаROOT: Codable {
    let context: String; let номер: Int; let предыдущая: String?
    let вид: String; let стадия: String; let следующая: String; let commit: String?
}
private struct ШагПриёмаROOT: Decodable { let схема: String; let действие: String; let следующая: String }
private struct ОбёрткаПриёмаROOT: Decodable {
    struct Наблюдение: Decodable { struct Результат: Decodable { let тип: String; let значение: String }; let результат: Результат }
    let наблюдение: Наблюдение
}
final class ПрограммаПриёмаROOT {
    private let c: ПодготовленныйКонтекстПриёмаROOT
    private let segment: Сегмент
    private var записи: [ЗаписьПриёмаROOT] = []
    private var хвост: String? = nil
    private var фаза = "prepare"
    private var pending: ЗаписьПриёмаROOT? = nil
    private var commit: String? = nil
    private var закрыт = false
    private var metadata: [String: Any]? = nil
    #if TESTING
    enum Failpoint { case ответCommit, ответPush, raw, intent }
    var failpoint: Failpoint? = nil
    var послеMerge: (() -> Void)? = nil
    #endif

    private let наблюденияФикстуры: ((String, [String]) throws -> (Int32, Data)?)?
    private let шагФикстуры: ((String) throws -> (String, String))?

    convenience init(_ context: ПодготовленныйКонтекстПриёмаROOT, операции: ФайловыеОперации = .системные) throws {
        try self.init(context, операции: операции, наблюденияФикстуры: nil, шагФикстуры: nil)
    }
    #if TESTING
    convenience init(_ context: ПодготовленныйКонтекстПриёмаROOT,
        наблюденияФикстуры: @escaping (String, [String]) throws -> (Int32, Data)?,
        шагФикстуры: @escaping (String) throws -> (String, String)) throws {
        try self.init(context, операции: .системные, наблюденияФикстуры: наблюденияФикстуры, шагФикстуры: шагФикстуры)
    }
    func сохранитьНамерениеMergeДляФикстуры() throws {
        try сохранить("intent", "prepare", "exact")
        try сохранить("outcome", "prepare", "exact")
        try сохранить("intent", "exact", "merge")
        try сохранить("outcome", "exact", "merge")
        try сохранить("intent", "merge", "raw")
    }
    #endif
    private init(_ context: ПодготовленныйКонтекстПриёмаROOT, операции: ФайловыеОперации,
        наблюденияФикстуры: ((String, [String]) throws -> (Int32, Data)?)?,
        шагФикстуры: ((String) throws -> (String, String))?) throws {
        c = context
        self.наблюденияФикстуры = наблюденияФикстуры
        self.шагФикстуры = шагФикстуры
        segment = try Сегмент(кореньДанных: c.среда.segment, запись: true, операции: операции)
        do {
            try проверитьPins()
            for r in segment.записи where r.описание.тип == "root-acceptance" {
                let bytes = try segment.извлечь(r.описание.идентификатор)
                let e = try JSONDecoder().decode(ЗаписьПриёмаROOT.self, from: bytes)
                try требоватьПриём(e.context == c.хэш && e.номер == записи.count && e.предыдущая == хвост && записи.count < 128, "checkpoint-chain")
                if e.вид == "intent" {
                    try требоватьПриём(pending == nil && e.стадия == фаза && e.commit == commit, "intent-order")
                    let expected = try шаг(стадия: e.стадия, исторический: true)
                    try требоватьПриём(expected.действие == e.стадия && expected.следующая == e.следующая, "intent-program-transition")
                    pending = e
                }
                else {
                    try требоватьПриём(pending?.стадия == e.стадия && e.вид == "outcome", "outcome-order")
                    try требоватьПриём(e.следующая == pending?.следующая || e.следующая == "held", "outcome-program-transition")
                    if e.стадия == "merge" && e.следующая != "held" {
                        try требоватьПриём(e.commit != nil && OIDКоммитаGit(oid: e.commit!) != nil && e.commit != c.поручение.L && e.commit != c.поручение.M, "merge-C-handoff")
                    } else { try требоватьПриём(e.commit == commit, "known-C-handoff") }
                    фаза = e.следующая; pending = nil; commit = e.commit
                }
                записи.append(e); хвост = r.хэш
            }
        } catch { segment.закрыть(); throw error }
    }
    func закрыть() { segment.закрыть(); закрыт = true }
    deinit { segment.закрыть() }
    private func сохранить(_ kind: String, _ stage: String, _ next: String) throws {
        try требоватьПриём(!закрыт && записи.count < 128, "closed-or-budget")
        let e = ЗаписьПриёмаROOT(context: c.хэш, номер: записи.count, предыдущая: хвост, вид: kind, стадия: stage, следующая: next, commit: commit)
        do {
            #if TESTING
            let источникЗаписи = шагФикстуры == nil ? "FUMA" : "synthetic-policy-fixture"
            #else
            let источникЗаписи = "FUMA"
            #endif
            let r = try segment.добавить(ОписаниеНаблюдения(идентификатор: c.поручение.идентификатор + "-" + String(записи.count), тип: "root-acceptance", источник: источникЗаписи, спецификация: Data(c.хэш.utf8)), данные: байтыПриёмаROOT(e))
            записи.append(e); хвост = r.хэш
            if kind == "intent" { pending = e } else { pending = nil; фаза = next }
        } catch { закрыть(); throw ОшибкаПриёмаROOT.неизвестно("Segment append; close/reopen/readback") }
    }
    private func процесс(_ executable: String, _ args: [String], input: Data? = nil, полноеОкружение: [String: String]? = nil) throws -> (Int32, Data) {
        #if TESTING
        if let result = try наблюденияФикстуры?(executable, args) { return result }
        #endif
        let dir = c.среда.logs.appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let out = dir.appendingPathComponent("stdout"), err = dir.appendingPathComponent("stderr")
        try Data().write(to: out, options: .withoutOverwriting); try Data().write(to: err, options: .withoutOverwriting)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: out.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: err.path)
        let oh = try FileHandle(forWritingTo: out), eh = try FileHandle(forWritingTo: err)
        defer { try? oh.close(); try? eh.close() }
        let p = Process(); p.executableURL = URL(fileURLWithPath: executable); p.arguments = args
        p.currentDirectoryURL = URL(fileURLWithPath: c.поручение.W); p.environment = полноеОкружение ?? (executable == "/usr/bin/git" ? c.кандидатЗапуска.окружениеGit : c.окружение)
        p.standardOutput = oh; p.standardError = eh
        let pipe = Pipe(); p.standardInput = pipe
        var launched = false
        do { try p.run(); launched = true; if let input { try pipe.fileHandleForWriting.write(contentsOf: input) }; try pipe.fileHandleForWriting.close(); p.waitUntilExit() }
        catch {
            if p.isRunning { p.waitUntilExit() }
            let r = ПроцессПриёмаROOT(executable: executable, argv: args, cwd: c.поручение.W, exit: launched ? p.terminationStatus : nil, signal: launched && p.terminationReason == .uncaughtSignal, stdoutSHA256: хэшПриёмаROOT(try Data(contentsOf: out)), stderrSHA256: хэшПриёмаROOT(try Data(contentsOf: err)))
            try байтыПриёмаROOT(r).write(to: dir.appendingPathComponent("process.json"), options: .withoutOverwriting); throw error
        }
        try oh.synchronize(); try eh.synchronize()
        let bytes = try Data(contentsOf: out)
        let r = ПроцессПриёмаROOT(executable: executable, argv: args, cwd: c.поручение.W, exit: p.terminationStatus, signal: p.terminationReason == .uncaughtSignal, stdoutSHA256: хэшПриёмаROOT(bytes), stderrSHA256: хэшПриёмаROOT(try Data(contentsOf: err)))
        try байтыПриёмаROOT(r).write(to: dir.appendingPathComponent("process.json"), options: .withoutOverwriting)
        return (p.terminationStatus, bytes)
    }
    private func git(_ args: [String], input: Data? = nil) throws -> Data {
        let r = try процесс("/usr/bin/git", ["-c", "core.fsmonitor=false", "-C", c.поручение.W] + args, input: input)
        try требоватьПриём(r.0 == 0, "git-exit-" + String(r.0)); return r.1
    }
    private func строка(_ args: [String]) throws -> String { String(decoding: try git(args), as: UTF8.self).trimmingCharacters(in: .newlines) }
    private func проверитьPins() throws {
        try требоватьПриём(c.native() == c.поручение.писатель, "custody-changed")
        try ЧитательПодготовкиЗапускаКодекс.сверитьПины(c.кандидатЗапуска)
        for p in c.поручение.pins { try требоватьПриём(хэшПриёмаROOT(try Data(contentsOf: URL(fileURLWithPath: p.путь))) == p.sha256, "pin-changed") }
        try требоватьПриём(try строка(["rev-parse", "--show-toplevel"]) == c.поручение.W && строка(["symbolic-ref", "HEAD"]) == c.поручение.ref, "W-ref-changed")
        try требоватьПриём(try строка(["remote", "get-url", "origin"]) == c.поручение.origin, "fetch-origin-changed")
        try безПобочныхМеханизмов()
    }
    private func безПобочныхМеханизмов() throws {
        let r = try процесс("/usr/bin/git", ["-c", "core.fsmonitor=false", "-C", c.поручение.W, "config", "--includes", "--name-only", "--get-regexp", "^(merge\\..*\\.driver|filter\\..*\\.(clean|smudge|process))$"])
        try требоватьПриём(r.0 == 1 && r.1.isEmpty, "external-driver-or-filter")
        let hooks = try строка(["rev-parse", "--git-path", "hooks"])
        let root = hooks.hasPrefix("/") ? URL(fileURLWithPath: hooks) : URL(fileURLWithPath: c.поручение.W).appendingPathComponent(hooks)
        for name in ["pre-merge-commit", "pre-commit", "prepare-commit-msg", "commit-msg", "post-commit", "post-merge", "reference-transaction", "pre-push"] {
            try требоватьПриём(!FileManager.default.isExecutableFile(atPath: root.appendingPathComponent(name).path), "active-hook")
        }
    }
    private func передЭффектом(_ head: String, merged: Bool = false) throws {
        try проверитьPins()
        try требоватьПриём(!c.stop() && !c.revoked(), "STOP-or-revoked")
        try требоватьПриём(try строка(["rev-parse", "HEAD"]) == head, "exact-HEAD")
        if merged {
            try требоватьПриём(try строка(["rev-parse", "MERGE_HEAD"]) == c.поручение.M && git(["diff", "--cached", "--quiet", "--no-ext-diff", "--no-textconv", c.поручение.дерево, "--"]).isEmpty, "commit-index")
        } else { try требоватьПриём(try git(["status", "--porcelain=v1", "-z"]).isEmpty, "dirty-before-effect") }
    }
    private func известныйCommit() throws -> String {
        guard let commit else { throw ОшибкаПриёмаROOT.отказ("missing-known-C") }
        try требоватьПриём(try строка(["rev-parse", "HEAD"]) == commit, "known-C-changed")
        return commit
    }
    private func настройкиPush() throws -> НастройкиЭффектовPushGit {
        func values(_ key: String, bool: Bool = false) throws -> [String] {
            let args = ["-c", "core.fsmonitor=false", "-C", c.поручение.W, "config", "--includes", "--null"] + (bool ? ["--type=bool"] : []) + ["--get-all", key]
            let r = try процесс("/usr/bin/git", args)
            if r.0 == 1 && r.1.isEmpty { return [] }
            try требоватьПриём(r.0 == 0 && r.1.last == 0, "push-config-read")
            return String(decoding: r.1, as: UTF8.self).split(separator: "\0", omittingEmptySubsequences: false).dropLast().map(String.init)
        }
        func bools(_ key: String) throws -> [Bool] {
            let all = try values(key, bool: true)
            try требоватьПриём(all.allSatisfy { $0 == "true" || $0 == "false" }, "push-config-bool")
            return all.map { $0 == "true" }
        }
        let urls = try строка(["remote", "get-url", "--push", "--all", "origin"]).split(separator: "\n").map(String.init)
        // Только наблюдение транспорта; общий существующий validator остаётся прежним.
        return try НастройкиЭффектовPushGit(фактическиеАдресаPush: urls, mirrorЗначения: bools("remote.origin.mirror"), followTagsЗначения: bools("push.followTags"), recurseSubmodulesЗначения: values("push.recurseSubmodules"), настроенныеPushRefspecs: values("remote.origin.push"), pushOptions: values("push.pushOption"), receivePackКоманды: values("remote.origin.receivepack"), autoSetupRemoteЗначения: bools("push.autoSetupRemote"), активныйPrePushHook: false)
    }
    private func шаг(стадия: String? = nil, исторический: Bool = false) throws -> ШагПриёмаROOT {
        let stage = стадия ?? фаза
        #if TESTING
        if let шагФикстуры {
            let transition = try шагФикстуры(stage)
            return ШагПриёмаROOT(схема: "fum.root-acceptance-step.1", действие: transition.0, следующая: transition.1)
        }
        #endif
        let input: [String: Any] = ["стадия": stage, "STOP": исторический ? false : c.stop(), "отозвано": исторический ? false : c.revoked()]
        let bytes = try JSONSerialization.data(withJSONObject: input, options: [.sortedKeys])
        let file = c.среда.logs.appendingPathComponent(UUID().uuidString + ".json")
        try bytes.write(to: file, options: .withoutOverwriting)
        let journal = c.среда.logs.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: journal, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let r = try процесс(c.среда.переменные["KOORDINACIYA_FUMA_OPERATOR"]!, ["--выполнить-оператор", "--определение", c.среда.программа, "--вход", file.path, "--тип-входа", "текст", "--журнал", journal.path])
        try требоватьПриём(r.0 == 0, "FUMA-program-exit")
        let envelope = try JSONDecoder().decode(ОбёрткаПриёмаROOT.self, from: r.1)
        try требоватьПриём(envelope.наблюдение.результат.тип == "текст", "FUMA-type")
        let step = try JSONDecoder().decode(ШагПриёмаROOT.self, from: Data(envelope.наблюдение.результат.значение.utf8))
        try требоватьПриём(step.схема == "fum.root-acceptance-step.1" && [stage, "held"].contains(step.действие) &&
            ["prepare", "exact", "merge", "raw", "push", "readback", "delivered", "held"].contains(step.следующая), "FUMA-step")
        return step
    }
    private func метаданные() throws -> [String: Any] {
        if let metadata { return metadata }
        let command = c.кандидатЗапуска.командаМетаданных
        let r = try процесс(command.исполняемыйФайл, command.аргументы, полноеОкружение: command.окружение)
        let obj = try JSONSerialization.jsonObject(with: r.1) as? [String: Any]
        try требоватьПриём(r.0 == 0 && obj?["готово"] as? Bool == true && obj?["метаданные"] is [String: Any], "metadata-prepare")
        let typed = try JSONDecoder().decode(РезультатГенерацииМетаданныхКоммита.self, from: JSONSerialization.data(withJSONObject: obj!["метаданные"]!))
        try требоватьПриём(typed.выборМодели.rootUUID == c.поручение.ROOT && typed.выборМодели.sessionIdentity.значение == c.поручение.писатель && typed.ошибки.isEmpty, "metadata-host-binding")
        metadata = obj!; return obj!
    }
    private func raw(_ oid: String) throws {
        #if TESTING
        if failpoint == .raw { throw ОшибкаПриёмаROOT.отказ("injected-full-raw") }
        #endif
        let bytes = try git(["cat-file", "commit", oid])
        let receipt = try ПолнаяПроверкаСырогоКоммитаКодекс.проверить(
            байты: bytes, наблюдаемыйOID: oid, ожидание: c.кандидатЗапуска.ожиданиеСырогоКоммита)
        let expected = c.кандидатЗапуска.ожидаемыйКонтекст
        let proof: [String: Any] = ["schema": "fum.full-commit-readback.1",
            "checkedOID": oid, "rawSHA256": хэшПриёмаROOT(bytes),
            "expectedContext": try JSONSerialization.jsonObject(with: байтыПриёмаROOT(expected)),
            "authorBodyReceipt": try JSONSerialization.jsonObject(with: байтыПриёмаROOT(receipt)),
            "checker": "ПолнаяПроверкаСырогоКоммитаКодекс", "modelAuthenticated": false]
        let file = c.среда.logs.appendingPathComponent(UUID().uuidString + ".full-readback.json")
        try JSONSerialization.data(withJSONObject: proof, options: [.sortedKeys]).write(to: file, options: .withoutOverwriting)
    }
    private func remote() throws -> String {
        let rows = try строка(["ls-remote", "--exit-code", "--refs", "origin", c.поручение.ref]).split(separator: "\n")
        try требоватьПриём(rows.count == 1, "remote-count")
        let columns = rows[0].split(separator: "\t")
        try требоватьПриём(columns.count == 2 && columns[1] == c.поручение.ref, "remote-ref")
        return String(columns[0])
    }
    func выполнить() throws -> ИсходПриёмаROOT {
        try требоватьПриём(!закрыт, "closed")
        if фаза == "held" { return ИсходПриёмаROOT(стадия: фаза, commit: commit, повтор: true) }
        try проверитьPins()
        if c.stop() || c.revoked() { return ИсходПриёмаROOT(стадия: "held", commit: commit, повтор: false) }
        if фаза == "delivered" {
            let head = try известныйCommit(); try raw(head)
            try требоватьПриём(try remote() == head, "terminal-independent-readback")
            return ИсходПриёмаROOT(стадия: фаза, commit: head, повтор: true)
        }
        if let p = pending {
            // Сначала только наблюдение. Ни merge, ни commit, ни push повторно не запускаются.
            let head = try строка(["rev-parse", "HEAD"])
            if p.стадия == "merge" {
                try raw(head); commit = head; try сохранить("outcome", "merge", p.следующая)
            } else if p.стадия == "push" {
                try требоватьПриём(p.commit == commit && p.commit == head, "pending-push-exact-C")
                try raw(head); try требоватьПриём(try remote() == head, "UNKNOWN-push-readback")
                commit = head; try сохранить("outcome", "push", p.следующая)
            } else { throw ОшибкаПриёмаROOT.неизвестно("pending-" + p.стадия) }
            return ИсходПриёмаROOT(стадия: фаза, commit: commit, повтор: true)
        }
        let s = try шаг()
        if s.действие == "held" { return ИсходПриёмаROOT(стадия: "held", commit: commit, повтор: false) }
        try сохранить("intent", s.действие, s.следующая)
        #if TESTING
        if failpoint == .intent { закрыть(); throw ОшибкаПриёмаROOT.неизвестно("simulated intent acknowledgement loss") }
        #endif
        var изменяющийЗапускНачат = false
        do {
            switch s.действие {
            case "prepare": _ = try метаданные()
            case "exact":
                try требоватьПриём(try строка(["rev-parse", "HEAD"]) == c.поручение.L && git(["status", "--porcelain=v1", "-z"]).isEmpty, "initial-index-or-HEAD")
                let base = try строка(["merge-base", c.поручение.L, c.поручение.M])
                let paths = String(decoding: try git(["diff", "--name-only", "-z", base, c.поручение.M]), as: UTF8.self).split(separator: "\0").map(String.init).sorted()
                try требоватьПриём(paths == c.поручение.пути.sorted(), "exact-source")
            case "merge":
                try требоватьПриём(try строка(["rev-parse", "HEAD"]) == c.поручение.L && git(["status", "--porcelain=v1", "-z"]).isEmpty, "merge-custody")
                let m = try метаданные(), meta = m["метаданные"] as! [String: Any]
                let message = Data((meta["сообщение"] as! String).utf8)
                try требоватьПриём(message == Data(c.кандидатЗапуска.ожиданиеСырогоКоммита.путь.телоСообщенияДляПроверкиСырогоКоммита.utf8), "prepared-message-source")
                try передЭффектом(c.поручение.L)
                изменяющийЗапускНачат = true
                _ = try git(["-c", "submodule.recurse=false", "merge", "--no-commit", "--no-ff", c.поручение.M])
                #if TESTING
                послеMerge?()
                #endif
                try требоватьПриём(try строка(["rev-parse", "MERGE_HEAD"]) == c.поручение.M && git(["diff", "--cached", "--quiet", "--no-ext-diff", "--no-textconv", c.поручение.дерево, "--"]).isEmpty, "merge-index")
                let observed = try НаблюдательКонтекстаПодготовкиКодекс.прочитать(c.кандидатЗапуска, доверенныйROOT: c.поручение.ROOT, доверенныйЭтап: c.поручение.писатель) { try git($0) }
                let launch = try ФабрикаПодтверждённогоЗапускаКодекс.подтвердить(c.кандидатЗапуска, наблюдённыйКонтекст: observed)
                try передЭффектом(c.поручение.L, merged: true)
                try ЧитательПодготовкиЗапускаКодекс.сверитьПины(c.кандидатЗапуска)
                try требоватьПриём(launch.запускGit.стандартныйВвод == message, "immutable-message-bytes")
                let execution = try процесс(launch.запускGit.исполняемыйФайл, launch.запускGit.аргументы,
                    input: launch.запускGit.стандартныйВвод, полноеОкружение: launch.запускGit.окружение)
                try требоватьПриём(execution.0 == 0, "prepared-commit-exit")
                commit = try строка(["rev-parse", "HEAD"])
                #if TESTING
                if failpoint == .ответCommit { throw ОшибкаПриёмаROOT.неизвестно("simulated lost commit response") }
                #endif
            case "raw": try raw(известныйCommit())
            case "push":
                let head = try известныйCommit(); try raw(head)
                try требоватьПриём(ПроверкаНастроекPushGit.ошибки(настройки: настройкиPush(), ожидаемыйАдресPush: АдресНазначенияPushGit(адрес: c.поручение.origin)!).isEmpty, "push-config")
                try передЭффектом(head)
                _ = try git(["-c", "remote.origin.mirror=false", "-c", "push.followTags=false", "-c", "push.recurseSubmodules=no", "-c", "push.gpgSign=false", "push", "--no-mirror", "--no-follow-tags", "--recurse-submodules=no", "--no-set-upstream", "--no-signed", "origin", head + ":" + c.поручение.ref])
                #if TESTING
                if failpoint == .ответPush { throw ОшибкаПриёмаROOT.неизвестно("simulated lost push response") }
                #endif
            case "readback":
                let head = try известныйCommit(); try raw(head); try требоватьПриём(try remote() == head, "remote-mismatch")
            default: throw ОшибкаПриёмаROOT.отказ("unknown-action")
            }
        } catch {
            if (s.действие == "merge" && изменяющийЗапускНачат) || s.действие == "push" { throw ОшибкаПриёмаROOT.неизвестно("effect requires readback: " + String(describing: error)) }
            try сохранить("outcome", s.действие, "held"); throw error
        }
        try сохранить("outcome", s.действие, s.следующая)
        return ИсходПриёмаROOT(стадия: фаза, commit: commit, повтор: false)
    }
}
