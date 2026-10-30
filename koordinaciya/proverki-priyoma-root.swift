import Foundation
import Testing
import КонтейнерНаблюдений
@testable import RootAcceptance

private final class ФлагПриёма { var значение = false }
private func отказПриёма(_ f: () throws -> Void) -> Bool { do { try f(); return false } catch { return true } }
private final class ФикстураПриёмаROOT {
    let dir: URL
    let W: URL
    let remote: URL
    let grant: URL
    let ref: String
    let L: String
    let M: String
    let tree: String
    let native: String
    var среда: СредаПриёмаROOT
    static func команда(_ executable: String, _ args: [String], cwd: URL, logs: URL, env: [String: String] = [:], input: Data? = nil, полноеОкружение: [String: String]? = nil) throws -> (Int32, Data) {
        let d = logs.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let out = d.appendingPathComponent("stdout"), err = d.appendingPathComponent("stderr")
        try Data().write(to: out); try Data().write(to: err)
        let oh = try FileHandle(forWritingTo: out), eh = try FileHandle(forWritingTo: err)
        defer { try? oh.close(); try? eh.close() }
        let p = Process(); p.executableURL = URL(fileURLWithPath: executable); p.arguments = args; p.currentDirectoryURL = cwd
        p.environment = полноеОкружение ?? (АдаптерВыполненияКомандGit.окружениеИзолированногоGit().merging(env) { _, b in b })
        p.standardOutput = oh; p.standardError = eh
        let pipe = Pipe(); p.standardInput = pipe; try p.run()
        if let input { try pipe.fileHandleForWriting.write(contentsOf: input) }; try pipe.fileHandleForWriting.close(); p.waitUntilExit()
        try oh.synchronize(); try eh.synchronize()
        let b = try Data(contentsOf: out)
        try байтыПриёмаROOT(ПроцессПриёмаROOT(executable: executable, argv: args, cwd: cwd.path, exit: p.terminationStatus, signal: p.terminationReason == .uncaughtSignal, stdoutSHA256: хэшПриёмаROOT(b), stderrSHA256: хэшПриёмаROOT(try Data(contentsOf: err)))).write(to: d.appendingPathComponent("process.json"))
        return (p.terminationStatus, b)
    }
    func git(_ args: [String]) throws -> String {
        let r = try Self.команда("/usr/bin/git", ["-C", W.path] + args, cwd: dir, logs: dir.appendingPathComponent("setup"))
        guard r.0 == 0 else { throw ОшибкаПриёмаROOT.отказ("fixture git") }
        return String(decoding: r.1, as: UTF8.self).trimmingCharacters(in: .newlines)
    }
    init() throws {
        let e = ProcessInfo.processInfo.environment
        let config = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: e["ROOT_FIXTURE_CONFIG"]!))) as! [String: Any]
        dir = URL(fileURLWithPath: e["ROOT_FIXTURE_ROOT"]!).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        W = dir.appendingPathComponent("tree with spaces;")
        remote = dir.appendingPathComponent("remote.git")
        grant = dir.appendingPathComponent("grant.json")
        native = e["CODEX_THREAD_ID"]!
        ref = "refs/heads/codex/root-acceptance-" + UUID().uuidString.lowercased()
        let setup = dir.appendingPathComponent("setup")
        let bare = try Self.команда("/usr/bin/git", ["init", "--bare", remote.path], cwd: dir, logs: setup)
        let initGit = try Self.команда("/usr/bin/git", ["init", "--initial-branch", String(ref.dropFirst("refs/heads/".count)), W.path], cwd: dir, logs: setup)
        guard bare.0 == 0 && initGit.0 == 0 else { throw ОшибкаПриёмаROOT.отказ("fixture init") }
        // Инициализация полей завершается до вызова instance git.
        let working = W, fixtureDir = dir
        func g(_ args: [String]) throws -> String {
            let r = try Self.команда("/usr/bin/git", ["-C", working.path] + args, cwd: fixtureDir, logs: setup)
            guard r.0 == 0 else { throw ОшибкаПриёмаROOT.отказ("fixture setup") }
            return String(decoding: r.1, as: UTF8.self).trimmingCharacters(in: .newlines)
        }
        _ = try g(["config", "user.name", "FUM"]); _ = try g(["config", "user.email", "fum@local"])
        _ = try g(["config", "commit.gpgSign", "false"])
        try Data("base\n".utf8).write(to: W.appendingPathComponent("base.txt"))
        _ = try g(["add", "--", "base.txt"]); _ = try g(["commit", "-m", "Synthetic fixture base"])
        let base = try g(["rev-parse", "HEAD"])
        let name = "путь с пробелом;$(echo nope).txt"
        try Data("incoming\n".utf8).write(to: W.appendingPathComponent(name))
        _ = try g(["add", "--", name]); _ = try g(["commit", "-m", "Synthetic incoming source"])
        M = try g(["rev-parse", "HEAD"])
        _ = try g(["reset", "--hard", base])
        try Data("own branch\n".utf8).write(to: W.appendingPathComponent("own.txt"))
        _ = try g(["add", "--", "own.txt"]); _ = try g(["commit", "-m", "Synthetic own divergent source"])
        L = try g(["rev-parse", "HEAD"])
        tree = try g(["merge-tree", "--write-tree", L, M])
        _ = try g(["remote", "add", "origin", remote.absoluteString])
        _ = try g(["push", "origin", L + ":" + ref])
        let stateFile = dir.appendingPathComponent("metadata-state.json")
        var state = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: config["template"] as! String))) as! [String: Any]
        // Конечная fixture проецирует только поля существующего Decodable-контракта;
        // закрытые отчёты/истории не копируются в каждый metadata input.
        let fields: Set<String> = ["схема", "корневойUUID", "принятаяОснова", "собственныйСтарт", "модельУзла", "корневойWorktree", "задачи", "переходыСостояния", "поставки", "переходыАвтоматизации", "планСамообновления"]
        state = state.filter { fields.contains($0.key) }
        for key in ["задачи", "переходыСостояния", "поставки", "переходыАвтоматизации"] { state[key] = [Any]() }
        var plan = state["планСамообновления"] as! [String: Any]
        plan["источники"] = [Any]() // fixture metadata API, не общая приёмка/self-update
        var identity = plan["идентичностьСледующегоКоммита"] as! [String: Any]
        identity["родитель"] = L; plan["идентичностьСледующегоКоммита"] = identity; plan["собственныйРеф"] = ref
        state["планСамообновления"] = plan
        try JSONSerialization.data(withJSONObject: state, options: [.sortedKeys]).write(to: stateFile)
        var variables = config["environment"] as! [String: String]
        for k in ["KOORDINACIYA_FUMA_RUN_ROOT", "FUM_RUNTIME_ROOT", "FUM_MEMORY_ROOT"] {
            let p = dir.appendingPathComponent(k)
            try FileManager.default.createDirectory(at: p, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]); variables[k] = p.path
        }
        let segment = dir.appendingPathComponent("segment"), logs = dir.appendingPathComponent("processes")
        for d in [segment, logs] { try FileManager.default.createDirectory(at: d, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]) }
        среда = СредаПриёмаROOT(metadataCLI: config["metadataCLI"] as! String, metadataState: stateFile.path, программа: config["program"] as! String, переменные: variables, segment: segment, logs: logs)
        var pins = try JSONDecoder().decode([PinПриёмаROOT].self, from: JSONSerialization.data(withJSONObject: config["pins"]!))
        pins.append(PinПриёмаROOT(путь: stateFile.path, sha256: хэшПриёмаROOT(try Data(contentsOf: stateFile))))
        let p = ПоручениеПриёмаROOT(схема: "fum.root-acceptance-program.1", идентификатор: "fixture-" + UUID().uuidString, ROOT: "01a07d3d-d376-7ad2-aafc-67e4c25a67eb", писатель: native, W: W.path, ref: ref, origin: remote.absoluteString, L: L, M: M, дерево: tree, пути: [name], pins: pins)
        try байтыПриёмаROOT(p).write(to: grant)
    }
    func контекст(_ variables: [String: String]? = nil, stop: @escaping () -> Bool = { false }, revoked: @escaping () -> Bool = { false }, actor: String? = nil) throws -> ПодготовленныйКонтекстПриёмаROOT {
        let s = СредаПриёмаROOT(metadataCLI: среда.metadataCLI, metadataState: среда.metadataState, программа: среда.программа, переменные: variables ?? среда.переменные, segment: среда.segment, logs: среда.logs)
        return try .дляЛокальнойФикстуры(поручение: grant, ожидаемыйSHA256: хэшПриёмаROOT(try Data(contentsOf: grant)), среда: s, native: { actor ?? self.native }, stop: stop, revoked: revoked)
    }
    func завершить(_ r: ПрограммаПриёмаROOT) throws -> ИсходПриёмаROOT {
        var result = ИсходПриёмаROOT(стадия: "prepare", commit: nil, повтор: false)
        for _ in 0..<8 { result = try r.выполнить(); if result.стадия == "delivered" || result.стадия == "held" { return result } }
        throw ОшибкаПриёмаROOT.отказ("fixture step budget")
    }
    func число(_ verb: String) throws -> Int {
        let files = FileManager.default.enumerator(at: среда.logs, includingPropertiesForKeys: nil)!
        var n = 0
        for case let f as URL in files where f.lastPathComponent == "process.json" {
            let r = try JSONDecoder().decode(ПроцессПриёмаROOT.self, from: Data(contentsOf: f))
            var i = 0
            while i + 1 < r.argv.count && ["-c", "-C"].contains(r.argv[i]) { i += 2 }
            if r.executable == "/usr/bin/git" && i < r.argv.count && r.argv[i] == verb { n += 1 }
        }
        return n
    }
}

