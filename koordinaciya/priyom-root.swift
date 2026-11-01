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
    let принятоеM: String?
    let основаниеИсходниковSHA256: String?
    let разрешённыйЭффект: String?
    let ожидаемыйУдалённыйOID: String?

    init(схема: String, идентификатор: String, ROOT: String, писатель: String, W: String,
         ref: String, origin: String, L: String, M: String, дерево: String,
         пути: [String], pins: [PinПриёмаROOT], принятоеM: String? = nil,
         основаниеИсходниковSHA256: String? = nil, разрешённыйЭффект: String? = nil,
         ожидаемыйУдалённыйOID: String? = nil) {
        self.схема = схема; self.идентификатор = идентификатор; self.ROOT = ROOT
        self.писатель = писатель; self.W = W; self.ref = ref; self.origin = origin
        self.L = L; self.M = M; self.дерево = дерево; self.пути = пути; self.pins = pins
        self.принятоеM = принятоеM; self.основаниеИсходниковSHA256 = основаниеИсходниковSHA256
        self.разрешённыйЭффект = разрешённыйЭффект; self.ожидаемыйУдалённыйOID = ожидаемыйУдалённыйOID
    }

    var намерение: НамерениеСозданияКоммитаGit {
        НамерениеСозданияКоммитаGit(вид: .слияние, реф: ref, родители: [L, M], дерево: дерево)
    }
}
struct СредаПриёмаROOT {
    let metadataCLI: String
    let metadataState: String
    let программа: String
    let переменные: [String: String]
    let segment: URL
    let logs: URL
}
// Не Codable: ROOT передаёт этот managed host и выбранные M/scope отдельно от candidate JSON.
// Это транспорт существующего допуска .3, не второй reader, generator или Git executor.
struct УправляемыйИсточникСохраняющегоПриёмаROOT {
    let принятоеM: String
    let основаниеSHA256: String
    let пути: [String]
    let ожидаемыйУдалённыйOID: String
    let контекст: КонтекстУправляемогоДопуска

    func проверить(_ поручение: ПоручениеПриёмаROOT, среда: СредаПриёмаROOT) throws {
        guard let запрос = контекст.запрос, let решение = контекст.решение else {
            throw ОшибкаПриёмаROOT.отказ("source-managed-host-missing")
        }
        try требоватьПриём(поручение.схема == "fum.root-acceptance-program.2" &&
            поручение.принятоеM == принятоеM && OIDКоммитаGit(oid: принятоеM) != nil &&
            поручение.основаниеИсходниковSHA256 == основаниеSHA256 &&
            ПолитикаУправляемогоДопуска.хэшВерный(основаниеSHA256) &&
            поручение.разрешённыйЭффект == "сохранение-исходников-слиянием" && поручение.пути == пути &&
            поручение.ожидаемыйУдалённыйOID == ожидаемыйУдалённыйOID &&
            (ожидаемыйУдалённыйOID == "ABSENT" || OIDКоммитаGit(oid: ожидаемыйУдалённыйOID) != nil),
            "source-host-M-grant-scope-effect")
        try требоватьПриём(запрос.корневойUUID == поручение.ROOT && запрос.писатель == поручение.писатель &&
            запрос.профиль == .исходники && запрос.операция == .исходники &&
            запрос.аргументы == ["--сгенерировать-метаданные-коммита", среда.metadataState, "--исходники-UNKNOWN"],
            "source-managed-host-address")
        try ПолитикаУправляемогоДопуска.проверить(запрос, решение, операция: .исходники)
        try контекст.подтвердитьПовторноеИспользование(запрос, решение)
    }

    func подготовить(_ поручение: ПоручениеПриёмаROOT, среда: СредаПриёмаROOT) throws -> МетаданныеИсходников {
        try проверить(поручение, среда: среда)
        guard let запрос = контекст.запрос, let решение = контекст.решение else {
            throw ОшибкаПриёмаROOT.отказ("source-managed-host-missing")
        }
        let байты = try ГлавнаяКоординатора.обработатьУправляемуюВетвь(запрос.аргументы,
            запросДопуска: запрос, решениеХоста: решение, швы: контекст.швы,
            подготовленныйКонтекст: контекст)
        let метаданные = try JSONDecoder().decode(МетаданныеИсходников.self, from: байты)
        try проверитьСохранённые(метаданные, поручение: поручение)
        return метаданные
    }