@Suite(.serialized) struct ПроверкиПрограммыПриёмаROOT {
    @Test func ПодменаCheckpointНеПодтверждаетДоставку() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст()
        let segment = try Сегмент(кореньДанных: f.среда.segment, запись: true)
        let intent: [String: Any] = ["context":c.хэш,"номер":0,"вид":"intent","стадия":"prepare","следующая":"exact"]
        let a = try segment.добавить(ОписаниеНаблюдения(идентификатор:"forged-0",тип:"root-acceptance"),данные:JSONSerialization.data(withJSONObject:intent,options:[.sortedKeys]))
        let outcome: [String: Any] = ["context":c.хэш,"номер":1,"предыдущая":a.хэш,"вид":"outcome","стадия":"prepare","следующая":"delivered","commit":f.L]
        _ = try segment.добавить(ОписаниеНаблюдения(идентификатор:"forged-1",тип:"root-acceptance"),данные:JSONSerialization.data(withJSONObject:outcome,options:[.sortedKeys]))
        segment.закрыть()
        #expect(отказПриёма { _ = try ПрограммаПриёмаROOT(c) })
        #expect(try f.число("merge") == 0)
        #expect(try f.число("push") == 0)
    }
    @Test func TerminalReceiptТребуетСвежийRemote() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        let done = try f.завершить(r); r.закрыть()
        let changed = try ФикстураПриёмаROOT.команда("/usr/bin/git",["--git-dir",f.remote.path,"update-ref",f.ref,f.L,done.commit!],cwd:f.dir,logs:f.dir.appendingPathComponent("remote-change"))
        #expect(changed.0 == 0)
        let reopened = try ПрограммаПриёмаROOT(c)
        #expect(отказПриёма { _ = try reopened.выполнить() })
        #expect(try f.число("push") == 1)
    }
    @Test func обязательноеОкружениеПроверяетсяДоЭффекта() throws {
        let f = try ФикстураПриёмаROOT()
        for k in ["KOORDINACIYA_FUMA_DEFINITION", "KOORDINACIYA_FUMA_OPERATOR", "KOORDINACIYA_FUMA_RUN_ROOT"] {
            var env = f.среда.переменные; env.removeValue(forKey: k)
            #expect(отказПриёма { _ = try f.контекст(env) })
        }
        #expect(try f.git(["rev-parse", "HEAD"]) == f.L)
        #expect(try f.число("merge") == 0)
        let original = try Data(contentsOf: f.grant)
        let selected = f.среда.переменные["KOORDINACIYA_FUMA_OPERATOR"]!
        let alias = f.dir.appendingPathComponent("operator-alias")
        try FileManager.default.createSymbolicLink(atPath: alias.path, withDestinationPath: selected)
        var aliasGrant = try JSONSerialization.jsonObject(with: original) as! [String: Any]
        aliasGrant["pins"] = (aliasGrant["pins"] as! [[String: String]]).map { pin in
            pin["путь"] == selected ? ["путь": alias.path, "sha256": pin["sha256"]!] : pin
        }
        try JSONSerialization.data(withJSONObject: aliasGrant).write(to: f.grant)
        var aliasEnv = f.среда.переменные; aliasEnv["KOORDINACIYA_FUMA_OPERATOR"] = alias.path
        #expect(отказПриёма { _ = try f.контекст(aliasEnv) })
        try original.write(to: f.grant)
        var wrong = try JSONSerialization.jsonObject(with: Data(contentsOf: f.grant)) as! [String: Any]
        wrong["ROOT"] = UUID().uuidString
        try JSONSerialization.data(withJSONObject: wrong).write(to: f.grant)
        let r = try ПрограммаПриёмаROOT(f.контекст())
        #expect(отказПриёма { _ = try r.выполнить() })
        #expect(try f.число("merge") == 0)
    }
    @Test func реальнаяЦепочкаСМетасимволамиИДубликат() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        let result = try f.завершить(r)
        #expect(result.стадия == "delivered")
        #expect(try f.git(["show", "HEAD:путь с пробелом;$(echo nope).txt"]) == "incoming")
        #expect(try f.git(["show", "HEAD:own.txt"]) == "own branch")
        #expect(try f.git(["rev-list", "--parents", "-n", "1", "HEAD"]) == result.commit! + " " + f.L + " " + f.M)
        #expect(c.окружение["PATH"] == ProcessInfo.processInfo.environment["PATH"])
        r.закрыть(); let reopened = try ПрограммаПриёмаROOT(c)
        #expect(try reopened.выполнить().повтор)
        #expect(try f.число("push") == 1)
    }
    @Test func чужиеCustodyRefИЗанятыйИндексУдерживаются() throws {
        let f = try ФикстураПриёмаROOT()
        #expect(отказПриёма { _ = try f.контекст(actor: UUID().uuidString) })
        let c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        _ = try r.выполнить()
        try Data("local".utf8).write(to: f.W.appendingPathComponent("local.txt")); _ = try f.git(["add", "--", "local.txt"])
        #expect(отказПриёма { _ = try r.выполнить() })
        #expect(try f.число("merge") == 0)
        r.закрыть()
        var p = try JSONSerialization.jsonObject(with: Data(contentsOf: f.grant)) as! [String: Any]
        p["W"] = f.dir.appendingPathComponent("foreign").path
        try JSONSerialization.data(withJSONObject: p).write(to: f.grant)
        #expect(отказПриёма { _ = try f.контекст() })
        let f2 = try ФикстураПриёмаROOT(), r2 = try ПрограммаПриёмаROOT(f2.контекст())
        let hook = f2.W.appendingPathComponent(".git/hooks/pre-commit")
        try Data("#!/bin/sh\nexit 42\n".utf8).write(to: hook)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: hook.path)
        #expect(отказПриёма { _ = try r2.выполнить() })
        try FileManager.default.removeItem(at: hook)
        _ = try f2.git(["config", "merge.external.driver", "/usr/bin/false"])
        #expect(отказПриёма { _ = try r2.выполнить() })
        _ = try f2.git(["config", "--unset", "merge.external.driver"])
        _ = try r2.выполнить(); _ = try f2.git(["checkout", "-b", "codex/foreign-fixture"])
        #expect(отказПриёма { _ = try r2.выполнить() })
        #expect(try f2.число("merge") == 0)
    }
    @Test func неправильныеДеревоИПорядокРодителейОтклоняются() throws {
        // Тот же подготовленный parser/raw-handler, положительный контроль и точные отказы.
        try проверитьАдресныеRawОтказы363()
    }
    @Test func известныйCommitПриRawFAILНеПубликуется() throws {
        let f = try ФикстураПриёмаROOT(), r = try ПрограммаПриёмаROOT(f.контекст())
        for _ in 0..<3 { _ = try r.выполнить() }
        let C = try f.git(["rev-parse","HEAD"]); #expect(C != f.L)
        r.failpoint = .raw
        #expect(отказПриёма { _ = try r.выполнить() })
        #expect(try f.число("push") == 0)
        #expect(try r.выполнить().стадия == "held")
    }
    @Test func неизвестныйCommitВосстанавливаетсяЧтением() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        _ = try r.выполнить(); _ = try r.выполнить(); r.failpoint = .ответCommit
        #expect(отказПриёма { _ = try r.выполнить() }); r.закрыть()
        let reopened = try ПрограммаПриёмаROOT(c), result = try reopened.выполнить()
        #expect(result.повтор && result.стадия == "raw")
        #expect(try f.число("commit") == 1)
        let C = result.commit!
        let raw = try ФикстураПриёмаROOT.команда("/usr/bin/git", ["-C",f.W.path,"cat-file","commit",C],cwd:f.dir,logs:f.dir.appendingPathComponent("alternate"))
        // Тот же message/tree/parents/identity, другой raw OID из-за добавленного header.
        let text = String(decoding: raw.1, as: UTF8.self)
        let changed = Data(text.replacingCharacters(in: text.range(of: "\n\n")!, with: "\nencoding UTF-8\n\n").utf8)
        let alternate = try ФикстураПриёмаROOT.команда("/usr/bin/git",["-C",f.W.path,"hash-object","-w","-t","commit","--stdin"],cwd:f.dir,logs:f.dir.appendingPathComponent("alternate"),input:changed)
        let D = String(decoding:alternate.1,as:UTF8.self).trimmingCharacters(in:.newlines)
        _ = try f.git(["update-ref",f.ref,D,C])
        #expect(отказПриёма { _ = try reopened.выполнить() })
        #expect(try f.число("push") == 0)
        _ = try f.git(["update-ref",f.ref,C,D])
        // Отказ exact C известен, но его raw-stage outcome уже held: не переигрываем этап.
        #expect(try reopened.выполнить().стадия == "held")
        #expect(try f.число("merge") == 1)
    }
    @Test func неизвестныйPushНеПовторяетсяПослеReadback() throws {
        let f = try ФикстураПриёмаROOT(), c = try f.контекст(), r = try ПрограммаПриёмаROOT(c)
        for _ in 0..<4 { _ = try r.выполнить() }; r.failpoint = .ответPush
        #expect(отказПриёма { _ = try r.выполнить() }); r.закрыть()
        let reopened = try ПрограммаПриёмаROOT(c)
        #expect(try reopened.выполнить().повтор)
        #expect(try f.число("push") == 1)
        #expect(try f.завершить(reopened).стадия == "delivered")
        #expect(try f.число("push") == 1)
    }
    @Test func STOPОтзывИНеПодтверждённыйIntent() throws {
        let f = try ФикстураПриёмаROOT(), stop = ФлагПриёма(), revoke = ФлагПриёма()
        stop.значение = true
        let c = try f.контекст(stop: { stop.значение }, revoked: { revoke.значение }), r = try ПрограммаПриёмаROOT(c)
        #expect(try r.выполнить().стадия == "held")
        stop.значение = false; revoke.значение = true
        #expect(try r.выполнить().стадия == "held")
        revoke.значение = false; r.failpoint = .intent
        #expect(отказПриёма { _ = try r.выполнить() })
        let reopened = try ПрограммаПриёмаROOT(c)
        #expect(отказПриёма { _ = try reopened.выполнить() })
        #expect(try f.число("merge") == 0)
        #expect(try f.число("push") == 0)
        let f2 = try ФикстураПриёмаROOT(), stopped = ФлагПриёма()
        let r2 = try ПрограммаПриёмаROOT(f2.контекст(stop: { stopped.значение }))
        _ = try r2.выполнить(); _ = try r2.выполнить()
        r2.послеMerge = { stopped.значение = true }
        #expect(отказПриёма { _ = try r2.выполнить() })
        #expect(try f2.число("merge") == 1)
        #expect(try f2.число("commit") == 0)
        #expect(try f2.число("push") == 0)
    }
}

// Адресная регрессия №363; общая историческая suite не входит в выбранный запуск.
func документыЛичности363(
    rootUUID: String,
    stageUUID: String,
    W: String,
    ref: String,
    L: String,
    M: String?,
    sourceTree: String
) throws -> [String: Data] {
    let сообщение = СообщениеКоммитаКодекс(
        тема: "Проверить подготовленный запуск",
        задача: "Синтетическое поручение для проверки №363.",
        изменения: "Подготовка вызова",
        проверки: "Синтетическая проверка",
        граница: "Только фикстура",
        модель: "fixture-model",
        усилие: "high",
        идентификаторКорневойЗадачи: rootUUID)
    let этап = try ВалидаторЛичностиИСообщенияКодекс.сформироватьЭтап(
        идентификаторКорневойЗадачи: rootUUID,
        идентификаторЭтапа: stageUUID,
        операция: M == nil ? "ordinary" : "merge",
        исходнаяСсылка: ref,
        исходныйИдентификаторОбъекта: L,
        исходноеДерево: sourceTree,
        входящийИдентификаторОбъекта: M,
        сообщение: сообщение)
    let снимок = СнимокИдентичностиКодекс(
        идентификаторСнимка: "f0000000-0000-4000-8000-000000000003",
        модель: "fixture-model",
        усилие: "high",
        наблюденоВМиллисекундах: 1_700_000_000_000,
        этап: этап)
    let source = try ВалидаторЛичностиИСообщенияКодекс.закодироватьСнимок(снимок)
    let selection = try ВалидаторЛичностиИСообщенияКодекс.выбратьИсточник(
        данныеСнимка: source,
        идентификаторСнимка: снимок.идентификаторСнимка,
        этап: этап)
    let binding = try ВалидаторЛичностиИСообщенияКодекс.проверитьВыбранныйИсточник(
        данныеСнимка: source,
        данныеВыбора: selection,
        ожидаемыйЭтап: этап)
    let identity = try ВалидаторЛичностиИСообщенияКодекс.ожиданиеИдентичности(
        по: binding)
    let message = try ВалидаторЛичностиИСообщенияКодекс.закодироватьСообщение(
        сообщение)
    let path = try ВалидаторЛичностиИСообщенияКодекс.проверить(
        связывание: binding,
        данныеОжидаемойИдентичности: identity,
        данныеСообщения: message)
    return [
        "snapshot.json": source,
        "selection.json": selection,
        "identity.json": identity,
        "message.json": message,
        "message.txt": Data(path.телоСообщенияДляПроверкиСырогоКоммита.utf8),
    ]
}

struct СинтетическаяСреда363 {
    static let rootUUID = "f0000000-0000-4000-8000-000000000001"
    static let stageUUID = "f0000000-0000-4000-8000-000000000002"

    let поручение: URL
    let хэшПоручения: String
    let среда: СредаПриёмаROOT