    func проверитьСохранённые(_ метаданные: МетаданныеИсходников, поручение: ПоручениеПриёмаROOT) throws {
        let вход = метаданные.запрос
        guard let запрос = контекст.запрос, запрос.аргументы.count == 3 else {
            throw ОшибкаПриёмаROOT.отказ("source-saved-input-missing")
        }
        let закреплённыйВход = try JSONDecoder().decode(ЗапросМетаданныхИсходников.self,
            from: контекст.прочитать(запрос.аргументы[1], роль: .запрос))
        try требоватьПриём(вход == закреплённыйВход, "source-saved-exact-input")
        let повтор = МетаданныеИсходников.подготовить(запрос: вход, выход: метаданные.выход,
            авторGit: "\(метаданные.автор.имя) <\(метаданные.автор.почта)> 0 +0000",
            коммитерGit: "\(метаданные.коммитер.имя) <\(метаданные.коммитер.почта)> 0 +0000")
        try требоватьПриём(повтор == метаданные && повтор.ошибки.isEmpty, "source-saved-metadata-integrity")
        try требоватьПриём(метаданные.схема == "fum.source-checkpoint-metadata.1" && метаданные.ошибки.isEmpty &&
            вход.проверить().isEmpty && вход.проверитьВыход(метаданные.выход).isEmpty &&
            вход.корневойUUID == поручение.ROOT && вход.писатель == поручение.писатель && вход.рабочееДерево == поручение.W &&
            вход.реф == поручение.ref && вход.родитель == поручение.L && вход.дерево == поручение.дерево &&
            вход.основаниеSHA256 == основаниеSHA256, "source-metadata-exact-intent")
    }
}

private struct СохранённыеМетаданныеИсходниковROOT: Codable {
    let контекст: String
    let значение: МетаданныеИсходников
}

private enum МетаданныеИсполненияПриёмаROOT {
    case подтверждённые(РезультатГенерацииМетаданныхКоммита, [String: String])
    case исходники(МетаданныеИсходников)

    var сообщение: String {
        switch self {
        case let .подтверждённые(значение, _): return значение.сообщение
        case let .исходники(значение): return значение.выход.message
        }
    }
    var окружение: [String: String] {
        switch self {
        case let .подтверждённые(_, переменные): return переменные
        case let .исходники(значение): return значение.выход.environment
        }
    }
    func идентичностиВерны(автор: String, коммитер: String) -> Bool {
        let ожидаемыйАвтор: ИдентификаторGit, ожидаемыйКоммитер: ИдентификаторGit
        switch self {
        case let .подтверждённые(значение, _): ожидаемыйАвтор = значение.автор; ожидаемыйКоммитер = значение.коммитер
        case let .исходники(значение): ожидаемыйАвтор = значение.автор; ожидаемыйКоммитер = значение.коммитер
        }
        return ГенераторМетаданныхКоммита.разобратьGitIdent(автор) == ожидаемыйАвтор &&
            ГенераторМетаданныхКоммита.разобратьGitIdent(коммитер) == ожидаемыйКоммитер
    }
}

// Не Decodable: предложенный JSON не может восстановить полномочие host.
struct ПодготовленныйКонтекстПриёмаROOT {
    let поручение: ПоручениеПриёмаROOT
    let хэш: String
    let среда: СредаПриёмаROOT
    let окружение: [String: String]
    let native: () -> String
    let stop: () -> Bool
    let revoked: () -> Bool
    let источники: УправляемыйИсточникСохраняющегоПриёмаROOT?