    static func создать() throws -> Self {
        guard let base = ProcessInfo.processInfo.environment["FUM_363_FIXTURE_ROOT"] else {
            throw ОшибкаПриёмаROOT.отказ("missing-FUM_363_FIXTURE_ROOT")
        }
        let manager = FileManager.default
        let root = URL(fileURLWithPath: base).resolvingSymlinksInPath()
            .appendingPathComponent(UUID().uuidString.lowercased())
        try manager.createDirectory(at: root, withIntermediateDirectories: false,
                                    attributes: [.posixPermissions: 0o700])
        func каталог(_ имя: String) throws -> URL {
            let url = root.appendingPathComponent(имя)
            try manager.createDirectory(at: url, withIntermediateDirectories: false,
                                        attributes: [.posixPermissions: 0o700])
            return url
        }
        var pins: [PinПриёмаROOT] = []
        func файл(_ имя: String, _ bytes: Data, mode: Int = 0o600) throws -> URL {
            let url = root.appendingPathComponent(имя)
            try bytes.write(to: url, options: .withoutOverwriting)
            try manager.setAttributes([.posixPermissions: mode], ofItemAtPath: url.path)
            pins.append(PinПриёмаROOT(путь: url.path, sha256: хэшПриёмаROOT(bytes)))
            return url
        }
        func json(_ value: [String: Any]) throws -> Data {
            try JSONSerialization.data(withJSONObject: value,
                options: [.sortedKeys, .withoutEscapingSlashes])
        }
        func ссылка(_ url: URL) throws -> [String: String] {
            ["path": url.path, "sha256": хэшПриёмаROOT(try Data(contentsOf: url))]
        }

        let W = try каталог("worktree")
        let segment = try каталог("segment")
        let logs = try каталог("logs")
        let runRoot = try каталог("fuma-runs")
        let runtimeRoot = try каталог("runtime")
        let memoryRoot = try каталог("memory")
        let metadata = try файл("metadata-executable",
            Data("synthetic metadata executable; never launched\n".utf8), mode: 0o700)
        let state = try файл("metadata-state.json", Data("{}".utf8))
        let program = try файл("root-program.json", Data("{}".utf8))
        let definition = try файл("definition.json", Data("{}".utf8))
        let operation = try файл("operator-executable",
            Data("synthetic operator executable; never launched\n".utf8), mode: 0o700)

        let ref = "refs/heads/codex/fixture-363"
        let L = String(repeating: "a", count: 40)
        let M = String(repeating: "b", count: 40)
        let sourceTree = String(repeating: "c", count: 40)
        let commitTree = String(repeating: "d", count: 40)
        let docs = try документыЛичности363(
            rootUUID: rootUUID, stageUUID: stageUUID, W: W.path,
            ref: ref, L: L, M: M, sourceTree: sourceTree)
        var urls: [String: URL] = [:]
        for name in docs.keys.sorted() {
            urls[name] = try файл(name, docs[name]!)
        }

        let preparation = try файл("preparation.json", json([
            "schema": "fum.codex-commit-run-preparation.1",
            "context": [
                "rootUUID": rootUUID, "stageUUID": stageUUID,
                "physicalW": W.path, "fullRef": ref, "head": L,
                "sourceTree": sourceTree, "commitTree": commitTree,
                "parents": [L, M],
            ],
            "documents": [
                "snapshot": try ссылка(urls["snapshot.json"]!),
                "selection": try ссылка(urls["selection.json"]!),
                "identity": try ссылка(urls["identity.json"]!),
                "message": try ссылка(urls["message.json"]!),
                "messageFile": try ссылка(urls["message.txt"]!),
            ],
            "identity": [
                "authorEmail": "fixture-author@local",
                "authorDate": ["seconds": Int64(1_700_000_000), "offset": "+0000"],
                "committerName": "Fixture Committer",
                "committerEmail": "fixture-committer@local",
                "committerDate": ["seconds": Int64(1_700_000_000), "offset": "+0000"],
            ],
            "runtime": [
                "metadataExecutable": try ссылка(metadata),
                "metadataState": try ссылка(state),
                "definition": try ссылка(definition),
                "operator": try ссылка(operation),
                "privateRunRoot": runRoot.path,
                "runtimeRoot": runtimeRoot.path,
                "memoryRoot": memoryRoot.path,
            ],
        ]))
        let selectorBytes = try json([
            "schema": "fum.codex-commit-run-selector.1",
            "preparation": try ссылка(preparation),
        ])
        let selector = try файл("selector.json", selectorBytes)

        let variables = [
            "KOORDINACIYA_FUMA_DEFINITION": definition.path,
            "KOORDINACIYA_FUMA_OPERATOR": operation.path,
            "KOORDINACIYA_FUMA_RUN_ROOT": runRoot.path,
            "FUM_RUNTIME_ROOT": runtimeRoot.path,
            "FUM_MEMORY_ROOT": memoryRoot.path,
            "FUM_COMMIT_PREPARATION": selector.path,
            "FUM_COMMIT_PREPARATION_SHA256": хэшПриёмаROOT(selectorBytes),
        ]
        let grant = ПоручениеПриёмаROOT(
            схема: "fum.root-acceptance-program.1",
            идентификатор: "fixture-363", ROOT: rootUUID, писатель: stageUUID,
            W: W.path, ref: ref,
            origin: root.appendingPathComponent("remote.git").absoluteString,
            L: L, M: M, дерево: commitTree,
            пути: ["synthetic.txt"], pins: pins)
        let grantBytes = try байтыПриёмаROOT(grant)
        let grantURL = root.appendingPathComponent("grant.json")
        try grantBytes.write(to: grantURL, options: .withoutOverwriting)
        try manager.setAttributes([.posixPermissions: 0o600],
                                  ofItemAtPath: grantURL.path)

        return Self(поручение: grantURL, хэшПоручения: хэшПриёмаROOT(grantBytes),
            среда: СредаПриёмаROOT(
                metadataCLI: metadata.path, metadataState: state.path,
                программа: program.path, переменные: variables,
                segment: segment, logs: logs))
    }

    func контекст(_ variables: [String: String]? = nil) throws
        -> ПодготовленныйКонтекстПриёмаROOT {
        let env = СредаПриёмаROOT(
            metadataCLI: среда.metadataCLI, metadataState: среда.metadataState,
            программа: среда.программа, переменные: variables ?? среда.переменные,
            segment: среда.segment, logs: среда.logs)
        return try .дляЛокальнойФикстуры(
            поручение: поручение, ожидаемыйSHA256: хэшПоручения,
            среда: env, native: { Self.stageUUID })
    }
}

private func типизированныйОтказ363(_ operation: () throws -> Void) -> Bool {
    do {
        try operation()
        return false
    } catch ОшибкаПриёмаROOT.отказ(_) {
        return true
    } catch {
        return false
    }
}

@Suite("Закрытая подготовка окружения коммита №363", .serialized)
struct ПроверкиПодготовкиОкруженияКоммита363 {
    @Test func ambientНеПопадаетВПодготовленноеОкружение() throws {
        let ambient = ProcessInfo.processInfo.environment
        try #require(ambient["PATH"]?.components(separatedBy: ":")
            .contains("/FUM_363_POISON") == true)
        try #require(ambient["KOORDINACIYA_FUMA_POISON"] == "fixture-poison-363")
        let fixture = try СинтетическаяСреда363.создать()
        let context = try fixture.контекст()

        #expect(context.окружение["KOORDINACIYA_FUMA_POISON"] == nil)
        #expect(context.окружение["PATH"] == "/usr/bin:/bin")
        #expect(context.окружение["FUM_COMMIT_PREPARATION"] == nil)
        #expect(context.окружение["FUM_COMMIT_PREPARATION_SHA256"] == nil)
    }

    @Test func отсутствиеSelectorИлиSHAУдерживаетсяДоПроцесса() throws {
        let fixture = try СинтетическаяСреда363.создать()
        for key in ["FUM_COMMIT_PREPARATION", "FUM_COMMIT_PREPARATION_SHA256"] {
            var variables = fixture.среда.переменные
            variables.removeValue(forKey: key)
            #expect(типизированныйОтказ363 {
                _ = try fixture.контекст(variables)
            })
        }
    }
}

import CryptoKit

// Нативные проверки используют существующий helper с явным полным окружением.
// Нового исполнителя процессов в этом дополнении нет.

func кодироватьПроверку363(_ o: [String: Any]) throws -> Data {
    try JSONSerialization.data(withJSONObject: o, options: [.sortedKeys, .withoutEscapingSlashes])
}
func объектПроверки363(_ d: Data) throws -> [String: Any] {
    guard let o = try JSONSerialization.jsonObject(with: d) as? [String: Any] else {
        throw ОшибкаПриёмаROOT.отказ("fixture-363-json")
    }; return o
}
func отказПроверки363(_ f: () throws -> Void) -> Bool {
    do { try f(); return false } catch { return true }
}
struct ВходПроверки363 {
    let path: String
    var data: Data
    var sha: String
    var docs: [String: Data]
    func кандидат() throws -> КандидатПодготовкиЗапускаКодекс {
        try ФабрикаПодтверждённогоЗапускаКодекс.подготовить(
            выбор: ДокументПодготовкиКодекс(путь: path, данные: data),
            ожидаемыйSHA256Выбора: sha, документы: docs)
    }
    func preparationPath() throws -> String {
        (try объектПроверки363(data)["preparation"] as! [String: String])["path"]!
    }
    mutating func изменить(_ f: (inout [String: Any]) -> Void) throws {
        let p = try preparationPath()
        var o = try объектПроверки363(docs[p]!); f(&o)
        let b = try кодироватьПроверку363(o); docs[p] = b
        var s = try объектПроверки363(data)
        s["preparation"] = ["path": p, "sha256": хэшПриёмаROOT(b)]
        data = try кодироватьПроверку363(s); sha = хэшПриёмаROOT(data); docs[path] = data
    }
}
func входПроверки363(_ f: СинтетическаяСреда363) throws -> ВходПроверки363 {
    let g = try JSONDecoder().decode(ПоручениеПриёмаROOT.self, from: Data(contentsOf: f.поручение))
    var d: [String: Data] = [:]
    for p in g.pins { d[p.путь] = try Data(contentsOf: URL(fileURLWithPath: p.путь)) }
    let p = f.среда.переменные["FUM_COMMIT_PREPARATION"]!
    return ВходПроверки363(path: p, data: d[p]!,
        sha: f.среда.переменные["FUM_COMMIT_PREPARATION_SHA256"]!, docs: d)
}
func наблюдениеПроверки363(
    _ e: КонтекстЗапускаКодекс, root: String? = nil, stage: String? = nil,
    W: String? = nil, ref: String? = nil, head: String? = nil,
    sourceTree: String? = nil, indexTree: String? = nil, parents: [String]? = nil
) -> НаблюдённыйКонтекстЗапускаКодекс {
    НаблюдённыйКонтекстЗапускаКодекс(
        идентификаторКорневойЗадачи: root ?? e.идентификаторКорневойЗадачи,
        идентификаторЭтапа: stage ?? e.идентификаторЭтапа,
        физическийКорень: W ?? e.физическийКорень, полныйRef: ref ?? e.полныйRef,
        исходныйOID: head ?? e.исходныйOID, исходноеДерево: sourceTree ?? e.исходноеДерево,
        деревоИндекса: indexTree ?? e.деревоКоммита, родители: parents ?? e.родители)
}
func идентификаторПроверки363(_ d: Data) -> String {
    var framed = Data("commit \(d.count)\u{0}".utf8); framed.append(d)
    return Insecure.SHA1.hash(data: framed).map { String(format: "%02x", $0) }.joined()
}
func сыройКоммитПроверки363(
    _ c: КандидатПодготовкиЗапускаКодекс, body: Data, tree: String? = nil,
    parents: [String]? = nil, author: String? = nil, authorEmail: String? = nil,
    authorDate: String? = nil, committer: String? = nil,
    committerEmail: String? = nil, committerDate: String? = nil
) -> Data {
    let e = c.ожидаемыйКонтекст, v = c.окружениеGit
    var s = "tree " + (tree ?? e.деревоКоммита) + "\n"
    for p in parents ?? e.родители { s += "parent " + p + "\n" }
    s += "author " + (author ?? v["GIT_AUTHOR_NAME"]!) + " <" +
        (authorEmail ?? v["GIT_AUTHOR_EMAIL"]!) + "> " +
        (authorDate ?? String(v["GIT_AUTHOR_DATE"]!.dropFirst())) + "\n"
    s += "committer " + (committer ?? v["GIT_COMMITTER_NAME"]!) + " <" +
        (committerEmail ?? v["GIT_COMMITTER_EMAIL"]!) + "> " +
        (committerDate ?? String(v["GIT_COMMITTER_DATE"]!.dropFirst())) + "\n\n"
    var d = Data(s.utf8); d.append(body); return d
}