    static func подготовить(поручение: URL, ожидаемыйSHA256: String, среда: СредаПриёмаROOT,
        native: @escaping () -> String, stop: @escaping () -> Bool = { false },
        revoked: @escaping () -> Bool = { false },
        источники: УправляемыйИсточникСохраняющегоПриёмаROOT? = nil) throws -> Self {
        try создать(поручение, ожидаемыйSHA256, среда, native, stop, revoked, источники, fixture: false)
    }
    #if TESTING
    static func дляЛокальнойФикстуры(поручение: URL, ожидаемыйSHA256: String, среда: СредаПриёмаROOT,
        native: @escaping () -> String, stop: @escaping () -> Bool = { false },
        revoked: @escaping () -> Bool = { false },
        источники: УправляемыйИсточникСохраняющегоПриёмаROOT? = nil) throws -> Self {
        try создать(поручение, ожидаемыйSHA256, среда, native, stop, revoked, источники, fixture: true)
    }
    #endif
    private static func создать(_ file: URL, _ expected: String, _ env: СредаПриёмаROOT,
        _ native: @escaping () -> String, _ stop: @escaping () -> Bool,
        _ revoked: @escaping () -> Bool, _ источники: УправляемыйИсточникСохраняющегоПриёмаROOT?, fixture: Bool) throws -> Self {
        let bytes = try Data(contentsOf: file)
        try требоватьПриём(хэшПриёмаROOT(bytes) == expected, "поручение-SHA")
        let p = try JSONDecoder().decode(ПоручениеПриёмаROOT.self, from: bytes)
        try требоватьПриём(p.схема == (источники == nil ? "fum.root-acceptance-program.1" : "fum.root-acceptance-program.2") && UUID(uuidString: p.ROOT) != nil &&
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
        try требоватьПриём(p.намерение.проверить().isEmpty, "typed-commit-intent")
        if источники == nil {
            try требоватьПриём(p.принятоеM == nil && p.основаниеИсходниковSHA256 == nil &&
                p.разрешённыйЭффект == nil && p.ожидаемыйУдалённыйOID == nil, "legacy-not-source-mode")
        }
        if let источники { try источники.проверить(p, среда: env) }
        let files = (источники == nil ? [env.metadataCLI] : []) + [env.metadataState, env.программа, env.переменные[keys[0]]!, env.переменные[keys[1]]!]
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
        var isolated = АдаптерВыполненияКомандGit.окружениеИзолированногоGit()
        // Вход не переопределяет PATH/GIT_*; FUMA/runtime параметры выбирает host.
        for (k,v) in env.переменные where k.hasPrefix("KOORDINACIYA_FUMA_") || k == "FUM_RUNTIME_ROOT" || k == "FUM_MEMORY_ROOT" { isolated[k] = v }
        return Self(поручение: p, хэш: expected, среда: env, окружение: isolated, native: native, stop: stop, revoked: revoked, источники: источники)
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
    private var metadata: МетаданныеИсполненияПриёмаROOT? = nil
    #if TESTING
    enum Failpoint { case ответCommit, ответPush, raw, intent }
    var failpoint: Failpoint? = nil
    var послеMerge: (() -> Void)? = nil
    #endif

    init(_ context: ПодготовленныйКонтекстПриёмаROOT, операции: ФайловыеОперации = .системные) throws {
        c = context
        segment = try Сегмент(кореньДанных: c.среда.segment, запись: true, операции: операции)
        do {
            try проверитьPins()
            let сохранённые = segment.записи.filter { $0.описание.тип == "приём-исходников-метаданные" }
            try требоватьПриём(сохранённые.count <= 1 && (сохранённые.isEmpty || c.источники != nil), "source-metadata-record-count")
            if let запись = сохранённые.first, let источник = c.источники {
                try требоватьПриём(запись.описание.идентификатор == c.поручение.идентификатор + "-metadata" &&
                    запись.описание.спецификация == Data(c.хэш.utf8), "source-metadata-record-context")
                let сохранённыеМетаданные = try JSONDecoder().decode(СохранённыеМетаданныеИсходниковROOT.self,
                    from: segment.извлечь(запись.описание.идентификатор))
                try требоватьПриём(сохранённыеМетаданные.контекст == c.хэш, "source-metadata-context")
                try источник.проверитьСохранённые(сохранённыеМетаданные.значение, поручение: c.поручение)
                metadata = .исходники(сохранённыеМетаданные.значение)
            }
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
            let r = try segment.добавить(ОписаниеНаблюдения(идентификатор: c.поручение.идентификатор + "-" + String(записи.count), тип: "root-acceptance", источник: "FUMA", спецификация: Data(c.хэш.utf8)), данные: байтыПриёмаROOT(e))
            записи.append(e); хвост = r.хэш
            if kind == "intent" { pending = e } else { pending = nil; фаза = next }
        } catch { закрыть(); throw ОшибкаПриёмаROOT.неизвестно("Segment append; close/reopen/readback") }
    }
    private func процесс(_ executable: String, _ args: [String], input: Data? = nil, author: [String: String] = [:]) throws -> (Int32, Data, Bool) {
        let dir = c.среда.logs.appendingPathComponent(UUID().uuidString.lowercased())
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        let out = dir.appendingPathComponent("stdout"), err = dir.appendingPathComponent("stderr")
        try Data().write(to: out, options: .withoutOverwriting); try Data().write(to: err, options: .withoutOverwriting)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: out.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: err.path)
        let oh = try FileHandle(forWritingTo: out), eh = try FileHandle(forWritingTo: err)
        defer { try? oh.close(); try? eh.close() }
        let p = Process(); p.executableURL = URL(fileURLWithPath: executable); p.arguments = args
        p.currentDirectoryURL = URL(fileURLWithPath: c.поручение.W); p.environment = c.окружение.merging(author) { _, b in b }
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
        return (p.terminationStatus, bytes, p.terminationReason == .uncaughtSignal)
    }
    private func git(_ args: [String], input: Data? = nil, author: [String: String] = [:],
                     известныйНеуспех: ((Int32) -> Void)? = nil) throws -> Data {
        let r = try процесс("/usr/bin/git", ["-c", "core.fsmonitor=false", "-C", c.поручение.W] + args, input: input, author: author)
        if r.0 != 0 && !r.2 { известныйНеуспех?(r.0) }
        try требоватьПриём(r.0 == 0, "git-exit-" + String(r.0)); return r.1
    }
    private func строка(_ args: [String]) throws -> String { String(decoding: try git(args), as: UTF8.self).trimmingCharacters(in: .newlines) }
    private func проверитьPins() throws {
        try требоватьПриём(c.native() == c.поручение.писатель, "custody-changed")
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
            try требоватьПриём(try строка(["rev-parse", "MERGE_HEAD"]) == c.поручение.M && строка(["write-tree"]) == c.поручение.дерево, "commit-index")
            let сыройСостав = try git(НаблюдательРабочегоДереваGit.аргументыСырогоСостава(основа: head, индекс: true))
            let строки = try НаблюдательРабочегоДереваGit.разобратьСыройСостав(сыройСостав)
            try требоватьПриём(строки.allSatisfy { c.поручение.пути.contains($0.путь) }, "commit-exact-scope")
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
    private func метаданные() throws -> МетаданныеИсполненияПриёмаROOT {
        if let metadata { return metadata }
        if let источник = c.источники {
            let подготовленные = try источник.подготовить(c.поручение, среда: c.среда)
            do {
                _ = try segment.добавить(ОписаниеНаблюдения(
                    идентификатор: c.поручение.идентификатор + "-metadata",
                    тип: "приём-исходников-метаданные", источник: "управляемый-хост",
                    спецификация: Data(c.хэш.utf8)),
                    данные: байтыПриёмаROOT(СохранённыеМетаданныеИсходниковROOT(контекст: c.хэш, значение: подготовленные)))
            } catch {
                закрыть()
                throw ОшибкаПриёмаROOT.неизвестно("source metadata append; reopen/readback, no generator replay")
            }
            let значение = МетаданныеИсполненияПриёмаROOT.исходники(подготовленные)
            metadata = значение; return значение
        }
        let r = try процесс(c.среда.metadataCLI, ["--сгенерировать-метаданные-коммита", c.среда.metadataState])
        let obj = try JSONSerialization.jsonObject(with: r.1) as? [String: Any]
        try требоватьПриём(r.0 == 0 && obj?["готово"] as? Bool == true && obj?["метаданные"] is [String: Any], "metadata-prepare")
        let typed = try JSONDecoder().decode(РезультатГенерацииМетаданныхКоммита.self, from: JSONSerialization.data(withJSONObject: obj!["метаданные"]!))
        try требоватьПриём(typed.выборМодели.rootUUID == c.поручение.ROOT && typed.выборМодели.sessionIdentity.значение == c.поручение.писатель && typed.ошибки.isEmpty, "metadata-host-binding")
        guard let окружениеАвтора = obj?["переменныеОкруженияКИзменению"] as? [String: String], окружениеАвтора == typed.окружение else {
            throw ОшибкаПриёмаROOT.отказ("metadata-environment-binding")
        }
        let значение = МетаданныеИсполненияПриёмаROOT.подтверждённые(typed, окружениеАвтора)
        metadata = значение; return значение
    }
    private func raw(_ oid: String) throws {
        if c.источники != nil {
            let значение = try метаданные()
            guard case let .исходники(исходники) = значение else { throw ОшибкаПриёмаROOT.отказ("source-metadata-mode") }
            let байты = try git(["cat-file", "commit", oid])
            let вычисленныйOID = String(decoding: try git(["hash-object", "-t", "commit", "--stdin"], input: байты),
                as: UTF8.self).trimmingCharacters(in: .newlines)
            try требоватьПриём(вычисленныйOID == oid &&
                ОценщикИдентичностиGit.проверитьСырыеИсходники(байты, метаданные: исходники,
                    намерение: c.поручение.намерение).isEmpty, "source-raw-intent-FAIL")
            return
        }
        let expected: [String: Any] = ["schema": "fum.raw-merge-commit-expectation.1", "expectedParents": [c.поручение.L, c.поручение.M], "expectedTree": c.поручение.дерево]
        var value = expected
        #if TESTING
        if failpoint == .raw { value["expectedTree"] = String(repeating: "0", count: 40) }
        #endif
        let file = c.среда.logs.appendingPathComponent(UUID().uuidString + ".json")
        try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]).write(to: file, options: .withoutOverwriting)
        let bytes = try git(["cat-file", "commit", oid])
        let hashed = String(decoding: try git(["hash-object", "-t", "commit", "--stdin"], input: bytes), as: UTF8.self).trimmingCharacters(in: .newlines)
        try требоватьПриём(hashed == oid, "raw-OID")
        let r = try процесс(c.среда.metadataCLI, ["--проверить-сырой-merge-коммит", c.среда.metadataState, file.path], input: bytes)
        try требоватьПриём(r.0 == 0, "raw-FAIL")
    }
    private func remote() throws -> String {
        let rows = try строка(["ls-remote", "--exit-code", "--refs", "origin", c.поручение.ref]).split(separator: "\n")
        try требоватьПриём(rows.count == 1, "remote-count")
        let columns = rows[0].split(separator: "\t")
        try требоватьПриём(columns.count == 2 && columns[1] == c.поручение.ref, "remote-ref")
        return String(columns[0])
    }
    private func сверитьУдалённоеОжидание() throws {
        let байты = try git(["ls-remote", "--refs", "origin", c.поручение.ref])
        let строки = String(decoding: байты, as: UTF8.self).split(separator: "\n")
        let ожидаемое = c.источники?.ожидаемыйУдалённыйOID ?? c.поручение.L
        if ожидаемое == "ABSENT" { try требоватьПриём(строки.isEmpty, "expected-absent-remote"); return }
        try требоватьПриём(строки.count == 1, "expected-old-remote-count")
        let поля = строки[0].split(separator: "\t")
        try требоватьПриём(поля.count == 2 && поля[0] == ожидаемое && поля[1] == c.поручение.ref,
            "expected-old-remote-OID-ref")
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
            if p.стадия == "prepare" && c.источники != nil && metadata != nil {
                try сохранить("outcome", "prepare", p.следующая)
            } else if p.стадия == "merge" {
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
        var слияниеИзвестноВыполнено = false
        var слияниеИзвестноОтклонено = false
        var коммитНачат = false
        do {
            switch s.действие {
            case "prepare": _ = try метаданные()
            case "exact":
                try требоватьПриём(try строка(["rev-parse", "HEAD"]) == c.поручение.L && git(["status", "--porcelain=v1", "-z"]).isEmpty, "initial-index-or-HEAD")
                let base = try строка(["merge-base", c.поручение.L, c.поручение.M])
                let сыройСостав = try git(НаблюдательРабочегоДереваGit.аргументыСырогоСостава(основа: base, цель: c.поручение.M))
                let пути = try НаблюдательРабочегоДереваGit.разобратьСыройСостав(сыройСостав).map(\.путь).sorted()
                if let источник = c.источники {
                    _ = try git(["merge-base", "--is-ancestor", источник.принятоеM, c.поручение.L])
                }
                try требоватьПриём(пути == c.поручение.пути.sorted(), "exact-source")
            case "merge":
                try требоватьПриём(try строка(["rev-parse", "HEAD"]) == c.поручение.L && git(["status", "--porcelain=v1", "-z"]).isEmpty, "merge-custody")
                let m = try метаданные()
                let message = Data(m.сообщение.utf8)
                let file = c.среда.logs.appendingPathComponent(UUID().uuidString + ".message")
                let checked = try ПотребительБайтСообщенияFUMA.подготовить(фактическиеБайтыFUMA: message, вФайл: file)
                try передЭффектом(c.поручение.L)
                _ = try git(["-c", "submodule.recurse=false", "merge", "--no-commit", "--no-ff", c.поручение.M],
                    известныйНеуспех: { _ in слияниеИзвестноОтклонено = true })
                слияниеИзвестноВыполнено = true
                #if TESTING
                послеMerge?()
                #endif
                try требоватьПриём(try строка(["rev-parse", "MERGE_HEAD"]) == c.поручение.M && строка(["write-tree"]) == c.поручение.дерево, "merge-index")
                _ = try ПотребительБайтСообщенияFUMA.выполнитьПередGitЭффектом(исходныеБайтыFUMA: message, подготовленныеБайты: checked) {
                    try передЭффектом(c.поручение.L, merged: true)
                    try требоватьПриём(try Data(contentsOf: file) == message, "message-file-changed")
                    let фактическийАвтор = String(decoding: try git(["var", "GIT_AUTHOR_IDENT"], author: m.окружение),
                        as: UTF8.self).trimmingCharacters(in: .newlines)
                    let фактическийКоммитер = try строка(["var", "GIT_COMMITTER_IDENT"])
                    try требоватьПриём(m.идентичностиВерны(автор: фактическийАвтор, коммитер: фактическийКоммитер), "commit-git-var-identity")
                    коммитНачат = true
                    return try git(["commit", "--no-gpg-sign", "--cleanup=verbatim", "-F", file.path], author: m.окружение)
                }
                commit = try строка(["rev-parse", "HEAD"])
                #if TESTING
                if failpoint == .ответCommit { throw ОшибкаПриёмаROOT.неизвестно("simulated lost commit response") }
                #endif
            case "raw": try raw(известныйCommit())
            case "push":
                let head = try известныйCommit(); try raw(head)
                try требоватьПриём(ПроверкаНастроекPushGit.ошибки(настройки: настройкиPush(), ожидаемыйАдресPush: АдресНазначенияPushGit(адрес: c.поручение.origin)!).isEmpty, "push-config")
                try передЭффектом(head)
                try сверитьУдалённоеОжидание()
                _ = try git(["-c", "remote.origin.mirror=false", "-c", "push.followTags=false", "-c", "push.recurseSubmodules=no", "-c", "push.gpgSign=false", "push", "--no-mirror", "--no-follow-tags", "--recurse-submodules=no", "--no-set-upstream", "--no-signed", "origin", head + ":" + c.поручение.ref])
                #if TESTING
                if failpoint == .ответPush { throw ОшибкаПриёмаROOT.неизвестно("simulated lost push response") }
                #endif
            case "readback":
                let head = try известныйCommit(); try raw(head); try требоватьПриём(try remote() == head, "remote-mismatch")
            default: throw ОшибкаПриёмаROOT.отказ("unknown-action")
            }
        } catch {
            if s.действие == "merge" && (слияниеИзвестноВыполнено || слияниеИзвестноОтклонено) && !коммитНачат {
                // Индекс сохраняется. Commit точно не запускался; нового ordinary checkpoint нет.
                try сохранить("outcome", s.действие, "held")
                throw ОшибкаПриёмаROOT.отказ("known-conflict-before-commit: " + String(describing: error))
            }
            if s.действие == "merge" || s.действие == "push" { throw ОшибкаПриёмаROOT.неизвестно("effect requires readback: " + String(describing: error)) }
            try сохранить("outcome", s.действие, "held"); throw error
        }
        try сохранить("outcome", s.действие, s.следующая)
        return ИсходПриёмаROOT(стадия: фаза, commit: commit, повтор: false)
    }
}