extension ПроверкиПодготовкиОкруженияКоммита363 {
    @Test func контекстИНеизвестностьУдерживаютсяДоДопускаКИсполнителю() throws {
        let f = try СинтетическаяСреда363.создать()
        let c = try f.контекст().кандидатЗапуска, e = c.ожидаемыйКонтекст
        let p = try ФабрикаПодтверждённогоЗапускаКодекс.подтвердить(
            c, наблюдённыйКонтекст: наблюдениеПроверки363(e))
        #expect(p.запускGit.окружение == c.окружениеGit)
        #expect(p.запускМетаданных.окружение == c.окружениеМетаданных)
        #expect(p.источникМоделиАутентифицирован == false)
        let foreign = "f0000000-0000-4000-8000-000000000009"
        let wrong = [
            наблюдениеПроверки363(e, root: foreign), наблюдениеПроверки363(e, stage: foreign),
            наблюдениеПроверки363(e, W: e.физическийКорень + "-foreign"),
            наблюдениеПроверки363(e, ref: "refs/heads/codex/foreign-363"),
            наблюдениеПроверки363(e, head: String(repeating: "e", count: 40)),
            наблюдениеПроверки363(e, sourceTree: String(repeating: "e", count: 40)),
            наблюдениеПроверки363(e, indexTree: String(repeating: "e", count: 40)),
            наблюдениеПроверки363(e, parents: Array(e.родители.reversed())),
            наблюдениеПроверки363(e, parents: []),
        ]
        var допусков = 0
        for o in wrong {
            #expect(отказПроверки363 {
                _ = try ФабрикаПодтверждённогоЗапускаКодекс.подтвердить(c, наблюдённыйКонтекст: o)
                допусков += 1
            })
        }
        #expect(допусков == 0)
    }
    @Test func emailДатыНеизвестныеПоляИХэшиНеСоздаютКандидата() throws {
        let original = try входПроверки363(СинтетическаяСреда363.создать())
        var hash = original; hash.sha = String(repeating: "0", count: 64)
        #expect(отказПроверки363 { _ = try hash.кандидат() })
        let changes: [(inout [String: Any]) -> Void] = [
            { $0["schema"] = "fum.unknown-preparation.1" },
            { $0["unexpected"] = true },
            { var v = $0["identity"] as! [String: Any]; v["authorEmail"] = "bad\naddress@local"; $0["identity"] = v },
            { var v = $0["identity"] as! [String: Any]; v["committerEmail"] = "bad\raddress@local"; $0["identity"] = v },
            { var v = $0["identity"] as! [String: Any]; v["authorName"] = "Forged"; $0["identity"] = v },
            { var v = $0["identity"] as! [String: Any]; v["authorDate"] = ["seconds": Int64(-1), "offset": "+0000"]; $0["identity"] = v },
            { var v = $0["identity"] as! [String: Any]; v["committerDate"] = ["seconds": "1700000000", "offset": "+0000"]; $0["identity"] = v },
            { var v = $0["identity"] as! [String: Any]; v["authorDate"] = ["seconds": Int64(1_700_000_000), "offset": "+2460"]; $0["identity"] = v },
            { var v = $0["runtime"] as! [String: Any]; v["environment"] = ["GIT_AUTHOR_NAME": "Forged"]; $0["runtime"] = v },
        ]
        var кандидатов = 0
        for change in changes {
            var v = original; try v.изменить(change)
            #expect(отказПроверки363 { _ = try v.кандидат(); кандидатов += 1 })
        }
        let prep = try объектПроверки363(original.docs[original.preparationPath()]!)
        let refs = prep["documents"] as! [String: [String: String]]
        let snapshot = refs["snapshot"]!["path"]!
        var missing = original; missing.docs.removeValue(forKey: snapshot)
        #expect(отказПроверки363 { _ = try missing.кандидат(); кандидатов += 1 })
        var changed = original; changed.docs[snapshot]!.append(0x0a)
        #expect(отказПроверки363 { _ = try changed.кандидат(); кандидатов += 1 })
        #expect(кандидатов == 0)
    }
    @Test func полныйRawСверяетКонтекстIdentityДатыИТело() throws {
        let f = try СинтетическаяСреда363.создать()
        let c = try f.контекст().кандидатЗапуска
        let body = try Data(contentsOf: f.среда.logs.deletingLastPathComponent().appendingPathComponent("message.txt"))
        let raw = сыройКоммитПроверки363(c, body: body)
        let r = try ПолнаяПроверкаСырогоКоммитаКодекс.проверить(
            байты: raw, наблюдаемыйOID: идентификаторПроверки363(raw), ожидание: c.ожиданиеСырогоКоммита)
        #expect(r.источникМоделиАутентифицирован == false)
        var changedBody = body; changedBody.append(0x0a)
        let wrong = [
            сыройКоммитПроверки363(c, body: body, tree: String(repeating: "e", count: 40)),
            сыройКоммитПроверки363(c, body: body, parents: Array(c.ожидаемыйКонтекст.родители.reversed())),
            сыройКоммитПроверки363(c, body: body, author: "Forged"),
            сыройКоммитПроверки363(c, body: body, authorEmail: "foreign-author@local"),
            сыройКоммитПроверки363(c, body: body, authorDate: "1700000001 +0000"),
            сыройКоммитПроверки363(c, body: body, committer: "Foreign Committer"),
            сыройКоммитПроверки363(c, body: body, committerEmail: "foreign-committer@local"),
            сыройКоммитПроверки363(c, body: body, committerDate: "1700000001 +0000"),
            сыройКоммитПроверки363(c, body: changedBody),
        ]
        for d in wrong {
            #expect(отказПроверки363 { _ = try ПолнаяПроверкаСырогоКоммитаКодекс.проверить(
                байты: d, наблюдаемыйOID: идентификаторПроверки363(d), ожидание: c.ожиданиеСырогоКоммита) })
        }
        #expect(отказПроверки363 { _ = try ПолнаяПроверкаСырогоКоммитаКодекс.проверить(
            байты: raw, наблюдаемыйOID: String(repeating: "0", count: 40), ожидание: c.ожиданиеСырогоКоммита) })
    }
}

// Counts/receipts around the existing helper. No new Process runner.
private final class УчётGitПроверки363 {
    let logs: URL
    private(set) var число = 0
    private(set) var коммитов = 0
    private(set) var слияний = 0
    static let setup = [
        "PATH": "/usr/bin:/bin", "LANG": "C", "LC_ALL": "C",
        "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_SYSTEM": "/dev/null",
        "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_OPTIONAL_LOCKS": "0", "GIT_TERMINAL_PROMPT": "0",
        "GIT_AUTHOR_NAME": "Synthetic Ancestor", "GIT_AUTHOR_EMAIL": "fixture-ancestor@local",
        "GIT_AUTHOR_DATE": "@1700000000 +0000", "GIT_COMMITTER_NAME": "Synthetic Ancestor",
        "GIT_COMMITTER_EMAIL": "fixture-ancestor@local", "GIT_COMMITTER_DATE": "@1700000000 +0000",
    ]
    let common = ["--no-optional-locks", "--no-replace-objects", "-c", "core.hooksPath=/dev/null",
        "-c", "core.fsmonitor=false", "-c", "maintenance.auto=false", "-c", "gc.auto=0",
        "-c", "commit.gpgSign=false"]
    init(logs: URL) throws {
        self.logs = logs
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    }
    private func verb(_ a: [String]) -> String {
        var i = 0
        while i < a.count {
            if ["-c", "-C"].contains(a[i]) { i += 2 }
            else if ["--no-optional-locks", "--no-replace-objects"].contains(a[i]) { i += 1 }
            else { break }
        }; return i < a.count ? a[i] : ""
    }
    @discardableResult func git(
        _ a: [String], W: URL, env: [String: String] = УчётGitПроверки363.setup,
        input: Data? = nil, exact: Bool = false
    ) throws -> Data {
        guard число < 32 else { throw ОшибкаПриёмаROOT.отказ("fixture-363-Git-budget") }
        число += 1; let argv = exact ? a : common + a
        if verb(argv) == "commit" { коммитов += 1 }; if verb(argv) == "merge" { слияний += 1 }
        let d = logs.appendingPathComponent(String(format: "git-%02d", число))
        try FileManager.default.createDirectory(at: d, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        func record(_ name: String, _ o: [String: Any]) throws {
            let p = d.appendingPathComponent(name)
            try кодироватьПроверку363(o).write(to: p, options: .withoutOverwriting)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: p.path)
        }
        try record("intent.json", ["ordinal": число, "executable": "/usr/bin/git", "argv": argv,
            "cwd": W.path, "environment": env, "stdinSHA256": хэшПриёмаROOT(input ?? Data())])
        let r: (Int32, Data)
        do { r = try ФикстураПриёмаROOT.команда("/usr/bin/git", argv, cwd: W, logs: d,
            input: input, полноеОкружение: env) }
        catch {
            try record("outcome.json", ["ordinal": число, "state": "unknown", "errorType": String(reflecting: type(of: error))])
            throw error
        }
        try record("outcome.json", ["ordinal": число, "exit": r.0, "stdoutSHA256": хэшПриёмаROOT(r.1)])
        try #require(r.0 == 0); return r.1
    }
}
private func идентификаторВыводаПроверки363(_ d: Data) throws -> String {
    let s = String(decoding: d, as: UTF8.self).trimmingCharacters(in: .newlines)
    try #require(s.utf8.count == 40 && s.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) })
    return s
}
private func нативныйКандидатПроверки363(
    _ f: СинтетическаяСреда363, W: URL, L: String, M: String?, sourceTree: String, commitTree: String
) throws -> КандидатПодготовкиЗапускаКодекс {
    let root = f.среда.logs.deletingLastPathComponent().appendingPathComponent("native-source-" + UUID().uuidString.lowercased())
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
    var documents: [String: Data] = [:]
    func file(_ name: String, _ d: Data) throws -> URL {
        let p = root.appendingPathComponent(name)
        try d.write(to: p, options: .withoutOverwriting)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: p.path)
        documents[p.path] = d; return p
    }
    func ref(_ p: URL) throws -> [String: String] {
        if documents[p.path] == nil { documents[p.path] = try Data(contentsOf: p) }
        return ["path": p.path, "sha256": хэшПриёмаROOT(documents[p.path]!)]
    }
    let fullRef = "refs/heads/codex/fixture-363", v = f.среда.переменные
    let identity = try документыЛичности363(rootUUID: СинтетическаяСреда363.rootUUID,
        stageUUID: СинтетическаяСреда363.stageUUID, W: W.path, ref: fullRef,
        L: L, M: M, sourceTree: sourceTree)
    var urls: [String: URL] = [:]
    for n in identity.keys.sorted() { urls[n] = try file(n, identity[n]!) }
    let prep = try file("preparation.json", кодироватьПроверку363([
        "schema": "fum.codex-commit-run-preparation.1",
        "context": ["rootUUID": СинтетическаяСреда363.rootUUID, "stageUUID": СинтетическаяСреда363.stageUUID,
            "physicalW": W.path, "fullRef": fullRef, "head": L, "sourceTree": sourceTree,
            "commitTree": commitTree, "parents": M.map { [L, $0] } ?? [L]],
        "documents": ["snapshot": try ref(urls["snapshot.json"]!), "selection": try ref(urls["selection.json"]!),
            "identity": try ref(urls["identity.json"]!), "message": try ref(urls["message.json"]!),
            "messageFile": try ref(urls["message.txt"]!)],
        "identity": ["authorEmail": "fixture-author@local",
            "authorDate": ["seconds": Int64(1_700_000_000), "offset": "+0000"],
            "committerName": "Fixture Committer", "committerEmail": "fixture-committer@local",
            "committerDate": ["seconds": Int64(1_700_000_000), "offset": "+0000"]],
        "runtime": ["metadataExecutable": try ref(URL(fileURLWithPath: f.среда.metadataCLI)),
            "metadataState": try ref(URL(fileURLWithPath: f.среда.metadataState)),
            "definition": try ref(URL(fileURLWithPath: v["KOORDINACIYA_FUMA_DEFINITION"]!)),
            "operator": try ref(URL(fileURLWithPath: v["KOORDINACIYA_FUMA_OPERATOR"]!)),
            "privateRunRoot": v["KOORDINACIYA_FUMA_RUN_ROOT"]!, "runtimeRoot": v["FUM_RUNTIME_ROOT"]!,
            "memoryRoot": v["FUM_MEMORY_ROOT"]!],
    ]))
    let selectorBytes = try кодироватьПроверку363(["schema": "fum.codex-commit-run-selector.1", "preparation": try ref(prep)])
    let selector = try file("selector.json", selectorBytes)
    return try ФабрикаПодтверждённогоЗапускаКодекс.подготовить(
        выбор: ДокументПодготовкиКодекс(путь: selector.path, данные: selectorBytes),
        ожидаемыйSHA256Выбора: хэшПриёмаROOT(selectorBytes), документы: documents)
}
private enum ПотеряОтветаПроверки363: Error { case послеКоммита }

extension ПроверкиПодготовкиОкруженияКоммита363 {
    @Test func обычныйИMergeКоммитыПроверяютсяЗаТридцатьОдинGitВызов() throws {
        let ordinary = try СинтетическаяСреда363.создать()
        let counter = try УчётGitПроверки363(logs: ordinary.среда.logs.appendingPathComponent("native-git"))
        for isMerge in [false, true] {
            let f = try (isMerge ? СинтетическаяСреда363.создать() : ordinary)
            let grant = try JSONDecoder().decode(ПоручениеПриёмаROOT.self, from: Data(contentsOf: f.поручение))
            let W = URL(fileURLWithPath: grant.W), ref = "refs/heads/codex/fixture-363"
            try counter.git(["init", "--object-format=sha1", "--initial-branch=codex/fixture-363", "."], W: W)
            let T0 = try идентификаторВыводаПроверки363(counter.git(["hash-object", "-w", "-t", "tree", "--stdin"], W: W, input: Data()))
            let base = try идентификаторВыводаПроверки363(counter.git(["commit-tree", T0], W: W,
                input: Data((isMerge ? "Synthetic common base\n" : "Synthetic ordinary base\n").utf8)))
            let L: String, M: String?
            if isMerge {
                L = try идентификаторВыводаПроверки363(counter.git(["commit-tree", T0, "-p", base], W: W, input: Data("Synthetic left\n".utf8)))
                M = try идентификаторВыводаПроверки363(counter.git(["commit-tree", T0, "-p", base], W: W, input: Data("Synthetic right\n".utf8)))
            } else { L = base; M = nil }
            try counter.git(["update-ref", ref, L], W: W)
            let targetTree: String
            if let M {
                targetTree = T0
                try counter.git(["read-tree", T0], W: W)
                try counter.git(["merge", "--no-commit", "--no-ff", M], W: W)
            } else {
                let content = Data("ordinary fixture\n".utf8)
                let B = try идентификаторВыводаПроверки363(counter.git(["hash-object", "-w", "--stdin"], W: W, input: content))
                targetTree = try идентификаторВыводаПроверки363(counter.git(["mktree"], W: W,
                    input: Data("100644 blob \(B)\tsynthetic.txt\n".utf8)))
                try content.write(to: W.appendingPathComponent("synthetic.txt"), options: .withoutOverwriting)
                try counter.git(["read-tree", targetTree], W: W)
            }
            let c = try нативныйКандидатПроверки363(f, W: W, L: L, M: M, sourceTree: T0, commitTree: targetTree)
            let observed = try НаблюдательКонтекстаПодготовкиКодекс.прочитать(c, доверенныйROOT: СинтетическаяСреда363.rootUUID, доверенныйЭтап: СинтетическаяСреда363.stageUUID, выполнитьGit: {
                try counter.git($0, W: W, env: c.окружениеGit)
            })
            let p = try ФабрикаПодтверждённогоЗапускаКодекс.подтвердить(c, наблюдённыйКонтекст: observed)
            try #require(p.запускGit.исполняемыйФайл == "/usr/bin/git")
            try #require(p.запускGit.рабочийКаталог == W.path)
            let stdin = try #require(p.запускGit.стандартныйВвод)
            let messagePin = try #require(c.закреплённыеФайлы.first { URL(fileURLWithPath: $0.путь).lastPathComponent == "message.txt" })
            let pending: ФикстураВозобновления363?
            if let M {
                let fixture = try ФикстураВозобновления363(f, кандидат: c, W: W, L: L, M: M, дерево: targetTree, счётчик: counter)
                let initial = try fixture.программа()
                try initial.сохранитьНамерениеMergeДляФикстуры()
                initial.закрыть()
                pending = fixture
            } else { pending = nil }
            // Подмена после последней проверки pathname не меняет уже проверенный stdin.
            try Data("unverified replacement\n".utf8).write(to: URL(fileURLWithPath: messagePin.путь))
            do {
                try counter.git(p.запускGit.аргументы, W: W, env: p.запускGit.окружение, input: stdin, exact: true)
                if isMerge { throw ПотеряОтветаПроверки363.послеКоммита }
            } catch ПотеряОтветаПроверки363.послеКоммита {
                // Намерение уже на диске; второй mutating launch не разрешён.
            }
            try stdin.write(to: URL(fileURLWithPath: messagePin.путь))
            let C: String, raw: Data
            if let pending {
                let resumed = try pending.программа()
                defer { resumed.закрыть() }
                let result = try resumed.выполнить()
                C = try #require(result.commit)
                raw = pending.сыройКоммит
                #expect(result.повтор && result.стадия == "raw")
                #expect(pending.запрещённыхМутаций == 0)
            } else {
                C = try идентификаторВыводаПроверки363(counter.git(["rev-parse", "HEAD"], W: W, env: p.запускGit.окружение))
                raw = try counter.git(["cat-file", "commit", C], W: W, env: p.запускGit.окружение)
            }
            _ = try ПолнаяПроверкаСырогоКоммитаКодекс.проверить(
                байты: raw, наблюдаемыйOID: C, ожидание: p.ожиданиеСырогоКоммита)
            #expect(идентификаторПроверки363(raw) == C)
            #expect(try counter.git(["status", "--porcelain=v1", "-z"], W: W, env: p.запускGit.окружение).isEmpty)
            #expect(отказПроверки363 { _ = try ФабрикаПодтверждённогоЗапускаКодекс.подтвердить(
                c, наблюдённыйКонтекст: наблюдениеПроверки363(c.ожидаемыйКонтекст, head: C)) })
            #expect(counter.число == (isMerge ? 31 : 15))
            #expect(counter.коммитов == (isMerge ? 2 : 1))
            #expect(counter.слияний == (isMerge ? 1 : 0))
        }
    }
}

// Два реальных чтения результата проходят через production pending-resume.
// Служебные RO-наблюдения и исторические FUMA-переходы здесь инъецированы;
// это не исполнение production FUMA и не проверка удалённого origin.
private final class ФикстураВозобновления363 {
    let контекст: ПодготовленныйКонтекстПриёмаROOT
    let W: URL
    let origin: String
    let счётчик: УчётGitПроверки363
    private(set) var запрещённыхМутаций = 0
    private(set) var сыройКоммит = Data()

    init(_ f: СинтетическаяСреда363, кандидат: КандидатПодготовкиЗапускаКодекс,
        W: URL, L: String, M: String, дерево: String, счётчик: УчётGitПроверки363) throws {
        self.W = W; self.счётчик = счётчик
        let originURL = f.среда.logs.deletingLastPathComponent().appendingPathComponent("pending-remote.git").absoluteString
        origin = originURL
        var pins = кандидат.закреплённыеФайлы.map { PinПриёмаROOT(путь: $0.путь, sha256: $0.хэш) }
        pins.append(PinПриёмаROOT(путь: f.среда.программа,
            sha256: хэшПриёмаROOT(try Data(contentsOf: URL(fileURLWithPath: f.среда.программа)))))
        let p = ПоручениеПриёмаROOT(схема: "fum.root-acceptance-program.1", идентификатор: "pending-363",
            ROOT: СинтетическаяСреда363.rootUUID, писатель: СинтетическаяСреда363.stageUUID,
            W: W.path, ref: "refs/heads/codex/fixture-363", origin: originURL,
            L: L, M: M, дерево: дерево, пути: ["synthetic.txt"], pins: pins)
        let bytes = try байтыПриёмаROOT(p)
        let file = f.среда.logs.appendingPathComponent("pending-grant.json")
        try bytes.write(to: file, options: .withoutOverwriting)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: file.path)
        let runtime = кандидат.средаГенератора
        var input: [String: String] = [:]
        for key in ["KOORDINACIYA_FUMA_DEFINITION", "KOORDINACIYA_FUMA_OPERATOR", "KOORDINACIYA_FUMA_RUN_ROOT", "FUM_RUNTIME_ROOT", "FUM_MEMORY_ROOT"] {
            input[key] = кандидат.окружениеМетаданных[key]
        }
        let args = кандидат.командаМетаданных.аргументы
        let selectorIndex = try #require(args.firstIndex(of: "--подготовка-запуска"))
        let hashIndex = try #require(args.firstIndex(of: "--sha256"))
        input["FUM_COMMIT_PREPARATION"] = args[selectorIndex + 1]
        input["FUM_COMMIT_PREPARATION_SHA256"] = args[hashIndex + 1]
        let env = СредаПриёмаROOT(metadataCLI: runtime.исполняемыйФайлМетаданных.путь,
            metadataState: runtime.состояниеМетаданных.путь, программа: f.среда.программа,
            переменные: input, segment: f.среда.segment, logs: f.среда.logs)
        контекст = try .дляЛокальнойФикстуры(поручение: file, ожидаемыйSHA256: хэшПриёмаROOT(bytes),
            среда: env, native: { СинтетическаяСреда363.stageUUID })
    }

    func программа() throws -> ПрограммаПриёмаROOT {
        try ПрограммаПриёмаROOT(контекст, наблюденияФикстуры: { try self.наблюдать($0, $1) },
            шагФикстуры: { stage in
                switch stage {
                case "prepare": return ("prepare", "exact")
                case "exact": return ("exact", "merge")
                case "merge": return ("merge", "raw")
                default: throw ОшибкаПриёмаROOT.отказ("unexpected-fixture-policy-stage")
                }
            })
    }

    private func наблюдать(_ executable: String, _ args: [String]) throws -> (Int32, Data)? {
        guard executable == "/usr/bin/git" else { throw ОшибкаПриёмаROOT.отказ("unexpected-fixture-process") }
        var i = 0
        while i < args.count {
            if ["-c", "-C"].contains(args[i]) { i += 2 }
            else if ["--no-optional-locks", "--no-replace-objects"].contains(args[i]) { i += 1 }
            else { break }
        }
        let tail = Array(args.dropFirst(i))
        guard let verb = tail.first else { throw ОшибкаПриёмаROOT.отказ("empty-fixture-command") }
        if verb == "commit" || verb == "merge" {
            запрещённыхМутаций += 1
            throw ОшибкаПриёмаROOT.отказ("duplicate-mutating-launch")
        }
        if tail == ["rev-parse", "--show-toplevel"] { return (0, Data((W.path + "\n").utf8)) }
        if tail == ["symbolic-ref", "HEAD"] { return (0, Data("refs/heads/codex/fixture-363\n".utf8)) }
        if tail == ["remote", "get-url", "origin"] { return (0, Data((origin + "\n").utf8)) }
        if tail == ["rev-parse", "--git-path", "hooks"] { return (0, Data((W.appendingPathComponent(".git/hooks").path + "\n").utf8)) }
        if verb == "config" { return (1, Data()) }
        if tail == ["rev-parse", "HEAD"] || (tail.count == 3 && tail[0] == "cat-file" && tail[1] == "commit") {
            let bytes = try счётчик.git(args, W: W, env: контекст.кандидатЗапуска.окружениеGit, exact: true)
            if verb == "cat-file" { сыройКоммит = bytes }
            return (0, bytes)
        }
        throw ОшибкаПриёмаROOT.отказ("unexpected-fixture-read")
    }
}

// Только синтетический результат callback: этот helper не запускает FUMA и не удостоверяет backend.
func метаданныеПроверки363(_ c: КандидатПодготовкиЗапускаКодекс) throws -> РезультатГенерацииМетаданныхКоммита {
    let e = c.ожиданиеСырогоКоммита
    let snapshot = try JSONDecoder().decode(СнимокИдентичностиКодекс.self, from: e.данныеСнимка)
    let unavailable = ИдентичностьAPI(статус: .недоступен, вид: .идентификаторВызова, значение: nil)
    let witness = СвидетельствоВыбораМодели(источник: .корневыеNativeClientMetadata,
        rootUUID: c.ожидаемыйКонтекст.идентификаторКорневойЗадачи,
        sessionIdentity: ИдентичностьAPI(статус: .доступен, вид: .идентификаторNativeThreadMetadata,
            значение: c.ожидаемыйКонтекст.идентификаторЭтапа),
        requestIdentity: unavailable, responseIdentity: unavailable, nativeThread: nil,
        requestedSelection: nil,
        selectedValue: ПараметрыВыбораAPI(model: snapshot.модель, reasoningEffort: snapshot.усилие),
        nativeSelectionSourceSHA256: хэшПриёмаROOT(e.данныеСнимка),
        backendModel: .неизвестно, nativeTurnContext: .неизвестно)
    return РезультатГенерацииМетаданныхКоммита(выборМодели: witness,
        автор: ИдентификаторGit(имя: e.имяАвтора, почта: e.почтаАвтора),
        коммитер: ИдентификаторGit(имя: e.имяКоммиттера, почта: e.почтаКоммиттера),
        окружение: ["GIT_AUTHOR_NAME": e.имяАвтора],
        сообщение: e.путь.телоСообщенияДляПроверкиСырогоКоммита, ошибки: [])
}
